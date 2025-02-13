import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/routes/routes.dart';
import '../../core/widgets/buttons/animated_gradient_button.dart';
import '../../core/widgets/text/animated_gradient_text.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'image.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0.03, 0),
            ).animate().fadeIn(duration: 1200.ms),
          ),
          // Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          // Content
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      top: 20.0,
                      bottom: 40.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedGradientText(
                          text: 'DASHBOARD',
                          fontSize: 42,
                          letterSpacing: 2,
                          useFloatingAnimation: false,
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(
                          begin: const Offset(0.2, 0.2),
                          end: const Offset(1.0, 1.0),
                          duration: 1200.ms,
                          curve: Curves.elasticOut,
                        )
                        .shimmer(
                          duration: 2000.ms,
                          color: Colors.white.withOpacity(0.8),
                          angle: -10,
                        )
                        .then()
                        .animate(
                          onPlay: (controller) => controller.repeat(),
                        )
                        .moveY(
                          begin: -2,
                          end: 2,
                          duration: 2000.ms,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .moveY(
                          begin: 2,
                          end: -2,
                          duration: 2000.ms,
                          curve: Curves.easeInOut,
                        ),
                        const SizedBox(height: 40),
                        _buildDashboardButton(
                          context,
                          'Studio',
                          Icons.video_call,
                          Routes.studio,
                        ).animate()
                        .fadeIn(delay: 200.ms)
                        .shimmer(
                          delay: 800.ms,
                          duration: 2000.ms,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 20),
                        _buildDashboardButton(
                          context,
                          'Analytics',
                          Icons.analytics,
                          Routes.analytics,
                        ).animate()
                        .fadeIn(delay: 400.ms)
                        .shimmer(
                          delay: 1000.ms,
                          duration: 2000.ms,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 20),
                        _buildDashboardButton(
                          context,
                          'Trending Formats',
                          Icons.trending_up,
                          Routes.trendingFormats,
                        ).animate()
                        .fadeIn(delay: 600.ms)
                        .shimmer(
                          delay: 1200.ms,
                          duration: 2000.ms,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 20),
                        _buildDashboardButton(
                          context,
                          'My Scripts',
                          Icons.format_list_bulleted,
                          Routes.myComedyStructures,
                        ).animate()
                        .fadeIn(delay: 800.ms)
                        .shimmer(
                          delay: 1400.ms,
                          duration: 2000.ms,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 20),
                        _buildDashboardButton(
                          context,
                          'Watch Feed',
                          Icons.play_circle_filled,
                          Routes.feed,
                        ).animate()
                        .fadeIn(delay: 1000.ms)
                        .shimmer(
                          delay: 1600.ms,
                          duration: 2000.ms,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardButton(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return AnimatedGradientButton(
      onPressed: () => Navigator.pushNamed(context, route),
      text: title,
      icon: icon,
      height: 64,
    );
  }
}
