import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:transitrack_web/components/validated_form_field.dart';

import '../../models/account_model.dart';
import '../../style/constants.dart';
import '../../style/style.dart';
import '../button.dart';
import '../text_field.dart';

// This widget displays the account settings page

class AccountSettings extends StatelessWidget {
  final User user;
  final AccountData account;
  const AccountSettings({super.key, required this.user, required this.account});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // focus node for forms
    final nameFocusNode = FocusNode();
    final emailFocusNode = FocusNode();
    final passwordFocusNode = FocusNode();
    final confirmPasswordFocusNode = FocusNode();

    nameController.text = account.account_name;
    emailController.text = user.email!;

    void errorMessage(String message) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
                backgroundColor: Constants.bgColor,
                title: Center(
                    child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                )));
          });
    }

    // Validator for name
    String? validateName(String? name) {
      if (name == null) {
        return null;
      }
      if (name.length < 3 || name.length > 12) {
        return 'Name should be 3-12 characters';
      }
      return null; // Valid input
    }

    // Validator for email
    String? validateEmail(String? email) {
      if (email == null) {
        return null;
      }
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email) && email.isNotEmpty) {
        return 'Enter a valid email address';
      }
      return null; // Valid input
    }

    // Validator for password
    String? validatePassword(String? password) {
      if (password == null) {
        return null;
      }
      if (password.length < 6 && password.isNotEmpty) {
        return 'Password must be at least 6 characters long';
      }
      return null; // Valid input
    }

    // Validator for confirm password
    String? validateConfirmPassword(String? confirmPassword) {
      if (confirmPassword == null) {
        return null;
      }
      if (confirmPassword != passwordController.text &&
          confirmPassword.isNotEmpty) {
        return 'Passwords do not match';
      }
      return null; // Valid input
    }

    void update() async {
      // show loading circle
      showDialog(
          context: context,
          builder: (context) {
            return const Center(child: CircularProgressIndicator());
          });

      try {
        // Validate name
        if (validateName(nameController.text) != null) {
          Navigator.pop(context); // Pop loading circle
          errorMessage(validateName(nameController.text)!);
          return;
        }

        // Validate password
        if (passwordController.text.isNotEmpty &&
            validatePassword(passwordController.text) != null) {
          Navigator.pop(context); // Pop loading circle
          errorMessage(validatePassword(passwordController.text)!);
          return;
        }

        // Check if passwords match
        if (passwordController.text != confirmPasswordController.text) {
          Navigator.pop(context); // Pop loading circle
          errorMessage("Passwords don't match!");
          return;
        }

        // Update name if changed
        if (nameController.text != account.account_name) {
          Map<String, dynamic> newAccountSettings = {
            'account_name': nameController.text,
          };
          AccountData.updateAccountFirestore(user.email!, newAccountSettings);
        }

        if (emailController.text != user.email! ||
            (passwordController.text != "" &&
                passwordController.text == confirmPasswordController.text)) {
          Map<String, dynamic> newAccountSettings = {
            'account_email': emailController.text,
          };

          AccountData.updateAccountFirestore(user.email!, newAccountSettings);

          AccountData.updateEmailAndPassword(
                  emailController.text, passwordController.text)
              .then((value) => FirebaseAuth.instance.signOut());
        }

        // pop loading circle
        Navigator.pop(context);
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        // pop loading circle
        Navigator.pop(context);
        errorMessage(e.code);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(
          left: Constants.defaultPadding,
          right: Constants.defaultPadding,
          bottom: Constants.defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            children: [
              PrimaryText(
                text: "Settings",
                color: Colors.white,
                size: 40,
                fontWeight: FontWeight.w700,
              )
            ],
          ),
          const SizedBox(height: Constants.defaultPadding),
          ValidatedFormField(
            controller: emailController,
            hintText: "Email",
            obscureText: false,
            focusNode: emailFocusNode,
            validator: validateEmail,
          ),
          const SizedBox(height: Constants.defaultPadding),
          ValidatedFormField(
            controller: nameController,
            hintText: "Name",
            obscureText: false,
            focusNode: nameFocusNode,
            validator: validateName,
          ),
          const SizedBox(height: Constants.defaultPadding),
          ValidatedFormField(
            controller: passwordController,
            hintText: "Password",
            obscureText: true,
            focusNode: passwordFocusNode,
            validator: validatePassword,
          ),
          const SizedBox(height: Constants.defaultPadding),
          ValidatedFormField(
            controller: confirmPasswordController,
            hintText: "Confirm Password",
            obscureText: true,
            focusNode: confirmPasswordFocusNode,
            validator: validateConfirmPassword,
          ),
          const SizedBox(height: Constants.defaultPadding),
          const SizedBox(height: Constants.defaultPadding / 2),
          const PrimaryText(
              text: "Email and password changes will log you out.",
              color: Colors.white),
          const SizedBox(height: Constants.defaultPadding * 2),
          Button(
            onTap: update,
            text: "Save",
          ),
        ],
      ),
    );
  }
}
