import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

// This widget is called when user selects the feedback button

class CommuterFeedbackTab extends StatelessWidget {
  final RouteData route;
  final FeedbackData feedBack;
  final Function loadCommuters;
  const CommuterFeedbackTab(
      {super.key,
      required this.route,
      required this.feedBack,
      required this.loadCommuters});

  // get the name of the driver/feedback recipient
  Future<String> getAccountName(String email) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('accounts')
          .where('account_email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['account_name'] ?? 'Unknown';
      }
    } catch (e) {
      debugPrint("Error fetching account name: $e");
    }
    return 'Unknown';
  }

  Future<void> deleteFeedback(String senderEmail, Timestamp timestamp) async {
    try {
      // Query the Firestore collection to find feedback documents
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('feedback_sender',
              isEqualTo: senderEmail) // Filter by sender email
          .where('timestamp', isEqualTo: timestamp) // Filter by timestamp
          .limit(1) // Limit the query to 1 document
          .get(); // Retrieve the matching document

      // Check if any document was found.
      if (querySnapshot.docs.isNotEmpty) {
        // Get the first document and delete it.
        await querySnapshot.docs.first.reference.delete();

        // Print success message in the console.
        // print("Feedback deleted successfully.");
      } else {
        // Print a message if no matching feedback is found.
        // print("No matching feedback found to delete.");
      }
    } catch (error) {
      // Print an error message if something goes wrong.
      // print("Error deleting feedback: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getAccountName(feedBack.feedback_recepient),
      builder: (context, snapshot) {
        String accountName = snapshot.data ?? 'Loading...';

        return Container(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(Constants.defaultPadding),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('MMMM d, y')
                          .format(feedBack.timestamp.toDate())),
                      Text(
                          DateFormat('hh:mm a')
                              .format(feedBack.timestamp.toDate()),
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      AwesomeDialog(
                        context: context,
                        width: 400,
                        dialogType: DialogType.warning,
                        padding: const EdgeInsets.all(Constants.defaultPadding),
                        desc:
                            "You are about to delete this feedback. This action cannot be undone.",
                        btnOkText: "Delete",
                        btnOkColor: Colors.red[600],
                        btnCancelText: "Cancel",
                        btnCancelColor: Constants.bgColor,
                        btnCancelOnPress: () {},
                        btnOkOnPress: () async {
                          await deleteFeedback(
                              feedBack.feedback_sender, feedBack.timestamp);

                          await AwesomeDialog(
                                  context: context,
                                  width: 150,
                                  padding: const EdgeInsets.only(
                                      bottom: Constants.defaultPadding),
                                  dialogType: DialogType.noHeader,
                                  body: CircularProgressIndicator(
                                      color: Color(route.routeColor)),
                                  dismissOnBackKeyPress: false,
                                  dismissOnTouchOutside: false,
                                  autoHide: const Duration(milliseconds: 1000))
                              .show();
                          loadCommuters();
                        },
                      ).show();
                    },
                    icon: Icon(Icons.delete, color: Colors.red[600]),
                    label: Text("Delete",
                        style: TextStyle(color: Colors.red[600])),
                  )
                ],
              ),
              const Divider(color: Colors.white),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(feedBack.feedback_jeepney),
                      Text(accountName), // Display the fetched account name
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          children: List.generate(5, (index) {
                        bool enabled = index < feedBack.feedback_jeepney_rating;
                        return Icon(
                          enabled ? Icons.star : Icons.star_border,
                          color:
                              enabled ? Color(route.routeColor) : Colors.grey,
                        );
                      })),
                      Row(
                          children: List.generate(5, (index) {
                        bool enabled = index < feedBack.feedback_driving_rating;
                        return Icon(
                          enabled ? Icons.star : Icons.star_border,
                          color:
                              enabled ? Color(route.routeColor) : Colors.grey,
                        );
                      })),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white),
              SizedBox(
                height: Constants.defaultPadding * 2.5,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Text(feedBack.feedback_content),
                ),
              ),
              if (feedBack.feedback_img != null &&
                  feedBack.feedback_img!.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: Image.network(
                    feedBack.feedback_img!,
                    fit: BoxFit.contain,
                    errorBuilder: (BuildContext context, Object error,
                        StackTrace? stackTrace) {
                      return const Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.red),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
