import 'package:cloud_firestore/cloud_firestore.dart';

class ComedyStructure {
  final String id;
  final String title;
  final String description;
  final List<ComedyBeatPoint> timeline;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> metadata;
  final String authorId;  // ID of the user who created/saved this structure
  final bool isTemplate;  // Whether this is a template from trending formats
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ReactionData> reactions;

  ComedyStructure({
    required this.id,
    required this.title,
    required this.description,
    required this.timeline,
    required this.metrics,
    required this.metadata,
    required this.authorId,
    this.isTemplate = false,
    required this.createdAt,
    required this.updatedAt,
    this.reactions = const [],
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
      authorId: data['authorId'] as String? ?? '',
      isTemplate: data['isTemplate'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: (data['reactions'] as List? ?? [])
          .map((e) => ReactionData.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timeline': timeline.map((beat) => beat.toMap()).toList(),
      'authorId': authorId,
      'isTemplate': isTemplate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reactions': reactions.map((r) => r.toMap()).toList(),
      'metrics': metrics,
      'metadata': metadata,
    };
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
      reactions: [],
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
    List<ReactionData>? reactions,
  }) {
    return ComedyStructure(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timeline: timeline ?? this.timeline,
      metrics: (isTemplate ?? this.isTemplate) ? (metrics ?? this.metrics) : {},
      metadata: (isTemplate ?? this.isTemplate) ? (metadata ?? this.metadata) : {},
      authorId: authorId ?? this.authorId,
      isTemplate: isTemplate ?? this.isTemplate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reactions: reactions ?? this.reactions,
    );
  }
}

class ComedyBeatPoint {
  final String type;
  final String description;
  final int durationSeconds;
  final String script;
  final bool isGeneratingScript;

  ComedyBeatPoint({
    required this.type,
    required this.description,
    required this.durationSeconds,
    this.script = '',
    this.isGeneratingScript = false,
  });

  ComedyBeatPoint copyWith({
    String? type,
    String? description,
    int? durationSeconds,
    String? script,
    bool? isGeneratingScript,
  }) {
    return ComedyBeatPoint(
      type: type ?? this.type,
      description: description ?? this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      script: script ?? this.script,
      isGeneratingScript: isGeneratingScript ?? this.isGeneratingScript,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'durationSeconds': durationSeconds,
      'script': script,
    };
  }

  factory ComedyBeatPoint.fromMap(Map<String, dynamic> map) {
    final duration = map['durationSeconds'];
    final int durationSeconds = duration is int 
        ? duration 
        : duration is double 
            ? duration.round() 
            : 0;
            
    return ComedyBeatPoint(
      type: map['type'] as String,
      description: map['description'] as String,
      durationSeconds: durationSeconds,
      script: map['script'] as String? ?? '',
    );
  }
}

class ReactionData {
  final String type; // 'rofl', 'smirk', 'eyeroll', 'vomit'
  final double timestamp; // Time in video when reaction occurred
  final String userId;
  final DateTime createdAt;

  ReactionData({
    required this.type,
    required this.timestamp,
    required this.userId,
    required this.createdAt,
  });

  factory ReactionData.fromMap(Map<String, dynamic> map) {
    return ReactionData(
      type: map['type'] as String,
      timestamp: map['timestamp'] as double,
      userId: map['userId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'timestamp': timestamp,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
