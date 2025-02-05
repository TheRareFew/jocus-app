import 'package:flutter/material.dart';
import '../../core/routes/routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Dashboard'),
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDashboardButton(
              context,
              'Studio',
              Icons.video_call,
              Routes.studio,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildDashboardButton(
              context,
              'Analytics',
              Icons.analytics,
              Routes.analytics,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildDashboardButton(
              context,
              'Trending Formats',
              Icons.trending_up,
              Routes.trendingFormats,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardButton(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, route),
      icon: Icon(icon, size: 24),
      label: Text(
        title,
        style: const TextStyle(fontSize: 18),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
} 