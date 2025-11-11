import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;

  const SectionTitle({
    super.key,
    required this.title,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: style ??
          TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[900],
          ),
    );
  }
}

