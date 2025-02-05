import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/video.dart';
import '../services/video_upload_service.dart';

enum UploadState {
  initial,
  validating,
  uploadingToOpenShot,
  processing,
  downloadingProcessed,
  uploadingToFirebase,
  completed,
  error
}

class VideoUploadProvider with ChangeNotifier {
  final VideoUploadService _uploadService = VideoUploadService();
  
  UploadState _state = UploadState.initial;
  String? _error;
  double _progress = 0.0;
  Video? _currentVideo;

  UploadState get state => _state;
  String? get error => _error;
  double get progress => _progress;
  Video? get currentVideo => _currentVideo;

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
  }) async {
    try {
      _error = null;
      _setProgress(0.0);
      _setState(UploadState.validating);

      await _uploadService.validateVideo(video);
      _setProgress(0.1);

      _setState(UploadState.uploadingToOpenShot);
      final uploadedVideo = await _uploadService.uploadVideo(
        video: video,
        userId: userId,
        title: title,
        description: description,
      );

      _currentVideo = uploadedVideo;
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