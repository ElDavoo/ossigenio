import 'package:flutter/material.dart';

import '../../Messages/co2_message.dart';
import '../../Messages/message.dart';
import '../../utils/device.dart';
import 'air_quality.dart';

// A stateful widget which is a wrapper for AirQuality
// Takes a device and wraps AirQuality widget in a stream builder

class AirQualityLocal extends StatefulWidget {
  final Device device;

  const AirQualityLocal({Key? key, required this.device}) : super(key: key);

  @override
  AirQualityLocalState createState() => AirQualityLocalState();
}

class AirQualityLocalState extends State<AirQualityLocal> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CO2Message>(
        stream: widget.device.messagesStream
            .where((m) => m.direction == MessageDirection.received)
            .where((m) => m.message is CO2Message)
            .map((m) => m.message as CO2Message)
            .cast<CO2Message>(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return AirQuality(
              co2: snapshot.data!.co2 > 400 ? snapshot.data!.co2 : 400,
              temperature: snapshot.data?.temperature,
              humidity: snapshot.data?.humidity,
              isHeating: widget.device.isHeating,
            );
          }
          return const Text('No data');
        });
  }
}
