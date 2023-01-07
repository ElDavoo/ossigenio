import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class UIWidgets {
  static Widget verticalSlider(int value) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(70, 0, 0, 0),
        child: SfSliderTheme(
            data: SfSliderThemeData(
              activeTrackHeight: 7,
              inactiveTrackHeight: 7,
            ),
            child: SfSlider.vertical(
              min: 400.0,
              max: value + 300,
              value: value,
              interval: 2,
              showTicks: false,
              showLabels: false,
              enableTooltip: true,
              shouldAlwaysShowTooltip: true,
              minorTicksPerInterval: 1,
              isInversed: true,
              onChanged: (dynamic newvalue) {
                newvalue = value;
              },
              inactiveColor: Colors.blue,
              activeColor: Colors.red,
              tooltipTextFormatterCallback: (actualValue, formattedText) {
                //add the unit to the value
                return "${actualValue.toInt()} ppm";
              },
            )));
  }

  static Widget spinText(String text) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const CircularProgressIndicator(),
        Text(text),
      ],
    ));
  }

  static Widget buildCard(Widget child) {
    return Card(
        elevation: 0,
        color: const Color.fromRGBO(255, 255, 255, 0.8),
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: child,
        ));
  }
}