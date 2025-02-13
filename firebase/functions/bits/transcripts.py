from firebase_functions import firestore_fn
from firebase_admin import firestore
from openai import OpenAI
import os
import requests
from moviepy.editor import VideoFileClip
from datetime import datetime
from typing import Dict, List, Optional
from .comedy_structure import analyze_joke_transcript
from firebase_functions.https_fn import CallableRequest
from firebase_functions import options

def generate_transcript(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """Generate transcript when a new bit is created in Firestore."""
    
    bit_data = event.data.to_dict()
    if not bit_data:
        print("No bit data found")
        return
        
    video_url = bit_data.get('storageUrl')
    if not video_url:
        print("No video URL found in bit")
        return
        
    try:
        print(f"Downloading video from URL: {video_url}")
        # Download video data from URL
        response = requests.get(video_url)
        response.raise_for_status()  # Raise an error for bad status codes
        
        # Save video data to a temporary file
        video_path = "/tmp/video.mp4"
        audio_path = "/tmp/audio.mp3"
        with open(video_path, "wb") as f:
            f.write(response.content)
        
        # Convert video to audio
        print("Converting video to audio")
        video = VideoFileClip(video_path)
        video.audio.write_audiofile(audio_path)
        video.close()
        
        # Open the audio file for streaming to OpenAI
        with open(audio_path, "rb") as audio_file:
            # Generate transcript using OpenAI Whisper
            print("Initializing OpenAI client")
            client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
            
            print("Sending to OpenAI for transcription")
            transcript_response = client.audio.transcriptions.create(
                file=audio_file,
                model="whisper-1",
                response_format="verbose_json",
                timestamp_granularities=["word"]
            )
        
        # Extract transcript with timestamps
        print("Processing transcript response")
        transcript_data = transcript_response.to_dict()
        
        # Format the transcript data with word-level timestamps
        words = transcript_data['words']
        for word in words:
            word['start'] = round(word['start'], 2)
            word['end'] = round(word['end'], 2)
            
        formatted_transcript = {
            'text': transcript_data['text'],
            'words': words,
            'language': transcript_data.get('language', 'en')
        }
        
        # Update the bit document with the transcript
        print(f"Updating bit document {event.data.id} with transcript")
        event.data.reference.update({
            'transcript': formatted_transcript
        })

        # Clean up temporary files
        os.remove(video_path)
        os.remove(audio_path)
        
        # After transcript is generated, call the analyze_joke_transcript API
        try:
            print("Analyzing comedy structure from transcript")
            functions_url = "https://us-central1-jocus-6c88f.cloudfunctions.net/analyze_joke_transcript"
            request_data = {
                'data': {
                    'transcript': formatted_transcript['text'],
                    'userId': bit_data.get('userId'),
                    'wordTimings': formatted_transcript['words']
                }
            }
            print(f"Sending request with data: {request_data}")
            response = requests.post(functions_url, json=request_data)
            response.raise_for_status()
            print(f"Comedy structure generated with ID: {response.json()['id']}")
            
        except Exception as e:
            print(f"Error analyzing comedy structure: {str(e)}")
            # Don't raise the error - we don't want to fail the transcript generation
            # if comedy structure analysis fails
            
    except Exception as e:
        print(f"Error generating transcript: {str(e)}")
        raise  # Re-raise the exception to ensure Cloud Functions marks this as failed
