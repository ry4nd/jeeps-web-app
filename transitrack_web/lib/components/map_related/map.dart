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

  late MapboxMapController _mapController;
  late StreamSubscription<Position> _positionStream;

  late Circle? deviceCircle;
  bool mapLoaded = false;

  late List<LatLng> setRoute;
  List<Circle> circles = [];
  List<Line> lines = [];
  List<JeepEntity> jeepEntities = [];

  // Ping Fetching
  StreamSubscription? pingListener;
  List<PingData> pings = [];
  late Timer timer;

  bool gpsTracking = false;

  JeepEntity? selectedJeep;

  @override
  void initState() {
    super.initState();

    setState(() {
      _value = widget.route;
      jeeps = widget.jeeps;
      _configRoute = -1;
      myLocation = null;
      deviceCircle = null;
    });

    if (mapLoaded) {
      refreshLineAndPingLayer();
    }

    timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mapLoaded && _value != null) {
        setState(() {
          pings = pings
              .where((element) =>
                  minuteOldChecker(element.ping_timestamp.toDate()))
              .toList();
          // SOSList = SOSList.where(
          //         (element) => minuteOldChecker(element.timestamp.toDate()))
          //     .toList();
        });
        _mapController.setGeoJsonSource("pings", listToGeoJSON(pings));
        // _mapController.setGeoJsonSource(
        //     "accidents",
        //     reportListToGeoJSON(
        //         SOSList.where((element) => element.report_type == 3).toList()));
        // _mapController.setGeoJsonSource(
        //     "crime",
        //     reportListToGeoJSON(
        //         SOSList.where((element) => element.report_type == 1).toList()));
        // _mapController.setGeoJsonSource(
        //     "mechError",
        //     reportListToGeoJSON(
        //         SOSList.where((element) => element.report_type == 2).toList()));
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

      addLine();
      refreshLineAndPingLayer();

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

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
  }

  void _listenToDeviceLocation() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    ).listen((Position position) {
      _updateDeviceCircle(LatLng(position.latitude, position.longitude));
    });
  }

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

  void refreshLineAndPingLayer() {
    if (_value != null) {
      // _mapController.clearLines();
      // _mapController.addLines([
      //   LineOptions(
      //       lineWidth: 4.0,
      //       lineColor: intToHexColor(_routeData!.routeColor),
      //       lineOpacity: 0.5,
      //       geometry: _routeData!.routeCoordinates)
      // ]);
      // addGeojsonCluster(_mapController, _routeData!);
      // addGeojsonSOS(_mapController);
      listenToPingsFirestore();
      // listenToReportsFirestore();
    } else {
      // _mapController.clearLines();
      pingListener?.cancel();
      pings.clear();
      _mapController.setGeoJsonSource("pings", listToGeoJSON(pings));
    }
  }

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

  void update() async {
    // show loading circle
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        });

    try {
      Map<String, dynamic> newAccountSettings = {
        'route_coordinates': setRoute
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
  void addPoints() {
    for (var circle in circles) {
      _mapController.removeCircle(circle);
    }
    circles.clear();

    for (int i = 0; i < setRoute.length; i++) {
      _mapController
          .addCircle(CircleOptions(
              circleRadius: 8.0,
              circleStrokeWidth: 2.0,
              circleStrokeOpacity: 1,
              circleColor: intToHexColor(widget.route!.routeColor),
              geometry: setRoute[i],
              circleStrokeColor: '#FFFFFF',
              draggable: _configRoute == 0 ? true : false))
          .then((circle) => circles.add(circle));
    }
  }

  // when line on the map is tapped it adds another coordinate
  // it clears the coordinates and reinitialize them again along with the lines
  void onLineTapped(Line pressedLine) {
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
    addPoints();
    _mapController
        .clearLines()
        .then((value) => lines.clear())
        .then((value) => addLine());
  }

  // if a coordinate is tapped it would be removed
  // it will call add points to reinitialize all points again
  // it will call add line to reinitilize all lines again
  void onCircleTapped(Circle pressedCircle) {
    int index = circles.indexWhere((circle) => pressedCircle == circle);

    if (index != -1) {
      setRoute.removeAt(index);
      addPoints();
      addLine();
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
                onStyleLoadedCallback: () {
                  addETALayer(_mapController);
                  addImageFromAsset(_mapController);
                  _mapController.setSymbolIconAllowOverlap(true);
                  _mapController.setSymbolTextAllowOverlap(true);
                  _mapController.setSymbolIconIgnorePlacement(true);
                  _mapController.setSymbolTextIgnorePlacement(true);
                  refreshLineAndPingLayer();
                  widget.mapLoaded(true);
                  startListening();
                },
                initialCameraPosition: CameraPosition(
                  target: Keys.MapCenter,
                  zoom: mapStartZoom,
                ),
                onMapClick: (point, latLng) {
                  if (_configRoute == 1) {
                    setRoute.add(latLng);

                    addPoints();
                    addLine();
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
                              int prev = _configRoute;

                              setState(() {
                                _configRoute = coordConfig;
                              });

                              // unselected any of the choices
                              if (_configRoute < 0) {
                                // Coming from moving points, we save the new coordinates.
                                if (prev == 0) {
                                  setRoute.clear();
                                  for (var circle in circles) {
                                    setRoute.add(circle.options.geometry!);
                                  }

                                  for (var circle in circles) {
                                    _mapController.removeCircle(circle);
                                  }
                                  circles.clear();
                                  if (_configRoute == -1) {
                                    update();
                                  }
                                  addLine();
                                } else if (prev == 1) {
                                  _mapController.onCircleTapped
                                      .remove(onCircleTapped);
                                  _mapController.onLineTapped
                                      .remove(onLineTapped);

                                  for (var circle in circles) {
                                    _mapController.removeCircle(circle);
                                  }
                                  circles.clear();

                                  if (_configRoute == -1) {
                                    update();
                                  }
                                }
                              } else {
                                setRoute = widget.route!.routeCoordinates;

                                // Move points
                                if (_configRoute == 0) {
                                  _mapController.clearLines();
                                  addPoints();
                                }

                                // Add or Remove Points
                                else if (_configRoute == 1) {
                                  _mapController.onLineTapped.add(onLineTapped);
                                  _mapController.onCircleTapped
                                      .add(onCircleTapped);
                                  addPoints();
                                }
                              }

                              if (_configRoute == -2) {
                                _configRoute = -1;
                              }
                            },
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
