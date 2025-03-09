// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

// Report Model.

class ReportData {
  String report_id;
  String report_sender; // email of report issuer
  String report_recepient; // email for driver
  String report_jeepney; // puv plate number
  Timestamp timestamp;
  String report_content;
  int report_type; // 0 for lost items, 1 for crime incidents, 2 for mechanical failure, 3 for accidents, 4 for other concerns
  GeoPoint report_location;
  int report_route;
  String? report_img;

  ReportData(
      {required this.report_id,
      required this.report_sender,
      required this.report_recepient,
      required this.report_jeepney,
      required this.timestamp,
      required this.report_content,
      required this.report_type,
      required this.report_route,
      required this.report_location,
      this.report_img});

  factory ReportData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ReportData(
      report_id: doc.id,
      report_sender: data['report_sender'] ?? '',
      report_recepient: data['report_recepient'] ?? '',
      report_jeepney: data['report_jeepney'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      report_content: data['report_content'] ?? '',
      report_type: data['report_type'] ?? 0,
      report_route: data['report_route'],
      report_location: data['report_location'],
      report_img: data['report_img'] ?? '',
    );
  }

  static Map<String, int> reportTypeMap = {
    'Lost Item': 0,
    'Crime Incident': 1,
    'Mechanical Failure': 2,
    'Accident': 3,
    'Other Concerns': 4,
  };

  // Method to get the report type as a string
  String getReportType() {
    return reportTypeMap.entries
        .firstWhere((entry) => entry.value == report_type)
        .key;
  }

  static List<ReportDetails> reportDetails = [
    ReportDetails(reportType: 'Lost Item', reportColors: Colors.lightBlue),
    ReportDetails(reportType: 'Crime Incident', reportColors: Colors.red),
    ReportDetails(
        reportType: 'Mechanical Failure', reportColors: Colors.yellow),
    ReportDetails(reportType: 'Accident', reportColors: Colors.orange),
    ReportDetails(reportType: 'Other Concerns', reportColors: Colors.lightBlue),
  ];
}

class ReportDetails {
  String reportType;
  Color reportColors;

  ReportDetails({required this.reportType, required this.reportColors});
}

class ReportEntity {
  ReportData reportData;
  Circle reportCircle;

  ReportEntity({required this.reportData, required this.reportCircle});
}

Future<List<ReportData>?> getReportSender(String email) async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where("report_sender", isEqualTo: email)
        .limit(50)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((e) => ReportData.fromFirestore(e)).toList();
    } else {
      // print("Error: No Feedback found");
      return [];
    }
  } catch (e) {
    // print(e.toString());
    return null;
  }
}
