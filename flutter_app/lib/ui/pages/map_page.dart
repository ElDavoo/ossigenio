/*
This class files implements a stateful widget which shows a map
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/managers/gps_man.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

import '../../managers/account_man.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin<MapPage> {
  late CenterOnLocationUpdate _centerOnLocationUpdate;
  late StreamController<double?> _centerCurrentLocationStreamController;
  late StreamSubscription<List<Place>> _nearbyPlacesSubscription;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _centerOnLocationUpdate = CenterOnLocationUpdate.never;
    _centerCurrentLocationStreamController = StreamController<double?>();
    _nearbyPlacesSubscription = GpsManager().
    placeStream.
    stream.listen((event) => onNearbyPlacesChanged(event));
  }

  @override
  void dispose() {
    _centerCurrentLocationStreamController.close();
    _nearbyPlacesSubscription.cancel();
    super.dispose();
  }

  void onNearbyPlacesChanged(List<Place> coords) {
    setState(() {
      _markers = placetomarkers(coords);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(44.6291399, 10.9488126),
        zoom: 15.0,
        maxZoom: 18.0,
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
        Positioned(
          right: 120,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: () {
              // Automatically center the location marker on the map when location updated until user interact with the map.
              refresh();
            },
            child: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ),
      ],
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'it.eldavo.aqm',
        ),
        CurrentLocationLayer(
          centerCurrentLocationStream:
          _centerCurrentLocationStreamController.stream,
          centerOnLocationUpdate: _centerOnLocationUpdate,
        ),
        MarkerLayer(
          markers: _markers,
        ),
      ],
        );
  }
  static List<Marker> latlngtomarkers(List<LatLng> coords){
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

  static List<Marker> placetomarkers(List<Place> coords){
    return coords
        .map((point) => Marker(
      point:
        point.location,
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

  Future<void> refresh() async {
    // User requested a manual refresh.
    // Check if we have a memorized location.
    GpsManager.position ??= await GpsManager.getCurrentPosition();
    List<Place> places = await AccountManager().getNearbyPlaces(LatLng
      (GpsManager.position!.latitude,
        GpsManager.position!.longitude));
    return GpsManager().placeStream.add(places);
  }

  @override
  bool get wantKeepAlive => true;

}

