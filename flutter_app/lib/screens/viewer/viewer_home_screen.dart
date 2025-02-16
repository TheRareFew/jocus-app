import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../core/widgets/navigation/bottom_nav_bar.dart';
import 'feed_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';

class ViewerHomeScreen extends StatelessWidget {
  const ViewerHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: navigationProvider.currentIndex,
            children: const [
              FeedScreen(),
              ExploreScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: navigationProvider.currentIndex,
            onTap: (index) {
              // Preload first video when switching to feed tab
              if (index == 0 && navigationProvider.currentIndex != 0) {
                FeedScreen.preloadFirstVideo();
              }
              navigationProvider.setIndex(index);
            },
            isCreator: false,
          ),
        );
      },
    );
  }
}
