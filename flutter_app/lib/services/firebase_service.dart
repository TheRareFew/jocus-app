import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseService {
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }

  static Future<void> testFirebaseConnection() async {
    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.logEvent(name: 'test_event');
      debugPrint('Test event logged successfully');
    } catch (e) {
      debugPrint('Error logging test event: $e');
    }
  }
} 