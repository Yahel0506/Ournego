import 'package:flutter/material.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300, maxHeight: 400),
        child: OurnegoContentContainer(
          customVerticalPadding: 0,
          customHorizontalPadding: 0,
          hasBlur: true,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: onAction, child: Text(actionLabel)),
              ...trailingActions,
            ],
          ),
        ),
      ),
    );
  }
}
