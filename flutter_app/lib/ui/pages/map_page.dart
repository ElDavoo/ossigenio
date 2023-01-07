/*
This class files implements a stateful widget which shows a map
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/managers/gps_man.dart';
import 'package:flutter_app/ui/pages/place_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../managers/account_man.dart';
import '../../utils/place.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage>
    with AutomaticKeepAliveClientMixin<MapPage> {
  final PopupController _popupController = PopupController();
  late CenterOnLocationUpdate _centerOnLocationUpdate;
  late StreamController<double?> _centerCurrentLocationStreamController;
  List<Marker> _markers = [];
  List<Place> _places = [];

  Widget popupBuilder(BuildContext context, marker) {
    // Find in _places a place with the same position of the marker
    final place =
        _places.firstWhere((element) => element.location == marker.point);
    return Container(
      width: 200,
      height: 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.fromRGBO(227, 252, 230, 1),
            Color.fromRGBO(111, 206, 250, 0.9)
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.fitWidth,
              child: Text(
                place.name,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.fitWidth,
              child: Text(
                "CO2 Attuale: ${place.co2Level} ppm",
                style: const TextStyle(
                  fontSize: 40,
                ),
              ),
            ),
            // Button to go to the place's page
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PredictionPlace(place: place)),
                );
              },
              child: const Text("Predizioni"),
            ),
          ],
        ),
      ),
    );
  }

  void refresh() {
    AccountManager()
        .getPlaces(LatLng(
            GpsManager.position!.latitude, GpsManager.position!.longitude))
        .then((value) {
      onNearbyPlacesChanged(value);
      _places = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _centerOnLocationUpdate = CenterOnLocationUpdate.never;
    _centerCurrentLocationStreamController = StreamController<double?>();
    refresh();
  }

  @override
  void dispose() {
    _centerCurrentLocationStreamController.close();
    super.dispose();
  }

  void onNearbyPlacesChanged(List<Place> coords) {
    setState(() {
      _markers = placetomarkers(coords);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    LatLng center = LatLng(44.6291399, 10.9488126);
    if (GpsManager.position != null) {
      center =
          LatLng(GpsManager.position!.latitude, GpsManager.position!.longitude);
    }
    return FlutterMap(
      options: MapOptions(
        onTap: (_, __) {
          _popupController.hideAllPopups();
        },
        center: center,
        minZoom: 9.0,
        zoom: 15.0,
        maxZoom: 21.0,
        maxBounds: LatLngBounds(LatLng(48, 6), LatLng(36, 19)),
        interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        onPositionChanged: (MapPosition position, bool hasGesture) {
          if (hasGesture) {
            setState(
              () => _centerOnLocationUpdate = CenterOnLocationUpdate.never,
            );
          }
        },
      ),
      nonRotatedChildren: [
        Positioned(
          right: 20,
          bottom: 20,
          child: InkWell(
            onLongPress: refresh,
            child: FloatingActionButton(
              onPressed: () {
                // Automatically center the location marker on the map when location updated until user interact with the map.
                setState(
                  () => _centerOnLocationUpdate = CenterOnLocationUpdate.always,
                );
                // Center the location marker on the map and zoom the map to level 18.
                _centerCurrentLocationStreamController.add(18);
              },
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'it.eldavo.aqm',
          maxNativeZoom: 18.0,
        ),
        CurrentLocationLayer(
          centerCurrentLocationStream:
              _centerCurrentLocationStreamController.stream,
          centerOnLocationUpdate: _centerOnLocationUpdate,
        ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            spiderfyCircleRadius: 80,
            spiderfySpiralDistanceMultiplier: 2,
            circleSpiralSwitchover: 12,
            maxClusterRadius: 120,
            rotate: true,
            size: const Size(40, 40),
            anchor: AnchorPos.align(AnchorAlign.center),
            fitBoundsOptions: const FitBoundsOptions(
              padding: EdgeInsets.all(50),
              maxZoom: 15,
            ),
            markers: _markers,
            polygonOptions: const PolygonOptions(
                borderColor: Colors.blueAccent,
                color: Colors.black12,
                borderStrokeWidth: 3),
            popupOptions: PopupOptions(
                popupState: PopupState(),
                popupSnap: PopupSnap.markerTop,
                popupController: _popupController,
                popupBuilder: popupBuilder),
            builder: (context, markers) {
              return Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.blue),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static List<Marker> latlngtomarkers(List<LatLng> coords) {
    return coords
        .map((point) => Marker(
              point: point,
              width: 60,
              height: 60,
              builder: (context) => const Icon(
                Icons.pin_drop,
                size: 60,
                color: Colors.blueAccent,
              ),
            ))
        .toList();
  }

  static List<Marker> placetomarkers(List<Place> coords) {
    return coords.map((point) {
      Color clr = decideColor(point.co2Level);
      return Marker(
        point: point.location,
        width: 60,
        height: 60,
        builder: (context) => Icon(
          Icons.location_on_outlined,
          size: 30,
          color: clr,
        ),
      );
    }).toList();
  }

  @override
  bool get wantKeepAlive => true;

  static decideColor(int co2level) {
    // Decide color with a linear grdient with the lerp method
    // https://api.flutter.dev/flutter/dart-ui/lerpDouble.html

    // The color gradient is from green to red
    Color startColor = Colors.green;
    Color endColor = Colors.red;

    // The gradient is from 0 to 1000
    double startValue = 0;
    double endValue = 1000;

    // The value to be converted
    double value = co2level.toDouble();

    // The value converted to a percentage
    double percentage = (value - startValue) / (endValue - startValue);

    // The color to be returned
    Color color = Color.lerp(startColor, endColor, percentage)!;
    return color;
  }
}
