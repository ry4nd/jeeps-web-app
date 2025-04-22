import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

import 'package:transitrack_web/services/find_location.dart';
import '../../services/nearest_index.dart';
import '../services/calculate_distance.dart';

class FareMatrix extends StatefulWidget {
  final RouteData route;
  const FareMatrix({super.key, required this.route});

  @override
  FareMatrixState createState() => FareMatrixState();
}

class FareMatrixState extends State<FareMatrix> {
  late int computedFarePrice = 0;
  late int discountedFarePrice = 0;
  late double increasePerKm = 0;
  double totalDistance = 0.0;
  late String selectedFrom; // Default value for "From"
  late String selectedTo; // Default value for "To"
  late List<LatLng> stops = []; // stop coordinates
  late List<LatLng> routeCoordinates = [];
  late Map<LatLng, String> locations =
      {}; // Map to store coordinates and addresses

  @override
  void initState() {
    super.initState();

    stops = widget.route.stopsCoordinates;
    routeCoordinates = widget.route.routeCoordinates;
    increasePerKm = widget.route.perKmRate;

    // Populate the locations list for dropdown options
    convertCoordinates();
  }

  @override
  void didUpdateWidget(covariant FareMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if stopsCoordinates has changed
    if (widget.route.stopsCoordinates != oldWidget.route.stopsCoordinates) {
      setState(() {
        stops = widget.route.stopsCoordinates; // Update the stops list
        routeCoordinates =
            widget.route.routeCoordinates; // Update the route coordinates list
      });
      convertCoordinates(); // Refresh the dropdown options
    }
  }

  bool isLoading = true;

  void convertCoordinates() async {
    setState(() {
      isLoading = true;
    });

    Map<LatLng, String> updatedLocations = {};

    for (LatLng stop in stops) {
      String address =
          await findAddress(LatLng(stop.latitude, stop.longitude), true);
      updatedLocations[stop] = address;
    }

    setState(() {
      locations = updatedLocations;
      isLoading = false;

      if (locations.isNotEmpty) {
        selectedFrom = locations.values.first;
        selectedTo = locations.values.first;
        computeDistance();
      }
    });
  }

  void computeDistance() {
    totalDistance = 0.0;
    // Find the LatLng coordinates for the selected addresses
    LatLng? fromCoordinates = locations.entries
        .firstWhere((entry) => entry.value == selectedFrom)
        .key;
    LatLng? toCoordinates =
        locations.entries.firstWhere((entry) => entry.value == selectedTo).key;

    // Find the nearest points in the route for the start and end
    int indexFrom = findNearestLatLngIndex(fromCoordinates, routeCoordinates);
    int indexTo = findNearestLatLngIndex(toCoordinates, routeCoordinates);
    // print('From: $indexFrom');
    // print('To: $indexTo');

    if (widget.route.isClockwise) {
      // Traverse the array clockwise
      for (int i = indexFrom;
          i != indexTo;
          i = (i + 1) % routeCoordinates.length) {
        // print(
        //     'Calculating distance between: ${routeCoordinates[i]} and ${routeCoordinates[(i + 1) % routeCoordinates.length]}');
        totalDistance += calculateDistance(
          routeCoordinates[i],
          routeCoordinates[(i + 1) % routeCoordinates.length],
        );
      }
    } else {
      // Reverse the array and traverse counterclockwise
      for (int i = indexFrom;
          i != indexTo;
          i = (i - 1 + routeCoordinates.length) % routeCoordinates.length) {
        // print(
        //     'Calculating distance between: ${routeCoordinates[i]} and ${routeCoordinates[(i - 1 + routeCoordinates.length) % routeCoordinates.length]}');
        totalDistance += calculateDistance(
          routeCoordinates[i],
          routeCoordinates[
              (i - 1 + routeCoordinates.length) % routeCoordinates.length],
        );
      }
    }

    print('Total Distance: $totalDistance');
    computeFarePrice();
  }

  void computeFarePrice() {
    double baseFare = widget.route.routeFare; // Base fare from the route
    double additionalFare = 0;
    int totalFare = 0;

    // Round totalDistance based on the decimal part
    double roundedDistance = (totalDistance % 1 > 0.8)
        ? totalDistance.ceilToDouble() // Round up
        : totalDistance.floorToDouble(); // Round down

    // Add +1 for every additional 4 km beyond the first 4 km
    if (totalDistance > 4) {
      additionalFare =
          (roundedDistance - 4) * increasePerKm; // +2 for each 4 km
    }

    // Compute the total fare
    totalFare = (baseFare + additionalFare).toInt();

    // Update the state with the computed fare
    setState(() {
      computedFarePrice = totalFare;
      discountedFarePrice = (totalFare * 0.8).ceil();
    });
    // print('Rounded Distance: $roundedDistance');
    // print('Base Fare: $baseFare');
    // print('Additional Fare: $additionalFare');
    // print('Total Fare: $computedFarePrice');
    // print('Discounted Fare: $discountedFarePrice');
  }

  Widget buildDropdown({
    required String label,
    required String selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownMenu(
      label: Text(label),
      width: 350,
      menuHeight: 250,
      enableFilter: true,
      requestFocusOnTap: true,
      initialSelection: selectedValue,
      onSelected: (newValue) {
        if (newValue is String) {
          onChanged(newValue);
        }
      },
      dropdownMenuEntries: locations.values.map((String address) {
        return DropdownMenuEntry<String>(
          value: address, // Use the address as the dropdown value
          label: address, // Display the address in the dropdown
        );
      }).toList(),
    );
  }

  Widget buildDropdowns({required VoidCallback onDropdownChanged}) {
    return Column(
      children: [
        buildDropdown(
          label: 'From',
          selectedValue: selectedFrom,
          onChanged: (String? newValue) {
            setState(() {
              selectedFrom = newValue!;
            });
            computeDistance(); // Recalculate distance and fare
            onDropdownChanged(); // Notify the dialog to rebuild
          },
        ),
        SizedBox(height: Constants.defaultPadding),
        buildDropdown(
          label: 'To',
          selectedValue: selectedTo,
          onChanged: (String? newValue) {
            setState(() {
              selectedTo = newValue!;
            });
            computeDistance(); // Recalculate distance and fare
            onDropdownChanged(); // Notify the dialog to rebuild
          },
        ),
      ],
    );
  }

  void showFareMatrix() {
    if (isLoading) {
      // Show a loading dialog or message if still loading
      AwesomeDialog(
        context: context,
        dialogType: DialogType.noHeader,
        width: 450,
        alignment: Alignment.topCenter,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ).show();
      return;
    }

    // Show the fare matrix dialog when loading is complete
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      width: 450,
      alignment: Alignment.topCenter,
      body: PointerInterceptor(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fare Matrix',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: Constants.defaultPadding / 2),
                      const Divider(color: Colors.white),
                      SizedBox(height: Constants.defaultPadding),
                      buildDropdowns(
                        onDropdownChanged: () {
                          // Update the dialog content when dropdown values change
                          dialogSetState(() {});
                        },
                      ),
                      SizedBox(height: Constants.defaultPadding * 2),
                      Text(
                        'Estimated Trip Fare: $computedFarePrice',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Discounted Trip Fare: $discountedFarePrice',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: Constants.defaultPadding * 2),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(widget.route.routeColor)
              .withValues(alpha: 0.3), // Dark background with low opacity
          padding: const EdgeInsets.symmetric(
              vertical: 12.0, horizontal: 16.0), // Button padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                Constants.defaultPadding), // Rounded corners
          ),
        ),
        onPressed: isLoading
            ? null // Disable the button while loading
            : () {
                showFareMatrix();
              },
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'View Fare Matrix',
                style: TextStyle(fontSize: 12.0, color: Colors.white),
              ),
      ),
    ]);
  }
}
