import 'package:flutter/material.dart';
import 'package:flutter_app/screens/auth/login_screen.dart';
import 'package:flutter_app/screens/onboarding/onboarding_screen.dart';
import 'package:flutter_app/screens/creator/dashboard_screen.dart';
import 'package:flutter_app/screens/creator/studio_screen.dart';
import 'package:flutter_app/screens/creator/analytics_screen.dart';
import 'package:flutter_app/screens/creator/trending_formats_screen.dart';
import 'package:flutter_app/screens/viewer/feed_screen.dart';

class Routes {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/login': (context) => const LoginScreen(),
      '/onboarding': (context) => const OnboardingScreen(),
      '/dashboard': (context) => const DashboardScreen(),
      '/studio': (context) => const StudioScreen(),
      '/analytics': (context) => const AnalyticsScreen(),
      '/trending': (context) => const TrendingFormatsScreen(),
      '/feed': (context) => const FeedScreen(),
    };
  }
} 