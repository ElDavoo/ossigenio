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
        padding: const EdgeInsets.fromLTRB(70, 0, 0, 0),
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
}
