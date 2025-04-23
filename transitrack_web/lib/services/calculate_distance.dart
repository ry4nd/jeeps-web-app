import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:math';

// Distance calculation to find the nearest point from the device to the route coordinates

double calculateDistance(LatLng point1, LatLng point2) {
  const double earthRadiusKm = 6371.0; // Radius of the Earth in kilometers

  double lat1 = point1.latitude;
  double lon1 = point1.longitude;
  double lat2 = point2.latitude;
  double lon2 = point2.longitude;

  // Convert degrees to radians
  double dLat = _degreesToRadians(lat2 - lat1);
  double dLon = _degreesToRadians(lon2 - lon1);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  // Distance in kilometers
  return earthRadiusKm * c;
}

double _degreesToRadians(double degrees) {
  return degrees * pi / 180;
}
