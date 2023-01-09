import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

import 'constants.dart';

/// Vari widget
class UI {
  /// Uno slider verticale che mostra un valore numerico
  /// affiancato da una unità di misura
  static Widget verticalSlider(int baseline, int value, String unit) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(75, 0, 0, 0),
        child: SfSliderTheme(
            data: SfSliderThemeData(
              activeTrackHeight: 7,
              inactiveTrackHeight: 7,
            ),
            child: SfSlider.vertical(
              min: baseline,
              max: value + 300,
              value: value,
              showTicks: false,
              showLabels: false,
              enableTooltip: true,
              shouldAlwaysShowTooltip: true,
              minorTicksPerInterval: 1,
              isInversed: true,
              onChanged: (dynamic newvalue) {
                newvalue = value;
              },
              inactiveColor: C.colors.inactiveSlider,
              activeColor: C.colors.activeSlider,
              tooltipTextFormatterCallback: (actualValue, formattedText) {
                // Aggiunge l'unità di misura
                return "${actualValue.toInt()} $unit";
              },
            )));
  }

  /// Un widget che mostra uno spinner di caricamento con del testo
  static Widget spinText(String text) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const CircularProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(text),
        ),
      ],
    ));
  }

  /// Encapsula un widget in una card
  static Widget buildCard(Widget child) {
    return Card(
        // Disattiva l'ombra
        elevation: 0,
        color: C.colors.cardBg,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: child,
        ));
  }

  /// Ritorna un BoxDecoration con un gradiente
  static BoxDecoration gradientBox() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          C.colors.startShade,
          C.colors.endShade,
        ],
      ),
    );
  }

  /// Restituisce un colore gradiente in base al valore della co2
  static decideColor(int co2level) {
    if (co2level < C.quotas.excellent) {
      return C.colors.excellent;
    } else if (co2level < C.quotas.veryGood) {
      final double percentage = (co2level - C.quotas.excellent) /
          (C.quotas.veryGood - C.quotas.excellent);
      return Color.lerp(C.colors.excellent, C.colors.veryGood, percentage)!;
    } else if (co2level < C.quotas.good) {
      final double percentage =
          (co2level - C.quotas.veryGood) / (C.quotas.good - C.quotas.veryGood);
      return Color.lerp(C.colors.veryGood, C.colors.good, percentage)!;
    } else if (co2level < C.quotas.acceptable) {
      final double percentage =
          (co2level - C.quotas.good) / (C.quotas.acceptable - C.quotas.good);
      return Color.lerp(C.colors.good, C.colors.acceptable, percentage)!;
    } else if (co2level < C.quotas.bad) {
      final double percentage = (co2level - C.quotas.acceptable) /
          (C.quotas.bad - C.quotas.acceptable);
      return Color.lerp(C.colors.acceptable, C.colors.bad, percentage)!;
    } else if (co2level < C.quotas.veryBad) {
      final double percentage =
          (co2level - C.quotas.bad) / (C.quotas.veryBad - C.quotas.bad);
      return Color.lerp(C.colors.bad, C.colors.veryBad, percentage)!;
    } else if (co2level < C.quotas.dangerous) {
      final double percentage = (co2level - C.quotas.veryBad) /
          (C.quotas.dangerous - C.quotas.veryBad);
      return Color.lerp(C.colors.veryBad, C.colors.dangerous, percentage)!;
    } else {
      return C.colors.dangerous;
    }
  }
}
