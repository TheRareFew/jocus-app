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
                      child: ListTile(
                        title: Text(
                          selectedStructure?.title ?? 'Select Comedy Structure',
                          style: TextStyle(
                            color: selectedStructure != null 
                              ? Theme.of(context).textTheme.bodyLarge?.color 
                              : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          final structure = await Navigator.pushNamed(
                            context,
                            Routes.myComedyStructures,
                            arguments: {'selectionMode': true},
                          ) as ComedyStructure?;
                          
                          if (structure != null) {
                            setState(() => selectedStructure = structure);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickAndUploadVideo(context),
                        icon: const Icon(Icons.file_upload),
                        label: const Text('Upload Video'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: selectedStructure != null ? () => _startRecording(context) : null,
                        icon: const Icon(Icons.videocam),
                        label: const Text('Record Video'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          backgroundColor: selectedStructure != null ? Colors.blue : null,
                        ),
                      ),
                    ],
                  ),
                ] else if (provider.state == UploadState.error) ...[
                  Icon(Icons.error, size: 64, color: Colors.red[700]),
                  const SizedBox(height: 16),
                  Text(
                    provider.error ?? 'An error occurred',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.reset,
                    child: const Text('Try Again'),
                  ),
                ] else if (provider.state == UploadState.completed) ...[
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('Upload Complete!'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.reset,
                    child: const Text('Upload Another Video'),
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_getStateMessage(provider.state)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: provider.progress),
                  const SizedBox(height: 16),
                  Text('${(provider.progress * 100).toStringAsFixed(1)}%'),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStateMessage(UploadState state) {
    switch (state) {
      case UploadState.validating:
        return 'Validating video...';
      case UploadState.uploadingToOpenShot:
        return 'Uploading to editor...';
      case UploadState.processing:
        return 'Processing video...';
      case UploadState.downloadingProcessed:
        return 'Downloading processed video...';
      case UploadState.uploadingToFirebase:
        return 'Uploading to storage...';
      default:
        return 'Processing...';
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