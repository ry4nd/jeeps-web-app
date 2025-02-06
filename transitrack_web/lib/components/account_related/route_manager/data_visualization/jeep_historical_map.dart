// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:transitrack_web/config/keys.dart';
import 'package:transitrack_web/config/map_settings.dart';
import 'package:transitrack_web/models/jeep_model.dart';
import 'package:transitrack_web/models/route_model.dart';
import 'package:transitrack_web/services/int_to_hex.dart';
import 'package:transitrack_web/services/mapbox/add_image_from_asset.dart';

// The Map Widget that appears when the jeep historical tab is selected in the data visualization panel of the route manager account.

class JeepHistoricalMap extends StatefulWidget {
  final ValueChanged<bool> mapLoaded;
  final List<JeepHistoricalData>? jeepHistoricalData;
  final RouteData routeData;
  final ValueChanged<JeepHistoricalData?> selectedJeep;
  const JeepHistoricalMap(
      {super.key,
      required this.mapLoaded,
      required this.jeepHistoricalData,
      required this.selectedJeep,
      required this.routeData});

  @override
  State<JeepHistoricalMap> createState() => JeepHistoricalMapState();
}

class JeepHistoricalAndIcon {
  JeepHistoricalData jeepHistorical;
  Symbol jeepSymbol;

  JeepHistoricalAndIcon(
      {required this.jeepHistorical, required this.jeepSymbol});

  void setJeepHistorical(JeepHistoricalData newData) {
    jeepHistorical = newData;
  }
}

class JeepHistoricalMapState extends State<JeepHistoricalMap> {
  late MapboxMapController _mapController;
  late List<JeepHistoricalData>? _jeepHistoricalData;

  List<JeepHistoricalAndIcon> data = [];

  JeepHistoricalAndIcon? tapped;

  @override
  void initState() {
    super.initState();

    setState(() {
      _jeepHistoricalData = widget.jeepHistoricalData;
    });
  }

  void onSymbolTapped(Symbol symbol) {
    JeepHistoricalAndIcon jeepHistorical =
        data.firstWhere((element) => element.jeepSymbol == symbol);
    if (tapped != null) {
      if (symbol == tapped!.jeepSymbol) {
        _mapController.updateSymbol(
            symbol, const SymbolOptions(iconImage: 'jeepTop'));
        setState(() {
          tapped = null;
        });
      } else {
        _mapController.updateSymbol(
            tapped!.jeepSymbol, const SymbolOptions(iconImage: 'jeepTop'));
        setState(() {
          tapped = JeepHistoricalAndIcon(
              jeepHistorical: jeepHistorical.jeepHistorical,
              jeepSymbol: symbol);
        });
        _mapController.updateSymbol(tapped!.jeepSymbol,
            const SymbolOptions(iconImage: 'jeepTopSelected'));
      }
    } else {
      setState(() {
        tapped = JeepHistoricalAndIcon(
            jeepHistorical: jeepHistorical.jeepHistorical, jeepSymbol: symbol);
      });

      _mapController.updateSymbol(
          symbol, const SymbolOptions(iconImage: 'jeepTopSelected'));
    }

    widget.selectedJeep(tapped?.jeepHistorical);
  }

  void addRoute() {
    var geometry = widget.routeData.routeCoordinates;
    geometry.add(widget.routeData.routeCoordinates.first);
    _mapController.addLines([
      LineOptions(
          lineWidth: 4.0,
          lineColor: intToHexColor(widget.routeData.routeColor),
          lineOpacity: 0.5,
          geometry: geometry)
    ]);
  }

  @override
  void didUpdateWidget(covariant JeepHistoricalMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_jeepHistoricalData != widget.jeepHistoricalData) {
      setState(() {
        _jeepHistoricalData = widget.jeepHistoricalData;
      });

      if (_jeepHistoricalData != null && _jeepHistoricalData!.isNotEmpty) {
        if (tapped != null) {
          if (_jeepHistoricalData!.any((element) =>
              element.jeepData.device_id ==
                  tapped!.jeepHistorical.jeepData.device_id &&
              element.isOperating)) {
            JeepHistoricalData jeep = _jeepHistoricalData!.firstWhere(
                (element) =>
                    element.jeepData.device_id ==
                    tapped!.jeepHistorical.jeepData.device_id);
            tapped!.setJeepHistorical(jeep);
            widget.selectedJeep(tapped!.jeepHistorical);
          } else {
            _mapController.updateSymbol(
                tapped!.jeepSymbol,
                const SymbolOptions(
                    iconSize: 0, textSize: 0, iconImage: 'jeepTop'));
            tapped = null;
            widget.selectedJeep(null);
          }
        }

        for (var device_id in data
            .map((e) => e.jeepHistorical.jeepData.device_id)
            .toSet()
            .difference(_jeepHistoricalData!
                .map((e) => e.jeepData.device_id)
                .toSet())) {
          int index = data.indexWhere((element) =>
              element.jeepHistorical.jeepData.device_id == device_id);
          _mapController.removeSymbol(data[index].jeepSymbol);
          data.removeAt(index);
        }

        for (JeepHistoricalData jeep in _jeepHistoricalData!) {
          if (data.any((element) =>
              element.jeepHistorical.jeepData.device_id ==
              jeep.jeepData.device_id)) {
            int index = data.indexWhere((element) =>
                element.jeepHistorical.jeepData.device_id ==
                jeep.jeepData.device_id);
            _mapController.updateSymbol(
                data[index].jeepSymbol,
                SymbolOptions(
                    geometry: LatLng(jeep.jeepData.location.latitude,
                        jeep.jeepData.location.longitude),
                    iconRotate: jeep.jeepData.bearing,
                    iconSize: jeep.isOperating ? 1 : 0,
                    textSize: jeep.isOperating ? 50 : 0,
                    textRotate: jeep.jeepData.bearing + 90));
            data[index].setJeepHistorical(jeep);
          } else {
            _mapController
                .addSymbol(SymbolOptions(
                    geometry: LatLng(jeep.jeepData.location.latitude,
                        jeep.jeepData.location.longitude),
                    iconImage: "jeepTop",
                    textField: "▬▬",
                    textLetterSpacing: -0.35,
                    textSize: 50,
                    textColor: intToHexColor(widget.routeData.routeColor),
                    textRotate: jeep.jeepData.bearing + 90,
                    iconRotate: jeep.jeepData.bearing,
                    iconOpacity: jeep.isOperating ? 1 : 0,
                    textOpacity: jeep.isOperating ? 1 : 0,
                    iconSize: 1))
                .then((value) => data.add(JeepHistoricalAndIcon(
                    jeepHistorical: jeep, jeepSymbol: value)));
          }
        }
      } else {
        tapped = null;
        _mapController.clearSymbols();
        data.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      accessToken: Keys.MapBoxKey,
      styleString: Keys.MapBoxNight,
      doubleClickZoomEnabled: false,
      minMaxZoomPreference: MinMaxZoomPreference(mapMinZoom, mapMaxZoom),
      compassEnabled: true,
      compassViewPosition: CompassViewPosition.TopLeft,
      onMapCreated: (controller) {
        _mapController = controller;
        _mapController.onSymbolTapped.add(onSymbolTapped);
      },
      onStyleLoadedCallback: () {
        addImageFromAsset(_mapController);
        addRoute();
        _mapController.setSymbolIconAllowOverlap(true);
        _mapController.setSymbolTextAllowOverlap(true);
        _mapController.setSymbolIconIgnorePlacement(true);
        _mapController.setSymbolTextIgnorePlacement(true);
        widget.mapLoaded(true);
      },
      initialCameraPosition: CameraPosition(
        target: Keys.MapCenter,
        zoom: mapStartZoom,
      ),
    );
  }
}
