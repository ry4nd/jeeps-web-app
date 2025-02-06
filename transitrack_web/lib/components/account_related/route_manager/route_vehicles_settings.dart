import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:transitrack_web/components/account_related/route_manager/delete_jeep.dart';
import 'package:transitrack_web/components/account_related/route_manager/edit_jeep.dart';

import '../../../models/jeep_model.dart';
import '../../../models/route_model.dart';
import 'register_jeep.dart';
import '../../../style/constants.dart';
import '../../button.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

// This widget displays the vehicle settings page

class VehiclesSettings extends StatefulWidget {
  final RouteData route;
  final List<JeepsAndDrivers> jeeps;
  final ValueChanged<JeepsAndDrivers> pressedJeep;

  const VehiclesSettings(
      {super.key,
      required this.route,
      required this.jeeps,
      required this.pressedJeep});

  @override
  State<VehiclesSettings> createState() => _VehiclesSettingsState();
}

class _VehiclesSettingsState extends State<VehiclesSettings> {
  List<JeepsAndDrivers>? _jeeps;
  JeepsAndDrivers? pressedJeep;

  int hovered = -1;

  @override
  void initState() {
    super.initState();

    setState(() {
      _jeeps = widget.jeeps;
    });
  }

  @override
  void didUpdateWidget(covariant VehiclesSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if jeepney changed
    if (widget.jeeps != _jeeps) {
      setState(() {
        _jeeps = widget.jeeps;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Plate #'),
          Text("Active"),
        ]),
        const SizedBox(height: Constants.defaultPadding),
        Expanded(
          child: ListView.builder(
            itemCount: _jeeps!.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  const Divider(color: Constants.white),
                  MouseRegion(
                    onHover: (_) => setState(() {
                      hovered = index;
                    }),
                    onExit: (_) => setState(() {
                      hovered = -1;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: Constants.defaultPadding / 2),
                      color: hovered == index
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.transparent,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(_jeeps![index].jeep.device_id),
                                if (hovered == index)
                                  Row(
                                    children: [
                                      if (_jeeps![index].driver == null)
                                        const SizedBox(
                                            width: Constants.defaultPadding),
                                      if (_jeeps![index].driver == null)
                                        GestureDetector(
                                          onTap: () {
                                            AwesomeDialog(
                                              dialogType: DialogType.noHeader,
                                              context: (context),
                                              width: 500,
                                              body: PointerInterceptor(
                                                child: EditJeep(
                                                  route: widget.route,
                                                  jeepData: _jeeps![index].jeep,
                                                ),
                                              ),
                                            ).show();
                                          },
                                          child: Icon(
                                            Icons.edit,
                                            size: 20,
                                            color:
                                                Color(widget.route.routeColor),
                                          ),
                                        ),
                                      if (_jeeps![index].driver == null)
                                        const SizedBox(
                                            width:
                                                Constants.defaultPadding / 2),
                                      if (_jeeps![index].driver == null)
                                        GestureDetector(
                                          onTap: () {
                                            AwesomeDialog(
                                              dialogType: DialogType.noHeader,
                                              context: (context),
                                              width: 500,
                                              body: PointerInterceptor(
                                                child: DeleteJeep(
                                                  jeepData: _jeeps![index].jeep,
                                                ),
                                              ),
                                            ).show();
                                          },
                                          child: Icon(
                                            Icons.delete,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                        ),
                                      if (_jeeps![index].driver != null)
                                        const SizedBox(
                                            width:
                                                Constants.defaultPadding / 2),
                                      if (_jeeps![index].driver != null)
                                        GestureDetector(
                                          onTap: () => widget
                                              .pressedJeep(_jeeps![index]),
                                          child: Icon(
                                            Icons.search,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  )
                              ],
                            ),
                            Icon(Icons.circle,
                                color: _jeeps![index].driver != null
                                    ? Colors.green
                                    : Colors.red),
                          ]),
                    ),
                  ),
                  if (index == _jeeps!.length - 1)
                    const Divider(color: Colors.white),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: Constants.defaultPadding),
        Button(
            onTap: () {
              AwesomeDialog(
                dialogType: DialogType.noHeader,
                context: (context),
                width: 500,
                body: PointerInterceptor(
                  child: RegisterJeep(
                    route: widget.route,
                  ),
                ),
              ).show();
            },
            text: '+',
            color: Color(widget.route.routeColor),
            isMobile: true)
      ]),
    );
  }
}
