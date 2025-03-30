import 'package:flutter/material.dart';

import '../../../models/route_model.dart';
import '../../../style/constants.dart';

// This widget allows the route manager to add and edit route stops for the fare matrix

class RouteStopsSettings extends StatefulWidget {
  final RouteData route;
  final ValueChanged<int> stopsConfig;
  const RouteStopsSettings(
      {super.key, required this.route, required this.stopsConfig});

  @override
  State<RouteStopsSettings> createState() => _RouteStopsSettingsState();
}

class _RouteStopsSettingsState extends State<RouteStopsSettings> {
  // this tracks the mode: -1 = no mode selected | 0 = edit | 1 = add/remove
  int mode = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Common Stops",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            GestureDetector(
                onTap: () {
                  // if no mode is selected
                  if (mode == -1) {
                    // Notify parent: No mode selected
                    widget.stopsConfig(-1);
                  } else {
                    //  otherwise, reset to no mode - close
                    setState(() {
                      mode = -1;
                    });
                    // Notify parent: Close/reset configuration
                    widget.stopsConfig(-2);
                  }
                },
                child: Icon(mode == -1
                    ? Icons.keyboard_backspace_outlined
                    : Icons.close))
          ],
        ),
        const SizedBox(height: Constants.defaultPadding),
        Row(
          children: [
            if (mode == -1 || mode == 0)
              Expanded(
                  child: GestureDetector(
                onTap: () {
                  if (mode == -1) {
                    setState(() {
                      mode = 0; // Enter edit mode
                    });
                    widget.stopsConfig(0); // Notify parent: Enter edit mode
                  } else if (mode == 0) {
                    setState(() {
                      mode = -1; // Exit edit mode
                    });
                    widget.stopsConfig(-1); // Notify parent: No mode selected
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: Constants.defaultPadding),
                  color: mode == 0
                      ? Color(widget.route.routeColor)
                      : Color(widget.route.routeColor).withValues(alpha: 0.6),
                  child: Center(
                    child: Icon(mode == 0 ? Icons.save : Icons.edit),
                  ),
                ),
              )),
            if (mode == -1 || mode == 1)
              Expanded(
                  child: GestureDetector(
                      onTap: () {
                        if (mode == -1) {
                          setState(() {
                            mode = 1; // Enter add/remove mode
                          });
                          // Notify parent: Enter add/remove mode
                          widget.stopsConfig(1);
                        } else if (mode == 1) {
                          setState(() {
                            mode = -1; // Exit add/remove mode
                          });
                          widget.stopsConfig(
                              -1); // Notify parent: No mode selected
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: Constants.defaultPadding),
                        color: mode == 1
                            ? Color(widget.route.routeColor)
                            : Color(widget.route.routeColor)
                                .withValues(alpha: 0.5),
                        child: Center(
                            child: mode == 1
                                ? const Icon(Icons.save)
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add),
                                      Text("/"),
                                      Icon(Icons.remove)
                                    ],
                                  )),
                      )))
          ],
        )
      ],
    );
  }
}
