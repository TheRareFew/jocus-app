import 'package:cloud_firestore/cloud_firestore.dart';

enum VideoStatus {
  initial,
  processing,
  ready,
  failed
}

class Video {
  final String id;
  final String title;
  final String description;
  final String userId;
  final String storageUrl;
  final String? thumbnailUrl;
  final int duration;
  final DateTime uploadDate;
  final VideoStatus status;
  final bool isProcessed;
  final Map<String, dynamic>? metadata;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.storageUrl,
    this.thumbnailUrl,
    required this.duration,
    required this.uploadDate,
    required this.status,
    required this.isProcessed,
    this.metadata,
  });

  factory Video.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Video(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      userId: data['userId'] ?? '',
      storageUrl: data['storageUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      duration: data['duration'] ?? 0,
      uploadDate: (data['uploadDate'] as Timestamp).toDate(),
      status: VideoStatus.values.firstWhere(
        (e) => e.toString() == 'VideoStatus.${data['status']}',
        orElse: () => VideoStatus.initial,
      ),
      isProcessed: data['isProcessed'] ?? false,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'storageUrl': storageUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'status': status.toString().split('.').last,
      'isProcessed': isProcessed,
      'metadata': metadata,
    };
  }

  Video copyWith({
    String? title,
    String? description,
    String? storageUrl,
    String? thumbnailUrl,
    VideoStatus? status,
    bool? isProcessed,
    Map<String, dynamic>? metadata,
  }) {
    return Video(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId,
      storageUrl: storageUrl ?? this.storageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration,
      uploadDate: uploadDate,
      status: status ?? this.status,
      isProcessed: isProcessed ?? this.isProcessed,
      metadata: metadata ?? this.metadata,
    );
  }
} 