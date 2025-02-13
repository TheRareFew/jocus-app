import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:jocus_app/models/comedy_structure.dart';
import 'package:jocus_app/providers/auth_provider.dart';
import 'package:jocus_app/screens/creator/edit_comedy_structure_screen.dart';

class ComedyStructureCard extends StatefulWidget {
  final ComedyStructure structure;
  final bool showEditButton;
  final bool autoStart;
  final bool overlay;
  final VoidCallback? onSave;
  final ValueChanged<int>? onBeatChange;

  const ComedyStructureCard({
    Key? key,
    required this.structure,
    this.showEditButton = true,
    this.autoStart = false,
    this.overlay = false,
    this.onSave,
    this.onBeatChange,
  }) : super(key: key);

  @override
  State<ComedyStructureCard> createState() => _ComedyStructureCardState();
}

class _ComedyStructureCardState extends State<ComedyStructureCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _beatAnimations;
  bool _isExpanded = false;
  bool _isTimerRunning = false;
  Timer? _progressTimer;
  int _currentTimeInSeconds = 0;
  int _activeIndex = -1;
  int _currentBeatRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    if (widget.autoStart) {
      _isExpanded = true;
      _startRealTimeProgress();
    }
  }

  @override
  void didUpdateWidget(ComedyStructureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoStart != oldWidget.autoStart) {
      if (widget.autoStart) {
        _isExpanded = true;
        _startRealTimeProgress();
      } else {
        _stopTimer();
      }
    }
  }

  void _toggleTimer() {
    setState(() {
      if (_isTimerRunning) {
        _stopTimer();
      } else {
        _startRealTimeProgress();
      }
    });
  }

  void _stopTimer() {
    _progressTimer?.cancel();
    _controller.stop();
    _isTimerRunning = false;
    _activeIndex = -1;
  }

  void _startRealTimeProgress() {
    _currentTimeInSeconds = 0;
    _activeIndex = 0;
    _currentBeatRemainingSeconds = widget.structure.timeline[0].durationSeconds;
    _progressTimer?.cancel();
    _controller.reset();
    _controller.forward();
    _isTimerRunning = true;
    
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isTimerRunning) {
        timer.cancel();
        _activeIndex = -1;
        return;
      }
      
      setState(() {
        _currentTimeInSeconds++;
        _currentBeatRemainingSeconds--;
        
        if (_currentBeatRemainingSeconds <= 0) {
          if (_activeIndex < widget.structure.timeline.length - 1) {
            _activeIndex++;
            _currentBeatRemainingSeconds = widget.structure.timeline[_activeIndex].durationSeconds;
            widget.onBeatChange?.call(_activeIndex);  // Notify of beat change
          } else {
            timer.cancel();
            _activeIndex = -1;
            _isTimerRunning = false;
          }
        }
      });
    });
  }

  void _setupAnimations() {
    final totalDuration = widget.structure.timeline.fold<int>(
      0,
      (sum, beat) => sum + beat.durationSeconds,
    );

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalDuration),
    );

    double startTime = 0.0;
    _beatAnimations = widget.structure.timeline.map((beat) {
      final endTime = startTime + (beat.durationSeconds / totalDuration);
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: Curves.easeInOut),
        ),
      );
      startTime = endTime;
      return animation;
    }).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  Color _getColorForBeatType(String type) {
    switch (type.toLowerCase()) {
      case 'setup':
        return Colors.blue;
      case 'pause':
        return Colors.orange;
      case 'punchline':
        return Colors.green;
      case 'callback':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActiveIndicator(String beatType) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColorForBeatType(beatType).withOpacity(0.1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getColorForBeatType(beatType)),
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          children: List.generate(widget.structure.timeline.length, (index) {
            final beat = widget.structure.timeline[index];
            final isLast = index == widget.structure.timeline.length - 1;
            final animation = _beatAnimations[index];
            final isActive = index == _activeIndex;
            final isCompleted = index < _activeIndex;

            return TimelineTile(
              isLast: isLast,
              endChild: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Opacity(
                  opacity: isActive ? 1.0 : 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beat.type.toUpperCase(),
                        style: TextStyle(
                          color: widget.overlay ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        beat.description,
                        style: TextStyle(
                          color: widget.overlay 
                            ? (isActive ? Colors.white : Colors.white70)
                            : (isActive ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodyMedium?.color),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (beat.script != null && beat.script!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.text_fields,
                              size: 16,
                              color: widget.overlay ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                beat.script!,
                                style: TextStyle(
                                  color: widget.overlay 
                                    ? Colors.white70 
                                    : Theme.of(context).textTheme.bodySmall?.color,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (isActive)
                        Text(
                          '${_currentBeatRemainingSeconds}s remaining',
                          style: TextStyle(
                            color: widget.overlay ? Colors.white : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          '${beat.durationSeconds}s',
                          style: TextStyle(
                            color: widget.overlay 
                              ? (isActive ? Colors.white : Colors.white70)
                              : (isActive ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              indicatorStyle: IndicatorStyle(
                color: _getColorForBeatType(beat.type),
                drawGap: true,
                width: isActive ? 25 : 20,
                height: isActive ? 25 : 20,
                indicator: isActive ? _buildActiveIndicator(beat.type) : null,
                padding: const EdgeInsets.all(2),
                iconStyle: IconStyle(
                  color: _getColorForBeatType(beat.type),
                  iconData: isCompleted ? Icons.check_circle : Icons.circle_outlined,
                ),
              ),
              beforeLineStyle: LineStyle(
                color: _getColorForBeatType(beat.type).withOpacity(animation.value),
              ),
              afterLineStyle: LineStyle(
                color: _getColorForBeatType(beat.type).withOpacity(
                  index < widget.structure.timeline.length - 1 ? 
                  _beatAnimations[index + 1].value : 1.0
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMetrics(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: widget.structure.metrics.entries.map((entry) {
        return _MetricChip(
          label: entry.key,
          value: entry.value,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: EdgeInsets.all(widget.overlay ? 4.0 : 8.0),
      color: widget.overlay ? Colors.black.withOpacity(0.7) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              widget.structure.title,
              style: TextStyle(
                color: widget.overlay ? Colors.white : Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            subtitle: widget.structure.isTemplate ? Text(
              'Laugh Rate: ${widget.structure.metrics['laughDensity']?.toStringAsFixed(1) ?? 'N/A'} /min',
              style: TextStyle(
                color: widget.overlay ? Colors.white70 : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ) : null,
            trailing: widget.showEditButton ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.structure.isTemplate)
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Create personal copy',
                    onPressed: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final userId = authProvider.currentUser?.uid;
                      
                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please sign in to create a personal copy'),
                          ),
                        );
                        return;
                      }

                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditComedyStructureScreen(
                            structure: widget.structure,
                            userId: userId,
                            onSave: widget.onSave,
                          ),
                        ),
                      );
                      
                      if (result == true) {
                        widget.onSave?.call();
                      }
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit structure',
                    onPressed: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final userId = authProvider.currentUser?.uid;
                      
                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please sign in to edit'),
                          ),
                        );
                        return;
                      }

                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditComedyStructureScreen(
                            structure: widget.structure,
                            userId: userId,
                            onSave: widget.onSave,
                          ),
                        ),
                      );
                      
                      if (result == true) {
                        widget.onSave?.call();
                      }
                    },
                  ),
              ],
            ) : null,
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded || widget.autoStart)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.structure.description,
                          style: TextStyle(
                            color: widget.overlay ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      if (!widget.overlay && !widget.autoStart)
                        IconButton(
                          icon: Icon(_isTimerRunning ? Icons.stop : Icons.play_arrow),
                          tooltip: _isTimerRunning ? 'Stop Timer' : 'Start Timer',
                          onPressed: _toggleTimer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTimeline(context),
                  if (!widget.overlay && widget.structure.isTemplate) ...[
                    const SizedBox(height: 16),
                    _buildMetrics(context),
                  ],
                ],
              ),
            ),
        ],
      ),
    );

    if (widget.overlay) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: card,
        ),
      );
    }

    return card;
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final dynamic value;

  const _MetricChip({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '$label: ${value is double ? value.toStringAsFixed(1) : value.toString()}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }
}
