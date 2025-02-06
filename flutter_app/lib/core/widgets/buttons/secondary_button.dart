import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? foregroundColor;
  final EdgeInsets? padding;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.foregroundColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = OutlinedButton.styleFrom(
      foregroundColor: foregroundColor ?? Theme.of(context).primaryColor,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide(
        color: foregroundColor ?? Theme.of(context).primaryColor,
      ),
    );

    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: style,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: Text(text),
    );
  }
} 