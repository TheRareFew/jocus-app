import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/video_upload_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/video.dart';
import '../../models/comedy_structure.dart';
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

  @override
  void initState() {
    super.initState();
    // Reset the upload provider when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoUploadProvider>().reset();
    });
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
    final details = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VideoDetailsDialog(),
    );

    if (details != null) {
      final userId = context.read<AuthProvider>().currentUser!.uid;
      await context.read<VideoUploadProvider>().uploadVideo(
        video: videoFile,
        userId: userId,
        title: details['title']!,
        description: details['description']!,
        comedyStructure: selectedStructure,  // Now optional
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
      appBar: AppBar(
        title: const Text('Studio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.dashboard,
            (route) => route.settings.name == Routes.dashboard || route.isFirst,
          ),
        ),
      ),
      body: Consumer<VideoUploadProvider>(
        builder: (context, provider, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (provider.state == UploadState.initial) ...[
                  const Icon(Icons.cloud_upload, size: 64),
                  const SizedBox(height: 16),
                  // Comedy Structure Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Card(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text(
                              selectedStructure?.title ?? 'Select Comedy Structure (Optional)',
                              style: TextStyle(
                                color: selectedStructure == null ? Colors.grey : null,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selectedStructure != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        selectedStructure = null;
                                      });
                                    },
                                  ),
                                const Icon(Icons.arrow_forward_ios),
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
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickAndUploadVideo(context),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Video'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _startRecording(context),
                        icon: const Icon(Icons.videocam),
                        label: const Text('Record Video'),
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
                  ElevatedButton(
                    onPressed: () => provider.reset(),
                    child: const Text('Try Again'),
                  ),
                ] else if (provider.state == UploadState.completed) ...[
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('Upload Complete!'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.reset();
                      setState(() {
                        selectedStructure = null;
                      });
                    },
                    child: const Text('Upload Another Video'),
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Uploading... ${(provider.progress * 100).toStringAsFixed(1)}%',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getUploadStateMessage(provider.state),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _getUploadStateMessage(UploadState state) {
    switch (state) {
      case UploadState.validating:
        return 'Validating video...';
      case UploadState.uploadingToOpenShot:
        return 'Preparing for processing...';
      case UploadState.processing:
        return 'Processing video...';
      case UploadState.downloadingProcessed:
        return 'Downloading processed video...';
      case UploadState.uploadingToFirebase:
        return 'Uploading to server...';
      default:
        return state.toString().split('.').last;
    }
  }
}

class _VideoDetailsDialog extends StatefulWidget {
  @override
  _VideoDetailsDialogState createState() => _VideoDetailsDialogState();
}

class _VideoDetailsDialogState extends State<_VideoDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Video Details'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'title': _titleController.text,
                'description': _descriptionController.text,
              });
            }
          },
          child: const Text('Upload'),
        ),
      ],
    );
  }
}