import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:transitrack_web/config/keys.dart';
import '../services/calculate_distance.dart';

// API Call Function for extracting the coordinate name using the Search Box API
Future<String> findAddress(LatLng latLng, bool isSpecific) async {
  // Truncate latitude and longitude to 4 decimal places
  String truncatedLat = latLng.latitude.toStringAsFixed(4);
  String truncatedLon = latLng.longitude.toStringAsFixed(4);

  // Use the Search Box API
  String apiUrl =
      'https://api.mapbox.com/search/searchbox/v1/reverse?longitude=$truncatedLon&latitude=$truncatedLat&access_token=${Keys.MapBoxKey}';

  final response = await http.get(Uri.parse(apiUrl));

  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);
    final features = decoded['features'];

    if (features.isNotEmpty) {
      // Extract the name and address of the closest feature
      final firstFeature = features[0];
      if (!isSpecific) {
        String name = firstFeature['properties']['name'] ?? 'Unknown Name';
        return name;
      } else {
        // Initialize variables to track the closest feature
        double closestDistance = double.infinity;
        Map<String, dynamic>? closestFeature;

        // Find the closest feature
        for (var feature in features) {
          // Extract the coordinates of the feature
          double featureLat = double.parse(
              feature['geometry']['coordinates'][1].toStringAsFixed(4));
          double featureLon = double.parse(
              feature['geometry']['coordinates'][0].toStringAsFixed(4));

          // Truncate the input coordinates to 4 decimal places
          double truncatedLat =
              double.parse(latLng.latitude.toStringAsFixed(4));
          double truncatedLon =
              double.parse(latLng.longitude.toStringAsFixed(4));

          // Calculate the distance using truncated coordinates
          double distance = calculateDistance(
            LatLng(truncatedLat, truncatedLon),
            LatLng(featureLat, featureLon),
          );

          // Update the closest feature if this one is closer
          if (distance < closestDistance) {
            closestDistance = distance;
            closestFeature = feature;
          }
        }

        // If a closest feature is found, return its details
        if (closestFeature != null) {
          String name = closestFeature['properties']['name'] ?? 'Unknown Name';
          String address =
              closestFeature['properties']['address'] ?? 'Unknown Address';
          return '$name, $address';
        }
        // Fallback: If no closest feature is found
        return 'No closest point found';
      }
    } else {
      return 'No address found';
    }
  } else {
    return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
  }
}
