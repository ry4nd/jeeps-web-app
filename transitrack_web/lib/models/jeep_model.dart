import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import '../models/account_model.dart';

// PUV Model

class JeepData {
  String device_id;
  Timestamp timestamp;
  int passenger_count; // -1 for passive broadcasting mode
  int max_capacity;
  GeoPoint location;
  int route_id;
  double bearing; // rotation of PUV symbol (0-360)

  JeepData(
      {required this.device_id,
      required this.timestamp,
      required this.passenger_count,
      required this.max_capacity,
      required this.location,
      required this.route_id,
      required this.bearing});

  factory JeepData.fromSnapshot(QueryDocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

    String deviceId = data['device_id'];
    Timestamp timestamp = data['timestamp'];
    int passengerCount = data['passenger_count'];
    int maxCapacity = data['max_capacity'];
    GeoPoint location = data['location'];
    int routeId = data['route_id'];
    double bearing = data['bearing'];

    return JeepData(
        device_id: deviceId,
        timestamp: timestamp,
        passenger_count: passengerCount,
        max_capacity: maxCapacity,
        location: location,
        route_id: routeId,
        bearing: bearing);
  }

  Map<String, dynamic> toGeoJSONFeature() {
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [location.longitude, location.latitude]
      },
    };
  }
}

jeepListToGeoJSON(List<JeepData> jeeps) {
  List<Map<String, dynamic>> features =
      jeeps.map((jeep) => jeep.toGeoJSONFeature()).toList();

  Map<String, dynamic> featureCollection = {
    'type': 'FeatureCollection',
    'features': features,
  };

  return featureCollection;
}

class JeepEntity {
  JeepsAndDrivers jeepAndDriver;
  Symbol jeepSymbol;

  JeepEntity({
    required this.jeepAndDriver,
    required this.jeepSymbol,
  });

  void setJeepsAndDrivers(JeepsAndDrivers newData) {
    jeepAndDriver = newData;
  }
}

class JeepsAndDrivers {
  AccountData? driver;
  JeepData jeep;

  JeepsAndDrivers({this.driver, required this.jeep});
}

class JeepHistoricalData {
  JeepData jeepData;
  String driverName;
  bool isOperating;

  JeepHistoricalData(
      {required this.jeepData,
      required this.driverName,
      required this.isOperating});

  factory JeepHistoricalData.fromSnapshot(
      QueryDocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

    return JeepHistoricalData(
        jeepData: JeepData(
          device_id: data['device_id'],
          timestamp: data['timestamp'],
          passenger_count: data['passenger_count'],
          max_capacity: data['max_capacity'],
          location: data['location'],
          route_id: data['route_id'],
          bearing: data['bearing'],
        ),
        driverName: data['driver'],
        isOperating: data['is_operating']);
  }
}

class PerJeepHistoricalData {
  String jeepPlateNumber;
  List<JeepHistoricalData> data;

  PerJeepHistoricalData({required this.jeepPlateNumber, required this.data});
}

Future<List<PerJeepHistoricalData>?> getJeepHistoricalData(
    int routeId, DateTime day) async {
  // Reference to the Firestore collection
  CollectionReference collectionReference =
      FirebaseFirestore.instance.collection('jeeps_historical');

  DateTime start = day;
  DateTime end = day.add(const Duration(hours: 1));

  // Query all documents in the collection
  QuerySnapshot querySnapshot = await collectionReference
      .where('route_id', isEqualTo: routeId)
      .where('timestamp', isGreaterThanOrEqualTo: start)
      .where('timestamp', isLessThan: end)
      .orderBy('timestamp', descending: true)
      .get();

  // Initialize a Set to store unique device IDs
  Set<String> uniqueDeviceIds = {};

  List<JeepHistoricalData> entireJeepHistoricalData = querySnapshot.docs
      .map((e) => JeepHistoricalData.fromSnapshot(e))
      .toList();

  uniqueDeviceIds =
      entireJeepHistoricalData.map((e) => e.jeepData.device_id).toSet();
  List<PerJeepHistoricalData> jeepHistoricalData =
      uniqueDeviceIds.map((plateNumber) {
    List<JeepHistoricalData> historicalJeepDataForSpecificJeep =
        entireJeepHistoricalData
            .where((element) => element.jeepData.device_id == plateNumber)
            .toList();

    return PerJeepHistoricalData(
        jeepPlateNumber: plateNumber, data: historicalJeepDataForSpecificJeep);
  }).toList();

  return jeepHistoricalData;
}
