/*
Class to handle and retrieve data from the GPS module
 */
import 'dart:async';

import 'package:flutter_app/Messages/message.dart';

import '../utils/log.dart';

import 'package:geolocator/geolocator.dart';

class GpsManager {
  // method to get the current position
  Future<Position> getCurrentPosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    Log.l(position.toString());
    return position;
  }

  // method to get the current position
  Future<Position?> getLastKnownPosition() async {
    Position? position = await Geolocator.getLastKnownPosition();
    Log.l(position.toString());
    return position;
  }

}