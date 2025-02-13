import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ReactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a reaction to a bit. If the user has already added this type of reaction,
  /// it will be ignored.
  Future<void> addReaction({
    required String bitId,
    required String userId,
    required String reactionType,
    required double timestamp,
  }) async {
    // Validate reaction type
    final validTypes = ['rofl', 'smirk', 'eyeroll', 'vomit'];
    if (!validTypes.contains(reactionType)) {
      throw ArgumentError('Invalid reaction type: $reactionType');
    }

    // Validate timestamp
    if (timestamp < 0) {
      throw ArgumentError('Timestamp must be non-negative');
    }

    final bitRef = _firestore.collection('bits').doc(bitId);
    
    // First check if user has already reacted with this type
    final existingReactions = await bitRef
        .collection('reactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: reactionType)
        .limit(1)
        .get();

    if (existingReactions.docs.isNotEmpty) {
      // User has already reacted with this type - remove the reaction
      debugPrint('Removing existing reaction for user $userId of type $reactionType');
      
      // Start a transaction to ensure atomic updates
      await _firestore.runTransaction((transaction) async {
        // Get the analytics document
        final analyticsRef = bitRef.collection('analytics').doc('stats');
        final analyticsDoc = await transaction.get(analyticsRef);
        
        if (analyticsDoc.exists) {
          final data = analyticsDoc.data() as Map<String, dynamic>;
          final reactionCounts = data['reactionCounts'] as Map<String, dynamic>;
          final totalReactions = data['totalReactions'] as int;

          // Delete the reaction and update counts
          transaction
            ..delete(existingReactions.docs.first.reference)
            ..update(analyticsRef, {
              'totalReactions': totalReactions - 1,
              'reactionCounts.$reactionType': (reactionCounts[reactionType] ?? 1) - 1,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
        }
      });
      return;
    }

    // Start a transaction to ensure atomic updates
    await _firestore.runTransaction((transaction) async {
      // First, do all reads
      final analyticsRef = bitRef.collection('analytics').doc('stats');
      final analyticsDoc = await transaction.get(analyticsRef);
      
      // Now do all writes
      // Add the reaction
      final reactionRef = bitRef.collection('reactions').doc();
      final reactionData = {
        'type': reactionType,
        'timestamp': timestamp,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (analyticsDoc.exists) {
        final data = analyticsDoc.data() as Map<String, dynamic>;
        final reactionCounts = data['reactionCounts'] as Map<String, dynamic>;
        final totalReactions = data['totalReactions'] as int;

        // Batch our writes
        transaction
          ..set(reactionRef, reactionData)
          ..update(analyticsRef, {
            'totalReactions': totalReactions + 1,
            'reactionCounts.$reactionType': (reactionCounts[reactionType] ?? 0) + 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      } else {
        // Batch our writes
        transaction
          ..set(reactionRef, reactionData)
          ..set(analyticsRef, {
            'totalReactions': 1,
            'reactionCounts': {
              'rofl': reactionType == 'rofl' ? 1 : 0,
              'smirk': reactionType == 'smirk' ? 1 : 0,
              'eyeroll': reactionType == 'eyeroll' ? 1 : 0,
              'vomit': reactionType == 'vomit' ? 1 : 0,
            },
            'viewCount': 0,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      }
    });
  }

  /// Removes a reaction from a comedy bit
  Future<void> removeReaction({
    required String bitId,
    required String userId,
    required String reactionId,
  }) async {
    await _firestore
        .collection('bits')
        .doc(bitId)
        .collection('reactions')
        .doc(reactionId)
        .delete();
  }

  /// Gets the current reaction counts for a bit
  Future<Map<String, int>> getReactionCounts(String bitId) async {
    final doc = await _firestore
        .collection('bits')
        .doc(bitId)
        .collection('analytics')
        .doc('stats')
        .get();

    if (!doc.exists) {
      return {
        'rofl': 0,
        'smirk': 0,
        'eyeroll': 0,
        'vomit': 0,
      };
    }

    final data = doc.data()!;
    final counts = data['reactionCounts'] as Map<String, dynamic>;
    
    return {
      'rofl': counts['rofl'] ?? 0,
      'smirk': counts['smirk'] ?? 0,
      'eyeroll': counts['eyeroll'] ?? 0,
      'vomit': counts['vomit'] ?? 0,
    };
  }

  /// Gets a real-time stream of reactions for a bit
  Stream<List<Map<String, dynamic>>> getReactionsStream(String bitId) {
    return _firestore
        .collection('bits')
        .doc(bitId)
        .collection('reactions')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Gets aggregated reaction counts for a comedy bit
  Stream<Map<String, int>> getReactionCountsStream(String bitId) {
    return _firestore
        .collection('bits')
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
        .collection('bits')
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
