/*
This class files implements a stateful widget which shows a map
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/managers/gps_man.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../managers/account_man.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin<MapPage> {
  final PopupController _popupController = PopupController();
  late CenterOnLocationUpdate _centerOnLocationUpdate;
  late StreamController<double?> _centerCurrentLocationStreamController;
  List<Marker> _markers = [];

  void refresh() {
    AccountManager().getPlaces(
        LatLng(GpsManager.position!.latitude, GpsManager.position!.longitude)
    ).then((value) {
      onNearbyPlacesChanged(value);
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
    final popupState = PopupState.maybeOf(context, listen: false);
    LatLng center = LatLng(44.6291399, 10.9488126);
    if (GpsManager.position != null) {
      center = LatLng(GpsManager.position!.latitude, GpsManager.position!.longitude);
    }
    return FlutterMap(
      options: MapOptions(
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
            popupBuilder: (_, marker) => Container(
              width: 200,
              height: 100,
              color: Colors.white,
              child: GestureDetector(
                onTap: () {
                  // close the popup
                  _popupController.hideAllPopups();
                },
                child: Text(
                  'Container popup for marker at ${marker.point}',
                ),
              ),
            )),
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
        },),),

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

  @override
  bool get wantKeepAlive => true;

}

