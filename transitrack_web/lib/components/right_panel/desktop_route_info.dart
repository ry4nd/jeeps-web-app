// ignore_for_file: non_constant_identifier_names

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'dart:async';

import '../../models/account_model.dart';
import '../../models/jeep_model.dart';
import '../../models/route_model.dart';
import '../../style/constants.dart';
import 'selected_jeep_info.dart';
import '../../services/eta.dart';
import '../select_jeep_prompt.dart';
import '../../components/cooldown_button.dart';
import '../../services/send_ping.dart';

import '../../components/fare_matrix.dart';
// This widget displays all the information for the route for the desktop view

class DesktopRouteInfo extends StatefulWidget {
  final bool gpsPermission;
  final RouteData route;
  final List<JeepsAndDrivers> jeeps;
  final JeepsAndDrivers? selectedJeep;
  final AccountData? user;
  final ValueChanged<bool> sendPing;
  final ValueChanged<List<LatLng>> etaCoordinates;
  final LatLng? myLocation;
  const DesktopRouteInfo(
      {super.key,
      required this.gpsPermission,
      required this.route,
      required this.user,
      required this.jeeps,
      required this.selectedJeep,
      required this.etaCoordinates,
      required this.sendPing,
      required this.myLocation});

  @override
  State<DesktopRouteInfo> createState() => _DesktopRouteInfoState();
}

class _DesktopRouteInfoState extends State<DesktopRouteInfo> {
  late RouteData _value;
  late List<JeepsAndDrivers> _jeeps;
  late JeepsAndDrivers? _selectedJeep;
  late String? _eta;
  late int operating;
  late int not_operating;
  late LatLng? _myLocation;
  late bool _gpsPermission;

  late Timer etaFetcher;

  // AccountData? driverInfo;
  bool isTapped = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _gpsPermission = widget.gpsPermission;
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
  void didUpdateWidget(covariant DesktopRouteInfo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.gpsPermission != _gpsPermission) {
      setState(() {
        _gpsPermission = widget.gpsPermission;
      });
    }

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
    return Container(
      width: 300,
      margin: const EdgeInsets.all(Constants.defaultPadding),
      padding: const EdgeInsets.all(Constants.defaultPadding),
      decoration: const BoxDecoration(
        color: Constants.secondaryColor,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            // Expanded(
            //     child: Padding(
            //   padding: const EdgeInsets.symmetric(vertical: 5.5),
            //   child: Text(
            //     _value.routeName,
            //     style:
            //         const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            //     maxLines: 1,
            //     overflow: TextOverflow.ellipsis,
            //   ),
            // )),
            FareMatrix(route: widget.route),
            const SizedBox(width: Constants.defaultPadding / 2),
            if (widget.user != null)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                // const Text("Wait a Ride",
                //     maxLines: 1,
                //     overflow: TextOverflow.ellipsis,
                //     style: TextStyle(fontSize: 10)),
                const SizedBox(width: Constants.defaultPadding / 3),
                if (_gpsPermission)
                  CooldownButton(
                      onPressed: () async {
                        int result = await sendPing(widget.user!.account_email,
                            _myLocation!, _value.routeId);
                        if (result == 0) {
                          widget.sendPing(true);
                        } else {
                          errorMessage("Failed to send your current location");
                        }
                      },
                      alert: "Broadcasting your location...",
                      verified: widget.user!.is_verified && _myLocation != null,
                      child: _myLocation != null
                          ? const Icon(Icons.location_on, size: 15)
                          : const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                color: Constants.bgColor,
                              ))),
                if (!_gpsPermission)
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Center(
                        child: Icon(
                      Icons.location_off,
                      size: 15,
                      color: Colors.red[600],
                    )),
                  ),
              ])
          ]),
          const SizedBox(height: Constants.defaultPadding),
          Stack(children: [
            ClipRect(
                clipper: TopClipper(),
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 70,
                          startDegreeOffset: -180,
                          sections: [
                            PieChartSectionData(
                              color: Color(widget.route.routeColor),
                              value: operating.toDouble(),
                              showTitle: false,
                              radius: 20,
                            ),
                            PieChartSectionData(
                              color: Color(widget.route.routeColor)
                                  .withValues(alpha: 0.1),
                              value: not_operating.toDouble(),
                              showTitle: false,
                              radius: 20,
                            ),
                            PieChartSectionData(
                              color: Colors.transparent,
                              value: (not_operating + operating).toDouble(),
                              showTitle: false,
                              radius: 20,
                            ),
                          ],
                        ),
                      ),
                      Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: Constants.defaultPadding * 3),
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
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                      ),
                                ),
                                TextSpan(
                                  text: "/${operating + not_operating}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                ),
                                TextSpan(
                                  text: '\noperating',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
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
            Column(children: [
              const SizedBox(height: Constants.defaultPadding * 7),
              const Divider(),
              const SizedBox(height: Constants.defaultPadding),
              if (_selectedJeep == null) const SelectJeepPrompt(),
              if (_selectedJeep != null)
                SelectedJeepInfo(
                    gpsPermission: widget.gpsPermission,
                    jeep: _selectedJeep!,
                    eta: _eta,
                    user: widget.user,
                    route: _value),
            ])
          ])
        ],
      ),
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
