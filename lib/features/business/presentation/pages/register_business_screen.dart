import 'package:flutter/material.dart';
import 'package:ournego/features/business/presentation/widgets/register_business_widget.dart';

class RegisterBusinessScreen extends StatelessWidget {
  const RegisterBusinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('registerBusinessScreen'),
      body: Center(
        child: Column(
          children: [Spacer(), const RegisterBusinessWidget(), Spacer()],
        ),
      ),
    );
  }
}
