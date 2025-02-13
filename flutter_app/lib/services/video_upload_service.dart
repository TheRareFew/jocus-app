import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video.dart';
import '../models/comedy_structure.dart';
import '../models/bit.dart';

class VideoUploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> validateVideo(File video) async {
    final size = await video.length();
    if (size > 100 * 1024 * 1024) { // 100MB limit
      throw Exception('Video size exceeds 100MB limit');
    }
  }

  Future<String> _uploadToFirebaseStorage(File video, String userId) async {
    final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final ref = _storage.ref().child('videos/$userId/$fileName');
    
    final uploadTask = ref.putFile(video);
    
    // Wait for the upload to complete
    final snapshot = await uploadTask.whenComplete(() => null);
    
    if (snapshot.state == TaskState.success) {
      // Wait a few seconds to ensure the file is fully available
      await Future.delayed(const Duration(seconds: 5));
      return await ref.getDownloadURL();
    } else {
      throw Exception('Failed to upload video to Firebase Storage');
    }
  }

  Future<(Video, Bit)> uploadVideo({
    required File videoFile,
    required String userId,
    required String title,
    required String description,
    ComedyStructure? comedyStructure,
  }) async {
    try {
      await validateVideo(videoFile);

      // Upload video to Firebase Storage and wait for completion
      final videoUrl = await _uploadToFirebaseStorage(videoFile, userId);

      // Start a batch write
      final batch = _firestore.batch();

      // Create video document
      final videoDoc = _firestore.collection('videos').doc();
      batch.set(videoDoc, {
        'title': title,
        'description': description,
        'userId': userId,
        'storageUrl': videoUrl,
        'uploadDate': Timestamp.now(),
        'status': VideoStatus.processing.toString().split('.').last,
        'duration': 0,
        'isProcessed': false,
      });

      // Create bit document
      final bitDoc = _firestore.collection('bits').doc();
      final bit = Bit(
        id: bitDoc.id,
        title: title,
        description: description,
        userId: userId,
        storageUrl: videoUrl,
        comedyStructureId: comedyStructure?.id,
        createdAt: DateTime.now(),
        metadata: {
          'duration': 0,
        },
      );
      batch.set(bitDoc, bit.toFirestore());

      // Create initial analytics document
      final analyticsDoc = bitDoc.collection('analytics').doc('stats');
      batch.set(analyticsDoc, {
        'totalReactions': 0,
        'reactionCounts': {
          'rofl': 0,
          'smirk': 0,
          'eyeroll': 0,
          'vomit': 0,
        },
      });

      // Commit all changes
      await batch.commit();

      // Create video object
      final video = Video(
        id: videoDoc.id,
        title: title,
        description: description,
        userId: userId,
        storageUrl: videoUrl,
        duration: 0,
        uploadDate: DateTime.now(),
        status: VideoStatus.processing,
        isProcessed: false,
      );

      return (video, bit);
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  Future<void> deleteVideo(Video video) async {
    try {
      // Delete from storage
      final storageRef = FirebaseStorage.instance.refFromURL(video.storageUrl);
      await storageRef.delete();

      // Delete from Firestore
      await _firestore.collection('videos').doc(video.id).delete();
    } catch (e) {
      throw Exception('Failed to delete video: $e');
    }
  }
}