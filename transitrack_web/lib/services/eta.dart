import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:transitrack_web/services/extract_coordinates.dart';
import '../../services/is_clockwise.dart';
import '../../services/nearest_index.dart';
import '../../config/keys.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/format_seconds.dart';

// This builds up the API call for Mapbox Directions API.

Future<EtaData?> eta(List<LatLng> coords, bool clockwise, LatLng commuter,
    LatLng jeep) async {
  List<LatLng> correctOrientation = coords;
  List<LatLng> reduced = [];
  if (clockwise) {
    if (!isClockwise(coords)) {
      correctOrientation = coords.reversed.toList();
    }

    // Find the nearest points in the route for the start and end
    int indexCommuter = findNearestLatLngIndex(commuter, correctOrientation);
    int indexJeep = findNearestLatLngIndex(jeep, correctOrientation);

    if (indexCommuter < indexJeep) {
      reduced.addAll(correctOrientation.sublist(indexJeep));
      reduced.addAll(correctOrientation.sublist(0, indexCommuter + 1));
    } else {
      reduced = correctOrientation.sublist(indexJeep, indexCommuter + 1);
    }
  } else {
    if (isClockwise(coords)) {
      correctOrientation = coords.reversed.toList();
    }
    // Find the nearest points in the route for the start and end
    int indexCommuter = findNearestLatLngIndex(commuter, correctOrientation);
    int indexJeep = findNearestLatLngIndex(jeep, correctOrientation);

    if (indexCommuter < indexJeep) {
      reduced.addAll(correctOrientation.sublist(indexJeep));
      reduced.addAll(correctOrientation.sublist(0, indexCommuter + 1));
    } else {
      reduced = correctOrientation.sublist(indexJeep, indexCommuter + 1);
    }
  }

  // Downsample List if longer than 22 entries since Mapbox only allows up to 22 points for pathfinding calculation
  List<LatLng> downsample = [];
  if (reduced.length > 23) {
    double step = reduced.length / 23;
    for (int i = 0; i < 23; i++) {
      int index = (i * step).round();
      downsample.add(reduced[index]);
    }
  } else {
    downsample = reduced;
  }

  String query = "";

  for (LatLng point in downsample) {
    query += "${point.longitude},${point.latitude};";
  }

  query = query.substring(0, query.length - 1);

  // First API Url is to calculate the ETA between the PUV location and the nearest route coordinate to the device of the client
  String apiUrl =
      'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/$query?geometries=geojson&access_token=${Keys.MapBoxKey}';

  // Second API Url is to calculate the ETA between the nearest route coordinate to the device of the client and the device of the client. This might sound
  // confusing, but this is essentially the cases when the device is far from the entire route, so this second API call will calculate that.
  String apiUrl2 =
      'https://api.mapbox.com/directions/v5/mapbox/walking/${commuter.longitude},${commuter.latitude};${downsample.last.longitude},${downsample.last.latitude}?geometries=geojson&access_token=${Keys.MapBoxKey}';

  final response = await http.get(Uri.parse(apiUrl));

  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);
    final routes = decoded['routes'] as List<dynamic>;
    double duration1 = routes[0]['duration'] as double;

    final response2 = await http.get(Uri.parse(apiUrl2));

    if (response2.statusCode == 200) {
      final decoded2 = json.decode(response2.body);
      final routes2 = decoded2['routes'] as List<dynamic>;
      double duration2 = routes2[0]['duration'] as double;

      List<LatLng> coords2 = extractCoordinates(decoded2);

      reduced.addAll(coords2.reversed.toList());
      return EtaData(
          etaTime: formatSeconds(duration1 + duration2),
          etaCoordinates: reduced);
    } else {
      return null;
    }
  } else {
    return null;
  }
}

class EtaData {
  String etaTime;
  List<LatLng> etaCoordinates;

  EtaData({
    required this.etaTime,
    required this.etaCoordinates,
  });
}
