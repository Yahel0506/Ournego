import 'package:flutter/material.dart';
import 'package:ournego/shared/widgets/information_card_widget.dart';

class OurnegoInformationDialog extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final double maxWidth;
  final EdgeInsetsGeometry actionsPadding;
  final Widget actions;

  const OurnegoInformationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.actions,
    this.maxWidth = 460,
    this.actionsPadding = const EdgeInsets.fromLTRB(20, 0, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          height: 550,
          child: Stack(
            children: [
              InformationCardWidget(
                title: title,
                description: description,
                imagePath: imagePath,
                blur: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
