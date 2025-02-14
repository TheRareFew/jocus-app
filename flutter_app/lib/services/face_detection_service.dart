import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:camera/camera.dart';

class FaceDetectionService {
  // Singleton pattern to reuse the detector
  static final FaceDetectionService _instance = FaceDetectionService._internal();
  factory FaceDetectionService() => _instance;
  FaceDetectionService._internal() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, // To compute smile probability
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  late final FaceDetector _faceDetector;
  // Throttle processing to one frame every 500 milliseconds.
  DateTime _lastProcessed = DateTime.now();

  Future<double?> detectSmile(InputImage image) async {
    if (DateTime.now().difference(_lastProcessed).inMilliseconds < 500) {
      return null;
    }
    _lastProcessed = DateTime.now();
    final List<Face> faces = await _faceDetector.processImage(image);
    if (faces.isNotEmpty) {
      // Use the first detected face's smiling probability.
      return faces.first.smilingProbability;
    }
    return null;
  }

  void dispose() {
    _faceDetector.close();
  }
} 