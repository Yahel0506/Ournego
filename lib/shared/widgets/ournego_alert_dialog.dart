import 'package:flutter/material.dart';

class OurnegoAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String actionLabel;
  final VoidCallback onAction;
  final List<Widget> trailingActions;

  const OurnegoAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.actionLabel = 'OK',
    required this.onAction,
    this.trailingActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: onAction, child: Text(actionLabel)),
        ...trailingActions,
      ],
    );
  }
}
