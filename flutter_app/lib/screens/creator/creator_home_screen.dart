import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../core/widgets/navigation/bottom_nav_bar.dart';
import 'studio_screen.dart';
import 'dashboard_screen.dart';
import 'analytics_screen.dart';
import 'trending_formats_screen.dart';

class CreatorHomeScreen extends StatelessWidget {
  const CreatorHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: navigationProvider.currentIndex,
            children: const [
              DashboardScreen(),
              StudioScreen(),
              AnalyticsScreen(),
              TrendingFormatsScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: navigationProvider.currentIndex,
            onTap: (index) => navigationProvider.setIndex(index),
            isCreator: true,
          ),
        );
      },
    );
  }
}
