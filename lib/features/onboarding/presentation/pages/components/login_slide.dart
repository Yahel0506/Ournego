import 'package:flutter/material.dart';
import 'package:ournego/features/auth/presentation/widgets/auth_selection_widget.dart';
import 'package:ournego/features/navigation/presentation/pages/main_layout_screen.dart';

class LoginSlide extends StatefulWidget {
  final String title;
  final String imagePath;
  final String darkImagePath;
  final String googleLogin;
  final String emailLogin;
  final String phoneLogin;
  final String guestAccess;
  final String termsText1;
  final String termsText2;
  final String termsText3;
  final String termsText4;

  const LoginSlide({
    super.key,
    required this.title,
    required this.imagePath,
    required this.darkImagePath,
    required this.googleLogin,
    required this.emailLogin,
    required this.phoneLogin,
    required this.guestAccess,
    required this.termsText1,
    required this.termsText2,
    required this.termsText3,
    required this.termsText4,
  });

  @override
  State<LoginSlide> createState() => _LoginSlideState();
}

class _LoginSlideState extends State<LoginSlide> {
  @override
  Widget build(BuildContext context) {
    return AuthSelectionWidget(
      title: widget.title,
      imagePath: widget.imagePath,
      darkImagePath: widget.darkImagePath,
      googleLogin: widget.googleLogin,
      emailLogin: widget.emailLogin,
      phoneLogin: widget.phoneLogin,
      guestAccess: widget.guestAccess,
      termsText1: widget.termsText1,
      termsText2: widget.termsText2,
      termsText3: widget.termsText3,
      termsText4: widget.termsText4,
      onSuccess: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
        );
      },
    );
  }
}
