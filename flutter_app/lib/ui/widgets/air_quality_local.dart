import 'package:flutter/material.dart';

import '../../Messages/message.dart';
import '../../utils/device.dart';
import '../../Messages/co2_message.dart';
import 'air_quality.dart';

// A stateful widget which is a wrapper for AirQuality
// Takes a device and wraps AirQuality widget in a stream builder

class AirQualityLocal extends StatefulWidget {
  final Device device;

  const AirQualityLocal({Key? key, required this.device}) : super(key: key);

  @override
  _AirQualityLocalState createState() => _AirQualityLocalState();
}

class _AirQualityLocalState extends State<AirQualityLocal> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MessageWithDirection>(
        stream: widget.device.messagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.message is CO2Message) {
              CO2Message msg = snapshot.data!.message as CO2Message;
              return AirQuality(
                co2: msg.co2,
                temperature: msg.temperature,
                humidity: msg.humidity,
              );
            }
          }
          return const Text('No data');
        });
  }
}