import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/manage_commuters_table.dart';
import 'package:transitrack_web/components/right_panel/feedback_tab.dart';
import 'package:transitrack_web/models/account_model.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/models/report_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

class SelectedCommuterDetails extends StatefulWidget {
  final List<RouteData> routes;
  final RouteData route;
  final AccountData commuter;
  final Function loadCommuters;
  const SelectedCommuterDetails(
      {super.key,
      required this.routes,
      required this.route,
      required this.commuter,
      required this.loadCommuters});

  @override
  State<SelectedCommuterDetails> createState() =>
      _SelectedCommuterDetailsState();
}

class _SelectedCommuterDetailsState extends State<SelectedCommuterDetails> {
  Future<CommuterFeedbackAndReport?> getFeedbackAndReport(String email) async {
    List<FeedbackData>? feedback = await getFeedbackSender(email);
    List<ReportData>? report = await getReportSender(email);

    return CommuterFeedbackAndReport(feedback: feedback, report: report);
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
            future: getFeedbackAndReport(widget.commuter.account_email),
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
                                    Text(widget.commuter.account_name),
                                    const SizedBox(
                                        width: Constants.defaultPadding / 2),
                                    Icon(
                                        widget.commuter.is_verified
                                            ? Icons.verified_user
                                            : Icons.remove_moderator,
                                        color: widget.commuter.is_verified
                                            ? Colors.blue
                                            : Colors.grey,
                                        size: 13)
                                  ]),
                                ]),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('<${widget.commuter.account_email}>',
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
                    const SizedBox(height: Constants.defaultPadding),
                    const Divider(color: Colors.white),
                    // if (jeep.rating!.isNotEmpty)
                    //   const SizedBox(height: Constants.defaultPadding),
                    // if (jeep.rating!.isNotEmpty)
                    //   FeedBack(feedbacks: jeep.rating!, routes: widget.routes),
                    // const SizedBox(height: Constants.defaultPadding),
                    // if (jeep.rating!.isNotEmpty)
                    //   const Divider(color: Colors.white),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            child: IconButton(
                              icon: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      widget.commuter.account_banned
                                          ? Icons.account_circle_outlined
                                          : Icons.no_accounts_outlined,
                                      color: widget.commuter.account_banned
                                          ? Colors.blue
                                          : Colors.red[600],
                                      size: 15),
                                  const SizedBox(
                                      width: Constants.defaultPadding / 2),
                                  Text(widget.commuter.account_banned
                                      ? "Enable Account"
                                      : "Ban Account"),
                                ],
                              ),
                              onPressed: () => AwesomeDialog(
                                  context: context,
                                  width: 400,
                                  dialogType: widget.commuter.account_banned
                                      ? DialogType.error
                                      : DialogType.success,
                                  padding: const EdgeInsets.all(
                                      Constants.defaultPadding),
                                  desc:
                                      "You are about to ${widget.commuter.account_banned ? "enable" : "ban"} ${widget.commuter.account_name}.",
                                  btnOkText: widget.commuter.account_banned
                                      ? "Enable"
                                      : "Ban",
                                  btnOkColor: widget.commuter.is_verified
                                      ? Colors.blue
                                      : Colors.red[600],
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
                                        widget.commuter.account_email, {
                                      'account_banned':
                                          widget.commuter.account_banned
                                              ? true
                                              : false
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
                                            ? "Successfully ${widget.commuter.account_banned ? "banned" : "enabled"} ${widget.commuter.account_name}. Reloading."
                                            : "Unable to ${widget.commuter.account_banned ? "ban" : "enable"} ${widget.commuter.account_name}. Check your connection!",
                                        autoHide:
                                            const Duration(milliseconds: 3000),
                                        onDismissCallback: (_) =>
                                            widget.loadCommuters()).show());
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
