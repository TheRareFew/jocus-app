import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeline_tile/timeline_tile.dart';

class ComedyStructure {
  final String id;
  final String title;
  final String description;
  final List<ComedyBeatPoint> timeline;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> metadata;

  ComedyStructure({
    required this.id,
    required this.title,
    required this.description,
    required this.timeline,
    required this.metrics,
    required this.metadata,
  });

  factory ComedyStructure.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComedyStructure(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      timeline: (data['timeline'] as List? ?? [])
          .map((e) => ComedyBeatPoint.fromMap(e as Map<String, dynamic>))
          .toList(),
      metrics: data['metrics'] as Map<String, dynamic>? ?? {},
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

class ComedyBeatPoint {
  final String description;
  final int durationSeconds;
  final String type; // 'setup', 'pause', 'punchline', 'callback'
  final Map<String, dynamic>? details;

  ComedyBeatPoint({
    required this.description,
    required this.durationSeconds,
    required this.type,
    this.details,
  });

  factory ComedyBeatPoint.fromMap(Map<String, dynamic> map) {
    return ComedyBeatPoint(
      description: map['description'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      type: map['type'] ?? 'setup',
      details: map['details'] as Map<String, dynamic>?,
    );
  }
}

class TrendingFormatsScreen extends StatelessWidget {
  const TrendingFormatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Comedy Structures'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('comedy_structures')
            .orderBy('metadata.popularity', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final structures = snapshot.data?.docs
              .map((doc) => ComedyStructure.fromFirestore(doc))
              .toList() ?? [];

          return ListView.builder(
            itemCount: structures.length,
            itemBuilder: (context, index) {
              final structure = structures[index];
              return _ComedyStructureCard(structure: structure);
            },
          );
        },
      ),
    );
  }
}

class _ComedyStructureCard extends StatelessWidget {
  final ComedyStructure structure;

  const _ComedyStructureCard({
    Key? key,
    required this.structure,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Text(structure.title),
        subtitle: Text(
          'Laugh Rate: ${structure.metrics['laughDensity']?.toStringAsFixed(1) ?? 'N/A'} /min',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  structure.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildTimeline(context),
                const SizedBox(height: 16),
                _buildMetrics(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return Column(
      children: structure.timeline.map((beat) {
        final isLast = structure.timeline.last == beat;
        return TimelineTile(
          isLast: isLast,
          endChild: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beat.type.toUpperCase(),
                  style: TextStyle(
                    color: _getColorForBeatType(beat.type),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(beat.description),
                Text('${beat.durationSeconds}s'),
              ],
            ),
          ),
          indicatorStyle: IndicatorStyle(
            color: _getColorForBeatType(beat.type),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetrics(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _MetricChip(
          label: 'Subject',
          value: structure.metadata['subject'] ?? 'N/A',
        ),
        _MetricChip(
          label: 'Style',
          value: structure.metadata['comedyStyle'] ?? 'N/A',
        ),
        _MetricChip(
          label: 'Duration',
          value: '${structure.metadata['duration']}s',
        ),
        _MetricChip(
          label: 'Audience Score',
          value: '${(structure.metrics['audienceScore'] ?? 0).toStringAsFixed(1)}',
        ),
      ],
    );
  }

  Color _getColorForBeatType(String type) {
    switch (type) {
      case 'setup':
        return Colors.blue;
      case 'pause':
        return Colors.orange;
      case 'punchline':
        return Colors.red;
      case 'callback':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
    );
  }
}