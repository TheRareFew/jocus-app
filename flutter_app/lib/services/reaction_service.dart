import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comedy_structure.dart';

class ReactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a reaction to a comedy bit
  Future<void> addReaction({
    required String bitId,
    required String userId,
    required String reactionType,
    required double timestamp,
  }) async {
    final reactionData = {
      'type': reactionType,
      'timestamp': timestamp,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add to reactions subcollection
    await _firestore
        .collection('comedy_structures')
        .doc(bitId)
        .collection('reactions')
        .add(reactionData);
  }

  /// Removes a reaction from a comedy bit
  Future<void> removeReaction({
    required String bitId,
    required String userId,
    required String reactionId,
  }) async {
    await _firestore
        .collection('comedy_structures')
        .doc(bitId)
        .collection('reactions')
        .doc(reactionId)
        .delete();
  }

  /// Gets a real-time stream of reactions for a comedy bit
  Stream<List<ReactionData>> getReactionsStream(String bitId) {
    return _firestore
        .collection('comedy_structures')
        .doc(bitId)
        .collection('reactions')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ReactionData(
          type: data['type'] as String,
          timestamp: data['timestamp'] as double,
          userId: data['userId'] as String,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  /// Gets aggregated reaction counts for a comedy bit
  Stream<Map<String, int>> getReactionCountsStream(String bitId) {
    return _firestore
        .collection('comedy_structures')
        .doc(bitId)
        .collection('reactions')
        .snapshots()
        .map((snapshot) {
      final counts = {
        'rofl': 0,
        'smirk': 0,
        'eyeroll': 0,
        'vomit': 0,
      };
      
      for (final doc in snapshot.docs) {
        final type = doc.data()['type'] as String;
        counts[type] = (counts[type] ?? 0) + 1;
      }
      
      return counts;
    });
  }

  /// Gets reaction counts for all bits by a creator
  Stream<Map<String, Map<String, int>>> getAllBitsReactionCounts(String creatorId) {
    return _firestore
        .collection('users')
        .doc(creatorId)
        .collection('comedy_structures')
        .snapshots()
        .asyncMap((structures) async {
          final result = <String, Map<String, int>>{};
          
          for (final structure in structures.docs) {
            final reactions = await structure.reference
                .collection('reactions')
                .get();
                
            final counts = {
              'rofl': 0,
              'smirk': 0,
              'eyeroll': 0,
              'vomit': 0,
            };
            
            for (final reaction in reactions.docs) {
              final type = reaction.data()['type'] as String;
              counts[type] = (counts[type] ?? 0) + 1;
            }
            
            result[structure.id] = counts;
          }
          
          return result;
        });
  }

  /// Gets a heatmap of reactions for a specific timestamp range
  Future<List<Map<String, dynamic>>> getReactionHeatmap(
    String bitId, {
    double startTime = 0,
    double? endTime,
  }) async {
    final query = _firestore
        .collection('comedy_structures')
        .doc(bitId)
        .collection('reactions')
        .where('timestamp', isGreaterThanOrEqualTo: startTime);

    final snapshot = endTime == null
        ? await query.get()
        : await query.where('timestamp', isLessThanOrEqualTo: endTime).get();

    final heatmap = <Map<String, dynamic>>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      heatmap.add({
        'timestamp': data['timestamp'],
        'type': data['type'],
      });
    }

    return heatmap;
  }
}
