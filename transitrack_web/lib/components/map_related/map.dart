// ignore_for_file: prefer_null_aware_operators, non_constant_identifier_names

import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/services/int_to_hex.dart';
import 'package:transitrack_web/services/mapbox/add_eta_line.dart';
import 'package:transitrack_web/services/mapbox/add_image_from_asset.dart';
import 'package:transitrack_web/services/mapbox/animate_ripple.dart';
import 'package:transitrack_web/services/mapbox/request_location.dart';
import 'package:transitrack_web/services/mapbox/minute_old_checker.dart';

import '../../config/keys.dart';
import '../../config/map_settings.dart';
import '../../config/responsive.dart';
import '../../models/account_model.dart';
import '../../models/jeep_model.dart';
import '../../models/route_model.dart';
import '../../models/ping_model.dart';

import '../../style/constants.dart';
import '../account_related/route_manager/route_manager_options.dart';
import '../right_panel/desktop_route_info.dart';
import '../right_panel/unselected_desktop_route_info.dart';
import '../right_panel/mobile_dashboard_unselected.dart';
import '../right_panel/mobile_route_info.dart';

// This is the main map

class MapWidget extends StatefulWidget {
  final RouteData? route;
  final List<JeepsAndDrivers>? jeeps;
  final AccountData? currentUserFirestore;
  final ValueChanged<LatLng> foundDeviceLocation;
  final ValueChanged<bool> mapLoaded;
  const MapWidget(
      {super.key,
      required this.route,
      required this.jeeps,
      required this.currentUserFirestore,
      required this.foundDeviceLocation,
      required this.mapLoaded});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with TickerProviderStateMixin {
  late RouteData? _value;
  late List<JeepsAndDrivers>? jeeps;
  late LatLng? myLocation;
  late int _configRoute;
  late int _configStops;

  late MapboxMapController _mapController;
  late StreamSubscription<Position> _positionStream;

  late Circle?
      deviceCircle; // the white circle showing the passengers current location
  bool mapLoaded = false; // used to trigger actions once map is fully loaded

  // for route points, lines, and jeepneys
  late List<LatLng> setRoute;
  late List<LatLng> setRouteCopy;
  late List<LatLng> setStops;
  LatLng? selectedStop; // To store the selected stop's coordinates
  List<Circle> circles = [];
  List<Circle> stopsCircles = [];
  List<Line> lines = [];
  List<JeepEntity> jeepEntities = [];

  // Ping Fetching
  StreamSubscription? pingListener;
  List<PingData> pings = [];
  late Timer timer;

  // set to true once user allows location service
  bool gpsTracking = false;

  JeepEntity? selectedJeep;

  @override
  void initState() {
    super.initState();

    setState(() {
      _value = widget.route;
      jeeps = widget.jeeps;
      _configRoute = -1;
      _configStops = -1;
      myLocation = null;
      deviceCircle = null;
    });

    // if the map is loaded refresh the available pings
    if (mapLoaded) {
      refreshPingLayer();
    }

    // runs every second to update the pings displayed on the map
    timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      // if map is fully loaded and routeData is not null
      if (mapLoaded && _value != null) {
        // we set pings to those ping's within the 1 minute duration
        setState(() {
          pings = pings
              .where((element) =>
                  minuteOldChecker(element.ping_timestamp.toDate()))
              .toList();
        });

        // converts pings as a GeoJSON format to set as the source for the pings layer
        _mapController.setGeoJsonSource("pings", listToGeoJSON(pings));
      }
    });
  }

  // triggers request loc permission and if allowed listen to location
  void startListening() async {
    var permission = await requestLocationPermission(context);

    setState(() {
      gpsTracking = permission;
    });

    if (gpsTracking) {
      _listenToDeviceLocation();
    }
  }

  @override
  // if the user selects a new route update the map information
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if route choice changed
    if (widget.route != _value) {
      selectedJeep = null;
      _mapController.setGeoJsonSource("eta", etaListToGeoJSON([]));

      if (_value == null) {
        _mapController.onSymbolTapped.add(onJeepTapped);
      } else {
        if (widget.route == null) {
          _mapController.onSymbolTapped.remove(onJeepTapped);
        }
      }

      setState(() {
        _value = widget.route;
      });

      // route lines and pings update
      addLine();
      refreshPingLayer();

      // clear jeepney entities in the map
      _mapController.clearSymbols().then((value) => jeepEntities.clear());
    }

    // jeepney updates
    if (widget.jeeps != jeeps) {
      setState(() {
        jeeps = widget.jeeps;
      });

      updateJeeps();
    }
  }

  // update jeepney entities
  void updateJeeps() {
    List<JeepsAndDrivers>? toUpdate = jeeps;
    if (toUpdate != null && toUpdate.isNotEmpty) {
      if (selectedJeep != null) {
        if (toUpdate.any((element) =>
            element.jeep.device_id ==
                selectedJeep!.jeepAndDriver.jeep.device_id &&
            element.driver != null)) {
          JeepsAndDrivers jeepsAndDrivers = toUpdate.firstWhere((element) =>
              element.jeep.device_id ==
              selectedJeep!.jeepAndDriver.jeep.device_id);
          selectedJeep!.setJeepsAndDrivers(jeepsAndDrivers);
        } else {
          _mapController.updateSymbol(
              selectedJeep!.jeepSymbol,
              const SymbolOptions(
                  iconSize: 0, textSize: 0, iconImage: 'jeepTop'));
          setState(() {
            selectedJeep = null;
          });
        }
      }

      for (var device_id in jeepEntities
          .map((e) => e.jeepAndDriver.jeep.device_id)
          .toSet()
          .difference(toUpdate.map((e) => e.jeep.device_id).toSet())) {
        int index = jeepEntities.indexWhere(
            (element) => element.jeepAndDriver.jeep.device_id == device_id);
        _mapController.removeSymbol(jeepEntities[index].jeepSymbol);
        jeepEntities.removeAt(index);
      }

      for (var jeep in toUpdate) {
        if (jeepEntities.any((element) =>
            element.jeepAndDriver.jeep.device_id == jeep.jeep.device_id)) {
          int index = jeepEntities.indexWhere((element) =>
              element.jeepAndDriver.jeep.device_id == jeep.jeep.device_id);
          _mapController.updateSymbol(
              jeepEntities[index].jeepSymbol,
              SymbolOptions(
                  geometry: LatLng(jeep.jeep.location.latitude,
                      jeep.jeep.location.longitude),
                  iconRotate: jeep.jeep.bearing,
                  iconSize: jeep.driver != null ? 1 : 0,
                  textSize: jeep.driver != null ? 50 : 0,
                  textRotate: jeep.jeep.bearing + 90));
          jeepEntities[index].setJeepsAndDrivers(jeep);
        } else {
          _mapController
              .addSymbol(SymbolOptions(
                  geometry: LatLng(jeep.jeep.location.latitude,
                      jeep.jeep.location.longitude),
                  iconImage: "jeepTop",
                  textField: "▬▬",
                  textLetterSpacing: -0.35,
                  textColor: intToHexColor(widget.route!.routeColor),
                  textRotate: jeep.jeep.bearing + 90,
                  iconRotate: jeep.jeep.bearing,
                  iconSize: jeep.driver != null ? 1 : 0,
                  textSize: jeep.driver != null ? 50 : 0))
              .then((value) => jeepEntities
                  .add(JeepEntity(jeepAndDriver: jeep, jeepSymbol: value)));
        }
      }
    } else {
      selectedJeep = null;
      _mapController.clearSymbols();
      jeepEntities.clear();
    }
  }

  // animate the users location indicator circle
  void animateCircleMovement(LatLng from, LatLng to, Circle circle,
      TickerProvider tick, MapboxMapController mapController) {
    final animationController = AnimationController(
      vsync: tick,
      duration: const Duration(milliseconds: 500),
    );
    final animation = LatLngTween(begin: from, end: to).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));

    animation.addListener(() {
      mapController.updateCircle(
          circle, CircleOptions(geometry: animation.value));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController.dispose();
      }
    });

    animationController.forward();
  }

  // sets the map controller when the Mapbox map is created
  // controller - instance of a class that allows you to perform operations
  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
  }

  // check and update user location circle within the map
  void _listenToDeviceLocation() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    ).listen((Position position) {
      _updateDeviceCircle(LatLng(position.latitude, position.longitude));
    });
  }

  // checks if there are new pings available
  void listenToPingsFirestore() {
    pingListener = FirebaseFirestore.instance
        .collection('pings')
        .where('ping_route', isEqualTo: _value!.routeId)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          pings = snapshot.docs
              .map((doc) => PingData.fromFirestore(doc))
              .where((element) =>
                  minuteOldChecker(element.ping_timestamp.toDate()))
              .toList();
        });
        _mapController.setGeoJsonSource("pings", listToGeoJSON(pings));
      }
    });
  }

  // update pings within the map
  void refreshPingLayer() {
    if (_value != null) {
      addGeojsonCluster(_mapController, _value!);
      listenToPingsFirestore();
    } else {
      pingListener?.cancel();
      pings.clear();
      // updates the pings layer of the map to display the current pings listed in GeoJSON format
      _mapController.setGeoJsonSource("pings", listToGeoJSON(pings));
    }
  }

  // update the user's location indicator
  void _updateDeviceCircle(LatLng latLng) {
    setState(() {
      myLocation = latLng;
    });
    if (deviceCircle != null) {
      animateCircleMovement(deviceCircle!.options.geometry as LatLng, latLng,
          deviceCircle!, this, _mapController);
    } else {
      _mapController
          .addCircle(CircleOptions(
              geometry: latLng,
              circleRadius: 5,
              circleColor: deviceCircleColor,
              circleStrokeWidth: 2,
              circleStrokeColor: '#FFFFFF'))
          .then((circle) {
        deviceCircle = circle;
      });
      // _mapController
      //     .animateCamera(CameraUpdate.newLatLngZoom(myLocation!, mapStartZoom));
      widget.foundDeviceLocation(latLng);
    }
  }

  void errorMessage(String message) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              backgroundColor: Constants.bgColor,
              title: Center(
                  child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              )));
        });
  }

  // update route
  void update(String collectionName, List<LatLng> coordinates) async {
    // show loading circle
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        });

    // updates route coordinates
    try {
      Map<String, dynamic> newAccountSettings = {
        collectionName: coordinates
            .map((latLng) => GeoPoint(latLng.latitude, latLng.longitude))
            .toList()
      };

      RouteData.updateRouteFirestore(widget.route!.routeId, newAccountSettings)
          .then((value) => Navigator.pop(context))
          .then((value) => Navigator.pop(context));

      errorMessage("Success!");
    } catch (e) {
      // pop loading circle
      Navigator.pop(context);
      errorMessage(e.toString());
    }
  }

  // initializes the lines of the map for the route
  void addLine() {
    _mapController.clearLines().then((value) => lines.clear());
    if (widget.route != null) {
      for (int i = 0;
          i <
              (_configRoute == -1
                  ? widget.route!.routeCoordinates.length
                  : setRoute.length);
          i++) {
        _mapController
            .addLine(LineOptions(
              lineWidth: 4.0,
              lineColor: intToHexColor(widget.route!.routeColor),
              lineOpacity: 0.5,
              geometry: i !=
                      (_configRoute == -1
                              ? widget.route!.routeCoordinates.length
                              : setRoute.length) -
                          1
                  ? (_configRoute == -1
                      ? [
                          widget.route!.routeCoordinates[i],
                          widget.route!.routeCoordinates[i + 1]
                        ]
                      : [setRoute[i], setRoute[i + 1]])
                  : (_configRoute == -1
                      ? [
                          widget.route!.routeCoordinates[i],
                          widget.route!.routeCoordinates[0]
                        ]
                      : [setRoute[i], setRoute[0]]),
            ))
            .then((line) => lines.add(line));
      }
    }
  }

  // initializes the points on the map
  void addPoints(List<Circle> circlePoints, List<LatLng> coords, int config) {
    // make circles and coord array parameters
    // remove the coordinate circles within the map
    for (var circle in circlePoints) {
      _mapController.removeCircle(circle);
    }

    // clear the array containing the coordinate circles
    circlePoints.clear();

    // for each route coordinate, add a circle coordinate and add it in the circle coordinates array
    for (int i = 0; i < coords.length; i++) {
      _mapController
          .addCircle(CircleOptions(
              circleRadius: 8.0,
              circleStrokeWidth: 2.0,
              circleStrokeOpacity: 1,
              circleColor: intToHexColor(widget.route!.routeColor),
              geometry: coords[i],
              circleStrokeColor: '#FFFFFF',
              draggable: config == 0 ? true : false))
          .then((circle) => circlePoints.add(circle));
    }
  }

  // when line on the map is tapped it adds another coordinate
  // it clears the coordinates and reinitialize them again along with the lines
  void onLineTapped(Line pressedLine) {
    // add bool to reuse this funct and use circles and coord array a parameter to reuse
    int index = lines.indexWhere((line) => pressedLine == line);

    double x = (pressedLine.options.geometry![0].latitude +
            pressedLine.options.geometry![1].latitude) /
        2;
    double y = (pressedLine.options.geometry![0].longitude +
            pressedLine.options.geometry![1].longitude) /
        2;

    setRoute.insert(index + 1, LatLng(x, y));

    for (var circle in circles) {
      _mapController.removeCircle(circle);
    }
    circles.clear();
    addPoints(circles, setRoute, _configRoute);
    _mapController
        .clearLines()
        .then((value) => lines.clear())
        .then((value) => addLine());
  }

  // if a coordinate is tapped it would be removed
  // it will call add points to reinitialize all points again
  // it will call add line to reinitilize all lines again
  void onCircleTapped(Circle pressedCircle) {
    // make circles and coord array a paramter
    int index = circles.indexWhere((circle) => pressedCircle == circle);

    if (index != -1) {
      setRoute.removeAt(index);
      addPoints(circles, setRoute, _configRoute);
      addLine();
    }
  }

  // add stop points within the map
  void onStopLocationTapped(LatLng tappedLocation) {
    // Add the tapped location to the stops list
    setStops.add(tappedLocation);

    // Update the selected stop
    setState(() {
      selectedStop = tappedLocation;
    });
    // Remove existing stop circles from the map
    for (var circle in stopsCircles) {
      _mapController.removeCircle(circle);
    }
    stopsCircles.clear();

    // Reinitialize the stop circles on the map
    addPoints(stopsCircles, setStops, _configStops);
  }

  void onStopLocationCircleTapped(Circle pressedCircle) {
    // Find the index of the tapped stop circle
    int index = stopsCircles.indexWhere((circle) => pressedCircle == circle);

    // If the circle exists in the stopsCircles list
    if (index != -1) {
      // Update the selected stop
      setState(() {
        selectedStop = stopsCircles[index].options.geometry;
      });
      // Remove the stop location from the setStops list
      setStops.removeAt(index);

      // Reinitialize the stop circles on the map
      addPoints(stopsCircles, setStops, _configStops);
    }
  }

  void onStopLocationCircleSelected(Circle pressedCircle) {
    // Find the index of the tapped stop circle
    int index = stopsCircles.indexWhere((circle) => pressedCircle == circle);

    // If the circle exists in the stopsCircles list
    if (index != -1) {
      // Update the selected stop
      setState(() {
        selectedStop = stopsCircles[index].options.geometry;
      });
    }
  }

  // jeep selection on the map
  void onJeepTapped(Symbol pressedJeep) {
    if (selectedJeep != null) {
      if (pressedJeep != selectedJeep!.jeepSymbol) {
        if (jeepEntities
            .any((jeepEntity) => jeepEntity.jeepSymbol == pressedJeep)) {
          setState(() {
            selectedJeep = jeepEntities.firstWhere(
                (jeepEntity) => jeepEntity.jeepSymbol == pressedJeep);
          });
        }
      } else {
        setState(() {
          selectedJeep = null;
        });

        _mapController.setGeoJsonSource("eta", etaListToGeoJSON([]));
      }
    } else {
      if (jeepEntities
          .any((jeepEntity) => jeepEntity.jeepSymbol == pressedJeep)) {
        setState(() {
          selectedJeep = jeepEntities
              .firstWhere((jeepEntity) => jeepEntity.jeepSymbol == pressedJeep);
        });
      }
    }

    for (var jeep in jeepEntities) {
      _mapController.updateSymbol(
          jeep.jeepSymbol, const SymbolOptions(iconImage: 'jeepTop'));
    }

    if (selectedJeep != null) {
      _mapController.updateSymbol(selectedJeep!.jeepSymbol,
          const SymbolOptions(iconImage: 'jeepTopSelected'));
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _positionStream.cancel();
    super.dispose();
  }

  void resetCamera() {
    _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(Keys.MapCenter, mapStartZoom));
  }

  void resetToLocation() {
    _mapController
        .animateCamera(CameraUpdate.newLatLngZoom(myLocation!, mapStartZoom));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(children: [
            Expanded(
              child: MapboxMap(
                accessToken: Keys.MapBoxKey,
                styleString: Keys.MapBoxNight,
                doubleClickZoomEnabled: false,
                minMaxZoomPreference:
                    MinMaxZoomPreference(mapMinZoom, mapMaxZoom),
                compassEnabled: true,
                compassViewPosition: Responsive.isDesktop(context)
                    ? CompassViewPosition.TopLeft
                    : CompassViewPosition.TopRight,
                onMapCreated: (controller) {
                  _onMapCreated(controller);
                },
                // allows you to perform additional setup and customization of the map once the style has been fully loaded
                onStyleLoadedCallback: () {
                  addETALayer(_mapController);
                  addImageFromAsset(_mapController);
                  _mapController.setSymbolIconAllowOverlap(true);
                  _mapController.setSymbolTextAllowOverlap(true);
                  _mapController.setSymbolIconIgnorePlacement(true);
                  _mapController.setSymbolTextIgnorePlacement(true);
                  refreshPingLayer();
                  widget.mapLoaded(true);
                  setState(() {
                    mapLoaded = true;
                  });
                  startListening();
                },
                initialCameraPosition: CameraPosition(
                  target: Keys.MapCenter,
                  zoom: mapStartZoom,
                ),
                onMapClick: (point, latLng) {
                  if (_configRoute == 1) {
                    setRoute.add(latLng);

                    addPoints(circles, setRoute, _configRoute);
                    addLine();
                  }
                  if (_configStops == 1) {
                    // Add a new stop location
                    onStopLocationTapped(latLng);
                  }
                },
              ),
            ),
            if (Responsive.isMobile(context))
              Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    color: Constants.secondaryColor,
                  ),
                  child: widget.route == null
                      ? const MobileDashboardUnselected()
                      : MobileRouteInfo(
                          gpsPermission: gpsTracking,
                          route: _value!,
                          jeeps: jeeps!,
                          selectedJeep: selectedJeep != null
                              ? selectedJeep!.jeepAndDriver
                              : null,
                          user: widget.currentUserFirestore,
                          sendPing: (bool value) async {
                            _mapController.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                    myLocation!, mapStartZoom));

                            LatLng pingLoc = myLocation!;
                            for (int i = 0; i < 3; i++) {
                              animateRipple(
                                  _mapController, _value, this, pingLoc);

                              await Future.delayed(
                                  const Duration(milliseconds: 2000));
                            }
                          },
                          etaCoordinates: (List<LatLng> etaCoordinates) async {
                            if (selectedJeep != null) {
                              await _mapController.setGeoJsonSource(
                                  "eta", etaListToGeoJSON(etaCoordinates));
                            }
                          },
                          myLocation: myLocation))
          ]),
          Positioned(
              right: Responsive.isDesktop(context)
                  ? null
                  : Constants.defaultPadding * 3,
              left: Responsive.isDesktop(context)
                  ? Constants.defaultPadding * 3
                  : null,
              top: Constants.defaultPadding * 0.75,
              child: Row(
                children: [
                  PointerInterceptor(
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: Colors.grey[100],
                      child: IconButton(
                        onPressed: () => resetCamera(),
                        icon: const Icon(Icons.center_focus_strong),
                        tooltip: "Reset Map Location",
                        visualDensity: VisualDensity.compact,
                        iconSize: 10,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (myLocation != null)
                    const SizedBox(width: Constants.defaultPadding / 2),
                  if (myLocation != null)
                    PointerInterceptor(
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: Colors.grey[100],
                        child: IconButton(
                          onPressed: () => resetToLocation(),
                          icon: const Icon(Icons.person),
                          tooltip: "Reset to your Location",
                          visualDensity: VisualDensity.compact,
                          iconSize: 10,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              )),
          if (!Responsive.isMobile(context))
            Positioned(
                top: 0,
                right: 0,
                child: Column(
                  children: [
                    if (widget.route == null)
                      PointerInterceptor(
                          child: const UnselectedDesktopRouteInfo()),

                    if (widget.route != null)
                      PointerInterceptor(
                        child: DesktopRouteInfo(
                          gpsPermission: gpsTracking,
                          route: _value!,
                          jeeps: jeeps!,
                          selectedJeep: selectedJeep != null
                              ? selectedJeep!.jeepAndDriver
                              : null,
                          user: widget.currentUserFirestore,
                          sendPing: (bool value) async {
                            _mapController.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                    myLocation!, mapStartZoom));

                            LatLng pingLoc = myLocation!;
                            for (int i = 0; i < 3; i++) {
                              animateRipple(
                                  _mapController, _value, this, pingLoc);

                              await Future.delayed(
                                  const Duration(milliseconds: 2000));
                            }
                          },
                          etaCoordinates: (List<LatLng> etaCoordinates) async {
                            if (selectedJeep != null) {
                              await _mapController.setGeoJsonSource(
                                  "eta", etaListToGeoJSON(etaCoordinates));
                            }
                          },
                          myLocation: myLocation,
                        ),
                      ),

                    // Route Manager Dashboard
                    if (widget.route != null &&
                        widget.currentUserFirestore != null &&
                        widget.currentUserFirestore!.account_type == 2 &&
                        widget.currentUserFirestore!.is_verified &&
                        widget.route!.routeId ==
                            widget.currentUserFirestore!.route_id)
                      Container(
                          width: 300,
                          padding:
                              const EdgeInsets.all(Constants.defaultPadding),
                          margin: const EdgeInsets.symmetric(
                              horizontal: Constants.defaultPadding),
                          decoration: const BoxDecoration(
                            color: Constants.secondaryColor,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: RouteManagerOptions(
                            route: widget.route!,
                            jeeps: widget.jeeps!,
                            pressedJeep: (JeepsAndDrivers searchedJeep) {
                              selectedJeep = null;
                              onJeepTapped(jeepEntities
                                  .firstWhere((element) =>
                                      element.jeepAndDriver.jeep.device_id ==
                                      searchedJeep.jeep.device_id)
                                  .jeepSymbol);
                              _mapController.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      LatLng(
                                          searchedJeep.jeep.location.latitude,
                                          searchedJeep.jeep.location.longitude),
                                      mapStartZoom));
                            },
                            coordConfig: (int coordConfig) {
                              // we save what is the previous mode
                              int prev = _configRoute;

                              setState(() {
                                _configRoute = coordConfig;
                              });

                              // unselected any of the choices
                              if (_configRoute < 0) {
                                print("prev mode: $prev");
                                print("configRoute mode: $_configRoute");
                                // Coming from moving points, we save the new coordinates.
                                if (prev == 0) {
                                  if (_configRoute == -1) {
                                    // clear the array containing route coordinates
                                    setRoute.clear();

                                    // repopulate the array with the new coordinates
                                    for (var circle in circles) {
                                      setRoute.add(circle.options.geometry!);
                                    }
                                    // remove the coordinate circles in the map
                                    for (var circle in circles) {
                                      _mapController.removeCircle(circle);
                                    }

                                    // clear the array containing coordinate circles
                                    circles.clear();
                                    // re-initialize the route lines
                                    addLine();
                                    // Update Firestore
                                    update('route_coordinates', setRoute);
                                  } else if (_configRoute == -2) {
                                    // remove the coordinate circles in the map
                                    for (var circle in circles) {
                                      _mapController.removeCircle(circle);
                                    }

                                    // clear the array containing coordinate circles
                                    circles.clear();
                                    // re-initialize the route lines
                                    addLine();
                                  }

                                  // if the mode is previously add/delete state
                                } else if (prev == 1) {
                                  if (_configRoute == -1) {
                                    // remove onTap listeners to ensure that tapping on the map would no longer add/delete points
                                    _mapController.onCircleTapped
                                        .remove(onCircleTapped);
                                    _mapController.onLineTapped
                                        .remove(onLineTapped);
                                    // remove the coordinate circles in the map
                                    for (var circle in circles) {
                                      _mapController.removeCircle(circle);
                                    }
                                    // clear the array containing coordinate circles
                                    circles.clear();
                                    update('route_coordinates', setRoute);
                                  } else if (_configRoute == -2) {
                                    _mapController.onCircleTapped
                                        .remove(onCircleTapped);
                                    _mapController.onLineTapped
                                        .remove(onLineTapped);

                                    // Revert to the original route coordinates from the database
                                    setRoute.clear();
                                    setRoute = List<LatLng>.from(widget
                                        .route!.routeCoordinates); // Deep copy

                                    // Remove the coordinate circles in the map
                                    for (var circle in circles) {
                                      _mapController.removeCircle(circle);
                                    }

                                    // Clear the array containing coordinate circles
                                    circles.clear();

                                    // Re-initialize the route lines
                                    addLine();
                                  }
                                }

                                // if not at default mode
                              } else {
                                // create a deep copy, otherwise the routeCoordinates would also be modified
                                setRoute = List<LatLng>.from(
                                    widget.route!.routeCoordinates);

                                // Move points mode
                                if (_configRoute == 0) {
                                  _mapController.clearLines();
                                  // re-initialize the coordinates in the map
                                  addPoints(circles, setRoute, _configRoute);
                                }

                                // Add or Remove Points
                                else if (_configRoute == 1) {
                                  // add the on tap listeners
                                  _mapController.onLineTapped.add(onLineTapped);
                                  _mapController.onCircleTapped
                                      .add(onCircleTapped);
                                  // re-initialize the coordinates in the map
                                  addPoints(circles, setRoute, _configRoute);
                                }
                              }
                            },
                            stopsConfig: (int stopsConfig) {
                              // we save what is the previous mode
                              int prev = _configStops;

                              // update _configStops to trigger state change
                              // note that coordConfig is the variable modified in route_settings
                              // and _configStops manages mode changes in the map
                              setState(() {
                                _configStops = stopsConfig;
                              });

                              // if at default mode
                              if (_configStops < 0) {
                                // Set selectedStop to null
                                setState(() {
                                  selectedStop = null;
                                });

                                // if from moving points mode
                                if (prev == 0) {
                                  // if changes are saved
                                  if (_configStops == -1) {
                                    // clear the array containing route coordinates
                                    setStops.clear();

                                    // repopulate the array with the new coordinates
                                    for (var circle in stopsCircles) {
                                      setStops.add(circle.options.geometry!);
                                    }
                                    // remove the coordinate circles in the map
                                    for (var circle in stopsCircles) {
                                      _mapController.removeCircle(circle);
                                    }

                                    // clear the array containing coordinate circles
                                    stopsCircles.clear();
                                    // re-initialize the route lines
                                    addLine();
                                    // Update Firestore
                                    update('stops_coordinates', setStops);
                                    // if changes are not saved
                                  } else if (_configStops == -2) {
                                    // remove the coordinate circles in the map
                                    for (var circle in stopsCircles) {
                                      _mapController.removeCircle(circle);
                                    }

                                    // clear the array containing coordinate circles
                                    stopsCircles.clear();
                                    // re-initialize the route lines
                                    addLine();
                                  }

                                  // if from adding/deleting points mode
                                } else if (prev == 1) {
                                  // if changes are saved
                                  if (_configStops == -1) {
                                    // remove onTap listeners to ensure that tapping on the map would no longer add/delete points
                                    _mapController.onCircleTapped
                                        .remove(onStopLocationCircleTapped);
                                    // remove the coordinate circles in the map
                                    for (var circle in stopsCircles) {
                                      _mapController.removeCircle(circle);
                                    }
                                    // clear the array containing coordinate circles
                                    stopsCircles.clear();
                                    update('stops_coordinates', setStops);
                                    // if changes are not saved
                                  } else if (_configStops == -2) {
                                    _mapController.onCircleTapped
                                        .remove(onStopLocationCircleTapped);

                                    // Revert to the original route coordinates from the database
                                    setStops.clear();
                                    setStops = List<LatLng>.from(widget
                                        .route!.stopsCoordinates); // Deep copy

                                    // Remove the coordinate circles in the map
                                    for (var circle in stopsCircles) {
                                      _mapController.removeCircle(circle);
                                    }

                                    // Clear the array containing coordinate circles
                                    stopsCircles.clear();

                                    // Re-initialize the route lines
                                    addLine();
                                  }
                                }
                              } else {
                                // create a deep copy, otherwise the routeCoordinates would also be modified
                                setStops = List<LatLng>.from(
                                    widget.route!.stopsCoordinates);
                                // if at adding/deleting points mode
                                if (_configStops == 0) {
                                  // Add the onCircleTapped listener for selecting stops
                                  _mapController.onCircleTapped
                                      .add(onStopLocationCircleSelected);
                                  addPoints(
                                      stopsCircles, setStops, _configStops);

                                  // if at moving points mode
                                } else if (_configStops == 1) {
                                  _mapController.onCircleTapped
                                      .add(onStopLocationCircleTapped);
                                  addPoints(
                                      stopsCircles, setStops, _configStops);
                                }
                              }
                            },
                            selectedStop: selectedStop,
                          ))
                  ],
                ))
        ],
      ),
    );
  }
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
      : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) => LatLng(
        lerpDouble(begin!.latitude, end!.latitude, t)!,
        lerpDouble(begin!.longitude, end!.longitude, t)!,
      );
}
