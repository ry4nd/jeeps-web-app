import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/filters.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/selected_driver_details.dart';
import 'package:transitrack_web/components/left_drawer/logo.dart';
import 'package:transitrack_web/models/account_model.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/models/filter_model.dart';
import 'package:transitrack_web/models/jeep_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

// This is the Manage Driver tab of the data visualization panel of the route manager.

class ManageDriversTable extends StatefulWidget {
  final RouteData route;
  const ManageDriversTable({super.key, required this.route});

  @override
  State<ManageDriversTable> createState() => _ManageDriversTableState();
}

class JeepDataRatingAndAddress {
  List<FeedbackData>? rating;
  JeepData? jeepData;
  String? address;

  JeepDataRatingAndAddress(
      {required this.rating, required this.jeepData, required this.address});
}

class _ManageDriversTableState extends State<ManageDriversTable> {
  TextEditingController searchController = TextEditingController();

  int selected = -1;
  late AccountData? selectedDriver;
  List<RouteData> routes = [];

  List<AccountData>? drivers;

  String searchString = "";

  FilterParameters orderBy =
      FilterParameters(filterSearch: "account_name", filterDescending: true);

  @override
  void initState() {
    super.initState();

    loadRoutes();
    loadDrivers();
  }

  void select(int index, AccountData? account) {
    setState(() {
      selected = index;
      selectedDriver = account;
    });
  }

  Future<void> loadRoutes() async {
    routes.clear();

    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('routes').orderBy("route_id");

    QuerySnapshot querySnapshot = await query.get();

    setState(() {
      routes = querySnapshot.docs.map((DocumentSnapshot document) {
        return RouteData.fromFirestore(document);
      }).toList();
    });
  }

  Future<void> loadDrivers() async {
    setState(() {
      drivers = null;
    });
    select(-1, null);

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('accounts')
        .where('account_type', isEqualTo: 1)
        .where('route_id', isEqualTo: widget.route.routeId);

    query = query.orderBy(orderBy.filterSearch,
        descending: orderBy.filterDescending);

    QuerySnapshot querySnapshot = await query.get();

    setState(() {
      drivers = querySnapshot.docs.map((DocumentSnapshot document) {
        return AccountData.fromSnapshot(document);
      }).toList();
    });
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
                    hintText: 'Search Account Name',
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
                                drivers = null;
                              });
                              loadDrivers();
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
                                dropdownList: FilterParameters.driversOrderBy,
                                oldFilter: orderBy,
                                newFilter: (FilterParameters newFilter) {
                                  setState(() {
                                    orderBy = newFilter;
                                  });
                                  loadDrivers();
                                },
                              )),
                            ).show(),
                            icon: const Icon(Icons.filter_list),
                          )
                        ],
                      )
                    ],
                  ),
                  if (drivers != null)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: Constants.defaultPadding),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text("Verified"),
                                SizedBox(width: Constants.defaultPadding * 1.5),
                                Text("Name")
                              ],
                            ),
                            Text("PUV Operating")
                          ]),
                    ),
                  if (drivers == null)
                    SizedBox(
                        height: 500,
                        child: Center(
                            child: CircularProgressIndicator(
                          color: Color(widget.route.routeColor),
                        ))),
                  if (drivers != null)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: drivers!.length,
                          itemBuilder: (context, index) {
                            AccountData driver = drivers![index];

                            if (searchString.isNotEmpty &&
                                !driver.account_name
                                    .toLowerCase()
                                    .contains(searchString.toLowerCase())) {
                              return const SizedBox();
                            }

                            return ListTile(
                                onTap: () async {
                                  if (selected == index) {
                                    select(-1, null);
                                  } else {
                                    select(index, driver);
                                  }
                                },
                                selected: index == selected,
                                selectedColor: Colors.white,
                                selectedTileColor:
                                    Color(widget.route.routeColor)
                                        .withOpacity(0.1),
                                hoverColor: Colors.white.withOpacity(0.2),
                                subtitleTextStyle: TextStyle(
                                    color: Colors.grey.withOpacity(0.75),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12),
                                leading: Padding(
                                  padding: const EdgeInsets.only(
                                      left: Constants.defaultPadding + 5),
                                  child: Icon(
                                    driver.is_verified
                                        ? Icons.verified_user
                                        : Icons.remove_moderator,
                                    color: driver.is_verified
                                        ? Colors.blue
                                        : Colors.grey,
                                    size: 15,
                                  ),
                                ),
                                title: Padding(
                                  padding: const EdgeInsets.only(
                                      left: Constants.defaultPadding * 2),
                                  child: Text(
                                    driver.account_name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(
                                      left: Constants.defaultPadding * 2),
                                  child: Text(
                                    "<${driver.account_email}>",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: Text(driver.jeep_driving != ""
                                    ? driver.jeep_driving!
                                    : "NA"));
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Constants.defaultPadding),
            Expanded(
              child: Center(
                child: selectedDriver != null
                    ? SelectedDriverDetails(
                        driver: selectedDriver!,
                        routes: routes,
                        route: widget.route,
                        loadDrivers: () => loadDrivers(),
                      )
                    : const Logo(),
              ),
            )
          ],
        ));
  }
}
