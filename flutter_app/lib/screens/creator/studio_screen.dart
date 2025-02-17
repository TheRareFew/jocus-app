import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/video_upload_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/video.dart';
import '../../models/comedy_structure.dart';
import '../../core/widgets/text/animated_gradient_text.dart';
import '../../core/widgets/buttons/animated_gradient_button.dart';
import 'camera_screen.dart';
import 'my_comedy_structures_screen.dart';
import '../../core/routes/routes.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({Key? key}) : super(key: key);

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  ComedyStructure? selectedStructure;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset the upload provider when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoUploadProvider>().reset();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadVideo(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        await _processVideoUpload(context, file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _processVideoUpload(BuildContext context, File videoFile) async {
    if (_formKey.currentState!.validate()) {
      final userId = context.read<AuthProvider>().currentUser!.uid;
      await context.read<VideoUploadProvider>().uploadVideo(
        video: videoFile,
        userId: userId,
        title: _titleController.text,
        description: _descriptionController.text,
        comedyStructure: selectedStructure,
      );
    }
  }

  Future<void> _startRecording(BuildContext context) async {
    final File? recordedVideo = await Navigator.pushNamed(
      context,
      Routes.camera,
      arguments: {'structure': selectedStructure},
    ) as File?;

    if (recordedVideo != null) {
      await _processVideoUpload(context, recordedVideo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'image.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0.03, 0),
            ).animate().fadeIn(duration: 1200.ms),
          ),
          // Overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
          ),
        ),
      ),
          // Content
          Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 24.0,
                        right: 24.0,
                        top: 20.0,
                        bottom: 40.0,
                      ),
                      child: Consumer<VideoUploadProvider>(
        builder: (context, provider, child) {
                          return Column(
              mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provider.state == UploadState.initial) ...[
                                const SizedBox(height: 20),
                                AnimatedGradientText(
                                  text: 'STUDIO',
                                  fontSize: 42,
                                  letterSpacing: 2,
                                  useFloatingAnimation: false,
                                )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .scale(
                                  begin: const Offset(0.2, 0.2),
                                  end: const Offset(1.0, 1.0),
                                  duration: 1200.ms,
                                  curve: Curves.elasticOut,
                                )
                                .shimmer(
                                  duration: 2000.ms,
                                  color: Colors.white.withOpacity(0.8),
                                  angle: -10,
                                )
                                .then()
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .moveY(
                                  begin: -2,
                                  end: 2,
                                  duration: 2000.ms,
                                  curve: Curves.easeInOut,
                                )
                                .then()
                                .moveY(
                                  begin: 2,
                                  end: -2,
                                  duration: 2000.ms,
                                  curve: Curves.easeInOut,
                                ),
                                const SizedBox(height: 40),
                                Icon(
                                  Icons.cloud_upload,
                                  size: 64,
                                  color: Colors.white,
                                )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .shimmer(
                                  duration: 1200.ms,
                                  color: Colors.white.withOpacity(0.8),
                                  angle: -45,
                                  size: 2,
                                )
                                .then()
                                .shimmer(
                                  delay: 600.ms,
                                  duration: 1200.ms,
                                  color: Colors.white.withOpacity(0.8),
                                  angle: 45,
                                  size: 2,
                                ),
                  const SizedBox(height: 16),
                  // Comedy Structure Selection
                                Card(
                                  color: Colors.black.withOpacity(0.3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text(
                              selectedStructure?.title ?? 'Select Comedy Structure (Optional)',
                              style: TextStyle(
                                            color: selectedStructure == null ? Colors.grey : Colors.white,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selectedStructure != null)
                                  IconButton(
                                                icon: const Icon(Icons.clear, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        selectedStructure = null;
                                      });
                                    },
                                  ),
                                            const Icon(Icons.arrow_forward_ios, color: Colors.white),
                              ],
                            ),
                            onTap: () async {
                              final structure = await Navigator.push<ComedyStructure>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyComedyStructuresScreen(
                                    selectionMode: true,
                                  ),
                                ),
                              );
                              if (structure != null) {
                                setState(() {
                                  selectedStructure = structure;
                                });
                              }
                            },
                          ),
                          if (selectedStructure == null)
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                'Adding a comedy structure helps organize your content and track audience reactions at specific moments.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                                ).animate()
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: 0.2, end: 0),
                                const SizedBox(height: 24),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _titleController,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Title',
                                          labelStyle: const TextStyle(color: Colors.white),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white),
                                          ),
                                          errorBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.red),
                                          ),
                                          focusedErrorBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.red),
                                          ),
                                          filled: true,
                                          fillColor: Colors.black.withOpacity(0.3),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a title';
                                          }
                                          return null;
                                        },
                                      ).animate()
                                      .fadeIn(delay: 300.ms)
                                      .slideX(begin: -0.2, end: 0),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _descriptionController,
                                        style: const TextStyle(color: Colors.white),
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          labelText: 'Description',
                                          labelStyle: const TextStyle(color: Colors.white),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white),
                                          ),
                                          errorBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.red),
                                          ),
                                          focusedErrorBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.red),
                                          ),
                                          filled: true,
                                          fillColor: Colors.black.withOpacity(0.3),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a description';
                                          }
                                          return null;
                                        },
                                      ).animate()
                                      .fadeIn(delay: 400.ms)
                                      .slideX(begin: 0.2, end: 0),
                                    ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                                    Expanded(
                                      child: AnimatedGradientButton(
                        onPressed: () => _pickAndUploadVideo(context),
                                        text: 'Upload',
                                        icon: Icons.upload_file,
                                        height: 48,
                                      ).animate()
                                      .fadeIn(delay: 400.ms)
                                      .slideX(begin: -0.2, end: 0),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AnimatedGradientButton(
                        onPressed: () => _startRecording(context),
                                        text: 'Record',
                                        icon: Icons.videocam,
                                        height: 48,
                                      ).animate()
                                      .fadeIn(delay: 600.ms)
                                      .slideX(begin: 0.2, end: 0),
                      ),
                    ],
                  ),
                ] else if (provider.state == UploadState.error) ...[
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.error ?? 'An error occurred',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                                AnimatedGradientButton(
                    onPressed: () => provider.reset(),
                                  text: 'Try Again',
                                  height: 64,
                  ),
                ] else if (provider.state == UploadState.completed) ...[
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 100),
                                      AnimatedGradientText(
                                        text: 'STUDIO',
                                        fontSize: 42,
                                        letterSpacing: 2,
                                        useFloatingAnimation: false,
                                      )
                                      .animate()
                                      .fadeIn(duration: 600.ms)
                                      .scale(
                                        begin: const Offset(0.2, 0.2),
                                        end: const Offset(1.0, 1.0),
                                        duration: 1200.ms,
                                        curve: Curves.elasticOut,
                                      )
                                      .shimmer(
                                        duration: 2000.ms,
                                        color: Colors.white.withOpacity(0.8),
                                        angle: -10,
                                      ),
                                      const SizedBox(height: 40),
                                      Icon(
                                        Icons.check_circle,
                                        size: 64,
                                        color: Colors.white,
                                      )
                                      .animate(
                                        onPlay: (controller) => controller.repeat(),
                                      )
                                      .shimmer(
                                        duration: 1200.ms,
                                        color: Colors.white.withOpacity(0.8),
                                        angle: -45,
                                        size: 2,
                                      )
                                      .then()
                                      .shimmer(
                                        delay: 600.ms,
                                        duration: 1200.ms,
                                        color: Colors.white.withOpacity(0.8),
                                        angle: 45,
                                        size: 2,
                                      ),
                  const SizedBox(height: 16),
                                      AnimatedGradientText(
                                        text: 'UPLOAD COMPLETE!',
                                        fontSize: 32,
                                        letterSpacing: 2,
                                        useFloatingAnimation: false,
                                      )
                                      .animate()
                                      .fadeIn(duration: 600.ms)
                                      .scale(
                                        begin: const Offset(0.2, 0.2),
                                        end: const Offset(1.0, 1.0),
                                        duration: 1200.ms,
                                        curve: Curves.elasticOut,
                                      )
                                      .shimmer(
                                        duration: 2000.ms,
                                        color: Colors.white.withOpacity(0.8),
                                        angle: -10,
                                      ),
                                      const SizedBox(height: 24),
                                      AnimatedGradientButton(
                    onPressed: () {
                      provider.reset();
                      setState(() {
                        selectedStructure = null;
                      });
                    },
                                        text: 'Upload Another',
                                        icon: Icons.add_circle,
                                        height: 48,
                                      )
                                      .animate()
                                      .fadeIn(delay: 400.ms)
                                      .slideY(begin: 0.2, end: 0),
                                    ],
                                  ),
                  ),
                ] else ...[
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 100),
                                      AnimatedGradientText(
                                        text: 'STUDIO',
                                        fontSize: 42,
                                        letterSpacing: 2,
                                        useFloatingAnimation: false,
                                      )
                                      .animate()
                                      .fadeIn(duration: 600.ms)
                                      .scale(
                                        begin: const Offset(0.2, 0.2),
                                        end: const Offset(1.0, 1.0),
                                        duration: 1200.ms,
                                        curve: Curves.elasticOut,
                                      )
                                      .shimmer(
                                        duration: 2000.ms,
                                        color: Colors.white.withOpacity(0.8),
                                        angle: -10,
                                      ),
                                      const SizedBox(height: 40),
                                      SizedBox(
                                        width: 200,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 4,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                  Text(
                    _getUploadStateMessage(provider.state),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                  ),
                ],
              ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Back Button
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.dashboard,
                (route) => route.settings.name == Routes.dashboard || route.isFirst,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUploadStateMessage(UploadState state) {
    switch (state) {
      case UploadState.validating:
        return 'Validating video...';
      case UploadState.uploading:
        return 'Uploading video...';
      case UploadState.processing:
        return 'Processing video...';
      case UploadState.completed:
        return 'Upload complete!';
      case UploadState.error:
        return 'Error uploading video';
      case UploadState.initial:
        return '';
    }
  }
}