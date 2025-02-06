import 'package:flutter/material.dart';
import '../../screens/creator/studio_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/creator/dashboard_screen.dart';
import '../../screens/creator/analytics_screen.dart';
import '../../screens/creator/trending_formats_screen.dart';
import '../../screens/viewer/feed_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';

class Routes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  
  // Main navigation routes
  static const String creatorHome = '/creator';
  static const String viewerHome = '/viewer';
  
  // Creator sub-routes
  static const String studio = '/creator/studio';
  static const String dashboard = '/creator/dashboard';
  static const String analytics = '/creator/analytics';
  static const String trendingFormats = '/creator/trending-formats';
  
  // Viewer sub-routes
  static const String feed = '/viewer/feed';
  static const String explore = '/viewer/explore';
  static const String profile = '/viewer/profile';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const OnboardingScreen());
    case Routes.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case Routes.signup:
      return MaterialPageRoute(builder: (_) => const SignupScreen());
    case Routes.onboarding:
      return MaterialPageRoute(builder: (_) => const OnboardingScreen());
    case Routes.creatorHome:
      return MaterialPageRoute(builder: (_) => const DashboardScreen());
    case Routes.viewerHome:
      return MaterialPageRoute(builder: (_) => const FeedScreen());
    case Routes.studio:
      return MaterialPageRoute(builder: (_) => const StudioScreen());
    case Routes.dashboard:
      return MaterialPageRoute(builder: (_) => const DashboardScreen());
    case Routes.analytics:
      return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
    case Routes.trendingFormats:
      return MaterialPageRoute(builder: (_) => const TrendingFormatsScreen());
    case Routes.feed:
      return MaterialPageRoute(builder: (_) => const FeedScreen());
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        ),
      );
  }
} 