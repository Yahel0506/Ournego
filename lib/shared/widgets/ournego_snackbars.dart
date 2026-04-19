import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';

class OurnegoSnackbars {
  OurnegoSnackbars._();

  static SnackBar error(BuildContext context, String message) {
    return SnackBar(
      content: Text(
        message,
        style: OurnegoTextStyles.body.copyWith(color: Colors.red),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  static SnackBar info(String message) {
    return SnackBar(content: Text(message));
  }
}
