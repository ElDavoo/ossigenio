// A stateful widget which takes a place id,
// Asks the api for the place data and displays it

import 'package:flutter/material.dart';

import '../../managers/account_man.dart';
import 'air_quality.dart';

class AirQualityPlace extends StatefulWidget {
  final int placeId;

  const AirQualityPlace({Key? key, required this.placeId}) : super(key: key);

  @override
  AirQualityPlaceState createState() => AirQualityPlaceState();
}

class AirQualityPlaceState extends State<AirQualityPlace> {
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
              co2:
                  snapshot.data!.co2Level > 400 ? snapshot.data!.co2Level : 400,
            );
          }
          return const Text('No data');
        });
  }
}
