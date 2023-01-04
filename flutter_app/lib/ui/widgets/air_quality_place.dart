// A stateful widget which takes a place id,
// Asks the api for the place data and displays it

import 'package:flutter/material.dart';
import 'package:flutter_app/Messages/message.dart';

import '../../Messages/co2_message.dart';

import '../../managers/account_man.dart';
import 'air_quality.dart';

class AirQualityPlace extends StatefulWidget {
  final int placeId;

  const AirQualityPlace({Key? key, required this.placeId}) : super(key: key);

  @override
  _AirQualityPlaceState createState() => _AirQualityPlaceState();
}

class _AirQualityPlaceState extends State<AirQualityPlace> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Place>(
        future: AccountManager().getPlace(widget.placeId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return AirQuality(
              co2: snapshot.data!.co2Level,
            );
          }
          return const Text('No data');
        });
  }
}