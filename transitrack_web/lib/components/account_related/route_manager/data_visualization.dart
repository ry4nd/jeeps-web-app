import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/feedbacks_table.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/jeep_historical.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/manage_drivers_table.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/manage_commuters_table.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/reports_table.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization/shared_locations_page.dart';
import 'package:transitrack_web/components/left_drawer/logo.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';
import 'package:transitrack_web/style/style.dart';

// This widget holds all data visualization features for the route manager account.

class DataVisualizationTab extends StatefulWidget {
  final RouteData route;
  const DataVisualizationTab({super.key, required this.route});

  @override
  State<DataVisualizationTab> createState() => _DataVisualizationTabState();
}

class DataVisualizationMenuList {
  String menuName;
  String? menuSubtitle;
  Widget menuWidget;

  DataVisualizationMenuList(
      {required this.menuName, required this.menuWidget, this.menuSubtitle});
}

class _DataVisualizationTabState extends State<DataVisualizationTab> {
  late List<DataVisualizationMenuList> menuList = [
    DataVisualizationMenuList(
        menuName: "Feedbacks",
        menuWidget: PointerInterceptor(
          child: FeedbacksTable(
            route: widget.route,
          ),
        )),
    DataVisualizationMenuList(
        menuName: "Reports",
        menuWidget: PointerInterceptor(
          child: ReportsTable(route: widget.route, isDispose: selected == 1),
        )),
    DataVisualizationMenuList(
        menuName: "Shared Locations",
        menuWidget: SharedLocationsPage(routeData: widget.route)),
    DataVisualizationMenuList(
        menuName: "PUV Locations",
        menuWidget: JeepHistoricalPage(
          routeData: widget.route,
        )),
    DataVisualizationMenuList(
        menuName: "Drivers",
        menuWidget: ManageDriversTable(
          route: widget.route,
        )),
    DataVisualizationMenuList(
        menuName: "Commuters",
        menuWidget: ManageCommutersTable(
          route: widget.route,
        )),
  ];

  int selected = -1;

  void selectOption(int index) {
    setState(() {
      selected = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: Constants.defaultPadding,
          right: Constants.defaultPadding,
          bottom: Constants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Space between text and button
            children: [
              PrimaryText(
                text: widget.route.routeName,
                color: Colors.white,
                size: 40,
                fontWeight: FontWeight.w700,
              ),
              IconButton(
                icon:
                    const Icon(Icons.close, color: Colors.white), // Close icon
                onPressed: () {
                  Navigator.pop(context); // Close the current screen
                },
                tooltip: "Close", // Tooltip for accessibility
              ),
            ],
          ),
          const Divider(color: Colors.white),
          const SizedBox(height: Constants.defaultPadding),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: menuList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      selected: selected == index,
                      selectedColor: Constants.bgColor,
                      selectedTileColor: Color(widget.route.routeColor),
                      hoverColor: Colors.white.withValues(alpha: 0.2),
                      subtitle: menuList[index].menuSubtitle != null
                          ? Text(menuList[index].menuSubtitle!)
                          : null,
                      title: Text(menuList[index].menuName),
                      onTap: () {
                        if (selected == index) {
                          selectOption(-1);
                        } else {
                          selectOption(index);
                        }
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: selected == -1
                    ? const SizedBox(
                        height: 500,
                        child: Center(
                          child: Logo(),
                        ))
                    : menuList[selected].menuWidget,
              )
            ],
          )
        ],
      ),
    );
  }
}
