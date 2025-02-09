import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/account_model.dart';
import '../../models/jeep_model.dart';
import '../../models/route_model.dart';
import '../../style/constants.dart';
import '../../style/style.dart';
import '../button.dart';
import '../attach_img_button.dart';
import '../text_field.dart';

// This widget is called when user selects the feedback button

class FeedbackForm extends StatefulWidget {
  AccountData? user;
  JeepsAndDrivers jeep;
  RouteData route;
  FeedbackForm(
      {super.key, required this.user, required this.jeep, required this.route});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final feedBackController = TextEditingController();

  int _drivingRating = 0;
  int _jeepRating = 0;
  Uint8List? _image;

  void sendFeedback() async {
    // show loading circle
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        });

    // feedback field is not empty
    if (feedBackController.text.isNotEmpty) {
      if (_drivingRating + _jeepRating > 0) {
        if (widget.user!.account_email != widget.jeep.driver!.account_email) {
          try {
            // Add a new document with auto-generated ID
            await FirebaseFirestore.instance
                .collection('feedbacks')
                .add({
                  'feedback_sender': widget.user!.account_email,
                  'feedback_recepient': widget.jeep.driver!.account_email,
                  'feedback_jeepney': widget.jeep.jeep.device_id,
                  'timestamp': FieldValue.serverTimestamp(),
                  'feedback_content': feedBackController.text,
                  'feedback_driving_rating': _drivingRating,
                  'feedback_jeepney_rating': _jeepRating,
                  'feedback_route': widget.route.routeId
                })
                .then((value) => Navigator.pop(context))
                .then((value) => Navigator.pop(context));

            errorMessage("Success!");
          } catch (e) {
            // pop loading circle
            Navigator.pop(context);
            errorMessage(e.toString());
          }
        } else {
          // pop loading circle
          Navigator.pop(context);

          errorMessage("You cannot rate yourself!");
        }
      } else {
        // pop loading circle
        Navigator.pop(context);

        errorMessage("You need to rate either PUV or Driver!");
      }
    } else {
      // pop loading circle
      Navigator.pop(context);

      // password dont match
      errorMessage("Feedback field is empty!");
    }
    // try sign up
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

  void selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: Constants.defaultPadding,
          right: Constants.defaultPadding,
          bottom: Constants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            children: [
              PrimaryText(
                text: "Feedback",
                color: Colors.white,
                size: 40,
                fontWeight: FontWeight.w700,
              )
            ],
          ),
          const Divider(color: Colors.white),
          const SizedBox(height: Constants.defaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Route"),
              Row(
                children: [
                  Text(widget.route.routeName),
                  const SizedBox(width: Constants.defaultPadding / 2),
                  Icon(Icons.circle, color: Color(widget.route.routeColor))
                ],
              ),
            ],
          ),
          const SizedBox(height: Constants.defaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Driver"),
              Text(widget.jeep.driver!.account_name),
            ],
          ),
          const SizedBox(height: Constants.defaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Plate Number"),
              Text(widget.jeep.jeep.device_id),
            ],
          ),
          const SizedBox(height: Constants.defaultPadding),
          const Divider(color: Colors.white),
          const SizedBox(height: Constants.defaultPadding),
          const Text("Driver"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _drivingRating ? Icons.star : Icons.star_border,
                  color: index < _drivingRating
                      ? Color(widget.route.routeColor)
                      : Colors.grey,
                  size: 30,
                ),
                onPressed: () {
                  if (_drivingRating == index + 1) {
                    setState(() {
                      _drivingRating = 0;
                    });
                  } else {
                    setState(() {
                      _drivingRating = index + 1;
                    });
                  }
                },
              );
            }),
          ),
          const SizedBox(height: Constants.defaultPadding),
          const Text("PUV"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _jeepRating ? Icons.star : Icons.star_border,
                  color: index < _jeepRating
                      ? Color(widget.route.routeColor)
                      : Colors.grey,
                  size: 30,
                ),
                onPressed: () {
                  if (_jeepRating == index + 1) {
                    setState(() {
                      _jeepRating = 0;
                    });
                  } else {
                    setState(() {
                      _jeepRating = index + 1;
                    });
                  }
                },
              );
            }),
          ),
          const SizedBox(height: Constants.defaultPadding),
          const Divider(color: Colors.white),
          const SizedBox(height: Constants.defaultPadding),
          InputTextField(
            controller: feedBackController,
            hintText: "Feedback",
            obscureText: false,
            lines: 4,
            limit: 150,
            helperWidget: AttachmentButton(
              onPressed: selectImage,
              label: "Attach Image",
              icon: Icons.add_a_photo,
            ),
          ),
          const SizedBox(height: Constants.defaultPadding),
          if (_image != null)
            Column(
              children: [
                const Text(
                  "Selected Image:",
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: Constants.defaultPadding / 2),
                IntrinsicHeight(
                  child: Image.memory(
                    _image!,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: Constants.defaultPadding),
              ],
            ),
          Button(
            onTap: () => sendFeedback(),
            text: _drivingRating + _jeepRating == 0
                ? "Rate Driver or PUV"
                : "Send Feedback for ${_drivingRating != 0 && _jeepRating != 0 ? "Driver and PUV" : _jeepRating != 0 ? "PUV" : "Driver"}",
          ),
        ],
      ),
    );
  }
}
