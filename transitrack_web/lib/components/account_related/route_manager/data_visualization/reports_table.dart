import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/filters.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/reports_map.dart';
import 'package:transitrack_web/components/acknowledge_report.dart';
import 'package:transitrack_web/components/attach_img_button.dart';
import 'package:transitrack_web/components/text_field.dart';
import 'package:transitrack_web/models/account_model.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/models/filter_model.dart';
import 'package:transitrack_web/models/report_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // For report acknowledgement
  // TextEditingController recipientEmailController = TextEditingController();
  TextEditingController emailController = TextEditingController();

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

  // display image as a dialog for RM
  void viewImg(String imgUrl) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      width: 1000,
      body: PointerInterceptor(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(30.0),
              child: Image.network(
                imgUrl,
                fit: BoxFit.contain,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) {
                  return const Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.red),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      showCloseIcon: true,
      dismissOnBackKeyPress: true,
      dismissOnTouchOutside: true,
    ).show();
  }

  Future<void> deleteReportDialog(
      BuildContext context, ReportData reportData, Function loadReports) async {
    Future<void> deleteReport(String senderEmail, Timestamp timestamp) async {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('reports')
            .where('report_sender', isEqualTo: senderEmail)
            .where('timestamp', isEqualTo: timestamp)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.delete();
        }
      } catch (error) {
        debugPrint("Error deleting report: $error");
      }
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      width: 400,
      body: PointerInterceptor(
        child: Column(
          children: [
            const Text(
              "You are about to delete this report. This action cannot be undone.",
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Constants.defaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.bgColor,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: Constants.defaultPadding / 2),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                  ),
                  onPressed: () async {
                    await deleteReport(
                        reportData.report_sender, reportData.timestamp);

                    await AwesomeDialog(
                      context: context,
                      width: 150,
                      padding: const EdgeInsets.only(
                          bottom: Constants.defaultPadding),
                      dialogType: DialogType.noHeader,
                      body:
                          const CircularProgressIndicator(color: Colors.white),
                      dismissOnBackKeyPress: false,
                      dismissOnTouchOutside: false,
                      autoHide: const Duration(milliseconds: 1000),
                    ).show();

                    loadReports();
                    Navigator.pop(context); // Close the dialog after deletion
                  },
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Constants.defaultPadding * 1.5),
          ],
        ),
      ),
      dismissOnBackKeyPress: true,
      dismissOnTouchOutside: true,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: Constants.defaultPadding),
        child: Row(
          children: [
            SizedBox(
              height: 500,
              width: 500,
              child: Column(
                children: [
                  SearchBar(
                    controller: searchController,
                    overlayColor: WidgetStateProperty.all(
                        Colors.white.withValues(alpha: 0.2)),
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
                    shape:
                        WidgetStateProperty.all(const ContinuousRectangleBorder(
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
                        height: 300,
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
                                  .withValues(alpha: 0.1),
                              hoverColor: Colors.white.withValues(alpha: 0.2),
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
              height: 500,
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
                        child: ReportContents(
                          reportData: selectedReport!,
                          viewImg: viewImg,
                          loadReports: loadReports,
                          acknowledgeReport: (report) => acknowledgeReport(
                              context,
                              report,
                              emailController,
                              widget.route.routeName),
                          deleteReport: (report) => deleteReportDialog(
                            context,
                            report,
                            loadReports,
                          ),
                        )),
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
                    .withValues(alpha: 0.5))));
  }
}

class ReportContents extends StatelessWidget {
  final ReportData reportData;
  final Function(String) viewImg;
  final Function loadReports;
  final Function(ReportData) acknowledgeReport;
  final Function(ReportData) deleteReport;
  const ReportContents(
      {super.key,
      required this.reportData,
      required this.viewImg,
      required this.loadReports,
      required this.acknowledgeReport,
      required this.deleteReport});

  // Future<void> deleteReport(String senderEmail, Timestamp timestamp) async {
  //   try {
  //     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  //         .collection('reports')
  //         .where('report_sender', isEqualTo: senderEmail)
  //         .where('timestamp', isEqualTo: timestamp)
  //         .limit(1)
  //         .get();

  //     if (querySnapshot.docs.isNotEmpty) {
  //       await querySnapshot.docs.first.reference.delete();
  //     }
  //   } catch (error) {
  //     debugPrint("Error deleting report: $error");
  //   }
  // }

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('MMM d, y')
                          .format(reportData.timestamp.toDate())),
                      Text(
                          DateFormat('hh:mm a')
                              .format(reportData.timestamp.toDate()),
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => deleteReport(reportData),
                    label: Text(
                      "Delete",
                      style: TextStyle(color: Colors.red[600]),
                    ),
                    icon: Icon(Icons.delete, color: Colors.red[600]),
                  ),
                ],
              ),
              const SizedBox(height: Constants.defaultPadding / 2),
              const Divider(color: Colors.white),
              const SizedBox(height: Constants.defaultPadding / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(ReportData
                        .reportDetails[reportData.report_type].reportType),
                  ),
                  if (reportData.report_type > 0 && reportData.report_type < 4)
                    Expanded(
                      child: Text(usersAdditionalInfo.locationData!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.5))),
                    ),
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
                          TextSpan(
                              text: reportData.report_content,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w200)),
                        ],
                      )),
                  const SizedBox(height: Constants.defaultPadding / 2),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 5.0,
                      children: [
                        AttachmentButton(
                            onPressed: () => acknowledgeReport(reportData),
                            label: "Acknowledge",
                            icon: Icons.send),
                        if (reportData.report_img != null &&
                            reportData.report_img!.isNotEmpty)
                          AttachmentButton(
                              onPressed: () => viewImg(reportData.report_img!),
                              label: "View Image",
                              icon: Icons.photo),
                      ]),
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
                              color: Colors.white.withValues(alpha: 0.5))),
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
                              color: Colors.white.withValues(alpha: 0.5))),
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
