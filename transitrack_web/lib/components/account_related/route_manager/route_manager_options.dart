import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/components/account_related/route_manager/data_visualization.dart';
import 'package:transitrack_web/components/account_related/route_manager/route_coordinates_settings.dart';
import 'package:transitrack_web/components/account_related/route_manager/route_properties_settings.dart';
import '../../../models/route_model.dart';
import '../../../style/constants.dart';
import '../../account_related/route_manager/route_vehicles_settings.dart';
import '../../../models/jeep_model.dart';

// This widget allows the route manager to modify the route's properties, coordinates, and PUVs

class RouteManagerOptions extends StatefulWidget {
  final RouteData route;
  final List<JeepsAndDrivers> jeeps;
  final ValueChanged<int> coordConfig;
  final ValueChanged<JeepsAndDrivers> pressedJeep;
  const RouteManagerOptions(
      {super.key,
      required this.route,
      required this.jeeps,
      required this.pressedJeep,
      required this.coordConfig});

  @override
  State<RouteManagerOptions> createState() => _RouteManagerOptionsState();
}

class _RouteManagerOptionsState extends State<RouteManagerOptions> {
  int selected = -1;
  String optionTitle = "Route Management";

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selected != 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  optionTitle,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (selected != -1)
                  GestureDetector(
                      onTap: () {
                        setState(() {
                          selected = -1;
                          optionTitle = "Route Management";
                        });
                        widget.coordConfig(-2);
                      },
                      child: const Icon(
                        Icons.keyboard_backspace_outlined,
                      )),
                if (selected == -1)
                  GestureDetector(
                      onTap: () async {
                        AwesomeDialog(
                          dialogType: DialogType.noHeader,
                          context: (context),
                          body: PointerInterceptor(
                            child: DataVisualizationTab(route: widget.route),
                          ),
                        ).show();
                      },
                      child: const Icon(Icons.assessment_outlined))
              ],
            ),
          if (selected != 1) const SizedBox(height: Constants.defaultPadding),
          if (selected == -1)
            Row(
              children: [
                // Route Manager Properties
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        selected = 0;
                        optionTitle = "Properties";
                      });
                    },
                    child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: selected == 0
                              ? Color(widget.route.routeColor)
                              : Color(widget.route.routeColor)
                                  .withValues(alpha: 0.6),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_tree),
                            Text(
                              "Properties",
                              style: TextStyle(
                                fontSize: 10,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          ],
                        )),
                  ),
                ),

                // Route Manager Coordinates
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        selected = 1;
                      });
                    },
                    child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: selected == 1
                              ? Color(widget.route.routeColor)
                              : Color(widget.route.routeColor)
                                  .withValues(alpha: 0.5),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.line_axis),
                            Text(
                              "Coordinates",
                              style: TextStyle(
                                fontSize: 10,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          ],
                        )),
                  ),
                ),

                // Route Manager Vehicles
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        selected = 2;
                        optionTitle = "Vehicles";
                      });
                    },
                    child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: selected == 2
                              ? Color(widget.route.routeColor)
                              : Color(widget.route.routeColor)
                                  .withValues(alpha: 0.4),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_bus),
                            Text(
                              "Vehicles",
                              style: TextStyle(
                                fontSize: 10,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          ],
                        )),
                  ),
                ),
              ],
            ),
          if (selected == 0)
            SizedBox(
              height: 250,
              child: PointerInterceptor(
                child: PropertiesSettings(route: widget.route),
              ),
            ),
          if (selected == 1)
            CoordinatesSettings(
                route: widget.route,
                coordConfig: (int coordConfig) {
                  if (coordConfig == -1) {
                    setState(() {
                      selected = -1;
                    });
                  }
                  widget.coordConfig(coordConfig);
                }),
          if (selected == 2)
            SizedBox(
              height: 250,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: VehiclesSettings(
                    route: widget.route,
                    jeeps: widget.jeeps,
                    pressedJeep: (JeepsAndDrivers jeep) {
                      widget.pressedJeep(jeep);
                    }),
              ),
            )
        ],
      ),
    );
  }
}
