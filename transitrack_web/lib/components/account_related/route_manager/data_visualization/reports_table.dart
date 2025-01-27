import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/filters.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/reports_map.dart';
import 'package:transitrack_web/models/account_model.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/models/filter_model.dart';
import 'package:transitrack_web/models/report_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

// This widget is used in the Reports tab of the Data visualization panel of the route manager to list all the reports issued in the route.

class ReportsTable extends StatefulWidget {
  final RouteData route;
  final bool isDispose;
  const ReportsTable({super.key, required this.route, required this.isDispose});

  @override
  State<ReportsTable> createState() => _ReportsTableState();
}

class _ReportsTableState extends State<ReportsTable> {
  TextEditingController searchController = TextEditingController();

  bool mapLoaded = false;
  int selected = -1;
  late ReportData? selectedReport;

  bool isHover = false;

  List<ReportData>? reports;

  String searchString = "";

  FilterParameters orderBy =
      FilterParameters(filterSearch: "timestamp", filterDescending: true);

  @override
  void initState() {
    super.initState();

    loadReports();
  }

  void select(int index, ReportData? report) {
    setState(() {
      selected = index;
      selectedReport = report;
    });
  }

  Future<void> loadReports() async {
    setState(() {
      reports = null;
    });
    select(-1, null);

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('reports')
        .where('report_route', isEqualTo: widget.route.routeId);

    query = query.orderBy(orderBy.filterSearch,
        descending: orderBy.filterDescending);

    QuerySnapshot querySnapshot = await query.get();

    setState(() {
      reports = querySnapshot.docs.map((DocumentSnapshot document) {
        return ReportData.fromFirestore(document);
      }).toList();
    });
  }

  Future<UsersAdditionalInfo?> loadReportDetails(
      String sender, String recepient) async {
    AccountData? senderData = await AccountData.getAccountByEmail(sender);
    AccountData? recepientData = await AccountData.getAccountByEmail(recepient);

    if (senderData != null && recepientData != null) {
      return UsersAdditionalInfo(
          senderData: senderData, recepientData: recepientData);
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: Constants.defaultPadding),
        child: Row(
          children: [
            SizedBox(
              height: 700,
              width: 500,
              child: Column(
                children: [
                  SearchBar(
                    controller: searchController,
                    overlayColor: WidgetStateProperty.all(
                        Colors.white.withOpacity(0.2)),
                    elevation: WidgetStateProperty.all(0.0),
                    onChanged: (String value) {
                      setState(() {
                        searchString = value;
                      });
                      select(-1, null);
                    },
                    hintText: 'Search report message',
                    hintStyle: WidgetStateProperty.all(
                        TextStyle(color: Color(widget.route.routeColor))),
                    leading: const Icon(Icons.search),
                    shape: WidgetStateProperty.all(
                        const ContinuousRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    )),
                    trailing: <Widget>[
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                reports = null;
                              });
                              loadReports();
                            },
                            icon: const Icon(Icons.refresh),
                          ),
                          IconButton(
                            onPressed: () => AwesomeDialog(
                              dialogType: DialogType.noHeader,
                              context: (context),
                              width: 500,
                              body: PointerInterceptor(
                                  child: Filters(
                                route: widget.route,
                                dropdownList: FilterParameters.reportsOrderBy,
                                oldFilter: orderBy,
                                newFilter: (FilterParameters newFilter) {
                                  setState(() {
                                    orderBy = newFilter;
                                  });
                                  loadReports();
                                },
                              )),
                            ).show(),
                            icon: const Icon(Icons.filter_list),
                          )
                        ],
                      )
                    ],
                  ),
                  if (reports == null || !mapLoaded)
                    SizedBox(
                        height: 500,
                        child: Center(
                            child: CircularProgressIndicator(
                          color: Color(widget.route.routeColor),
                        ))),
                  if (reports != null && mapLoaded)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: reports!.length,
                          itemBuilder: (context, index) {
                            ReportData report = reports![index];

                            if (searchString.isNotEmpty &&
                                !report.report_content
                                    .toLowerCase()
                                    .contains(searchString.toLowerCase())) {
                              return const SizedBox();
                            }
                            return ListTile(
                              onTap: () async {
                                if (selected == index) {
                                  select(-1, null);
                                } else {
                                  select(index, report);
                                }
                              },
                              selected: index == selected,
                              selectedColor: Colors.white,
                              selectedTileColor: Color(widget.route.routeColor)
                                  .withOpacity(0.1),
                              hoverColor: Colors.white.withOpacity(0.2),
                              trailing: Text(
                                DateFormat('MMM d')
                                    .format(report.timestamp.toDate()),
                                style: const TextStyle(fontSize: 13),
                              ),
                              title: RichText(
                                  textAlign: TextAlign.justify,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                          text:
                                              "[${ReportData.reportDetails[report.report_type].reportType}]",
                                          style: TextStyle(
                                              color: Color(
                                                  widget.route.routeColor),
                                              fontWeight: FontWeight.w200)),
                                      TextSpan(
                                        text: ' - "${report.report_content}"',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  )),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Constants.defaultPadding),
            Expanded(
                child: SizedBox(
              height: 700,
              child: Stack(
                children: [
                  ReportsMap(
                    isHover: isHover,
                    isDispose: widget.isDispose,
                    reportData: reports ?? [],
                    selectedReport: selectedReport,
                    selectedFromMap: (ReportData selectedReportFromMap) =>
                        select(
                            reports!.indexWhere((element) =>
                                element.report_id ==
                                selectedReportFromMap.report_id),
                            selectedReportFromMap),
                    mapLoaded: (bool value) {
                      setState(() {
                        mapLoaded = value;
                      });
                    },
                    deselect: () => select(-1, null),
                  ),
                  if (selectedReport != null)
                    Positioned(
                        right: Constants.defaultPadding,
                        top: Constants.defaultPadding,
                        child: ReportContents(reportData: selectedReport!)),
                  const Positioned(
                      right: Constants.defaultPadding,
                      bottom: Constants.defaultPadding * 2,
                      child: Legends())
                ],
              ),
            ))
          ],
        ));
  }
}

class Legends extends StatelessWidget {
  const Legends({super.key});

  Widget legendWidget(String text, Color color) {
    return Row(
      children: [
        Text(text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(width: Constants.defaultPadding / 3),
        Icon(Icons.circle, color: color, size: 11)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
            3,
            (index) => legendWidget(
                ReportData.reportDetails[index + 1].reportType,
                ReportData.reportDetails[index + 1].reportColors
                    .withOpacity(0.5))));
  }
}

class ReportContents extends StatelessWidget {
  final ReportData reportData;
  const ReportContents({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Constants.defaultPadding),
      width: 350,
      decoration: BoxDecoration(
          color: Constants.bgColor,
          borderRadius: BorderRadius.circular(Constants.defaultPadding / 2)),
      child: FutureBuilder(
        future: AccountData.loadAccountPairDetails(
            reportData.report_sender, reportData.report_recepient,
            location: LatLng(reportData.report_location.latitude,
                reportData.report_location.longitude)),
        builder: (BuildContext context,
            AsyncSnapshot<UsersAdditionalInfo?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
                height: 200, child: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          UsersAdditionalInfo usersAdditionalInfo = snapshot.data!;

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ReportData
                      .reportDetails[reportData.report_type].reportType),
                  const SizedBox(width: Constants.defaultPadding),
                  Text(DateFormat('MMM d, y')
                      .format(reportData.timestamp.toDate())),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (reportData.report_type > 0 && reportData.report_type < 4)
                    Text(usersAdditionalInfo.locationData!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.5))),
                  const SizedBox(width: Constants.defaultPadding),
                  Text(
                      DateFormat('hh:mm a')
                          .format(reportData.timestamp.toDate()),
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.5))),
                ],
              ),
              const SizedBox(height: Constants.defaultPadding / 2),
              const Divider(color: Colors.white),
              const SizedBox(height: Constants.defaultPadding / 2),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        children: [
                          const WidgetSpan(child: SizedBox(width: 40.0)),
                          TextSpan(
                              text: reportData.report_content,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w200)),
                        ],
                      )),
                ],
              ),
              const SizedBox(height: Constants.defaultPadding / 2),
              const Divider(color: Colors.white),
              const SizedBox(height: Constants.defaultPadding / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Reporter"),
                  const SizedBox(width: Constants.defaultPadding),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(usersAdditionalInfo.senderData != null
                          ? usersAdditionalInfo.senderData!.account_name
                          : "No Data"),
                      Text("<${reportData.report_sender}>",
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Driver"),
                  const SizedBox(width: Constants.defaultPadding),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(usersAdditionalInfo.recepientData != null
                          ? usersAdditionalInfo.recepientData!.account_name
                          : "No Data"),
                      Text("<${reportData.report_recepient}>",
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Jeep"),
                  const SizedBox(width: Constants.defaultPadding),
                  Text(reportData.report_jeepney)
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
