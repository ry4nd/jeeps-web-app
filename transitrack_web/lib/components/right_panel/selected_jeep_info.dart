import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/components/icon_button_big.dart';
import 'package:transitrack_web/components/right_panel/feedback_viewer.dart';
import 'package:transitrack_web/components/right_panel/report_form.dart';
import 'package:transitrack_web/models/feedback_model.dart';

import '../../models/account_model.dart';
import '../../models/jeep_model.dart';
import '../../models/route_model.dart';
import '../../config/responsive.dart';
import '../../style/constants.dart';
import 'feedback_form.dart';

import 'package:flutter/services.dart';

// This widget displays relevant information of the PUV

class SelectedJeepInfo extends StatefulWidget {
  final bool gpsPermission;
  final JeepsAndDrivers jeep;
  final String? eta;
  final AccountData? user;
  final RouteData route;
  const SelectedJeepInfo(
      {super.key,
      required this.gpsPermission,
      required this.jeep,
      required this.eta,
      required this.user,
      required this.route});

  @override
  State<SelectedJeepInfo> createState() => _SelectedJeepInfoState();
}

class _SelectedJeepInfoState extends State<SelectedJeepInfo> {
  late JeepsAndDrivers _jeep;
  late String? _eta;
  late AccountData? _user;
  late RouteData _route;

  List<FeedbackData>? jeepRating;
  List<FeedbackData>? driverRating;

  bool isTapped = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _jeep = widget.jeep;
      _eta = widget.eta;
      _user = widget.user;
      _route = widget.route;
    });

    loadRatings();
  }

  @override
  void didUpdateWidget(covariant SelectedJeepInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if route choice changed
    if (widget.jeep != _jeep) {
      if (_jeep.jeep.device_id != widget.jeep.jeep.device_id) {
        loadRatings();
      }
      setState(() {
        _jeep = widget.jeep;
      });
    }

    if (widget.eta != _eta) {
      setState(() {
        _eta = widget.eta;
      });
    }

    if (widget.user != _user) {
      setState(() {
        _user = widget.user;
      });
    }

    if (widget.route != _route) {
      setState(() {
        _route = widget.route;
      });
    }
  }

  void loadRatings() async {
    setState(() {
      driverRating = null;
      jeepRating = null;
    });
    var data1 =
        await getRating(_jeep.driver!.account_email, 'feedback_recepient');
    var data2 = await getRating(_jeep.jeep.device_id, 'feedback_jeepney');

    setState(() {
      driverRating = data1;
      jeepRating = data2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(Constants.defaultPadding),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(Constants.defaultPadding)),
        child: Responsive.isDesktop(context)
            ? SelectedJeepInfoBox(
                gpsPermission: widget.gpsPermission,
                user: widget.user,
                jeep: _jeep.jeep,
                driver: _jeep.driver,
                route: widget.route,
                jeepRating: jeepRating,
                driverRating: driverRating,
                eta: _eta)
            : SizedBox(
                height: 106,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SelectedJeepInfoBox(
                      gpsPermission: widget.gpsPermission,
                      user: widget.user,
                      jeep: _jeep.jeep,
                      driver: _jeep.driver,
                      route: widget.route,
                      jeepRating: jeepRating,
                      driverRating: driverRating,
                      eta: _eta),
                ),
              ));
  }
}

class SelectedJeepInfoRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  const SelectedJeepInfoRow(
      {super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      SizedBox(
        height: Constants.defaultPadding * 1.5,
        child: left,
      ),
      SizedBox(
        height: Constants.defaultPadding * 1.5,
        child: right,
      )
    ]);
  }
}

class SelectedJeepInfoBox extends StatefulWidget {
  final bool gpsPermission;
  final AccountData? user;
  final JeepData jeep;
  final AccountData? driver;
  final RouteData route;
  final List<FeedbackData>? jeepRating;
  final List<FeedbackData>? driverRating;
  final String? eta;
  const SelectedJeepInfoBox(
      {super.key,
      required this.gpsPermission,
      required this.user,
      required this.jeep,
      required this.driver,
      required this.route,
      required this.jeepRating,
      required this.driverRating,
      required this.eta});

  @override
  State<SelectedJeepInfoBox> createState() => _SelectedJeepInfoBoxState();
}

class _SelectedJeepInfoBoxState extends State<SelectedJeepInfoBox> {
  bool isSharing = false;
  String? currentShareDocId;

  void _toggleSharing(bool value) async {
    setState(() => isSharing = value);

    final firestore = FirebaseFirestore.instance;

    if (value) {
      // Create a new share doc
      final docRef = await firestore.collection('live_shares').add({
        'route_id': widget.route.routeId,
        'device_id': widget.jeep.device_id,
        'is_sharing': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final shareUrl = '${Uri.base.origin}/#/share?share_id=${docRef.id}';
      currentShareDocId = docRef.id;

      await Clipboard.setData(ClipboardData(text: shareUrl));

      if (context.mounted) {
        message('Copied Live Location Link');
      }
    } else {
      // Stop sharing by updating Firestore
      if (currentShareDocId != null) {
        await firestore
            .collection('live_shares')
            .doc(currentShareDocId)
            .update({'is_sharing': false});
      }

      currentShareDocId = null;
      message('Stopped Sharing Live Location');
    }
  }

  void message(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SelectedJeepInfoRow(
            left: Row(
              children: [
                Icon(Icons.supervisor_account,
                    color: Color(widget.route.routeColor), size: 15),
                const SizedBox(width: Constants.defaultPadding / 2),
                const Text("Occupancy"),
              ],
            ),
            right: Text(widget.jeep.passenger_count < 0
                ? "Available"
                : widget.jeep.passenger_count >= widget.jeep.max_capacity
                    ? "Full"
                    : "${widget.jeep.passenger_count}/${widget.jeep.max_capacity}")),
        const Divider(color: Colors.white),
        SelectedJeepInfoRow(
            left: Row(children: [
              Icon(Icons.timelapse_rounded,
                  color: Color(widget.route.routeColor), size: 15),
              const SizedBox(
                width: Constants.defaultPadding / 2,
              ),
              const Text("ETA")
            ]),
            right: widget.gpsPermission
                ? Text(widget.eta ?? "...")
                : Row(
                    children: [
                      Icon(
                        Icons.location_off,
                        color: Colors.red[600],
                        size: 15,
                      ),
                      const SizedBox(width: Constants.defaultPadding / 4),
                      const Text("GPS Disabled")
                    ],
                  )),
        const Divider(color: Colors.white),
        SelectedJeepInfoRow(
            left: IconButton(
              onPressed: () => widget.driverRating != null
                  ? AwesomeDialog(
                          context: context,
                          dialogType: DialogType.noHeader,
                          padding: const EdgeInsets.only(
                              left: Constants.defaultPadding,
                              right: Constants.defaultPadding,
                              bottom: Constants.defaultPadding),
                          width: 600,
                          body: PointerInterceptor(
                              child: FeedBackViewer(
                                  routeData: widget.route,
                                  isDriver: false,
                                  feedbackRecepient: widget.jeep.device_id,
                                  feedbacks: widget.jeepRating!)))
                      .show()
                  : null,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: Row(children: [
                Text(widget.jeepRating != null
                    ? widget.jeepRating!.isNotEmpty
                        ? double.parse((widget.jeepRating!
                                        .map((e) => e.feedback_jeepney_rating)
                                        .toList()
                                        .reduce((value, element) =>
                                            value + element) /
                                    widget.jeepRating!.length)
                                .toString())
                            .toStringAsFixed(1)
                        : "N/A"
                    : "..."),
                const SizedBox(
                  width: Constants.defaultPadding / 5,
                ),
                Icon(Icons.star,
                    color: Color(widget.route.routeColor), size: 15),
                const SizedBox(
                  width: Constants.defaultPadding / 2,
                ),
                const Text("Plate Number"),
                const SizedBox(width: Constants.defaultPadding / 2),
              ]),
            ),
            right: Text(widget.jeep.device_id)),
        const Divider(color: Colors.white),
        SelectedJeepInfoRow(
            left: IconButton(
              onPressed: () => widget.driverRating != null
                  ? AwesomeDialog(
                          context: context,
                          dialogType: DialogType.noHeader,
                          padding: const EdgeInsets.only(
                              left: Constants.defaultPadding,
                              right: Constants.defaultPadding,
                              bottom: Constants.defaultPadding),
                          width: 600,
                          body: PointerInterceptor(
                              child: FeedBackViewer(
                                  routeData: widget.route,
                                  isDriver: true,
                                  feedbackRecepient:
                                      widget.driver!.account_name,
                                  feedbacks: widget.driverRating!)))
                      .show()
                  : null,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: Row(children: [
                Text(widget.driverRating != null
                    ? widget.driverRating!.isNotEmpty
                        ? double.parse((widget.driverRating!
                                        .map((e) => e.feedback_driving_rating)
                                        .toList()
                                        .reduce((value, element) =>
                                            value + element) /
                                    widget.driverRating!.length)
                                .toString())
                            .toStringAsFixed(1)
                        : "N/A"
                    : "..."),
                const SizedBox(
                  width: Constants.defaultPadding / 5,
                ),
                Icon(Icons.star,
                    color: Color(widget.route.routeColor), size: 15),
                const SizedBox(
                  width: Constants.defaultPadding / 2,
                ),
                const Text("Driver"),
                const SizedBox(width: Constants.defaultPadding / 2),
              ]),
            ),
            right: Text(widget.driver!.account_name,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
        const Divider(color: Colors.white),
        SelectedJeepInfoRow(
          left: Text("Share Live Location"),
          right: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => _toggleSharing(!isSharing),
                icon: Icon(
                  isSharing ? Icons.stop_circle_rounded : Icons.share,
                  color: isSharing
                      ? Colors.red[600]
                      : Color(widget.route.routeColor),
                  size: 16,
                ),
                tooltip: isSharing ? 'Stop Sharing' : 'Share Location',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ),
        if (widget.user != null &&
            widget.user!.is_verified &&
            widget.driver != null)
          const Divider(color: Colors.white),
        if (widget.user != null &&
            widget.user!.is_verified &&
            widget.driver != null)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconButtonBig(
                color: Color(widget.route.routeColor),
                function: () => AwesomeDialog(
                      dialogType: DialogType.noHeader,
                      context: (context),
                      width: 500,
                      body: PointerInterceptor(
                          child: FeedbackForm(
                              jeep: JeepsAndDrivers(
                                  jeep: widget.jeep, driver: widget.driver),
                              route: widget.route,
                              user: widget.user)),
                    ).show(),
                icon: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Constants.bgColor, size: 20),
                    SizedBox(width: Constants.defaultPadding / 5),
                    Text(
                      "Feedback",
                      style: TextStyle(color: Constants.bgColor),
                    )
                  ],
                )),
            const SizedBox(width: Constants.defaultPadding / 2),
            IconButtonBig(
                inverted: true,
                color: Color(widget.route.routeColor),
                function: () => AwesomeDialog(
                      dialogType: DialogType.noHeader,
                      context: (context),
                      width: 500,
                      body: PointerInterceptor(
                          child: ReportForm(
                              jeep: JeepsAndDrivers(
                                  jeep: widget.jeep, driver: widget.driver),
                              route: widget.route,
                              user: widget.user)),
                    ).show(),
                icon: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.report_outlined,
                        color: Color(widget.route.routeColor), size: 20),
                    const SizedBox(width: Constants.defaultPadding / 5),
                    Text(
                      "Report",
                      style: TextStyle(color: Color(widget.route.routeColor)),
                    )
                  ],
                ))
          ])
      ],
    );
  }
}
