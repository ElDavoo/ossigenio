// A stateful widget which takes a place id,
// Asks the api for the place data and displays it

import 'package:flutter/material.dart';
import 'package:flutter_app/Messages/message.dart';

import '../../Messages/co2_message.dart';

import '../../managers/account_man.dart';
import 'air_quality.dart';

class AirQualityPlace extends StatefulWidget {
  int placeId;

  AirQualityPlace({Key? key, required this.placeId}) : super(key: key);

  @override
  _AirQualityPlaceState createState() => _AirQualityPlaceState();
}

class _AirQualityPlaceState extends State<AirQualityPlace> {
  late Future<Place> future;

  @override
  void initState() {
    super.initState();
    future = AccountManager().getPlace(widget.placeId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Place>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return AirQuality(
              co2: snapshot.data!.co2Level > 400
                  ? snapshot.data!.co2Level
                  : 400,
            );
          }
          return const Text('No data');
        });
  }
}