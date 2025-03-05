import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// This widget is called when user selects the feedback button

class CommuterFeedbackTab extends StatelessWidget {
  final RouteData route;
  final FeedbackData feedBack;
  const CommuterFeedbackTab(
      {super.key, required this.route, required this.feedBack});

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
                  const Text("Date"),
                  const SizedBox(width: Constants.defaultPadding / 2),
                  Text(DateFormat('MMM d, yyyy')
                      .format(feedBack.timestamp.toDate())),
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
