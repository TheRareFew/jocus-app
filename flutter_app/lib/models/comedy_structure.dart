import 'package:cloud_firestore/cloud_firestore.dart';

class ComedyStructure {
  final String id;
  final String title;
  final String description;
  final List<ComedyBeatPoint> timeline;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> metadata;
  final String? authorId;  // ID of the user who created/saved this structure
  final bool isTemplate;  // Whether this is a template from trending formats
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ComedyStructure({
    required this.id,
    required this.title,
    required this.description,
    required this.timeline,
    required this.metrics,
    required this.metadata,
    this.authorId,
    this.isTemplate = true,
    this.createdAt,
    this.updatedAt,
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
      authorId: data['authorId'] as String?,
      isTemplate: data['isTemplate'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'description': description,
      'timeline': timeline.map((beat) => beat.toMap()).toList(),
      'authorId': authorId,
      'isTemplate': isTemplate,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };

    // Only include metrics and metadata for templates
    if (isTemplate) {
      map['metrics'] = metrics;
      map['metadata'] = metadata;
    }

    return map;
  }

  // Create a copy as a personal card
  ComedyStructure createPersonalCopy(String userId) {
    return ComedyStructure(
      id: '', // Will be set by Firestore
      title: 'Copy of $title',
      description: description,
      timeline: timeline.map((beat) => beat.copyWith()).toList(),
      metrics: {}, // Reset metrics for new copy
      metadata: {}, // Reset metadata for new copy
      authorId: userId,
      isTemplate: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  ComedyStructure copyWith({
    String? id,
    String? title,
    String? description,
    List<ComedyBeatPoint>? timeline,
    Map<String, dynamic>? metrics,
    Map<String, dynamic>? metadata,
    String? authorId,
    bool? isTemplate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ComedyStructure(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timeline: timeline ?? this.timeline,
      // Only copy metrics and metadata if it's a template
      metrics: (isTemplate ?? this.isTemplate) ? (metrics ?? this.metrics) : {},
      metadata: (isTemplate ?? this.isTemplate) ? (metadata ?? this.metadata) : {},
      authorId: authorId ?? this.authorId,
      isTemplate: isTemplate ?? this.isTemplate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ComedyBeatPoint {
  final String description;
  final int durationSeconds;
  final String type; // 'setup', 'pause', 'punchline', 'callback'
  final Map<String, dynamic>? details;
  final String? script;  // Optional script for this beat

  ComedyBeatPoint({
    required this.description,
    required this.durationSeconds,
    required this.type,
    this.details,
    this.script,
  });

  factory ComedyBeatPoint.fromMap(Map<String, dynamic> map) {
    return ComedyBeatPoint(
      description: map['description'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      type: map['type'] ?? 'setup',
      details: map['details'] as Map<String, dynamic>?,
      script: map['script'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'durationSeconds': durationSeconds,
      'type': type,
      'details': details,
      'script': script,
    };
  }

  ComedyBeatPoint copyWith({
    String? description,
    int? durationSeconds,
    String? type,
    Map<String, dynamic>? details,
    String? script,
  }) {
    return ComedyBeatPoint(
      description: description ?? this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      type: type ?? this.type,
      details: details ?? this.details,
      script: script ?? this.script,
    );
  }
}
