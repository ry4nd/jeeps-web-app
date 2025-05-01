// ignore_for_file: non_constant_identifier_names

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:async';

import '../../models/account_model.dart';
import '../../models/jeep_model.dart';
import '../../models/route_model.dart';
import '../../style/constants.dart';
import '../../services/eta.dart';
import '../../services/format_time.dart';
import '../select_jeep_prompt.dart';
import 'selected_jeep_info.dart';
import '../cooldown_button.dart';
import '../../services/send_ping.dart';

import '../../components/fare_matrix.dart';

// This widget displays all the information for the route for the mobile view

class MobileRouteInfo extends StatefulWidget {
  final bool gpsPermission;
  final RouteData route;
  final List<JeepsAndDrivers> jeeps;
  final JeepsAndDrivers? selectedJeep;
  final AccountData? user;
  final ValueChanged<bool> sendPing;
  final ValueChanged<List<LatLng>> etaCoordinates;
  final LatLng? myLocation;
  const MobileRouteInfo(
      {super.key,
      required this.gpsPermission,
      required this.route,
      required this.jeeps,
      required this.selectedJeep,
      required this.user,
      required this.sendPing,
      required this.etaCoordinates,
      required this.myLocation});

  @override
  State<MobileRouteInfo> createState() => _MobileRouteInfoState();
}

class _MobileRouteInfoState extends State<MobileRouteInfo> {
  late RouteData _value;
  late List<JeepsAndDrivers> _jeeps;
  late JeepsAndDrivers? _selectedJeep;
  late String? _eta;
  late int operating;
  late int not_operating;
  late LatLng? _myLocation;

  // AccountData? driverInfo;
  bool isTapped = false;

  late Timer etaFetcher;

  @override
  void initState() {
    super.initState();

    setState(() {
      _value = widget.route;
      _jeeps = widget.jeeps;
      _selectedJeep = widget.selectedJeep;
      _myLocation = widget.myLocation;
      operating = widget.jeeps.where((jeep) => jeep.driver != null).length;
      _eta = null;
      not_operating = widget.jeeps.where((jeep) => jeep.driver == null).length;
    });

    etaFetcher = Timer.periodic(const Duration(seconds: 3), fetchEta);
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

  void fetchEta(Timer timer) async {
    if (_myLocation != null && _selectedJeep != null) {
      EtaData? result = await eta(
          widget.route.routeCoordinates,
          widget.route.isClockwise,
          _myLocation!,
          LatLng(_selectedJeep!.jeep.location.latitude,
              _selectedJeep!.jeep.location.longitude));
      if (result != null) {
        setState(() {
          _eta = result.etaTime;
        });

        widget.etaCoordinates(result.etaCoordinates);
      }
    }
  }

  @override
  void didUpdateWidget(covariant MobileRouteInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if route choice changed
    if (widget.route != _value) {
      setState(() {
        _value = widget.route;
      });
    }

    if (widget.myLocation != _myLocation) {
      setState(() {
        _myLocation = widget.myLocation;
      });
    }

    if (widget.selectedJeep != _selectedJeep) {
      if (_selectedJeep != null &&
          widget.selectedJeep != null &&
          _selectedJeep!.jeep.device_id !=
              widget.selectedJeep!.jeep.device_id) {
        setState(() {
          // driverInfo = null;
          _eta = null;
        });
      }

      setState(() {
        _selectedJeep = widget.selectedJeep;
      });
    }

    if (widget.jeeps != _jeeps) {
      setState(() {
        _jeeps = widget.jeeps;
        operating = widget.jeeps.where((jeep) => jeep.driver != null).length;
        not_operating =
            widget.jeeps.where((jeep) => jeep.driver == null).length;
      });
    }
  }

  @override
  void dispose() {
    etaFetcher.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(Constants.defaultPadding),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _value.routeName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: Constants.defaultPadding),
                          if (_selectedJeep != null)
                            Text(
                              "$operating/${operating + not_operating} operating",
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ]),
                    if (_selectedJeep == null)
                      Stack(children: [
                        Column(children: [
                          const SizedBox(height: Constants.defaultPadding / 3),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRect(
                                      clipper: TopClipper(),
                                      child: SizedBox(
                                        height: 120,
                                        child: Stack(
                                          children: [
                                            PieChart(
                                              PieChartData(
                                                sectionsSpace: 0,
                                                centerSpaceRadius: 50,
                                                startDegreeOffset: -180,
                                                sections: [
                                                  PieChartSectionData(
                                                    color: Color(widget
                                                        .route.routeColor),
                                                    value: operating.toDouble(),
                                                    showTitle: false,
                                                    radius: 10,
                                                  ),
                                                  PieChartSectionData(
                                                    color: Color(widget
                                                            .route.routeColor)
                                                        .withValues(alpha: 0.1),
                                                    value: not_operating
                                                        .toDouble(),
                                                    showTitle: false,
                                                    radius: 10,
                                                  ),
                                                  PieChartSectionData(
                                                    color: Colors.transparent,
                                                    value: (not_operating +
                                                            operating)
                                                        .toDouble(),
                                                    showTitle: false,
                                                    radius: 10,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Center(
                                                child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                const SizedBox(
                                                    height: Constants
                                                        .defaultPadding),
                                                RichText(
                                                  textAlign: TextAlign.center,
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: '$operating',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displaySmall
                                                            ?.copyWith(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 18,
                                                            ),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            "/${operating + not_operating}",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displaySmall
                                                            ?.copyWith(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              fontSize: 14,
                                                            ),
                                                      ),
                                                      TextSpan(
                                                        text: '\noperating',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displaySmall
                                                            ?.copyWith(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 15,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )),
                                          ],
                                        ),
                                      )),
                                ),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      // Text(
                                      //   "${_value.routeFare} Regular",
                                      //   style: const TextStyle(
                                      //       fontSize: 14,
                                      //       fontWeight: FontWeight.w500),
                                      //   maxLines: 1,
                                      //   overflow: TextOverflow.ellipsis,
                                      // ),
                                      // Text(
                                      //   "${_value.perKmRate} Discounted",
                                      //   style: const TextStyle(
                                      //       fontSize: 14,
                                      //       fontWeight: FontWeight.w500),
                                      //   maxLines: 1,
                                      //   overflow: TextOverflow.ellipsis,
                                      // ),
                                      FareMatrix(route: widget.route),
                                      SizedBox(
                                          height: Constants.defaultPadding / 2),
                                      Text(
                                        formatTime(_value.routeTime),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ])
                              ]),
                        ]),
                        const Column(children: [
                          SizedBox(height: Constants.defaultPadding * 4.5),
                          Divider(color: Colors.white),
                          SizedBox(height: Constants.defaultPadding / 2),
                          SelectJeepPrompt()
                        ])
                      ]),
                    if (_selectedJeep != null)
                      Column(children: [
                        const SizedBox(height: Constants.defaultPadding),
                        SelectedJeepInfo(
                          gpsPermission: widget.gpsPermission,
                          jeep: _selectedJeep!,
                          eta: _eta,
                          user: widget.user,
                          route: _value,
                        )
                      ]),
                  ]),
            )),
          ],
        ),
        if (widget.user != null)
          Positioned(
              bottom: Constants.defaultPadding / 2,
              right: Constants.defaultPadding / 2,
              child: CooldownButton(
                  onPressed: () async {
                    int result = await sendPing(widget.user!.account_email,
                        widget.myLocation!, _value.routeId);
                    if (result == 0) {
                      widget.sendPing(true);
                    } else {
                      errorMessage("Failed to send your current location");
                    }
                  },
                  alert: "We have broadcasted your location.",
                  verified:
                      widget.user!.is_verified && widget.myLocation != null,
                  child: widget.myLocation != null
                      ? const Icon(Icons.location_on)
                      : const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            color: Constants.bgColor,
                          ))))
      ],
    );
  }
}

class TopClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, 110); // Clip to top 120 pixels
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return false;
  }
}
