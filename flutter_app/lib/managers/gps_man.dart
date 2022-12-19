/*
Class to handle and retrieve data from the GPS module
 */
import 'dart:async';

import '../utils/log.dart';

import 'package:geolocator/geolocator.dart';

class GpsManager {
  static final GpsManager _instance = GpsManager._internal();

  factory GpsManager() {
    return _instance;
  }

  GpsManager._internal();

  // method to get the current position
  Future<Position> getCurrentPosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    Log.v(position.toString());
    return position;
  }

  // method to get the current position
  Future<Position?> getLastKnownPosition() async {
    Position? position = await Geolocator.getLastKnownPosition();
    Log.v(position.toString());
    return position;
  }
}
