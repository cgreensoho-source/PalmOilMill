import 'package:flutter/material.dart';

class InitialAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final double fontSize;
  final Color? backgroundColor;

  const InitialAvatar({
    super.key,
    required this.name,
    this.radius = 20,
    this.fontSize = 16,
    this.backgroundColor,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    List<String> names = name.trim().split(RegExp(r'\s+'));
    String initials = "";

    if (names.length > 1) {
      initials = names[0][0] + names[names.length - 1][0];
    } else {
      initials = names[0][0];
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.green.shade700,
      child: Text(
        _getInitials(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
