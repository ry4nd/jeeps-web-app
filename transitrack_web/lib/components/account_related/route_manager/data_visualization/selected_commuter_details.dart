import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/manage_commuters_table.dart';
import 'package:transitrack_web/components/right_panel/commuter_feedback_tab.dart';
import 'package:transitrack_web/models/account_model.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/models/report_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  // Method to disable a user by calling the Firebase function
  Future<void> toggleCommuterStatus(String email, bool disable) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('accounts')
          .where('account_email', isEqualTo: email)
          .limit(1)
          .get();

      // Get the UID from the 'account_id' field in the Firestore document
      String uid = snapshot.docs.first.get('account_uid');

      // Get the instance of the Firebase function
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('toggleUserStatus');

      // Call the function with the user ID
      await callable.call(<String, dynamic>{
        'uid': uid,
        'disable': disable,
      });
    } catch (e) {
      // Display the error message
      errorMessage('Error ${disable ? 'banning' : 'activating'} account: $e');
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
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_circle,
                                color: Color(widget.route.routeColor),
                                size: 32,
                              ),
                              const SizedBox(width: Constants.defaultPadding),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.commuter.account_name),
                                  Text(widget.commuter.account_email,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white
                                              .withValues(alpha: 0.2))),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            widget.commuter.account_banned
                                ? "Banned"
                                : "Active",
                            style: TextStyle(
                                color: widget.commuter.account_banned
                                    ? Colors.red[600]
                                    : Color(widget.route.routeColor)),
                          ),
                        ]),
                    // const Divider(color: Colors.white),
                    // const SizedBox(height: Constants.defaultPadding),
                    const SizedBox(height: Constants.defaultPadding),
                    const Divider(color: Colors.white),
                    if (snapshot.hasData && snapshot.data!.feedback!.isNotEmpty)
                      const SizedBox(height: Constants.defaultPadding),
                    if (snapshot.hasData && snapshot.data!.feedback!.isNotEmpty)
                      FeedBack(
                          feedbacks: snapshot.data!.feedback!,
                          routes: widget.routes),
                    const SizedBox(height: Constants.defaultPadding),
                    if (snapshot.hasData && snapshot.data!.feedback!.isNotEmpty)
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
                                      ? DialogType.info
                                      : DialogType.warning,
                                  padding: const EdgeInsets.all(
                                      Constants.defaultPadding),
                                  desc:
                                      "You are about to ${widget.commuter.account_banned ? "enable" : "ban"} ${widget.commuter.account_name}.",
                                  btnOkText: widget.commuter.account_banned
                                      ? "Enable"
                                      : "Ban",
                                  btnOkColor: widget.commuter.account_banned
                                      ? Colors.blue
                                      : Colors.red[600],
                                  btnOkOnPress: () async {
                                    await toggleCommuterStatus(
                                        widget.commuter.account_email,
                                        !widget.commuter.account_banned);
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
                                    widget.loadCommuters();
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
              child: CommuterFeedbackTab(
                  route: widget.routes[widget.feedbacks[index].feedback_route],
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
