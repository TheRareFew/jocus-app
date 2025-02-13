import 'package:flutter/material.dart';

enum JocusButtonVariant {
  filled,
  tonal,
  outlined,
  text,
}

class JocusButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final JocusButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsets? padding;

  const JocusButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.variant = JocusButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressIndicatorColor(colorScheme),
                ),
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(icon, size: 18),
          ),
        Text(label),
      ],
    );

    if (fullWidth) {
      buttonChild = Center(child: buttonChild);
    }

    switch (variant) {
      case JocusButtonVariant.filled:
        return FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            padding: padding,
            minimumSize: fullWidth ? const Size.fromHeight(48) : null,
          ),
          child: buttonChild,
        );

      case JocusButtonVariant.tonal:
        return FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            padding: padding,
            minimumSize: fullWidth ? const Size.fromHeight(48) : null,
          ),
          child: buttonChild,
        );

      case JocusButtonVariant.outlined:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding,
            minimumSize: fullWidth ? const Size.fromHeight(48) : null,
          ),
          child: buttonChild,
        );

      case JocusButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: padding,
            minimumSize: fullWidth ? const Size.fromHeight(48) : null,
          ),
          child: buttonChild,
        );
    }
  }

  Color _getProgressIndicatorColor(ColorScheme colorScheme) {
    switch (variant) {
      case JocusButtonVariant.filled:
        return colorScheme.onPrimary;
      case JocusButtonVariant.tonal:
        return colorScheme.onSecondaryContainer;
      case JocusButtonVariant.outlined:
        return colorScheme.primary;
      case JocusButtonVariant.text:
        return colorScheme.primary;
    }
  }
}
