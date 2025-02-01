import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transitrack_web/models/route_model.dart';

// Range Slider widget used for the hour selector of the historical data tab.

class ScrollerWidget extends StatefulWidget {
  final RouteData routeData;
  final int earliest;
  final int latest;
  final ValueChanged<List<int>> bounds;
  final int divisions;
  const ScrollerWidget(
      {super.key,
      required this.routeData,
      required this.earliest,
      required this.latest,
      required this.divisions,
      required this.bounds});

  @override
  State<ScrollerWidget> createState() => _ScrollerWidgetState();
}

class _ScrollerWidgetState extends State<ScrollerWidget> {
  late int _startValue;
  late int _endValue;

  @override
  void initState() {
    super.initState();
    setState(() {
      _startValue = widget.earliest;
      _endValue = widget.latest;
    });
  }

  int _calculateDaysDifference(Timestamp timestamp1, Timestamp timestamp2) {
    DateTime dateTime1 =
        DateTime.fromMillisecondsSinceEpoch(timestamp1.seconds * 1000);
    DateTime dateTime2 =
        DateTime.fromMillisecondsSinceEpoch(timestamp2.seconds * 1000);

    Duration difference = dateTime2.difference(dateTime1);

    return difference.inDays;
  }

  @override
  Widget build(BuildContext context) {
    return RangeSlider(
      values: RangeValues(_startValue.toDouble(), _endValue.toDouble()),
      min: widget.earliest.toDouble(),
      max: widget.latest.toDouble(),
      divisions: widget.divisions == -1
          ? _calculateDaysDifference(
              Timestamp.fromMillisecondsSinceEpoch(widget.earliest),
              Timestamp.fromMillisecondsSinceEpoch(widget.latest))
          : widget.divisions,
      activeColor: Color(widget.routeData.routeColor),
      inactiveColor: Color(widget.routeData.routeColor).withValues(alpha: 0.2),
      onChanged: (RangeValues values) {
        setState(() {
          if (values.start.toInt() < values.end.toInt()) {
            _startValue = values.start.toInt();
            _endValue = values.end.toInt();
          }

          widget.bounds([_startValue, _endValue]);
        });
      },
    );
  }
}
