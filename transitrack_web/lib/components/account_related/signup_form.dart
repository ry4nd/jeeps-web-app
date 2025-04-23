import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/components/signup_form_field.dart';

import '../../models/account_model.dart';
import '../../style/constants.dart';
import '../../style/style.dart';
import '../button.dart';

// Register Page

class SignupForm extends StatefulWidget {
  final Function()? onTap;
  const SignupForm({super.key, required this.onTap});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>(); // Key to manage the form state

  List<String> registerPrompts = [
    "Congratulations on registering your commuter account!\n\nTo access the commuter features, please verify your account by clicking the link we've sent to your email\ninbox/spam folder.",
    "Congratulations on registering your driver account!\n\nTo access the driver features, contact your route manager for verification and install the JeePS Driver App.",
    "Congratulations on registering your route manager account!\n\nTo access the route manager features, please wait while we verify your account.\n\n-JeePS Team"
  ];
  List<RouteData>? routes;
  List<String>? names;
  String? chosenRoute;

  // text editing controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String accountType = "Commuter";

  // focus node for forms
  final nameFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  final confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    fetchRoutes();
  }

  @override
  // to avoid memory leakage
  void dispose() {
    // Dispose controllers and focus nodes
    emailController.dispose();
    emailFocusNode.dispose();
    nameController.dispose();
    nameFocusNode.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    confirmPasswordController.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void fetchRoutes() async {
    List<RouteData>? data = await RouteData.fetchRoutes();

    setState(() {
      routes = data;
      names = routes!.map((e) => e.routeName).toList();
      chosenRoute = names!.first;
    });
  }

  // sign user in method
  void signUserUp() async {
    // Show loading circle
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        });

    // Try sign up
    try {
      // Validate email first
      if (emailController.text.isEmpty ||
          validateEmail(emailController.text) != null) {
        Navigator.pop(context); // Pop loading circle
        errorMessage("Enter a valid email address");
        return;
      }

      // Validate name
      if (nameController.text.isEmpty || nameController.text.length < 3) {
        Navigator.pop(context); // Pop loading circle
        errorMessage("Name should be at least 3 characters");
        return;
      }

      // Check if password is confirmed
      if (passwordController.text != confirmPasswordController.text) {
        Navigator.pop(context); // Pop loading circle
        errorMessage("Passwords don't match!");
        return;
      }

      // Check if a route is selected
      if (routes == null || chosenRoute == null) {
        Navigator.pop(context); // Pop loading circle
        errorMessage("Select a route you wish to associate to.");
        return;
      }

      // Proceed with Firebase sign-up
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text, password: passwordController.text)
          .then((value) async {
        String uid = value.user!.uid;

        await FirebaseFirestore.instance.collection('accounts').add({
          'account_name': nameController.text,
          'account_email': emailController.text,
          'account_uid': uid,
          'account_type': AccountData.accountTypeMap[accountType],
          'jeep_driving': "",
          'is_verified': false,
          'route_id': routes!
              .firstWhere((element) => element.routeName == chosenRoute!)
              .routeId,
          'show_discounted': false,
          'account_banned': false,
        });

        if (AccountData.accountTypeMap[accountType] == 0) {
          value.user!.sendEmailVerification();
        }

        // Pop loading circle
        Navigator.pop(context);
      });

      // Show success dialog
      AwesomeDialog(
          context: context,
          dialogType: DialogType.info,
          padding: const EdgeInsets.only(
              left: Constants.defaultPadding,
              right: Constants.defaultPadding,
              bottom: Constants.defaultPadding),
          width: 400,
          onDismissCallback: (_) => Navigator.pop(context),
          body: PointerInterceptor(
            child: Text(
              registerPrompts[AccountData.accountTypeMap[accountType]!],
              textAlign: TextAlign.center,
            ),
          )).show();
    } on FirebaseAuthException catch (e) {
      // Pop loading circle
      Navigator.pop(context);
      errorMessage(e.code);
    }
  }

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
    if (name.length < 3 && name.isNotEmpty) {
      return 'Name should be at least 3 characters';
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: Constants.defaultPadding,
          right: Constants.defaultPadding,
          bottom: Constants.defaultPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              children: [
                PrimaryText(
                  text: "Sign Up",
                  color: Colors.white,
                  size: 40,
                  fontWeight: FontWeight.w700,
                )
              ],
            ),
            const SizedBox(height: Constants.defaultPadding),
            SignupFormField(
              controller: emailController,
              hintText: "Email",
              obscureText: false,
              focusNode: emailFocusNode,
              validator: validateEmail,
            ),
            const SizedBox(height: Constants.defaultPadding),
            SignupFormField(
              controller: nameController,
              hintText: "Name",
              obscureText: false,
              focusNode: nameFocusNode,
              validator: validateName,
            ),
            const SizedBox(height: Constants.defaultPadding),
            SignupFormField(
              controller: passwordController,
              hintText: "Password",
              obscureText: true,
              focusNode: passwordFocusNode,
              validator: validatePassword,
            ),
            const SizedBox(height: Constants.defaultPadding),
            SignupFormField(
              controller: confirmPasswordController,
              hintText: "Confirm Password",
              obscureText: true,
              focusNode: confirmPasswordFocusNode,
              validator: validateConfirmPassword,
            ),
            const SizedBox(height: Constants.defaultPadding),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.symmetric(
                  horizontal: Constants.defaultPadding / 2, vertical: 4),
              decoration: BoxDecoration(
                color: Constants.secondaryColor,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: Colors.white, // Set border color here
                  width: 1, // Set border width here
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: accountType, // Initial value
                  onChanged: null,
                  items: AccountData.accountTypeMap.keys
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: Constants.defaultPadding),
            if (accountType != 'Commuter' && names == null)
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.symmetric(
                    horizontal: Constants.defaultPadding / 2,
                    vertical: Constants.defaultPadding + 2.5),
                decoration: BoxDecoration(
                  color: Constants.secondaryColor,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: Colors.white, // Set border color here
                    width: 1, // Set border width here
                  ),
                ),
                child: const Text(
                  "Loading Routes...",
                  style: TextStyle(fontSize: 15),
                ),
              ),
            if (accountType != 'Commuter' && names != null)
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.symmetric(
                    horizontal: Constants.defaultPadding / 2, vertical: 4),
                decoration: BoxDecoration(
                  color: Constants.secondaryColor,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: Colors.white, // Set border color here
                    width: 1, // Set border width here
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: chosenRoute, // Initial value
                    onChanged: (String? newValue) {
                      // Handle dropdown value change
                      if (newValue != null) {
                        setState(() {
                          chosenRoute = newValue;
                        });
                      }
                    },
                    items: names!.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: Constants.defaultPadding * 2),
            Button(
              onTap: signUserUp,
              text: "Sign Up",
            ),
            const SizedBox(height: Constants.defaultPadding * 2.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account?',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onTap,
                  child: const Text(
                    'Login now',
                    style: TextStyle(
                        color: Constants.primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
