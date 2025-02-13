import 'package:cloud_firestore/cloud_firestore.dart';

class Bit {
  final String id;
  final String title;
  final String description;
  final String userId;
  final String storageUrl;
  final String? comedyStructureId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final String? transcript;

  Bit({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.storageUrl,
    this.comedyStructureId,
    required this.createdAt,
    this.metadata,
    this.transcript,
  });

  factory Bit.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Helper function to safely get string values
    String getStringValue(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map) return value.toString();
      return value.toString();
    }

    return Bit(
      id: doc.id,
      title: getStringValue(data['title']),
      description: getStringValue(data['description']),
      userId: getStringValue(data['userId']),
      storageUrl: getStringValue(data['storageUrl']),
      comedyStructureId: data['comedyStructureId']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      transcript: data['transcript']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'storageUrl': storageUrl,
      'comedyStructureId': comedyStructureId,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
      'transcript': transcript,
    };
  }

  Bit copyWith({
    String? title,
    String? description,
    String? storageUrl,
    String? comedyStructureId,
    Map<String, dynamic>? metadata,
    String? transcript,
  }) {
    return Bit(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId,
      storageUrl: storageUrl ?? this.storageUrl,
      comedyStructureId: comedyStructureId ?? this.comedyStructureId,
      createdAt: createdAt,
      metadata: metadata ?? this.metadata,
      transcript: transcript ?? this.transcript,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => title;
}
