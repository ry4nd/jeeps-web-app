import 'package:flutter/material.dart';

import '../../../models/route_model.dart';
import '../../../style/constants.dart';

// This widget allows the route manager to edit the route coordinates

class CoordinatesSettings extends StatefulWidget {
  final RouteData route;
  // used to communicate changes in mode: -1 = no mode | 0 = edit | 1 = add/delete | -2 = close/ reset
  final ValueChanged<int> coordConfig;
  final ValueChanged<int> stopsConfig;
  const CoordinatesSettings(
      {super.key,
      required this.route,
      required this.coordConfig,
      required this.stopsConfig});

  @override
  State<CoordinatesSettings> createState() => _CoordinatesSettingsState();
}

class _CoordinatesSettingsState extends State<CoordinatesSettings> {
  // this tracks the mode: -1 = no mode selected | 0 = edit | 1 = add/remove
  int routeCoordSettingsMode = -1;
  int stopsCoordSettingsMode = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // For route coordinates
        buildHeader('Coordinates', routeCoordSettingsMode, widget.coordConfig,
            withBackButton: true),
        const SizedBox(height: Constants.defaultPadding),
        buildModeButtons(routeCoordSettingsMode, updateRouteCoordSettingsMode,
            updateRouteCoordCancelMode),

        // For stops coordinates
        const SizedBox(height: Constants.defaultPadding),
        buildHeader('Usual Stops', stopsCoordSettingsMode, widget.stopsConfig),
        const SizedBox(height: Constants.defaultPadding),
        buildModeButtons(stopsCoordSettingsMode, updateStopsCoordSettingsMode,
            updateStopsCoordCancelMode),
      ],
    );
  }

  Widget buildHeader(String title, int mode, ValueChanged<int> config,
      {bool withBackButton = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        if (mode == -1 && withBackButton)
          GestureDetector(
            onTap: () {
              config(mode); // Notify parent: No mode selected
            },
            child: const Icon(Icons.keyboard_backspace_outlined),
          ),
      ],
    );
  }

  void updateRouteCoordSettingsMode(int newMode) {
    setState(() {
      routeCoordSettingsMode = newMode; // Update the mode
    });
    widget.coordConfig(newMode); // Notify the parent widget
  }

  void updateRouteCoordCancelMode(int newMode) {
    setState(() {
      routeCoordSettingsMode = newMode; // Update the mode
    });
    widget.coordConfig(-2); // Notify the parent widget
  }

  void updateStopsCoordSettingsMode(int newMode) {
    setState(() {
      stopsCoordSettingsMode = newMode; // Update the mode
    });
    widget.stopsConfig(newMode); // Notify the parent widget
  }

  void updateStopsCoordCancelMode(int newMode) {
    setState(() {
      stopsCoordSettingsMode = newMode; // Update the mode
    });
    widget.stopsConfig(-2); // Notify the parent widget
  }

  // ... is a spread operator - it takes a list of iterable and spread them in the widget tree
  // this is an alternative to using another Row for the build button save and cancel
  Widget buildModeButtons(int mode, ValueChanged<int> onModeChange,
      ValueChanged<int> onModeCancel) {
    return Row(
      children: [
        if (mode == -1) buildButton(Icons.edit, "Edit", 0, 0.6, onModeChange),
        if (mode == 0) ...[
          buildButton(Icons.save, "Save", -1, 0.6, onModeChange),
          buildCancelButton(-1, onModeCancel),
        ],
        if (mode == -1)
          buildButton(
            null,
            "Add/Remove",
            1,
            0.5,
            onModeChange,
            isAddRemove: true,
          ),
        if (mode == 1) ...[
          buildButton(Icons.save, "Save", -1, 0.6, onModeChange),
          buildCancelButton(-1, onModeCancel),
        ],
      ],
    );
  }

  Widget buildButton(IconData? icon, String label, int newMode, double alpha,
      ValueChanged<int> onModeChange,
      {bool isAddRemove = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          onModeChange(newMode);
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

  Widget buildCancelButton(int newMode, ValueChanged<int> config) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          config(newMode); // Notify parent: Close/reset configuration
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
