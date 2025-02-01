import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/selected_jeep_info_historical.dart';
import 'package:transitrack_web/components/select_jeep_prompt.dart';
import 'package:transitrack_web/models/jeep_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

// The panel on the top right corner of the jeep historical tab of the data visualization panel of the route manager account. This only appears when you select a PUV.

class JeepHistoricalRouteInfo extends StatefulWidget {
  final RouteData routeData;
  final int operatingJeeps;
  final int totalJeeps;
  final JeepHistoricalData? selectedJeep;
  const JeepHistoricalRouteInfo(
      {super.key,
      required this.routeData,
      required this.operatingJeeps,
      required this.totalJeeps,
      required this.selectedJeep});

  @override
  State<JeepHistoricalRouteInfo> createState() =>
      _JeepHistoricalRouteInfoState();
}

class _JeepHistoricalRouteInfoState extends State<JeepHistoricalRouteInfo> {
  late JeepHistoricalData? _selectedJeep;

  @override
  void initState() {
    super.initState();

    setState(() {
      _selectedJeep = widget.selectedJeep;
    });
  }

  @override
  void didUpdateWidget(covariant JeepHistoricalRouteInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if route choice changed
    if (widget.selectedJeep != _selectedJeep) {
      setState(() {
        _selectedJeep = widget.selectedJeep;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(top: Constants.defaultPadding),
      padding: const EdgeInsets.all(Constants.defaultPadding),
      decoration: const BoxDecoration(
        color: Constants.secondaryColor,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.routeData.routeName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
                              color: Color(widget.routeData.routeColor),
                              value: widget.operatingJeeps.toDouble(),
                              showTitle: false,
                              radius: 20,
                            ),
                            PieChartSectionData(
                              color: Color(widget.routeData.routeColor)
                                  .withValues(alpha: 0.1),
                              value: widget.totalJeeps -
                                  widget.operatingJeeps.toDouble(),
                              showTitle: false,
                              radius: 20,
                            ),
                            PieChartSectionData(
                              color: Colors.transparent,
                              value: widget.totalJeeps.toDouble(),
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
                          SizedBox(height: Constants.defaultPadding * 3),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: widget.operatingJeeps.toString(),
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
                                  text: "/${widget.totalJeeps}",
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
                SelectedJeepInfoBoxHistorical(
                    jeep: _selectedJeep!, routeData: widget.routeData)
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
