import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/route_model.dart';
import '../../../style/constants.dart';
import '../../../style/style.dart';
import '../../text_field.dart';
import '../../button.dart';

// This widget allows the route manager to register a PUV

class RegisterJeep extends StatefulWidget {
  final RouteData route;
  const RegisterJeep({super.key, required this.route});

  @override
  State<RegisterJeep> createState() => _RegisterJeepState();
}

class _RegisterJeepState extends State<RegisterJeep> {
  final jeepNameController = TextEditingController();

  final jeepCapacityController = TextEditingController();

  void registerJeep() async {
    // show loading circle
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        });

    // feedback field is not empty
    if (jeepNameController.text.isNotEmpty) {
      if (jeepCapacityController.text.isNotEmpty &&
          int.parse(jeepCapacityController.text) > 0) {
        bool nameAvailable = true;
        try {
          // Get reference to Firestore collection
          CollectionReference jeepsCollection =
              FirebaseFirestore.instance.collection('jeeps_realtime');

          // Query Firestore for documents where 'device_id' is equal to given deviceId
          QuerySnapshot querySnapshot = await jeepsCollection
              .where('device_id', isEqualTo: jeepNameController.text)
              .get();

          // Check if any documents exist matching the query
          if (querySnapshot.docs.isNotEmpty) {
            nameAvailable = false;
          }
        } catch (e) {
          Navigator.pop(context);
          errorMessage(e.toString());
        }

        if (nameAvailable) {
          try {
            // Add a new document with auto-generated ID
            await FirebaseFirestore.instance
                .collection('jeeps_realtime')
                .add({
                  'device_id': jeepNameController.text.toUpperCase(),
                  'timestamp': FieldValue.serverTimestamp(),
                  'max_capacity': int.parse(jeepCapacityController.text),
                  'location': const GeoPoint(14.653836, 121.068427),
                  'route_id': widget.route.routeId,
                  'bearing': 0.1,
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
          errorMessage(
              "Plate Number is already registered to another vehicle.");
        }
      } else {
        // pop loading circle
        Navigator.pop(context);

        errorMessage("Input PUV Maximum Capacity");
      }
    } else {
      // pop loading circle
      Navigator.pop(context);

      // password dont match
      errorMessage("Input PUV Plate Number");
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
                text: "Register PUV",
                color: Colors.white,
                size: 40,
                fontWeight: FontWeight.w700,
              )
            ],
          ),
          const Divider(color: Colors.white),
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
          const Divider(color: Colors.white),
          const SizedBox(height: Constants.defaultPadding),
          InputTextField(
              controller: jeepNameController,
              hintText: "Plate Number",
              obscureText: false),
          const SizedBox(height: Constants.defaultPadding),
          InputTextField(
              controller: jeepCapacityController,
              hintText: "Max Capacity",
              obscureText: false,
              type: TextInputType.number),
          const SizedBox(height: Constants.defaultPadding),
          const Divider(color: Colors.white),
          const SizedBox(height: Constants.defaultPadding),
          Button(
            onTap: () => registerJeep(),
            text: "Register",
          ),
        ],
      ),
    );
  }
}
