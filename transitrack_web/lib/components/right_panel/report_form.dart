import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:transitrack_web/services/find_location.dart';

import '../../models/account_model.dart';
import '../../models/jeep_model.dart';
import '../../models/report_model.dart';
import '../../models/route_model.dart';
import '../../style/constants.dart';
import '../../style/style.dart';
import '../button.dart';
import '../attach_img_button.dart';
import '../text_field.dart';

// This widget is called when user selects the report button

class ReportForm extends StatefulWidget {
  AccountData? user;
  JeepsAndDrivers jeep;
  RouteData route;
  ReportForm(
      {super.key, required this.user, required this.jeep, required this.route});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final reportController = TextEditingController();

  String reportType = "Lost Item";
  late String address;
  Uint8List? _image;

  @override
  void initState() {
    super.initState();
    getAddress();
  }

  void getAddress() async {
    String result = await findAddress(LatLng(widget.jeep.jeep.location.latitude,
        widget.jeep.jeep.location.longitude));
    setState(() {
      address = result;
    });
  }

  void sendReport() async {
    // show loading circle
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        });

    // report field is not empty
    if (reportController.text.isNotEmpty) {
      try {
        String? imageUrl;
        if (_image != null) {
          imageUrl = await uploadImageToStorage(
              '${widget.user!.account_email}_${DateTime.now().millisecondsSinceEpoch}',
              _image!,
              'report_images');
        }
        // Add a new document with auto-generated ID
        await FirebaseFirestore.instance
            .collection('reports')
            .add({
              'report_sender': widget.user!.account_email,
              'report_recepient': widget.jeep.driver!.account_email,
              'report_jeepney': widget.jeep.jeep.device_id,
              'timestamp': FieldValue.serverTimestamp(),
              'report_content': reportController.text,
              'report_type': ReportData.reportTypeMap[reportType],
              'report_location': GeoPoint(widget.jeep.jeep.location.latitude,
                  widget.jeep.jeep.location.longitude),
              'report_route': widget.route.routeId,
              'report_img': imageUrl,
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

      // password dont match
      errorMessage("Report field is empty!");
    }
    // try sign up
  }

  // sets the Uint8List variable to be the selected image file
  // needs to be within the widget
  void selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    // setState is used to notify the framework that the internal state of the widget has changed
    // signals that there is a need to rebuild
    setState(() {
      _image = img;
    });
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
                text: "Report",
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
          if (ReportData.reportTypeMap[reportType]! > 0)
            Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Address"),
                  const SizedBox(width: Constants.defaultPadding),
                  Expanded(
                      child: Text(address,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: Constants.defaultPadding),
            ]),
          const Divider(color: Colors.white),
          const SizedBox(height: Constants.defaultPadding / 2),
          const Text("Report Type"),
          const SizedBox(height: 5),
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
                value: reportType, // Initial value
                onChanged: (String? newValue) {
                  // Handle dropdown value change
                  if (newValue != null) {
                    setState(() {
                      reportType = newValue;
                    });
                  }
                },
                items: ReportData.reportTypeMap.keys
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
          InputTextField(
              controller: reportController,
              hintText: "Report",
              obscureText: false,
              lines: 4,
              limit: 150,
              helperWidget: AttachmentButton(
                onPressed: selectImage,
                label: "Attach Image",
                icon: Icons.add_a_photo,
              )),
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
            onTap: () => sendReport(),
            text: "Send Report",
          ),
        ],
      ),
    );
  }
}
