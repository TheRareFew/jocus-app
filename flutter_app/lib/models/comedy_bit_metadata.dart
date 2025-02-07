import 'package:cloud_firestore/cloud_firestore.dart';

class ComedyBitMetadata {
  final String id;
  final String videoId;
  final String userId;
  final DateTime uploadDate;
  final int viewCount;
  final Map<String, int> reactionCounts;
  final Map<String, List<double>> reactionTimestamps;
  final double averageWatchTime;
  final double completionRate;
  final Map<String, dynamic> customMetrics;

  ComedyBitMetadata({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.uploadDate,
    this.viewCount = 0,
    Map<String, int>? reactionCounts,
    Map<String, List<double>>? reactionTimestamps,
    this.averageWatchTime = 0,
    this.completionRate = 0,
    Map<String, dynamic>? customMetrics,
  }) : 
    reactionCounts = reactionCounts ?? {
      'rofl': 0,
      'smirk': 0,
      'eyeroll': 0,
      'vomit': 0,
    },
    reactionTimestamps = reactionTimestamps ?? {
      'rofl': [],
      'smirk': [],
      'eyeroll': [],
      'vomit': [],
    },
    customMetrics = customMetrics ?? {};

  factory ComedyBitMetadata.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComedyBitMetadata(
      id: doc.id,
      videoId: data['videoId'] as String,
      userId: data['userId'] as String,
      uploadDate: (data['uploadDate'] as Timestamp).toDate(),
      viewCount: data['viewCount'] as int? ?? 0,
      reactionCounts: Map<String, int>.from(data['reactionCounts'] as Map? ?? {}),
      reactionTimestamps: (data['reactionTimestamps'] as Map?)?.map(
        (key, value) => MapEntry(
          key as String,
          (value as List).map((e) => (e as num).toDouble()).toList(),
        ),
      ) ?? {},
      averageWatchTime: (data['averageWatchTime'] as num?)?.toDouble() ?? 0,
      completionRate: (data['completionRate'] as num?)?.toDouble() ?? 0,
      customMetrics: data['customMetrics'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'videoId': videoId,
      'userId': userId,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'viewCount': viewCount,
      'reactionCounts': reactionCounts,
      'reactionTimestamps': reactionTimestamps,
      'averageWatchTime': averageWatchTime,
      'completionRate': completionRate,
      'customMetrics': customMetrics,
    };
  }

  ComedyBitMetadata copyWith({
    String? videoId,
    int? viewCount,
    Map<String, int>? reactionCounts,
    Map<String, List<double>>? reactionTimestamps,
    double? averageWatchTime,
    double? completionRate,
    Map<String, dynamic>? customMetrics,
  }) {
    return ComedyBitMetadata(
      id: id,
      videoId: videoId ?? this.videoId,
      userId: userId,
      uploadDate: uploadDate,
      viewCount: viewCount ?? this.viewCount,
      reactionCounts: reactionCounts ?? Map.from(this.reactionCounts),
      reactionTimestamps: reactionTimestamps ?? Map.from(this.reactionTimestamps),
      averageWatchTime: averageWatchTime ?? this.averageWatchTime,
      completionRate: completionRate ?? this.completionRate,
      customMetrics: customMetrics ?? Map.from(this.customMetrics),
    );
  }
}
