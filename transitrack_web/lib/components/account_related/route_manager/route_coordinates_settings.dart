import 'package:flutter/material.dart';

import '../../../models/route_model.dart';
import '../../../style/constants.dart';

// This widget allows the route manager to edit the route coordinates

class CoordinatesSettings extends StatefulWidget {
  final RouteData route;
  final ValueChanged<int> coordConfig;
  const CoordinatesSettings(
      {super.key, required this.route, required this.coordConfig});

  @override
  State<CoordinatesSettings> createState() => _CoordinatesSettingsState();
}

class _CoordinatesSettingsState extends State<CoordinatesSettings> {
  int selected = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Coordinates",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            GestureDetector(
                onTap: () {
                  if (selected == -1) {
                    widget.coordConfig(-1);
                  } else {
                    setState(() {
                      selected = -1;
                    });
                    widget.coordConfig(-2);
                  }
                },
                child: Icon(selected == -1
                    ? Icons.keyboard_backspace_outlined
                    : Icons.close))
          ],
        ),
        const SizedBox(height: Constants.defaultPadding),
        Row(
          children: [
            if (selected == -1 || selected == 0)
              Expanded(
                  child: GestureDetector(
                onTap: () {
                  if (selected == -1) {
                    setState(() {
                      selected = 0;
                    });
                    widget.coordConfig(0);
                  } else if (selected == 0) {
                    setState(() {
                      selected = -1;
                    });
                    widget.coordConfig(-1);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: Constants.defaultPadding),
                  color: selected == 0
                      ? Color(widget.route.routeColor)
                      : Color(widget.route.routeColor).withValues(alpha: 0.6),
                  child: Center(
                    child: Icon(selected == 0 ? Icons.save : Icons.edit),
                  ),
                ),
              )),
            if (selected == -1 || selected == 1)
              Expanded(
                  child: GestureDetector(
                onTap: () {
                  if (selected == -1) {
                    setState(() {
                      selected = 1;
                    });
                    widget.coordConfig(1);
                  } else if (selected == 1) {
                    setState(() {
                      selected = -1;
                    });
                    widget.coordConfig(-1);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: Constants.defaultPadding),
                  color: selected == 1
                      ? Color(widget.route.routeColor)
                      : Color(widget.route.routeColor).withValues(alpha: 0.5),
                  child: Center(
                      child: selected == 1
                          ? const Icon(Icons.save)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add),
                                Text("/"),
                                Icon(Icons.remove)
                              ],
                            )),
                ),
              ))
          ],
        ),
      ],
    );
  }
}
