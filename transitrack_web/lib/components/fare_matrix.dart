import 'package:flutter/material.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

class FareMatrix extends StatefulWidget {
  final RouteData route;
  const FareMatrix({super.key, required this.route});

  @override
  FareMatrixState createState() => FareMatrixState();
}

class FareMatrixState extends State<FareMatrix> {
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
          // Add your logic here to navigate or display the fare matrix
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Fare Matrix'),
                content: const Text('Display fare matrix details here.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
        child: const Text(
          'View Fare Matrix',
          style: TextStyle(fontSize: 12.0, color: Colors.white),
        ),
      ),
    ]);
  }
}
