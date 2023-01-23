import 'package:flutter/material.dart';
import 'package:flutter_app/managers/mqtt_man.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../utils/constants.dart';
import '../../utils/ui.dart';
import 'air_quality.dart';

/// Un widget che, dato un id di posto, ne visualizza la qualità
class AirQualityPlace extends StatefulWidget {
  final int placeId;
  late final String topic;

  AirQualityPlace({super.key, required this.placeId}) {
    topic = "${C.mqtt.rootTopic}$placeId/${C.mqtt.co2Topic}";
  }

  @override
  AirQualityPlaceState createState() => AirQualityPlaceState();
}

class AirQualityPlaceState extends State<AirQualityPlace> {
  late final ValueNotifier<int?> co2;

  @override
  void initState() {
    co2 = ValueNotifier<int?>(null);
    MqttManager().subscribe(widget.topic, (payload) {
      co2.value = int.parse(payload);
    });
    super.initState();
  }

  @override
  void dispose() {
    MqttManager().unsubscribe(widget.topic);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: co2,
      builder: (context, value, child) {
        if (value == null) {
          return UI.spinText(AppLocalizations.of(context)!.loading);
        }
        return AirQuality(
          co2: value,
        );
      },
    );
  }
}
