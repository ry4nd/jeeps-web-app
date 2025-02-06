import 'package:flutter/material.dart';
import 'package:transitrack_web/components/right_panel/selected_jeep_info.dart';
import 'package:transitrack_web/models/jeep_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/style/constants.dart';

// This widget contains the selected PUV under the historical data tab of the data visualization panel of the route manager.

class SelectedJeepInfoBoxHistorical extends StatefulWidget {
  final JeepHistoricalData jeep;
  final RouteData routeData;
  const SelectedJeepInfoBoxHistorical(
      {super.key, required this.jeep, required this.routeData});

  @override
  State<SelectedJeepInfoBoxHistorical> createState() =>
      _SelectedJeepInfoBoxHistoricalState();
}

class _SelectedJeepInfoBoxHistoricalState
    extends State<SelectedJeepInfoBoxHistorical> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.jeep.jeepData.passenger_count == -2)
          const SelectedJeepInfoRow(
              left: Text("Driver disabled passenger counting.",
                  style: TextStyle(fontSize: 12)),
              right: SizedBox()),
        if (widget.jeep.jeepData.passenger_count != -2)
          SelectedJeepInfoRow(
              left: Row(
                children: [
                  Icon(Icons.supervisor_account,
                      color: Color(widget.routeData.routeColor), size: 15),
                  const SizedBox(width: Constants.defaultPadding / 2),
                  const Text("Occupancy"),
                ],
              ),
              right: Text(widget.jeep.jeepData.passenger_count == -1
                  ? "Available"
                  : widget.jeep.jeepData.passenger_count ==
                          widget.jeep.jeepData.max_capacity
                      ? "Full"
                      : "${widget.jeep.jeepData.passenger_count}/${widget.jeep.jeepData.max_capacity}")),
        const Divider(color: Colors.white),
        SelectedJeepInfoRow(
            left: const Text("Plate Number"),
            right: Text(widget.jeep.jeepData.device_id)),
        const Divider(color: Colors.white),
        SelectedJeepInfoRow(
            left: const Text("Driver"),
            right: Text(widget.jeep.driverName,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
