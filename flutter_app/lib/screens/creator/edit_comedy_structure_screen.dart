import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jocus_app/models/comedy_structure.dart';
import 'package:cloud_functions/cloud_functions.dart';

class EditComedyStructureScreen extends StatefulWidget {
  final ComedyStructure structure;
  final String userId;  
  final VoidCallback? onSave;

  const EditComedyStructureScreen({
    Key? key,
    required this.structure,
    required this.userId,  
    this.onSave,
  }) : super(key: key);

  @override
  State<EditComedyStructureScreen> createState() => _EditComedyStructureScreenState();
}

class _EditComedyStructureScreenState extends State<EditComedyStructureScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<ComedyBeatPoint> _timeline;
  final Map<int, TextEditingController> _scriptControllers = {};
  bool _isSaving = false;
  late ComedyStructure _editingStructure;

  @override
  void initState() {
    super.initState();
    _editingStructure = widget.structure.isTemplate 
        ? widget.structure.createPersonalCopy(widget.userId)
        : widget.structure;
    
    _titleController = TextEditingController(text: _editingStructure.title);
    _descriptionController = TextEditingController(text: _editingStructure.description);
    _timeline = List.from(_editingStructure.timeline);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scriptControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  TextEditingController _getScriptController(int index) {
    if (!_scriptControllers.containsKey(index)) {
      _scriptControllers[index] = TextEditingController(text: _timeline[index].script);
    }
    return _scriptControllers[index]!;
  }

  Future<void> _saveStructure() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final updatedStructure = _editingStructure.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        timeline: _timeline,
        updatedAt: DateTime.now(),
      );

      final userStructuresRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('comedy_structures');

      if (_editingStructure.id.isEmpty) {
        await userStructuresRef.add(updatedStructure.toMap());
      } else {
        await userStructuresRef.doc(_editingStructure.id).set(
          updatedStructure.toMap(),
          SetOptions(merge: true),
        );
      }

      widget.onSave?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comedy structure saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving comedy structure: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _generateScript(int index) async {
    try {
      setState(() {
        _timeline[index] = _timeline[index].copyWith(isGeneratingScript: true);
      });

      // Get previous beats for context
      final previousBeats = _timeline.sublist(0, index).map((beat) => {
        'type': beat.type,
        'description': beat.description,
      }).toList();

      // Call the Cloud Function
      final result = await FirebaseFunctions.instance
          .httpsCallable('generate_beat_script')
          .call({
        'beatType': _timeline[index].type,
        'description': _timeline[index].description,
        'previousBeats': previousBeats,
      });

      if (mounted) {
        final scriptData = result.data;
        if (scriptData is Map<String, dynamic> && scriptData.containsKey('script')) {
          setState(() {
            _timeline[index] = _timeline[index].copyWith(
              script: scriptData['script'],
              isGeneratingScript: false,
            );
          });
          // Update the controller text directly
          _getScriptController(index).text = scriptData['script'];
        } else if (scriptData is Map<String, dynamic> && scriptData.containsKey('timeline')) {
          // Handle response from analyze_joke_transcript
          final timeline = scriptData['timeline'] as List;
          if (timeline.isNotEmpty) {
            _timeline = timeline.map((beat) => ComedyBeatPoint.fromMap(beat as Map<String, dynamic>)).toList();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _timeline[index] = _timeline[index].copyWith(isGeneratingScript: false);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating script: $e')),
        );
      }
    }
  }

  Widget _buildBeatEditor(ComedyBeatPoint beat, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: beat.type,
                    items: ['setup', 'pause', 'punchline', 'callback']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _timeline[index] = beat.copyWith(type: value);
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Type',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _timeline.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: beat.description,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              onChanged: (value) {
                setState(() {
                  _timeline[index] = beat.copyWith(description: value);
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: beat.durationSeconds.toString(),
              decoration: const InputDecoration(
                labelText: 'Duration (seconds)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final duration = int.tryParse(value) ?? 0;
                setState(() {
                  _timeline[index] = beat.copyWith(durationSeconds: duration);
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _getScriptController(index),
                    decoration: const InputDecoration(
                      labelText: 'Script (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Write your script for this beat...',
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {
                        _timeline[index] = beat.copyWith(script: value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: beat.isGeneratingScript 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  onPressed: beat.isGeneratingScript 
                      ? null 
                      : () => _generateScript(index),
                  tooltip: 'Generate script',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.structure.isTemplate ? 'Create Comedy Structure' : 'Edit Comedy Structure'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveStructure,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Timeline',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ..._timeline.asMap().entries.map(
                  (entry) => _buildBeatEditor(entry.value, entry.key),
                ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _timeline.add(
                    ComedyBeatPoint(
                      description: '',
                      durationSeconds: 30,
                      type: 'setup',
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Beat'),
            ),
          ],
        ),
      ),
    );
  }
}
