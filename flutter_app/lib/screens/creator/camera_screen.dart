import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:jocus_app/models/comedy_structure.dart';
import 'package:jocus_app/widgets/comedy_structure_card.dart';

class CameraScreen extends StatefulWidget {
  final ComedyStructure? structure;  // Optional comedy structure for overlay

  const CameraScreen({
    Key? key,
    this.structure,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isRecording = false;
  String? _errorMessage;
  List<CameraDescription>? _cameras;
  bool _isEmulator = false;
  int _currentBeatIndex = 0;  // Track current beat in timeline
  bool _isStructureTimerRunning = false;  // Track if structure timer is running

  @override
  void initState() {
    super.initState();
    _checkEmulator();
    _initializeCamera();
  }

  Future<void> _checkEmulator() async {
    // Simple check for Android emulator - not perfect but works for most cases
    if (Platform.isAndroid) {
      final String brand = await _getAndroidBrand();
      _isEmulator = brand.toLowerCase().contains('google') || 
                    brand.toLowerCase().contains('sdk');
    }
  }

  Future<String> _getAndroidBrand() async {
    try {
      final result = await Process.run('getprop', ['ro.product.brand']);
      return result.stdout.toString().trim();
    } catch (e) {
      return '';
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() => _errorMessage = 'No cameras found');
        return;
      }

      // Use the front camera by default
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      await _switchCamera(camera);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize camera: $e');
    }
  }

  Future<void> _switchCamera(CameraDescription camera) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _controller!.initialize();
    // Set exposure and focus mode to prevent darkening
    await _controller!.setExposureMode(ExposureMode.auto);
    await _controller!.setFocusMode(FocusMode.auto);
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentLensDirection = _controller!.description.lensDirection;
    CameraDescription? newCamera;

    if (currentLensDirection == CameraLensDirection.back) {
      newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
    } else {
      newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
    }

    if (newCamera != null) {
      await _switchCamera(newCamera);
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized || _isRecording) return;

    try {
      // Create a temporary file for the video
      final Directory tempDir = await getTemporaryDirectory();
      final String videoPath = path.join(
        tempDir.path,
        'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _currentBeatIndex = 0; // Reset beat index when starting recording
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isInitialized || !_isRecording) return;

    try {
      final XFile videoFile = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _isStructureTimerRunning = false;  // Stop the timer when recording stops
      });
      
      if (!mounted) return;
      Navigator.pop(context, File(videoFile.path));
    } catch (e) {
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping recording: $e')),
      );
    }
  }

  void _toggleStructureTimer() {
    setState(() {
      _isStructureTimerRunning = !_isStructureTimerRunning;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Record Video')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Record Video')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Video'),
        actions: [
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: !_isRecording ? _toggleCamera : null,
            ),
          if (_isRecording)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopRecording,
            ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 9 / 16, // Force portrait aspect ratio
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: SizedBox(
                      width: _controller!.value.previewSize!.height,
                      height: _controller!.value.previewSize!.width,
                      child: _isEmulator
                        ? Transform.rotate(
                            angle: 3.14159 / 2,
                            child: CameraPreview(_controller!),
                          )
                        : CameraPreview(_controller!),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.structure != null)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100, // Leave space for the record button
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  ComedyStructureCard(
                    structure: widget.structure!,
                    showEditButton: false,
                    autoStart: _isStructureTimerRunning,
                    overlay: true,
                    onBeatChange: (index) {
                      setState(() => _currentBeatIndex = index);
                    },
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isStructureTimerRunning ? Icons.timer_off : Icons.timer,
                          color: _isStructureTimerRunning ? Colors.blue : Colors.white,
                        ),
                        tooltip: _isStructureTimerRunning ? 'Stop Timer' : 'Start Timer',
                        onPressed: () {
                          _toggleStructureTimer();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: FloatingActionButton(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                backgroundColor: _isRecording ? Colors.red : Colors.white,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.videocam,
                  color: _isRecording ? Colors.white : Colors.black,
                  size: 32,
                ),
              ),
            ),
          ),
          if (_isRecording)
            Positioned(
              top: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        color: Colors.red,
                        size: 12,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Recording',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}