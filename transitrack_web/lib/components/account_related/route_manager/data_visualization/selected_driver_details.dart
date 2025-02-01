import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/manage_drivers_table.dart';
import 'package:transitrack_web/components/right_panel/feedback_tab.dart';
import 'package:transitrack_web/models/account_model.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/models/jeep_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/services/find_location.dart';
import 'package:transitrack_web/style/constants.dart';

// This widget appears when a driver is selected in the Manager Driver Tab of the Data visualization panel of the route manager account.

class SelectedDriverDetails extends StatefulWidget {
  final List<RouteData> routes;
  final RouteData route;
  final AccountData driver;
  final Function loadDrivers;
  const SelectedDriverDetails(
      {super.key,
      required this.routes,
      required this.route,
      required this.driver,
      required this.loadDrivers});

  @override
  State<SelectedDriverDetails> createState() => _SelectedDriverDetailsState();
}

class _SelectedDriverDetailsState extends State<SelectedDriverDetails> {
  Future<JeepDataRatingAndAddress?> getAddress(
      String email, String jeep) async {
    List<FeedbackData>? ratings = await getRating(email, 'feedback_recepient');

    if (jeep == "") {
      return JeepDataRatingAndAddress(
          jeepData: null, address: null, rating: ratings);
    }
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('jeeps_realtime')
        .where('device_id', isEqualTo: jeep)
        .get();

    JeepData jeepData = JeepData.fromSnapshot(querySnapshot.docs.first);

    String address = await findAddress(
        LatLng(jeepData.location.latitude, jeepData.location.longitude));

    return JeepDataRatingAndAddress(
        jeepData: jeepData, address: address, rating: ratings);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 600,
        padding: const EdgeInsets.all(Constants.defaultPadding * 2),
        decoration: BoxDecoration(
            border: Border.all(
                width: 2, color: Colors.white.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(Constants.defaultPadding / 2)),
        child: FutureBuilder(
            future: getAddress(
                widget.driver.account_email, widget.driver.jeep_driving!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                  color: Color(widget.route.routeColor),
                ));
              }

              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              }

              JeepDataRatingAndAddress? jeep;
              double? ratingAve;
              if (snapshot.hasData) {
                jeep = snapshot.data;
                if (jeep!.rating != null && jeep.rating!.isNotEmpty) {
                  ratingAve = (jeep.rating!
                          .map((e) => e.feedback_driving_rating)
                          .toList()
                          .reduce((value, element) => value + element) /
                      jeep.rating!.length);
                }
              }

              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(widget.route.routeColor), // Circle color
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            size: 22,
                            color: Constants.bgColor, // Icon color
                          ),
                        ),
                      ),
                      const SizedBox(width: Constants.defaultPadding),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    Text(widget.driver.account_name),
                                    const SizedBox(
                                        width: Constants.defaultPadding / 2),
                                    Icon(
                                        widget.driver.is_verified
                                            ? Icons.verified_user
                                            : Icons.remove_moderator,
                                        color: widget.driver.is_verified
                                            ? Colors.blue
                                            : Colors.grey,
                                        size: 13)
                                  ]),
                                  Row(
                                    children: [
                                      Text(jeep!.jeepData != null
                                          ? jeep.jeepData!.device_id
                                          : "Not Operating"),
                                      const SizedBox(
                                          width: Constants.defaultPadding / 2),
                                      Icon(
                                        jeep.jeepData != null
                                            ? Icons.circle
                                            : Icons.circle_outlined,
                                        color: jeep.jeepData != null
                                            ? Color(widget
                                                .routes[jeep.jeepData!.route_id]
                                                .routeColor)
                                            : Colors.grey,
                                        size: 13,
                                      ),
                                    ],
                                  ),
                                ]),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('<${widget.driver.account_email}>',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white
                                            .withValues(alpha: 0.5))),
                                if (jeep.address != null)
                                  Text(jeep.address!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white
                                              .withValues(alpha: 0.5))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ]),
                    const Divider(color: Colors.white),
                    const SizedBox(height: Constants.defaultPadding),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                          "Average Rating: ${ratingAve != null ? double.parse(ratingAve.toString()).toStringAsFixed(1) : "No Rating Found."}"),
                      if (ratingAve != null)
                        const SizedBox(width: Constants.defaultPadding),
                      if (ratingAve != null)
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < ratingAve!.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: index < ratingAve.round()
                                  ? Color(widget.route.routeColor)
                                  : Colors.grey,
                              size: 20,
                            );
                          }),
                        ),
                      if (ratingAve != null)
                        Text(" (${jeep.rating!.length} results)")
                    ]),
                    const SizedBox(height: Constants.defaultPadding),
                    const Divider(color: Colors.white),
                    if (jeep.rating!.isNotEmpty)
                      const SizedBox(height: Constants.defaultPadding),
                    if (jeep.rating!.isNotEmpty)
                      FeedBack(feedbacks: jeep.rating!, routes: widget.routes),
                    const SizedBox(height: Constants.defaultPadding),
                    if (jeep.rating!.isNotEmpty)
                      const Divider(color: Colors.white),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            child: IconButton(
                              icon: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      widget.driver.is_verified
                                          ? Icons.remove_moderator
                                          : Icons.verified_user,
                                      color: widget.driver.is_verified
                                          ? Colors.red[600]
                                          : Colors.blue,
                                      size: 15),
                                  const SizedBox(
                                      width: Constants.defaultPadding / 2),
                                  Text(widget.driver.is_verified
                                      ? "Unverify Driver"
                                      : "Verify Driver"),
                                ],
                              ),
                              onPressed: () => AwesomeDialog(
                                  context: context,
                                  width: 400,
                                  dialogType: widget.driver.is_verified
                                      ? DialogType.error
                                      : DialogType.success,
                                  padding: const EdgeInsets.all(
                                      Constants.defaultPadding),
                                  desc:
                                      "You are about to ${widget.driver.is_verified ? "unverify" : "verify"} ${widget.driver.account_name}.",
                                  btnOkText: widget.driver.is_verified
                                      ? "Unverify"
                                      : "Verify",
                                  btnOkColor: widget.driver.is_verified
                                      ? Colors.red[600]
                                      : Colors.blue,
                                  btnOkOnPress: () async {
                                    await AwesomeDialog(
                                            context: context,
                                            width: 150,
                                            padding: const EdgeInsets.only(
                                                bottom:
                                                    Constants.defaultPadding),
                                            dialogType: DialogType.noHeader,
                                            body: CircularProgressIndicator(
                                                color: Color(
                                                    widget.route.routeColor)),
                                            dismissOnBackKeyPress: false,
                                            dismissOnTouchOutside: false,
                                            autoHide: const Duration(
                                                milliseconds: 1000))
                                        .show();
                                    await AccountData.updateAccountFirestore(
                                        widget.driver.account_email, {
                                      'is_verified': widget.driver.is_verified
                                          ? false
                                          : true
                                    }).then((bool success) => AwesomeDialog(
                                        width: 400,
                                        context: context,
                                        dialogType: success
                                            ? DialogType.success
                                            : DialogType.error,
                                        padding: const EdgeInsets.all(
                                          Constants.defaultPadding,
                                        ),
                                        desc: success
                                            ? "Successfully ${widget.driver.is_verified ? "unverified" : "verified"} ${widget.driver.account_name}. Reloading."
                                            : "Unable to ${widget.driver.is_verified ? "unverify" : "verify"} ${widget.driver.account_name}. Check your connection!",
                                        autoHide:
                                            const Duration(milliseconds: 3000),
                                        onDismissCallback: (_) =>
                                            widget.loadDrivers()).show());
                                  }).show(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]);
            }));
  }
}

class FeedBack extends StatefulWidget {
  final List<RouteData> routes;
  final List<FeedbackData> feedbacks;
  const FeedBack({super.key, required this.routes, required this.feedbacks});

  @override
  State<FeedBack> createState() => FeedBackState();
}

class FeedBackState extends State<FeedBack> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
                onPressed: () {
                  if (index > 0) {
                    setState(() {
                      index--;
                    });
                  }
                },
                icon: const Icon(Icons.arrow_left)),
            Expanded(
              child: FeedbackTab(
                  route: widget.routes[widget.feedbacks[index].feedback_route],
                  isDriver: true,
                  feedBack: widget.feedbacks[index]),
            ),
            IconButton(
                onPressed: () {
                  if (index < widget.feedbacks.length - 1) {
                    setState(() {
                      index++;
                    });
                  }
                },
                icon: const Icon(Icons.arrow_right)),
          ],
        ),
        const SizedBox(height: Constants.defaultPadding),
        Text("${index + 1}/${widget.feedbacks.length}")
      ],
    );
  }
}
