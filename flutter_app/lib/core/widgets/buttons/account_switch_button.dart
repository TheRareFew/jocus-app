import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AccountSwitchButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const AccountSwitchButton({
    Key? key,
    required this.onPressed,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.black45,
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(double.infinity, 48),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    ).animate()
    .fadeIn(delay: 1000.ms, duration: 600.ms)
    .slideY(begin: 0.2, end: 0);
  }
}
