import 'package:flutter/material.dart';

class SheetHeader extends StatelessWidget {
  final String name;
  final bool isExpanded;

  const SheetHeader({super.key, required this.name, required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      maxLines: isExpanded ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    );
  }
}
