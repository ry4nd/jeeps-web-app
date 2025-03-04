import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/filters.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/selected_commuter_details.dart';
import 'package:transitrack_web/components/left_drawer/logo.dart';
import 'package:transitrack_web/models/account_model.dart';
import 'package:transitrack_web/models/feedback_model.dart';
import 'package:transitrack_web/models/filter_model.dart';
import 'package:transitrack_web/models/jeep_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

class ManageCommutersTable extends StatefulWidget {
  final RouteData route;
  const ManageCommutersTable({super.key, required this.route});

  @override
  State<ManageCommutersTable> createState() => _ManageCommutersTableState();
}

class JeepDataRatingAndAddress {
  List<FeedbackData>? rating;
  JeepData? jeepData;
  String? address;

  JeepDataRatingAndAddress(
      {required this.rating, required this.jeepData, required this.address});
}

class _ManageCommutersTableState extends State<ManageCommutersTable> {
  TextEditingController searchController = TextEditingController();

  int selected = -1;
  AccountData? selectedCommuter;
  List<RouteData> routes = [];

  List<AccountData>? commuters;

  String searchString = "";

  FilterParameters orderBy =
      FilterParameters(filterSearch: "account_name", filterDescending: true);

  @override
  void initState() {
    super.initState();

    loadRoutes();
  }

  void select(int index, AccountData? account) {
    setState(() {
      selected = index;
      selectedCommuter = account;
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

  Future<void> loadCommuters() async {
    setState(() {
      commuters = null;
    });
    select(-1, null);

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('accounts')
        // filter to only include commuter accounts
        .where('account_type', isEqualTo: 0);

    query = query.orderBy(orderBy.filterSearch,
        descending: orderBy.filterDescending);

    QuerySnapshot querySnapshot = await query.get();

    setState(() {
      commuters = querySnapshot.docs.map((DocumentSnapshot document) {
        return AccountData.fromSnapshot(document);
      }).toList();
    });
  }

  void onSearchChanged(String value) {
    setState(() {
      searchString = value;
    });

    if (value.isNotEmpty) {
      if (commuters == null) {
        loadCommuters();
      }
    } else {
      // Clear the list when search is empty
      setState(() {
        commuters = null;
      });
    }

    select(-1, null);
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
                        Colors.white.withValues(alpha: 0.2)),
                    elevation: WidgetStateProperty.all(0.0),
                    onChanged: onSearchChanged,
                    hintText: 'Search Account Name',
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
                              if (searchString.isNotEmpty) {
                                // Reload commuters based on the current search string
                                loadCommuters();
                              } else {
                                // Clear commuters when search bar is empty
                                setState(() {
                                  commuters = null;
                                });
                              }
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
                                dropdownList: FilterParameters.commutersOrderBy,
                                oldFilter: orderBy,
                                newFilter: (FilterParameters newFilter) {
                                  setState(() {
                                    orderBy = newFilter;
                                  });
                                  loadCommuters();
                                },
                              )),
                            ).show(),
                            icon: const Icon(Icons.filter_list),
                          )
                        ],
                      )
                    ],
                  ),
                  if (commuters != null)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                          Constants.defaultPadding,
                          Constants.defaultPadding,
                          Constants.defaultPadding,
                          0.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text("Name"), Text("Status")]),
                    ),
                  if (commuters != null)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: commuters!.length,
                          itemBuilder: (context, index) {
                            AccountData commuter = commuters![index];

                            if (searchString.isNotEmpty &&
                                !commuter.account_name
                                    .toLowerCase()
                                    .contains(searchString.toLowerCase())) {
                              return const SizedBox();
                            }

                            return ListTile(
                              onTap: () async {
                                if (selected == index) {
                                  select(-1, null);
                                } else {
                                  select(index, commuter);
                                }
                              },
                              selected: index == selected,
                              selectedColor: Colors.white,
                              selectedTileColor: Color(widget.route.routeColor)
                                  .withValues(alpha: 0.1),
                              hoverColor: Colors.white.withValues(alpha: 0.2),
                              subtitleTextStyle: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.75),
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12),
                              title: Text(
                                commuter.account_name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                "<${commuter.account_email}>",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                commuter.account_banned
                                    ? Icons.no_accounts_outlined
                                    : Icons.account_circle_outlined,
                                color: commuter.account_banned
                                    ? Colors.red
                                    : Colors.grey,
                                size: 20,
                              ),
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
              child: Center(
                child: selectedCommuter != null
                    ? SelectedCommuterDetails(
                        driver: selectedCommuter!,
                        routes: routes,
                        route: widget.route,
                        loadCommuters: () => loadCommuters(),
                      )
                    : const Logo(),
              ),
            )
          ],
        ));
  }
}
