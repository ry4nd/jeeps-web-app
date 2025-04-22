import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/scroller_widget.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/shared_locations_map.dart';
import 'package:transitrack_web/models/ping_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

// This widget is called under the shared locations tab of the data visualization panel

class SharedLocationsPage extends StatefulWidget {
  final RouteData routeData;
  const SharedLocationsPage({super.key, required this.routeData});

  @override
  State<SharedLocationsPage> createState() => _SharedLocationsPageState();
}

class DayWidgetClass {
  String day;
  bool enabled;

  DayWidgetClass({required this.day, required this.enabled});

  toggle() {
    enabled = !enabled;
  }

  reset() {
    enabled = true;
  }
}

class _SharedLocationsPageState extends State<SharedLocationsPage> {
  late List<PingData>? pings;
  late List<PingData>? boundedPings;
  late Timestamp? earliest;
  late Timestamp? latest;

  late Timestamp? startBound;
  late Timestamp? endBound;
  late int hourBoundStart;
  late int hourBoundEnd;
  late List<int> selectedDays;

  bool mapLoaded = false;

  List<DayWidgetClass> dayWidgetClass = [
    DayWidgetClass(day: "M", enabled: true),
    DayWidgetClass(day: "T", enabled: true),
    DayWidgetClass(day: "W", enabled: true),
    DayWidgetClass(day: "Th", enabled: true),
    DayWidgetClass(day: "F", enabled: true),
    DayWidgetClass(day: "Sa", enabled: true),
    DayWidgetClass(day: "Su", enabled: true),
  ];

  @override
  void initState() {
    super.initState();
    setState(() {
      pings = null;
      boundedPings = null;
      earliest = null;
      latest = null;
      startBound = null;
      endBound = null;
      hourBoundStart = 0;
      hourBoundEnd = 24;
    });
    scanDays();
    fetchPingData();
  }

  void boundPings() {
    setState(() {
      boundedPings = pings!
          .where((ping) =>
              ping.ping_timestamp.seconds >= startBound!.seconds &&
              ping.ping_timestamp.seconds <= endBound!.seconds &&
              ping.ping_timestamp.toDate().hour >= hourBoundStart &&
              ping.ping_timestamp.toDate().hour <= hourBoundEnd &&
              selectedDays.contains(ping.ping_timestamp.toDate().weekday))
          .toList();
    });
  }

  void scanDays() {
    selectedDays = dayWidgetClass
        .asMap()
        .entries
        .where((day) => day.value.enabled)
        .map((entry) => entry.key + 1)
        .toList();
  }

  void toggleDays(int index) {
    dayWidgetClass[index].toggle();
    scanDays();
  }

  void fetchPingData() async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('pings')
        .where('ping_route', isEqualTo: widget.routeData.routeId);

    query = query.orderBy('ping_timestamp', descending: true);

    QuerySnapshot querySnapshot = await query.get();

    setState(() {
      pings = querySnapshot.docs.map((DocumentSnapshot document) {
        return PingData.fromFirestore(document);
      }).toList();
      earliest = pings!.last.ping_timestamp;
      latest = pings!.first.ping_timestamp;

      startBound = earliest!;
      endBound = latest!;
    });

    boundPings();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 500,
        child: Stack(
          children: [
            SharedLocationsMap(
                routeData: widget.routeData,
                pings: boundedPings,
                mapLoaded: (bool value) {
                  setState(() {
                    mapLoaded = value;
                  });
                }),
            Positioned(
              top: Constants.defaultPadding,
              right: Constants.defaultPadding,
              child: PointerInterceptor(
                child: Container(
                  padding: const EdgeInsets.all(Constants.defaultPadding),
                  width: 350,
                  decoration: BoxDecoration(
                      color: Constants.bgColor,
                      borderRadius:
                          BorderRadius.circular(Constants.defaultPadding / 2)),
                  child: (mapLoaded &&
                          pings != null &&
                          earliest != null &&
                          latest != null)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                    dayWidgetClass.length,
                                    (index) => IconButton(
                                        onPressed: () {
                                          toggleDays(index);
                                          boundPings();
                                        },
                                        icon: Container(
                                          width: 29,
                                          height: 29,
                                          decoration: BoxDecoration(
                                              color:
                                                  dayWidgetClass[index].enabled
                                                      ? Color(widget
                                                          .routeData.routeColor)
                                                      : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(50)),
                                          child: Center(
                                              child: Text(
                                                  dayWidgetClass[index].day,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          dayWidgetClass[index]
                                                                  .enabled
                                                              ? Colors.black
                                                              : Colors.white))),
                                        )))),
                            const SizedBox(height: Constants.defaultPadding),
                            ScrollerWidget(
                              routeData: widget.routeData,
                              earliest: earliest!.millisecondsSinceEpoch,
                              latest: latest!.millisecondsSinceEpoch,
                              divisions: -1,
                              bounds: (List<int> bounds) {
                                setState(() {
                                  startBound =
                                      Timestamp.fromMillisecondsSinceEpoch(
                                          bounds[0]);
                                  endBound =
                                      Timestamp.fromMillisecondsSinceEpoch(
                                          bounds[1]);
                                  boundPings();
                                });
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('MMM d')
                                    .format(startBound!.toDate())),
                                Text(DateFormat('MMM d')
                                    .format(endBound!.toDate())),
                              ],
                            ),
                            const SizedBox(height: Constants.defaultPadding),
                            ScrollerWidget(
                              routeData: widget.routeData,
                              earliest: 0,
                              latest: 24,
                              divisions: 24,
                              bounds: (List<int> bounds) {
                                setState(() {
                                  hourBoundStart = bounds[0];
                                  hourBoundEnd = bounds[1];
                                });

                                boundPings();
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    "${hourBoundStart == 0 ? 12 : (hourBoundStart > 12 ? hourBoundStart % 12 : hourBoundStart)}:00 ${hourBoundStart >= 12 ? "PM" : "AM"}"),
                                Text(
                                    "${hourBoundEnd == 24 ? 12 : (hourBoundEnd > 12 ? hourBoundEnd % 12 : hourBoundEnd)}:00 ${hourBoundEnd >= 12 && hourBoundEnd != 24 ? "PM" : "AM"}"),
                              ],
                            ),
                            const Divider(color: Colors.white),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                          onPressed: () =>
                                              downloadPingDataAsCSV(
                                                  boundedPings!,
                                                  widget.routeData),
                                          icon: const Icon(Icons.download)),
                                      const SizedBox(
                                          width: Constants.defaultPadding / 2),
                                      Text(
                                          "Showing ${boundedPings!.length} results."),
                                    ],
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        for (DayWidgetClass day
                                            in dayWidgetClass) {
                                          day.reset();
                                        }

                                        scanDays();
                                        setState(() {
                                          pings = null;
                                          boundedPings = null;
                                          earliest = null;
                                          latest = null;
                                          startBound = null;
                                          endBound = null;
                                          hourBoundStart = 0;
                                          hourBoundEnd = 24;
                                        });
                                        fetchPingData();
                                      },
                                      icon: const Icon(Icons.refresh))
                                ]),
                          ],
                        )
                      : Center(
                          child: CircularProgressIndicator(
                          color: Color(widget.routeData.routeColor),
                        )),
                ),
              ),
            )
          ],
        ));
  }
}
