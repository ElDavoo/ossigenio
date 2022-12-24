/*
Class to handle and retrieve data from the GPS module
 */
import 'dart:async';

import 'package:flutter_app/managers/account_man.dart';
import 'package:latlong2/latlong.dart';

import '../utils/log.dart';

import 'package:geolocator/geolocator.dart';

class GpsManager {
  static final GpsManager _instance = GpsManager._internal();

  factory GpsManager() {
    return _instance;
  }

  GpsManager._internal(){
    Log.l('GpsManager initializing...');
    poStream
    .where((event) => filterEvent(event))
        .listen((event) {
      Log.l('Position updated: $event');
      position = event;
      AccountManager().getNearbyPlaces(
        LatLng(event.latitude, event.longitude)
      ).then((list) {
        placeStream.add(list);
      });
      });
    Log.l('GpsManager initialized...');

  }

  static Position? position;
  Stream<Position> poStream = getPositionStream();
  //Stream controller for group of nearby places
  StreamController<List<Place>> placeStream = StreamController<List<Place>>.broadcast();

  static const LocationSettings locationSettings =
  LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 0,
  );

  // method to get the current position
  static Future<Position> getCurrentPosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    Log.v(position.toString());
    return position;
  }

  // method to get the current position
  static Future<Position?> getLastKnownPosition() async {
    Position? position = await Geolocator.getLastKnownPosition();
    Log.v(position.toString());
    return position;
  }

  // Method that gives a stream of positions
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: locationSettings
    );
  }

  /* Filter the events so we only get position updates that are:
  Not mocked, accurate, the user is not moving.
   */
  static bool filterEvent(Position position){
    return !position.isMocked &&
        position.accuracy < 20 &&
        position.speed < 1 &&
        position.speedAccuracy < 1;
  }
}
