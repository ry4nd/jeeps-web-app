import 'package:flutter/material.dart';
import 'package:transitrack_web/models/route_model.dart';

// This widget is found in the historical data tab to run through the entire hour selected.

class SecondSlider extends StatefulWidget {
  final RouteData routeData;
  final double second;
  final ValueChanged<double> newSecond;
  const SecondSlider(
      {super.key,
      required this.routeData,
      required this.second,
      required this.newSecond});

  @override
  State<SecondSlider> createState() => _SecondSliderState();
}

class _SecondSliderState extends State<SecondSlider> {
  late double _second;

  @override
  void initState() {
    super.initState();

    setState(() {
      _second = widget.second;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Slider(
        value: _second, // Initial value
        min: 0,
        max: 3599,
        divisions: 3599.toInt(),
        activeColor: Color(widget.routeData.routeColor).withOpacity(0.25),
        thumbColor: Color(widget.routeData.routeColor),
        inactiveColor: Color(widget.routeData.routeColor).withOpacity(0.25),
        onChanged: (value) {
          setState(() {
            _second = value;
          });
          widget.newSecond(_second);
        },
      ),
    );
  }
}
