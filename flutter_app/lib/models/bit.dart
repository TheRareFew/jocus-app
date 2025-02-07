import 'package:cloud_firestore/cloud_firestore.dart';

class Bit {
  final String id;
  final String title;
  final String description;
  final String userId;
  final String videoUrl;
  final String? comedyStructureId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  Bit({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.videoUrl,
    this.comedyStructureId,
    required this.createdAt,
    this.metadata,
  });

  factory Bit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Bit(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      userId: data['userId'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      comedyStructureId: data['comedyStructureId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'videoUrl': videoUrl,
      'comedyStructureId': comedyStructureId,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  Bit copyWith({
    String? title,
    String? description,
    String? videoUrl,
    String? comedyStructureId,
    Map<String, dynamic>? metadata,
  }) {
    return Bit(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId,
      videoUrl: videoUrl ?? this.videoUrl,
      comedyStructureId: comedyStructureId ?? this.comedyStructureId,
      createdAt: createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
