import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/video.dart';
import '../models/bit.dart';
import '../models/comedy_structure.dart';
import '../services/video_upload_service.dart';

enum UploadState {
  initial,
  validating,
  uploading,
  processing,
  completed,
  error
}

class VideoUploadProvider with ChangeNotifier {
  final VideoUploadService _uploadService = VideoUploadService();
  
  UploadState _state = UploadState.initial;
  String? _error;
  double _progress = 0.0;
  Video? _currentVideo;
  Bit? _currentBit;

  UploadState get state => _state;
  String? get error => _error;
  double get progress => _progress;
  Video? get currentVideo => _currentVideo;
  Bit? get currentBit => _currentBit;

  void _setState(UploadState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _setState(UploadState.error);
  }

  void _setProgress(double progress) {
    _progress = progress;
    notifyListeners();
  }

  Future<void> uploadVideo({
    required File video,
    required String userId,
    required String title,
    required String description,
    ComedyStructure? comedyStructure,
  }) async {
    try {
      _error = null;
      _setProgress(0.0);
      
      // Validating - 0% to 20%
      _setState(UploadState.validating);
      await _uploadService.validateVideo(video);
      _setProgress(0.2);

      // Uploading - 20% to 60%
      _setState(UploadState.uploading);
      _setProgress(0.3);
      await Future.delayed(const Duration(milliseconds: 500));
      _setProgress(0.4);
      await Future.delayed(const Duration(milliseconds: 500));
      _setProgress(0.5);
      await Future.delayed(const Duration(milliseconds: 500));
      _setProgress(0.6);
      
      // Processing - 60% to 90%
      _setState(UploadState.processing);
      _setProgress(0.7);
      await Future.delayed(const Duration(milliseconds: 500));
      _setProgress(0.8);
      await Future.delayed(const Duration(milliseconds: 500));
      _setProgress(0.9);
      
      final (uploadedVideo, bit) = await _uploadService.uploadVideo(
        videoFile: video,
        userId: userId,
        title: title,
        description: description,
        comedyStructure: comedyStructure,
      );

      _currentVideo = uploadedVideo;
      _currentBit = bit;
      _setProgress(1.0);
      _setState(UploadState.completed);
    } catch (e) {
      _setError(e.toString());
    }
  }

  void reset() {
    _state = UploadState.initial;
    _error = null;
    _progress = 0.0;
    _currentVideo = null;
    _currentBit = null;
    notifyListeners();
  }

  Future<void> deleteVideo(Video video) async {
    try {
      await _uploadService.deleteVideo(video);
      if (video.id == _currentVideo?.id) {
        reset();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }
}