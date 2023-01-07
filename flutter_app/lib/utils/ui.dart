/*
Various widgets
 */
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
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

//Build a gauge with minimum, maximum and current value
  static Widget buildGauge(String title, int min, int max, int value) {
    return Stack(
      children: [
        SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
                minimum: min.toDouble(),
                maximum: max.toDouble(),
                ranges: <GaugeRange>[
                  GaugeRange(
                      startValue: min.toDouble(),
                      endValue: max.toDouble(),
                      gradient: const SweepGradient(
                          colors: <Color>[Colors.green, Colors.red],
                          stops: <double>[0.25, 0.75]),
                      startWidth: 10,
                      endWidth: 10),
                ],
                pointers: <GaugePointer>[
                  NeedlePointer(
                      value: value.toDouble(),
                      enableAnimation: true,
                      animationType: AnimationType.ease,
                      animationDuration: 500,
                      needleColor: Colors.red,
                      needleStartWidth: 1,
                      needleEndWidth: 5,
                      lengthUnit: GaugeSizeUnit.factor,
                      needleLength: 0.8,
                      knobStyle: const KnobStyle(
                          knobRadius: 0,
                          sizeUnit: GaugeSizeUnit.factor,
                          color: Colors.red))
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                      widget: Text(title,
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold)),
                      angle: 90,
                      positionFactor: 0.1)
                ])
          ],
        ),
        if (value == 0)
          Container(
            color: Colors.white.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
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

class CustomSliderThumbRectangle extends SliderComponentShape {
  final Color color;
  final int min;
  final int max;

  const CustomSliderThumbRectangle(
      {required this.color, this.min = 0, this.max = 255});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size.fromRadius(10);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    TextSpan span = TextSpan(
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
      text: (min + (max - min) * value).round().toString(),
    );

    TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    Offset textCenter =
        Offset(center.dy - (tp.height / 2), -center.dx - (tp.width / 2));

    Paint paintRB;
    final RRect borderRectB = BorderRadius.circular(8)
        .resolve(textDirection)
        .toRRect(Rect.fromCenter(center: center, width: 30, height: 70));
    paintRB = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    Paint paintR;
    final RRect borderRect = BorderRadius.circular(8)
        .resolve(textDirection)
        .toRRect(Rect.fromCenter(center: center, width: 30, height: 70));
    paintR = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawRRect(borderRectB, paintRB);
    canvas.drawRRect(borderRect, paintR);

    canvas.rotate(1.5708);
    tp.paint(canvas, textCenter);
  }
}
