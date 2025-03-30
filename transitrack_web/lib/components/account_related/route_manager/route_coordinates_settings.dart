import 'package:flutter/material.dart';

import '../../../models/route_model.dart';
import '../../../style/constants.dart';

// This widget allows the route manager to edit the route coordinates

class CoordinatesSettings extends StatefulWidget {
  final RouteData route;
  // used to communicate changes in mode: -1 = no mode | 0 = edit | 1 = add/delete | -2 = close/ reset
  final ValueChanged<int> coordConfig;
  const CoordinatesSettings(
      {super.key, required this.route, required this.coordConfig});

  @override
  State<CoordinatesSettings> createState() => _CoordinatesSettingsState();
}

class _CoordinatesSettingsState extends State<CoordinatesSettings> {
  // this tracks the mode: -1 = no mode selected | 0 = edit | 1 = add/remove
  int selected = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildHeadear(),
        const SizedBox(height: Constants.defaultPadding),
        buildModeButtons(),
      ],
    );
  }

  Widget buildHeadear() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Coordinates",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        if (selected == -1)
          GestureDetector(
            onTap: () {
              widget.coordConfig(-1); // Notify parent: No mode selected
            },
            child: const Icon(Icons.keyboard_backspace_outlined),
          ),
      ],
    );
  }

  // ... is a spread operator - it takes a list of iterable and spread them in the widget tree
  // this is an alternative to using another Row for the build button save and cancel
  Widget buildModeButtons() {
    return Row(
      children: [
        if (selected == -1) buildButton(Icons.edit, "Edit", 0, 0.6),
        if (selected == 0) ...[
          buildButton(Icons.save, "Save", -1, 0.6),
          buildCancelButton(),
        ],
        if (selected == -1)
          buildButton(
            null,
            "Add/Remove",
            1,
            0.5,
            isAddRemove: true,
          ),
        if (selected == 1) ...[
          buildButton(Icons.save, "Save", -1, 0.6),
          buildCancelButton(),
        ],
      ],
    );
  }

  Widget buildButton(IconData? icon, String label, int newState, double alpha,
      {bool isAddRemove = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selected = newState; // Update the selected mode
          });
          widget.coordConfig(newState); // Notify parent of the mode change
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: Constants.defaultPadding),
          color: Color(widget.route.routeColor)
              .withValues(alpha: alpha), // Highlight active mode
          child: Center(
            child: isAddRemove
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add),
                      Text("/"),
                      Icon(Icons.remove),
                    ],
                  )
                : Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget buildCancelButton() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selected = -1; // Reset to no mode
          });
          widget.coordConfig(-2); // Notify parent: Close/reset configuration
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: Constants.defaultPadding),
          color: Color(widget.route.routeColor).withValues(alpha: 0.5),
          child: const Center(
            child: Icon(Icons.close, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
