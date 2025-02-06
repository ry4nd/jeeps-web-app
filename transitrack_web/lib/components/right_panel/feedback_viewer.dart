import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transitrack_web/components/right_panel/feedback_tab.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';
import 'package:transitrack_web/style/style.dart';

// This widget is called when user selects either the PUV or the Driver Name to view the feedbacks for them.

class FeedBackViewer extends StatefulWidget {
  final bool isDriver;
  final String feedbackRecepient;
  final RouteData routeData;
  final List<FeedbackData> feedbacks;
  const FeedBackViewer(
      {super.key,
      required this.feedbackRecepient,
      required this.feedbacks,
      required this.routeData,
      required this.isDriver});

  @override
  State<FeedBackViewer> createState() => _FeedBackViewerState();
}

class _FeedBackViewerState extends State<FeedBackViewer> {
  List<RouteData> routes = [];
  int index = 0;

  @override
  void initState() {
    super.initState();

    loadRoutes();
  }

  void loadRoutes() async {
    var data = await FirebaseFirestore.instance
        .collection('routes')
        .orderBy('route_id')
        .get();

    if (data.docs.isNotEmpty) {
      setState(() {
        routes = data.docs.map((e) => RouteData.fromFirestore(e)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PrimaryText(
                  text: "Feedbacks",
                  color: Colors.white,
                  size: 40,
                  fontWeight: FontWeight.w700,
                ),
                Row(
                  children: [
                    Text(
                        "for ${widget.feedbackRecepient} (${widget.feedbacks.length} results)"),
                    Icon(
                      widget.isDriver ? Icons.person : Icons.directions_bus,
                      color: Color(widget.routeData.routeColor),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.feedbacks.isNotEmpty)
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${index + 1}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 25,
                          ),
                    ),
                    TextSpan(
                      text: "/${widget.feedbacks.length}",
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                    )
                  ],
                ),
              ),
          ],
        ),
        const Divider(color: Colors.white),
        const SizedBox(height: Constants.defaultPadding),
        if (widget.feedbacks.isNotEmpty && routes.isNotEmpty)
          Column(
            children: [
              SizedBox(
                  height: 200,
                  child: FeedbackTab(
                      route: routes[widget.feedbacks[index].feedback_route],
                      isDriver: widget.isDriver,
                      feedBack: widget.feedbacks[index])),
              Row(
                children: [
                  Expanded(
                    child: IconButton(
                        onPressed: () {
                          if (index > 0) {
                            setState(() {
                              index--;
                            });
                          }
                        },
                        icon: const Icon(Icons.arrow_left)),
                  ),
                  Expanded(
                    child: IconButton(
                        onPressed: () {
                          if (index < widget.feedbacks.length - 1) {
                            setState(() {
                              index++;
                            });
                          }
                        },
                        icon: const Icon(Icons.arrow_right)),
                  )
                ],
              ),
            ],
          ),
      ],
    );
  }
}
