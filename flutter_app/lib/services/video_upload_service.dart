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
    final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}';
    final ref = _storage.ref().child('videos/$userId/$fileName');
    
    final uploadTask = ref.putFile(video);
    final snapshot = await uploadTask;
    
    if (snapshot.state == TaskState.success) {
      return await ref.getDownloadURL();
    } else {
      throw Exception('Failed to upload video to Firebase Storage');
    }
  }

  Future<(Video, Bit)> uploadVideo({
    required File video,
    required String userId,
    required String title,
    required String description,
    ComedyStructure? comedyStructure,
  }) async {
    try {
      await validateVideo(video);

      // Upload video to Firebase Storage
      final videoUrl = await _uploadToFirebaseStorage(video, userId);

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
        'status': 'ready', // TODO: Add VideoStatus enum
        'duration': 0, // TODO: Add duration calculation
      });

      // Create bit document
      final bitDoc = _firestore.collection('bits').doc();
      final bit = Bit(
        id: bitDoc.id,
        title: title,
        description: description,
        userId: userId,
        videoUrl: videoUrl,
        comedyStructureId: comedyStructure?.id,
        createdAt: DateTime.now(),
        metadata: {
          'duration': 0, // TODO: Add duration calculation
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
        'viewCount': 0,
        'lastUpdated': Timestamp.now(),
      });

      // Commit the batch
      await batch.commit();

      // Return video and bit models
      final videoModel = Video.fromFirestore(await videoDoc.get());
      final bitModel = Bit.fromFirestore(await bitDoc.get());

      return (videoModel, bitModel);
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