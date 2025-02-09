import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

pickImage(ImageSource source) async {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _file = await _imagePicker.pickImage(source: source);
  if (_file != null) {
    return await _file.readAsBytes();
  }
  print('No Image Selected');
}

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
