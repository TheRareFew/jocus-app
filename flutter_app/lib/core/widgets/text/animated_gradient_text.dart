import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedGradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  final List<Color> gradientColors;
  final bool useFloatingAnimation;
  final FontWeight fontWeight;
  final String? fontFamily;
  final double letterSpacing;

  const AnimatedGradientText({
    Key? key,
    required this.text,
    this.fontSize = 48.0,
    this.gradientColors = const [
      Color(0xFFB388FF), // purple.shade300
      Color(0xFF64B5F6), // blue.shade400
      Color(0xFF80DEEA), // cyan.shade300
    ],
    this.useFloatingAnimation = true,
    this.fontWeight = FontWeight.w600,
    this.fontFamily = 'Righteous',
    this.letterSpacing = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          fontWeight: fontWeight,
          color: Colors.white,
          letterSpacing: letterSpacing,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
