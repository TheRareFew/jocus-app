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
  static const String studio = '/studio';
  static const String dashboard = '/dashboard';
  static const String analytics = '/analytics';
  static const String trendingFormats = '/trending-formats';
  static const String feed = '/feed';
  static const String onboarding = '/onboarding';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const OnboardingScreen());
    case Routes.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case Routes.signup:
      return MaterialPageRoute(builder: (_) => const SignupScreen());
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
    case Routes.onboarding:
      return MaterialPageRoute(builder: (_) => const OnboardingScreen());
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