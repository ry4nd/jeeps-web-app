import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// allows selection of image from a source
pickImage(ImageSource source) async {
  final ImagePicker _imagePicker =
      ImagePicker(); // creates an instance of ImagePicker plugin
  XFile? _file = await _imagePicker.pickImage(
      source: source); // opens img picker and waits the user to select an image
  if (_file != null) {
    return await _file
        .readAsBytes(); // if an img is selected it reads and returns Uint8List (a list of bytes)
  }
  print('No Image Selected');
}

final FirebaseStorage _storage = FirebaseStorage
    .instance; // create an instance of FirebaseStorage to access its functionality

// uploads image to FirebaseStorage and return its downloadURL
Future<String> uploadImageToStorage(
    String name, Uint8List file, String directory) async {
  try {
    Reference ref = _storage
        .ref()
        .child(directory)
        .child(name); // get reference to FirebaseStorage location
    UploadTask uploadTask = ref.putData(file); // upload img as binary data
    TaskSnapshot snapshot = await uploadTask; // waits for upload to complete
    String downloadUrl =
        await snapshot.ref.getDownloadURL(); // retrive the download url
    return downloadUrl;
  } catch (e) {
    throw Exception('Error uploading image: $e');
  }
}

// definition of variables of attachment button class
// allows us to create an object for attachment button
// 'final' are immutable variables
class AttachmentButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final double iconSize;
  final double fontSize;
  final Color iconColor;
  final Color textColor;
  // constructor that initializes the object's properties
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

  // build(BuildContext context) is a method from StatelessWidget
  // @override annotation makes it clear that we are replacing the original method
  @override
  // build method is required when creating widgets
  Widget build(BuildContext context) {
    // context provides the widget's location in the widget tree
    // we return an elevated button widget with icon for the attachment button widget
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
