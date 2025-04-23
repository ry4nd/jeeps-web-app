import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:transitrack_web/services/find_location.dart';

import '../../../models/route_model.dart';
import '../../../style/constants.dart';

// This widget allows the route manager to edit the route coordinates

class CoordinatesSettings extends StatefulWidget {
  final RouteData route;
  // used to communicate changes in mode: -1 = no mode | 0 = edit | 1 = add/delete | -2 = close/ reset
  final ValueChanged<int> coordConfig;
  final ValueChanged<int> stopsConfig;
  final LatLng? selectedStop; // Add selectedStop to display it

  const CoordinatesSettings(
      {super.key,
      required this.route,
      required this.coordConfig,
      required this.stopsConfig,
      required this.selectedStop});

  @override
  State<CoordinatesSettings> createState() => _CoordinatesSettingsState();
}

class _CoordinatesSettingsState extends State<CoordinatesSettings> {
  // this tracks the mode: -1 = no mode selected | 0 = edit | 1 = add/remove
  int routeCoordSettingsMode = -1;
  int stopsCoordSettingsMode = -1;
  String? address; // To store the fetched address

  @override
  void didUpdateWidget(covariant CoordinatesSettings oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the selectedStop has changed
    if (widget.selectedStop != oldWidget.selectedStop) {
      _fetchAddress(); // Fetch the address for the new selectedStop
    }
  }

  Future<void> _fetchAddress() async {
    if (widget.selectedStop != null) {
      try {
        // Call the asynchronous findAddress function
        String fetchedAddress = await findAddress(widget.selectedStop!, true);

        // Update the state with the fetched address
        setState(() {
          address = fetchedAddress;
        });
      } catch (e) {
        // Handle errors (e.g., network issues)
        setState(() {
          address = "Unable to fetch address";
        });
      }
    } else {
      // If no stop is selected, clear the address
      setState(() {
        address = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align everything to the left
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (stopsCoordSettingsMode != 0 && stopsCoordSettingsMode != 1) ...[
          // For route coordinates
          buildHeader('Coordinates', withBackButton: true),
          const SizedBox(height: Constants.defaultPadding),
          buildModeButtons(
            routeCoordSettingsMode,
            updateRouteCoordSettingsMode,
            updateRouteCoordCancelMode,
            enabled: stopsCoordSettingsMode != 0 && stopsCoordSettingsMode != 1,
          ),
          const SizedBox(height: Constants.defaultPadding),
        ],

        // For stops coordinates
        buildHeader('Usual Stops'),
        const SizedBox(height: Constants.defaultPadding),
        buildModeButtons(
          stopsCoordSettingsMode,
          updateStopsCoordSettingsMode,
          updateStopsCoordCancelMode,
          enabled: routeCoordSettingsMode != 0 && routeCoordSettingsMode != 1,
        ),

        // Display the selected stop
        if (widget.selectedStop != null) ...[
          const SizedBox(height: Constants.defaultPadding),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align content to the left
            children: [
              Text(
                "Selected Stop", // Display the fetched address
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                textAlign: TextAlign.start,
              ),
              Text(
                address ?? "Fetching...", // Display the fetched address
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget buildHeader(String title, {bool withBackButton = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        if (routeCoordSettingsMode == -1 &&
            stopsCoordSettingsMode == -1 &&
            withBackButton)
          GestureDetector(
            onTap: () {
              widget.coordConfig(-1); // Notify parent: No mode selected
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
  Widget buildModeButtons(
      int mode, ValueChanged<int> onModeChange, ValueChanged<int> onModeCancel,
      {bool enabled = true}) {
    return Row(
      children: [
        if (mode == -1)
          buildButton(Icons.edit, "Edit", 0, 0.6, onModeChange,
              enabled: enabled),
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
            enabled: enabled,
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
      {bool isAddRemove = false, bool enabled = true}) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled
            ? () {
                onModeChange(newMode);
              }
            : null, // Disable onTap if the button is not enabled
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: Constants.defaultPadding),

          color: enabled
              ? Color(widget.route.routeColor).withValues(alpha: alpha)
              : Color(widget.route.routeColor)
                  .withValues(alpha: 0.1), // Highlight active mode
          child: Center(
            child: isAddRemove
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: enabled
                            ? Colors.white
                            : Colors.white.withValues(
                                alpha: 0.1), // Reduced opacity when disabled
                      ),
                      Text(
                        "/",
                        style: TextStyle(
                          color: enabled
                              ? Colors.white
                              : Colors.white.withValues(
                                  alpha: 0.1), // Reduced opacity when disabled
                        ),
                      ),
                      Icon(
                        Icons.remove,
                        color: enabled
                            ? Colors.white
                            : Colors.white.withValues(
                                alpha: 0.1), // Reduced opacity when disabled
                      ),
                    ],
                  )
                : Icon(
                    icon,
                    color: enabled
                        ? Colors.white
                        : Colors.white.withValues(
                            alpha: 0.1), // Reduced opacity when disabled
                  ),
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
