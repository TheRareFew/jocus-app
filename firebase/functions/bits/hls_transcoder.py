import os
import logging
import tempfile
import ffmpeg
import requests
from urllib.parse import urlparse
from firebase_admin import storage
from firebase_admin import firestore
from firebase_functions import firestore_fn
from enum import Enum
import time
from firebase_functions import options

# Configure logging
logger = logging.getLogger('hls_transcoder')
logger.setLevel(logging.INFO)

class VideoStatus(str, Enum):
    processing = 'processing'
    ready = 'ready'
    error = 'error'

def create_hls_stream(video_url: str, video_path: str) -> str:
    """
    Convert a video file to HLS format with multiple quality levels.
    Returns the base URL for the HLS stream.
    """
    logger.info(f"Starting HLS conversion for video at {video_path}")
    
    bucket = storage.bucket('jocus-6c88f.firebasestorage.app')
    # Create temporary directory for processing
    with tempfile.TemporaryDirectory() as temp_dir:
        logger.info(f"Created temp dir: {temp_dir}")
        
        # Download video using requests (matching transcripts.py approach)
        input_path = os.path.join(temp_dir, 'input.mp4')
        logger.info(f"Downloading video from {video_url}")
        response = requests.get(video_url)
        response.raise_for_status()  # Raise an error for bad status codes
        
        with open(input_path, 'wb') as f:
            f.write(response.content)
        logger.info(f"Downloaded video to {input_path}")
        
        # Create HLS output directory
        hls_dir = os.path.join(temp_dir, 'hls')
        os.makedirs(hls_dir, exist_ok=True)
        
        # Define quality levels (resolution, bitrate)
        qualities = [
            ('240p', 426, 240, '400k'),
            ('480p', 854, 480, '800k'),
            ('720p', 1280, 720, '1800k'),
        ]
        
        # Create variant streams
        variant_streams = []
        for quality, width, height, bitrate in qualities:
            quality_dir = os.path.join(hls_dir, quality)
            os.makedirs(quality_dir, exist_ok=True)
            output_path = os.path.join(quality_dir, 'stream.m3u8')
            variant_streams.append((output_path, width, height, bitrate, quality))
            
            logger.info(f"Transcoding {quality} stream...")
            
            # First analyze the input file for audio streams
            probe = ffmpeg.probe(input_path)
            audio_streams = [stream for stream in probe['streams'] if stream['codec_type'] == 'audio']
            logger.info(f"Found {len(audio_streams)} audio streams in input file")
            for stream in audio_streams:
                logger.info(f"Audio stream: codec={stream.get('codec_name')}, channels={stream.get('channels')}, sample_rate={stream.get('sample_rate')}")
            
            # Create input streams
            input_stream = ffmpeg.input(input_path)
            
            # Separate video and audio streams
            video_stream = input_stream.video
            audio_stream = input_stream.audio
            
            # Apply filters
            video_stream = ffmpeg.filter(video_stream, 'scale', width, height)
            
            # Output with explicit stream mapping
            stream = ffmpeg.output(
                video_stream,  # Video stream
                audio_stream,  # Audio stream
                output_path,
                acodec='aac',
                vcodec='libx264',
                video_bitrate=bitrate,
                audio_bitrate='128k',
                ac=2,  # 2 audio channels (stereo)
                ar='44100',  # audio sample rate
                **{
                    'c:a': 'aac',  # Explicitly set audio codec
                    'b:a': '128k',  # Audio bitrate
                    'strict': 'experimental',  # Allow experimental codecs
                    'channel_layout': 'stereo',  # Force stereo layout
                },
                hls_time=4,
                hls_list_size=0,
                hls_flags='independent_segments+program_date_time',  # Added program_date_time for better player compatibility
                start_number=0,
                hls_segment_type='mpegts',
                hls_segment_filename=os.path.join(quality_dir, 'segment_%03d.ts'),
                f='hls'
            )
            
            try:
                # Run FFmpeg with detailed logging
                logger.info("Starting FFmpeg transcoding...")
                out, err = ffmpeg.run(stream, overwrite_output=True, capture_stdout=True, capture_stderr=True)
                if err:
                    logger.info(f"FFmpeg stderr output: {err.decode()}")
                logger.info(f"Finished transcoding {quality} stream")
                
                # Verify the output has audio
                output_probe = ffmpeg.probe(output_path)
                output_audio = [stream for stream in output_probe['streams'] if stream['codec_type'] == 'audio']
                if output_audio:
                    logger.info(f"Output stream has {len(output_audio)} audio streams")
                    for stream in output_audio:
                        logger.info(f"Output audio: codec={stream.get('codec_name')}, channels={stream.get('channels')}, sample_rate={stream.get('sample_rate')}")
                else:
                    logger.error("No audio streams found in output file!")
                    raise Exception("Transcoding failed: No audio streams in output file")
                    
            except ffmpeg.Error as e:
                logger.error(f"FFmpeg error during transcoding: {e.stderr.decode() if e.stderr else str(e)}")
                raise
        
        # Create master playlist
        master_path = os.path.join(hls_dir, 'master.m3u8')
        with open(master_path, 'w') as f:
            f.write('#EXTM3U\n')
            f.write('#EXT-X-VERSION:3\n')
            for output_path, width, height, bitrate, quality in variant_streams:
                bandwidth = int(bitrate.replace('k', '000'))
                f.write(f'#EXT-X-STREAM-INF:BANDWIDTH={bandwidth},RESOLUTION={width}x{height}\n')
                f.write(f'{quality}/stream.m3u8\n')
        
        # Upload HLS files to Firebase Storage
        hls_storage_path = video_path  # Use the provided path directly
        logger.info(f"Will upload HLS files to path: {hls_storage_path}")
        
        # First, list all files we need to upload
        files_to_upload = []
        for root, _, files in os.walk(hls_dir):
            for file in files:
                local_path = os.path.join(root, file)
                relative_path = os.path.relpath(local_path, hls_dir)
                blob_path = f"{hls_storage_path}/{relative_path}"
                files_to_upload.append((local_path, blob_path, file))
                logger.info(f"Will upload {local_path} to {blob_path}")
        
        # Now upload each file
        master_url = None
        for local_path, blob_path, filename in files_to_upload:
            try:
                # Verify file exists and is readable
                if not os.path.exists(local_path):
                    raise ValueError(f"File not found: {local_path}")
                
                file_size = os.path.getsize(local_path)
                logger.info(f"Uploading {filename} ({file_size} bytes) to {blob_path}")
                
                # Set content type based on file extension
                if filename.endswith('.m3u8'):
                    content_type = 'application/vnd.apple.mpegurl'
                elif filename.endswith('.ts'):
                    content_type = 'video/mp2t'
                else:
                    content_type = 'application/octet-stream'
                
                # Create blob and set its properties
                blob = bucket.blob(blob_path)
                blob.content_type = content_type
                
                # Upload the file with retry
                max_retries = 3
                for attempt in range(max_retries):
                    try:
                        with open(local_path, 'rb') as f:
                            blob.upload_from_file(
                                f,
                                content_type=content_type,
                                predefined_acl='publicRead'
                            )
                            logger.info(f"Upload successful for {filename}")
                        break
                    except Exception as e:
                        logger.error(f"Upload attempt {attempt + 1} failed for {filename}: {str(e)}")
                        if attempt == max_retries - 1:
                            raise
                        continue
                
                # Set cache control based on file type
                if filename == 'master.m3u8':
                    blob.cache_control = 'public, max-age=3600'  # 1 hour for master playlist
                    master_url = f"https://storage.googleapis.com/{bucket.name}/{blob_path}"
                elif filename.endswith('.m3u8'):
                    blob.cache_control = 'public, max-age=3600'  # 1 hour for variant playlists
                else:
                    blob.cache_control = 'public, max-age=31536000'  # 1 year for segments
                
                # Update the blob
                blob.patch()
                logger.info(f"Updated metadata for {filename}")
                
            except Exception as e:
                logger.error(f"Error uploading {filename}: {str(e)}")
                raise
        
        if not master_url:
            raise ValueError("Failed to upload master playlist")
        
        logger.info(f"Successfully created HLS stream at {master_url}")
        return master_url

def on_bit_created(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """Triggered when a bit document is created in Firestore"""
    try:
        logger.info("========== STARTING VIDEO PROCESSING ==========")
        
        # Get bit data
        bit_data = event.data.to_dict()
        if not bit_data:
            print("No bit data found")
            return
            
        video_url = bit_data.get('storageUrl')
        if not video_url:
            print("No video URL found in bit")
            return
            
        # Get the associated video document
        db = firestore.client()
        video_docs = db.collection('videos').where('storageUrl', '==', video_url).limit(1).get()
        if not video_docs:
            print("No associated video document found")
            return
            
        video_doc = video_docs[0]
        video_data = video_doc.to_dict()
        
        # Check if this video is in processing status
        status = video_data.get('status')
        if status != VideoStatus.processing.name:
            print(f"Video status is {status}, not processing. Skipping.")
            return
            
        # Check if this video has already been processed
        if video_data.get('isProcessed'):
            print("Video already processed")
            return
            
        try:
            logger.info(f"Downloading video from URL: {video_url}")
            # Download video data from URL (matching transcripts.py approach)
            response = requests.get(video_url)
            response.raise_for_status()  # Raise an error for bad status codes
            
            # Save video data to a temporary file
            video_path = os.path.join(tempfile.gettempdir(), 'video.mp4')
            with open(video_path, "wb") as f:
                f.write(response.content)

            # Use video ID for HLS storage path
            storage_path = f'hls/{video_doc.id}'
            
            try:
                # Create HLS stream using the Firebase download URL
                hls_url = create_hls_stream(video_url, storage_path)
                logger.info(f"HLS stream created successfully: {hls_url}")
                
                # Update the video document with HLS URL
                video_doc.reference.update({
                    'hlsUrl': hls_url,
                    'status': VideoStatus.ready.name,
                    'processingEndTime': firestore.SERVER_TIMESTAMP,
                    'isProcessed': True
                })
                logger.info(f"Successfully processed video {video_doc.id}")
            finally:
                # Clean up temporary file
                if os.path.exists(video_path):
                    os.remove(video_path)
                    logger.info("Cleaned up temporary video file")
            
        except Exception as e:
            logger.error(f"Error processing video {video_doc.id}: {str(e)}")
            logger.error(f"Stack trace:", exc_info=True)
            # Update video document with error status
            video_doc.reference.update({
                'status': VideoStatus.error.name,
                'error': str(e),
                'processingEndTime': firestore.SERVER_TIMESTAMP,
                'isProcessed': False
            })
            raise
        
    except Exception as e:
        logger.error("========== FATAL ERROR ==========")
        logger.error(str(e))
        logger.error("Stack trace:", exc_info=True)
        raise
