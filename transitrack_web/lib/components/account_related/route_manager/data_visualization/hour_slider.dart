import 'package:flutter/material.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

// A component of the hour selector panel in the historical puv tab of the data visualization panel of the route manager account.

class HourSlider extends StatefulWidget {
  final RouteData routeData;
  final double hour;
  final ValueChanged<double> newHour;
  const HourSlider(
      {super.key,
      required this.routeData,
      required this.hour,
      required this.newHour});

  @override
  State<HourSlider> createState() => _HourSliderState();
}

class _HourSliderState extends State<HourSlider> {
  late double _hour;

  @override
  void initState() {
    super.initState();

    setState(() {
      _hour = widget.hour;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
        child: Slider(
          value: _hour, // Initial value
          min: 0,
          max: 23,
          divisions: 23.toInt(),
          activeColor:
              Color(widget.routeData.routeColor).withValues(alpha: 0.25),
          thumbColor: Color(widget.routeData.routeColor),
          inactiveColor:
              Color(widget.routeData.routeColor).withValues(alpha: 0.25),
          onChanged: (value) {
            setState(() {
              _hour = value;
            });
            widget.newHour(_hour);
          },
        ),
      ),
    );
  }
}
