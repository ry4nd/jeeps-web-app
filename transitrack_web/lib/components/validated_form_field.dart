import 'package:flutter/material.dart';
import '../style/constants.dart';

class ValidatedFormField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? type;
  final int? lines;
  final int? limit;
  final bool? enabled;
  final String? Function(String?)? validator; // Validator function
  final FocusNode focusNode; // FocusNode for interaction tracking

  const ValidatedFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.focusNode,
    this.type,
    this.lines,
    this.enabled,
    this.limit,
    this.validator,
  });

  @override
  _ValidatedFormFieldState createState() => _ValidatedFormFieldState();
}

class _ValidatedFormFieldState extends State<ValidatedFormField> {
  String? errorText;

  @override
  void initState() {
    super.initState();

    // Add a listener to the controller to validate input on text change
    widget.controller.addListener(() {
      validateInput();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(validateInput);
    super.dispose();
  }

  void validateInput() {
    setState(() {
      errorText = widget.validator?.call(widget.controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      focusNode: widget.focusNode,
      enabled: widget.enabled ?? true,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: errorText == null && widget.controller.text.isNotEmpty
                ? Colors.green // Green border for valid input
                : Colors.white, // Default border color
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: errorText == null && widget.controller.text.isNotEmpty
                ? Colors.green // Green border for valid input
                : Constants.primaryColor, // Default focused border color
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide:
              BorderSide(color: Constants.formError), // Red border for errors
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(
              color:
                  Constants.formError), // Red border when focused and invalid
        ),
        fillColor: Constants.secondaryColor,
        filled: true,
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Colors.white),
        errorText: errorText, // Display error message if invalid
      ),
      style: const TextStyle(color: Colors.white),
      maxLines: widget.obscureText ? 1 : widget.lines,
      maxLength: widget.limit,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
