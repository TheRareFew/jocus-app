import 'package:flutter/material.dart';
import '../../core/widgets/dialogs/jocus_dialog.dart';
import '../../core/widgets/inputs/jocus_text_field.dart';

class VideoDetailsDialog extends StatefulWidget {
  const VideoDetailsDialog({Key? key}) : super(key: key);

  @override
  _VideoDetailsDialogState createState() => _VideoDetailsDialogState();
}

class _VideoDetailsDialogState extends State<VideoDetailsDialog> {
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
    return JocusDialog(
      title: 'Video Details',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          JocusTextField(
            controller: _titleController,
            label: 'Title',
            hint: 'Enter video title',
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          JocusTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Enter video description',
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
      confirmLabel: 'Save',
      cancelLabel: 'Cancel',
      onConfirm: () {
        if (_titleController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a title'),
            ),
          );
          return;
        }
        
        final result = {
          'title': _titleController.text,
          'description': _descriptionController.text,
        };
        Navigator.of(context).pop(result);
      },
    );
  }
}
