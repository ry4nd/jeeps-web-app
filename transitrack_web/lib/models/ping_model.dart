// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:html' as html;
import '../services/int_to_hex.dart';

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

  // convert ping data to GeoJSON format
  // a format for encoding a variety of geographic data structures
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

// converts a list of Ping Data to GeoJSON format
listToGeoJSON(List<PingData> pings) {
  List<Map<String, dynamic>> features =
      pings.map((ping) => ping.toGeoJSONFeature()).toList();

  Map<String, dynamic> featureCollection = {
    'type': 'FeatureCollection',
    'features': features,
  };

  return featureCollection;
}

// converts a list of CSV data to a CSV string
// CSV - info separated by commas
String convertToCsv(List<List<dynamic>> csvData) {
  final List<List<String>> csvRows = csvData.map((row) {
    return row.map((cell) => '"$cell"').toList();
  }).toList();
  return csvRows.map((row) => row.join(',')).join('\n');
}

// adds a GeoJSON cluster to the Mapbox map
// displays the pings
Future<void> addGeojsonCluster(
    MapboxMapController mapController, RouteData routeData) async {
  // remove the existing pings to update the map with new ones
  // for refreshing the pings
  mapController.removeLayer("pings-circles");
  mapController.removeLayer("pings-count");
  mapController.removeSource("pings");

  // add the new pings
  // addSource provides the ping data
  mapController.addSource(
      "pings",
      GeojsonSourceProperties(
          data: listToGeoJSON([]), cluster: true, clusterRadius: 20));

  // addLayer provides the appearance of the ping data within the map
  mapController.addLayer(
      "pings",
      "pings-circles",
      CircleLayerProperties(
          circleColor: intToHexColor(routeData.routeColor),
          circleOpacity: 0.5,
          circleRadius: [
            Expressions.step,
            [Expressions.get, 'point_count'],
            // example: circle radius is 20 if point count is less than 5
            20,
            5,
            30,
            10,
            40
          ]));

  // includes the ping count for a cluster
  mapController.addLayer(
      "pings",
      "pings-count",
      const SymbolLayerProperties(
        textField: [Expressions.get, 'point_count_abbreviated'],
        textFont: ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
        textSize: 12,
      ));
}

// just allows the ping data to be downloaded within the shared locations widget for RM
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
