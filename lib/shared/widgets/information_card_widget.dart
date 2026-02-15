import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/ournego_text_styles.dart';

class InformationCardWidget extends StatelessWidget {
  const InformationCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  final String title;
  final String description;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(image: AssetImage(imagePath), height: 250),
          SizedBox(height: 16.0),
          Text(
            title,
            style: OurnegoTextStyles.header,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.0),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 48),
        ],
      ),
    );
  }
}
