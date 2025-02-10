// ignore_for_file: non_constant_identifier_names, avoid_print

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transitrack_web/models/account_model.dart';

// Model for Feedbacks. Recommendation: Should be using document IDs instead of emails and plate numbers. Users can rate either driver, puv or both.

class FeedbackData {
  String feedback_sender; // Email of Sender
  String feedback_recepient; // Email of Driver
  String feedback_jeepney; // Plate Number of PUV
  Timestamp timestamp;
  int feedback_driving_rating;
  int feedback_jeepney_rating;
  int feedback_route;
  String feedback_content;
  String? feedback_img;

  FeedbackData(
      {required this.feedback_sender,
      required this.feedback_recepient,
      required this.feedback_jeepney,
      required this.timestamp,
      required this.feedback_route,
      required this.feedback_driving_rating,
      required this.feedback_content,
      required this.feedback_jeepney_rating,
      this.feedback_img});

  factory FeedbackData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return FeedbackData(
      feedback_sender: data['feedback_sender'] ?? '',
      feedback_recepient: data['feedback_recepient'] ?? '',
      feedback_jeepney: data['feedback_jeepney'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      feedback_driving_rating: data['feedback_driving_rating'] ?? 0,
      feedback_jeepney_rating: data['feedback_jeepney_rating'] ?? 0,
      feedback_content: data['feedback_content'] ?? '',
      feedback_route: data['feedback_route'] ?? 0,
      feedback_img: data['feedback_img'] ?? '',
    );
  }
}

class UsersAdditionalInfo {
  AccountData? senderData;
  AccountData? recepientData;
  String? locationData;

  UsersAdditionalInfo(
      {required this.senderData,
      required this.recepientData,
      this.locationData});
}

Future<List<FeedbackData>?> getRating(String email, String field) async {
  try {
    QuerySnapshot ratingSnapshot = await FirebaseFirestore.instance
        .collection('feedbacks')
        .where(field, isEqualTo: email)
        .where(
            field == 'feedback_recepient'
                ? 'feedback_driving_rating'
                : 'feedback_jeepney_rating',
            isGreaterThan: 0)
        .limit(50)
        .get();
    if (ratingSnapshot.docs.isNotEmpty) {
      return ratingSnapshot.docs
          .map((e) => FeedbackData.fromFirestore(e))
          .toList();
    } else {
      print("Error: No Ratings found");
      return [];
    }
  } catch (e) {
    print(e.toString());
    return null;
  }
}
