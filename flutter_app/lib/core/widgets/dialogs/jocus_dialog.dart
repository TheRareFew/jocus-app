import 'package:flutter/material.dart';
import '../buttons/jocus_button.dart';

class JocusDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final List<Widget>? actions;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const JocusDialog({
    Key? key,
    required this.title,
    this.message,
    this.content,
    this.actions,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      title: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null)
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          if (content != null) content!,
        ],
      ),
      actions: actions ??
          [
            if (cancelLabel != null)
              JocusButton(
                label: cancelLabel!,
                variant: JocusButtonVariant.text,
                onPressed: () async {
                  if (!context.mounted) return;
                  onCancel?.call();
                  await Navigator.maybePop(context, false);
                },
              ),
            if (confirmLabel != null)
              JocusButton(
                label: confirmLabel!,
                variant: isDestructive
                    ? JocusButtonVariant.filled
                    : JocusButtonVariant.tonal,
                onPressed: () async {
                  if (!context.mounted) return;
                  onConfirm?.call();
                  await Navigator.maybePop(context, true);
                },
              ),
          ],
      actionsPadding: const EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 20,
      ),
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    List<Widget>? actions,
    String confirmLabel = 'OK',
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => JocusDialog(
        title: title,
        message: message,
        content: content,
        actions: actions,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
      ),
    );
  }
}
