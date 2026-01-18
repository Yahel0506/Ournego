import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationSlide extends StatefulWidget {
  final String title;
  final String description;
  final String imagePath;
  final String? buttonText;

  const LocationSlide({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.buttonText,
  });

  @override
  State<LocationSlide> createState() => _LocationSlideState();
}

class _LocationSlideState extends State<LocationSlide> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ------ Imágen ------
        SizedBox(
          height: 300,
          width: 300,
          child: Image(image: AssetImage(widget.imagePath)),
        ),
        SizedBox(height: 30),
        // ------ Titulo ------
        Text(
          widget.title,
          style: OurnegoTextStyles.header,
          textAlign: TextAlign.center,
        ),
        // ------ Descripción ------
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Text(
            widget.description,
            style: OurnegoTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 20),
        OutlinedButton(
          onPressed: () async {
            var status = await Permission.location.request();
            if (status.isDenied) {
              await Permission.location.request();
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            side: BorderSide(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          child: Text('ACTIVAR UBICACIÓN', style: OurnegoTextStyles.body),
        ),
      ],
    );
  }
}
