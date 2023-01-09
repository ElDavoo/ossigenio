import 'package:flutter/material.dart';
import 'package:flutter_app/utils/ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../utils/constants.dart';

/// Mostra i valori della CO2 da un sensore o da un posto
class AirQuality extends StatefulWidget {
  /// Il valore della CO2 in ppm
  final int co2;

  /// Il valore della temperatura in gradi Celsius
  final int? temperature;

  /// Il valore dell'umidità in percentuale
  final int? humidity;

  /// Mostra se il sensore si sta riscaldando
  final bool? isHeating;

  const AirQuality(
      {Key? key,
      required this.co2,
      this.temperature,
      this.humidity,
      this.isHeating})
      : super(key: key);

  @override
  AirQualityState createState() => AirQualityState();
}

class AirQualityState extends State<AirQuality> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.isHeating != null && widget.isHeating!)
          Container(
            decoration: BoxDecoration(color: C.colors.isHeatingBg),
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 4),
              child: Center(
                child: Row(
                  children: [
                    const Text(
                      '⚠️ ',
                      style: TextStyle(fontSize: 40),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text(
                          textAlign: TextAlign.center,
                          AppLocalizations.of(context)!.sensorWarmingWarning,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topLeft,
            child: Text(
              AppLocalizations.of(context)!.airQualityIs,
              style: const TextStyle(fontSize: 320),
            )),

        // FIXME
        SizedBox(
          height: 500,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                    child: Column(
                  children: [
                    AirQualityText(co2: widget.co2),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: Text(
                        // Insert temperature
                        _buildExplanationText(
                            widget.co2, widget.temperature, widget.humidity),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                )),
                UI.verticalSlider(400, widget.co2, "ppm"),
              ]),
        ),
      ],
    );
  }

  String _buildExplanationText(int co2, [int? temp, int? hum]) {
    String text = "";
    if (temp != null && hum != null) {
      text = "${AppLocalizations.of(context)!.tempHum(temp, hum)}\n";
    }
    text += "${AppLocalizations.of(context)!.co2Explanation}\n";

    text += C.explanation(context, co2);

    return text;
  }
}

// A stateful widget which maps a range of co2 values to a text
class AirQualityText extends StatefulWidget {
  final int co2;

  const AirQualityText({Key? key, required this.co2}) : super(key: key);

  @override
  AirQualityTextState createState() => AirQualityTextState();
}

class AirQualityTextState extends State<AirQualityText> {
  @override
  Widget build(BuildContext context) {
    final String text = C.catchWord(context, widget.co2);
    final TextStyle style = TextStyle(
      fontSize: 80,
      fontWeight: FontWeight.bold,
      color: UI.decideColor(widget.co2),
    );
    return FittedBox(
      fit: BoxFit.fill,
      alignment: Alignment.topLeft,
      child: Text(text, style: style),
    );
  }
}
