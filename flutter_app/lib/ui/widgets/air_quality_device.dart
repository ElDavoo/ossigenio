import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../Messages/co2_message.dart';
import '../../Messages/message.dart';
import '../../utils/device.dart';
import '../../utils/ui.dart';
import 'air_quality.dart';

/// Un widget che wrappa AirQuality nello StreamBuilder di un dispositivo
class AirQualityDevice extends StatefulWidget {
  final Device device;

  const AirQualityDevice({Key? key, required this.device}) : super(key: key);

  @override
  AirQualityDeviceState createState() => AirQualityDeviceState();
}

class AirQualityDeviceState extends State<AirQualityDevice> {
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
          return UI.spinText(
            AppLocalizations.of(context)!.connectingToSensor,
          );
        });
  }
}
