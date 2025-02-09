import 'package:flutter/material.dart';

class AttachmentButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final double iconSize;
  final double fontSize;
  final Color iconColor;
  final Color textColor;
  const AttachmentButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.iconSize = 14.0,
    this.fontSize = 12.0,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
  });
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize, color: iconColor),
      label: Text(
        label,
        style: TextStyle(fontSize: fontSize, color: textColor),
      ),
    );
  }
}
