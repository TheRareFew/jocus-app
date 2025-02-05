import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video.dart';
import 'openshot_service.dart';

class VideoUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OpenShotService _openshotService = OpenShotService();

  Future<bool> validateVideo(File video) async {
    // Get file size in MB
    final size = await video.length() / (1024 * 1024);
    if (size > 500) { // 500MB limit
      throw Exception('Video size exceeds 500MB limit');
    }

    // TODO: Add format validation
    // TODO: Add duration validation
    return true;
  }

  Future<String> _uploadToFirebaseStorage(File video, String userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final videoId = 'video_$timestamp';
    final storageRef = _storage.ref().child('videos/$userId/$videoId');
    final uploadTask = storageRef.putFile(
      video,
      SettableMetadata(
        contentType: 'video/mp4',  // Set proper content type
      ),
    );
    
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<Video> uploadVideo({
    required File video,
    required String userId,
    required String title,
    required String description,
  }) async {
    try {
      // Validate video
      await validateVideo(video);

      // Check OpenShot availability
      final isOpenShotAvailable = await _openshotService.isAvailable();
      String videoUrl;
      bool isProcessed = false;

      if (isOpenShotAvailable) {
        // Process with OpenShot
        final projectId = await _openshotService.uploadVideoForEditing(video);
        
        // Monitor processing status
        bool isComplete = false;
        while (!isComplete) {
          final status = await _openshotService.getEditingStatus(projectId);
          if (status['status'] == 'completed') {
            isComplete = true;
          } else if (status['status'] == 'failed') {
            throw Exception('Video processing failed');
          }
          await Future.delayed(const Duration(seconds: 5));
        }

        // Download processed video
        final processedVideoPath = await _openshotService.downloadProcessedVideo(projectId);
        final processedVideo = File(processedVideoPath);
        
        // Upload processed video to Firebase
        videoUrl = await _uploadToFirebaseStorage(processedVideo, userId);
        isProcessed = true;
        
        // Cleanup temp file
        await processedVideo.delete();
      } else {
        // Upload raw video to Firebase
        videoUrl = await _uploadToFirebaseStorage(video, userId);
      }

      // Create video document
      final videoDoc = await _firestore.collection('videos').add({
        'title': title,
        'description': description,
        'userId': userId,
        'storageUrl': videoUrl,
        'uploadDate': Timestamp.now(),
        'status': VideoStatus.ready.toString().split('.').last,
        'isProcessed': isProcessed,
        'duration': 0, // TODO: Add duration calculation
      });

      // Return video model
      return Video.fromFirestore(await videoDoc.get());
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  Future<void> deleteVideo(Video video) async {
    try {
      // Delete from storage
      final storageRef = _storage.refFromURL(video.storageUrl);
      await storageRef.delete();

      // Delete from Firestore
      await _firestore.collection('videos').doc(video.id).delete();
    } catch (e) {
      throw Exception('Failed to delete video: $e');
    }
  }
} 