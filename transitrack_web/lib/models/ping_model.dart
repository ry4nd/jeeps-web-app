// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:html' as html;

import 'package:transitrack_web/models/route_model.dart';

// Broadcasted Location model

class PingData {
  String ping_id;
  String
      ping_email; // not really being used since we keep the broadcasted locations annonymous
  GeoPoint ping_location;
  int ping_route;
  Timestamp ping_timestamp;

  PingData(
      {required this.ping_id,
      required this.ping_email,
      required this.ping_location,
      required this.ping_route,
      required this.ping_timestamp});

  factory PingData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PingData(
      ping_id: doc.id,
      ping_email: data['ping_email'],
      ping_location: data['ping_location'],
      ping_route: data['ping_route'],
      ping_timestamp: data['ping_timestamp'],
    );
  }

  Map<String, dynamic> toGeoJSONFeature() {
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [ping_location.longitude, ping_location.latitude]
      },
      'properties': {
        'ping_id': ping_id,
        'ping_email': ping_email,
        'ping_route': ping_route,
        'ping_timestamp': ping_timestamp.toDate().toIso8601String()
      }
    };
  }
}

class PingEntity {
  PingData pingData;
  Circle pingCircle;

  PingEntity({required this.pingData, required this.pingCircle});
}

listToGeoJSON(List<PingData> pings) {
  List<Map<String, dynamic>> features =
      pings.map((ping) => ping.toGeoJSONFeature()).toList();

  Map<String, dynamic> featureCollection = {
    'type': 'FeatureCollection',
    'features': features,
  };

  return featureCollection;
}

String convertToCsv(List<List<dynamic>> csvData) {
  final List<List<String>> csvRows = csvData.map((row) {
    return row.map((cell) => '"$cell"').toList();
  }).toList();
  return csvRows.map((row) => row.join(',')).join('\n');
}

void downloadPingDataAsCSV(List<PingData> pingDataList, RouteData routeData) {
  // Define CSV headers
  List<String> headers = [
    'Latitude',
    'Longitude',
    'Timestamp',
  ];

  // Convert PingData objects to CSV rows
  List<List<dynamic>> csvRows = pingDataList.map((pingData) {
    return [
      pingData.ping_location.latitude,
      pingData.ping_location.longitude,
      pingData.ping_timestamp
          .toDate()
          .toString(), // Convert Timestamp to DateTime and then to string
    ];
  }).toList();

  // Combine headers and rows
  List<List<dynamic>> csvData = [
    [
      "Shared Locations for ${routeData.routeName} route with ${pingDataList.length} results. (Data is sorted by Timestamp in DESCENDING order.)"
    ],
    headers,
    ...csvRows
  ];

  // Convert CSV data to a string
  String csvString = convertToCsv(csvData);

  // Create a blob with the CSV data
  final blob = html.Blob([csvString], 'text/csv');

  // Create a URL for the blob
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Create an anchor element with the URL
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "shared_locations_${routeData.routeName}.csv");

  // Click the anchor to trigger the download
  anchor.click();

  // Revoke the URL to release memory
  html.Url.revokeObjectUrl(url);
}
