import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jocus_app/models/comedy_structure.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedGradientIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AnimatedGradientIcon({
    Key? key,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<AnimatedGradientIcon> createState() => _AnimatedGradientIconState();
}

class _AnimatedGradientIconState extends State<AnimatedGradientIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return IconButton(
          onPressed: widget.onPressed,
          icon: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(1.0),
                Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(1.0),
                Theme.of(context).colorScheme.primary.withOpacity(1.0),
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ).createShader(bounds),
            child: Icon(
              widget.icon,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class AnimatedGradientText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const AnimatedGradientText({
    Key? key,
    required this.text,
    this.style,
  }) : super(key: key);

  @override
  State<AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<AnimatedGradientText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(1.0),
              Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(1.0),
              Theme.of(context).colorScheme.primary.withOpacity(1.0),
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
            transform: GradientRotation(_controller.value * 2 * 3.14159),
          ).createShader(bounds),
          child: Text(
            widget.text,
            style: widget.style?.copyWith(
              color: Colors.white,
            ) ?? const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}

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
  final Map<int, TextEditingController> _beatDescriptionControllers = {};
  final Map<int, TextEditingController> _beatDurationControllers = {};
  final Map<int, FocusNode> _scriptFocusNodes = {};
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
    _beatDescriptionControllers.values.forEach((controller) => controller.dispose());
    _beatDurationControllers.values.forEach((controller) => controller.dispose());
    _scriptFocusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }

  TextEditingController _getScriptController(int index) {
    if (!_scriptControllers.containsKey(index)) {
      _scriptControllers[index] = TextEditingController(text: _timeline[index].script);
    }
    return _scriptControllers[index]!;
  }

  TextEditingController _getBeatDescriptionController(int index) {
    if (!_beatDescriptionControllers.containsKey(index)) {
      _beatDescriptionControllers[index] = TextEditingController(text: _timeline[index].description);
    }
    return _beatDescriptionControllers[index]!;
  }

  TextEditingController _getBeatDurationController(int index) {
    if (!_beatDurationControllers.containsKey(index)) {
      _beatDurationControllers[index] = TextEditingController(text: _timeline[index].durationSeconds.toString());
    }
    return _beatDurationControllers[index]!;
  }

  FocusNode _getScriptFocusNode(int index) {
    if (!_scriptFocusNodes.containsKey(index)) {
      final node = FocusNode();
      node.addListener(() { setState(() {}); });
      _scriptFocusNodes[index] = node;
    }
    return _scriptFocusNodes[index]!;
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
              controller: _getBeatDescriptionController(index),
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
              controller: _getBeatDurationController(index),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Script',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    AnimatedGradientText(
                      text: 'Generate with AI',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    AnimatedGradientIcon(
                      icon: Icons.auto_awesome,
                      onPressed: beat.isGeneratingScript ? null : () => _generateScript(index),
                      isLoading: beat.isGeneratingScript,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _getScriptFocusNode(index).hasFocus ? 400 : 100,
              child: TextFormField(
                controller: _getScriptController(index),
                focusNode: _getScriptFocusNode(index),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write your script for this beat...',
                ),
                maxLines: null,
                expands: true,
                onChanged: (value) {
                  setState(() {
                    _timeline[index] = beat.copyWith(script: value);
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: index > 0
                      ? () {
                          setState(() {
                            // Create new list to trigger proper state update
                            final newTimeline = List<ComedyBeatPoint>.from(_timeline);
                            
                            // Create completely new beat objects with all fields
                            final currentBeat = ComedyBeatPoint(
                              type: _timeline[index].type,
                              description: _timeline[index].description,
                              durationSeconds: _timeline[index].durationSeconds,
                              script: _timeline[index].script,
                              isGeneratingScript: _timeline[index].isGeneratingScript,
                            );
                            
                            final previousBeat = ComedyBeatPoint(
                              type: _timeline[index - 1].type,
                              description: _timeline[index - 1].description,
                              durationSeconds: _timeline[index - 1].durationSeconds,
                              script: _timeline[index - 1].script,
                              isGeneratingScript: _timeline[index - 1].isGeneratingScript,
                            );
                            
                            // Update the list with the new objects
                            newTimeline[index - 1] = currentBeat;
                            newTimeline[index] = previousBeat;
                            
                            // Clear all controllers to force rebuild
                            _scriptControllers.forEach((_, controller) => controller.dispose());
                            _beatDescriptionControllers.forEach((_, controller) => controller.dispose());
                            _beatDurationControllers.forEach((_, controller) => controller.dispose());
                            _scriptFocusNodes.forEach((_, node) => node.dispose());
                            _scriptControllers.clear();
                            _beatDescriptionControllers.clear();
                            _beatDurationControllers.clear();
                            _scriptFocusNodes.clear();
                            
                            // Update timeline with new order
                            _timeline = newTimeline;
                          });
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: index < _timeline.length - 1
                      ? () {
                          setState(() {
                            // Create new list to trigger proper state update
                            final newTimeline = List<ComedyBeatPoint>.from(_timeline);
                            
                            // Create completely new beat objects with all fields
                            final currentBeat = ComedyBeatPoint(
                              type: _timeline[index].type,
                              description: _timeline[index].description,
                              durationSeconds: _timeline[index].durationSeconds,
                              script: _timeline[index].script,
                              isGeneratingScript: _timeline[index].isGeneratingScript,
                            );
                            
                            final nextBeat = ComedyBeatPoint(
                              type: _timeline[index + 1].type,
                              description: _timeline[index + 1].description,
                              durationSeconds: _timeline[index + 1].durationSeconds,
                              script: _timeline[index + 1].script,
                              isGeneratingScript: _timeline[index + 1].isGeneratingScript,
                            );
                            
                            // Update the list with the new objects
                            newTimeline[index + 1] = currentBeat;
                            newTimeline[index] = nextBeat;
                            
                            // Clear all controllers to force rebuild
                            _scriptControllers.forEach((_, controller) => controller.dispose());
                            _beatDescriptionControllers.forEach((_, controller) => controller.dispose());
                            _beatDurationControllers.forEach((_, controller) => controller.dispose());
                            _scriptFocusNodes.forEach((_, node) => node.dispose());
                            _scriptControllers.clear();
                            _beatDescriptionControllers.clear();
                            _beatDurationControllers.clear();
                            _scriptFocusNodes.clear();
                            
                            // Update timeline with new order
                            _timeline = newTimeline;
                          });
                        }
                      : null,
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
