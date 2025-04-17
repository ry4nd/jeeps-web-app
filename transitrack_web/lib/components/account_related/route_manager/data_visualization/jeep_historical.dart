import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/calendar_selector.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/jeep_historical_map.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/jeep_historical_route_info.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/minute_slider.dart';
import 'package:transitrack_web/models/jeep_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

// This is the Historical Data panel of the data visualization panel of the route manager account.

class JeepHistoricalPage extends StatefulWidget {
  final RouteData routeData;
  const JeepHistoricalPage({super.key, required this.routeData});

  @override
  State<JeepHistoricalPage> createState() => _JeepHistoricalPageState();
}

class _JeepHistoricalPageState extends State<JeepHistoricalPage> {
  DateTime? _selectedDate;

  bool mapLoaded = false;

  List<PerJeepHistoricalData>? jeepHistoricalData = [];

  int _second = 0;

  JeepHistoricalData? selectedJeep;

  List<JeepHistoricalData>? processedJeeps;

  void processHistoricalData() {
    setState(() {
      processedJeeps = jeepHistoricalData!
          .map((e) => e.data.firstWhere((element) => element.jeepData.timestamp
              .toDate()
              .isBefore(_selectedDate!.add(Duration(seconds: _second)))))
          .toList();
    });
  }

  void fetchHistoricalData() async {
    setState(() {
      jeepHistoricalData = null;
      processedJeeps = null;
    });

    List<PerJeepHistoricalData>? data =
        await getJeepHistoricalData(widget.routeData.routeId, _selectedDate!);

    if (data != null) {
      setState(() {
        jeepHistoricalData = data;
        _second = 0;
      });

      print("Loaded ${jeepHistoricalData!.length} Documents.");

      processHistoricalData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Stack(
          children: [
            JeepHistoricalMap(
              mapLoaded: (bool value) {
                setState(() {
                  mapLoaded = value;
                });
              },
              jeepHistoricalData: processedJeeps,
              routeData: widget.routeData,
              selectedJeep: (JeepHistoricalData? value) => setState(() {
                selectedJeep = value;
              }),
            ),
            Positioned(
              right: Constants.defaultPadding,
              top: Constants.defaultPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  PointerInterceptor(
                    child: Container(
                      padding: const EdgeInsets.all(Constants.defaultPadding),
                      width: 300,
                      decoration: BoxDecoration(
                          color: Constants.bgColor,
                          borderRadius: BorderRadius.circular(
                              Constants.defaultPadding / 2)),
                      child: (mapLoaded)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: IconButton(
                                    onPressed: () => AwesomeDialog(
                                        context: context,
                                        dialogType: DialogType.noHeader,
                                        padding: const EdgeInsets.only(
                                            bottom: Constants.defaultPadding),
                                        width: 600,
                                        body: PointerInterceptor(
                                            child: CalendarSelector(
                                          routeData: widget.routeData,
                                          selectedDate: _selectedDate ??
                                              DateTime(
                                                  DateTime.now().year,
                                                  DateTime.now().month,
                                                  DateTime.now().day),
                                          newSelectedDate:
                                              (DateTime newSelectedDate) {
                                            setState(() {
                                              _selectedDate = newSelectedDate;
                                            });

                                            // print(_selectedDate);
                                            fetchHistoricalData();
                                          },
                                        ))).show(),
                                    icon: Text(_selectedDate == null
                                        ? "Select Date"
                                        : '${DateFormat('MMM d, yyyy').format(_selectedDate!)} (${formatSliderValue(_selectedDate!.hour.toDouble())} - ${formatSliderValue(_selectedDate!.hour.toDouble() + 1)})'),
                                  ),
                                ),
                                if (jeepHistoricalData != null &&
                                    _selectedDate != null)
                                  Column(
                                    children: [
                                      const Divider(color: Colors.white),
                                      SecondSlider(
                                          routeData: widget.routeData,
                                          second: _second.toDouble(),
                                          newSecond: (double newSecond) {
                                            setState(() {
                                              _second = newSecond.toInt();
                                            });
                                            processHistoricalData();
                                          }),
                                      Center(
                                          child: Text(DateFormat('hh:mm:ss a')
                                              .format(DateTime(
                                                  _selectedDate!.year,
                                                  _selectedDate!.month,
                                                  _selectedDate!.day,
                                                  _selectedDate!.hour,
                                                  _second ~/ 60,
                                                  _second % 60))))
                                    ],
                                  ),
                                if (jeepHistoricalData == null)
                                  Center(
                                    child: CircularProgressIndicator(
                                      color: Color(widget.routeData.routeColor),
                                    ),
                                  )
                              ],
                            )
                          : Center(
                              child: CircularProgressIndicator(
                              color: Color(widget.routeData.routeColor),
                            )),
                    ),
                  ),
                  if (processedJeeps != null)
                    PointerInterceptor(
                        child: JeepHistoricalRouteInfo(
                            operatingJeeps: processedJeeps!
                                .where((element) => element.isOperating)
                                .length,
                            totalJeeps: processedJeeps!.length,
                            routeData: widget.routeData,
                            selectedJeep: selectedJeep))
                ],
              ),
            ),
          ],
        ));
  }
}
