import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

// This widget is called when user selects the feedback button

class FeedbackTab extends StatelessWidget {
  final RouteData route;
  final bool isDriver;
  final FeedbackData feedBack;
  const FeedbackTab(
      {super.key,
      required this.route,
      required this.isDriver,
      required this.feedBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Constants.defaultPadding),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(Constants.defaultPadding)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Route"),
              Row(
                children: [
                  Text(route.routeName),
                  const SizedBox(width: Constants.defaultPadding / 2),
                  Icon(Icons.circle, color: Color(route.routeColor))
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                    "Feedback by ${replaceWithAsterisks(feedBack.feedback_sender, 0.6)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: Constants.defaultPadding),
              Row(
                  children: List.generate(5, (index) {
                bool enabled = index <
                    (isDriver
                        ? feedBack.feedback_driving_rating
                        : feedBack.feedback_jeepney_rating);
                return Icon(
                  enabled ? Icons.star : Icons.star_border,
                  color: enabled ? Color(route.routeColor) : Colors.grey,
                );
              })),
            ],
          ),
          const Divider(color: Colors.white),
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
          SizedBox(
            height: Constants.defaultPadding * 2.5,
            child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Text(feedBack.feedback_content)),
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
                )),
        ],
      ),
    );
  }
}

String replaceWithAsterisks(String input, double probability) {
  // Define a random number generator
  final random = Random();

  // Convert the input string to a list of characters
  List<String> characters = input.split('');

  // Iterate through each character in the list
  for (int i = 0; i < characters.length; i++) {
    // Generate a random number between 0 and 1
    double randomValue = random.nextDouble();

    // Check if the random value is less than the probability
    if (randomValue < probability) {
      // Replace the character with an asterisk
      characters[i] = '*';
    }
  }

  // Join the list of characters back into a string
  String result = characters.join('');

  return result;
}
