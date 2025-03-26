import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

class FareMatrix extends StatefulWidget {
  final RouteData route;
  const FareMatrix({super.key, required this.route});

  @override
  FareMatrixState createState() => FareMatrixState();
}

class FareMatrixState extends State<FareMatrix> {
  int computedFarePrice = 0;
  int discountedFarePrice = 0;
  String _selectedFrom = 'Location A'; // Default value for "From"
  String _selectedTo = 'Location A'; // Default value for "To"
  final List<String> _locations = [
    'Location A',
    'Location B',
    'Location C'
  ]; // Dropdown options

  Widget buildDropdown({
    required String label,
    required String selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownMenu(
      label: Text(label),
      width: 350,
      enableFilter: true,
      initialSelection: selectedValue,
      onSelected: (newValue) {
        if (newValue is String) {
          onChanged(newValue);
        }
      },
      dropdownMenuEntries: _locations.map((String value) {
        return DropdownMenuEntry<String>(
          value: value,
          label: value,
        );
      }).toList(),
    );
  }

  void showFareMatrix() {
    AwesomeDialog(
        context: context,
        dialogType: DialogType.noHeader,
        width: 450,
        alignment: Alignment.topCenter,
        body: PointerInterceptor(
            child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Fare Matrix',
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ]),
                  SizedBox(height: Constants.defaultPadding / 2),
                  const Divider(color: Colors.white),
                  SizedBox(height: Constants.defaultPadding),
                  buildDropdown(
                    label: 'From',
                    selectedValue: _selectedFrom,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedFrom = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: Constants.defaultPadding),
                  buildDropdown(
                    label: 'To',
                    selectedValue: _selectedTo,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedTo = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: Constants.defaultPadding * 2),
                  Text('Estimated Trip Fare: $computedFarePrice',
                      style: TextStyle(fontSize: 16)),
                  Text('Discounted Trip Fare: $discountedFarePrice',
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: Constants.defaultPadding * 2),
                ],
              ),
            )
          ],
        ))).show();
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
        onPressed: () {
          showFareMatrix();
        },
        child: const Text(
          'View Fare Matrix',
          style: TextStyle(fontSize: 12.0, color: Colors.white),
        ),
      ),
    ]);
  }
}
