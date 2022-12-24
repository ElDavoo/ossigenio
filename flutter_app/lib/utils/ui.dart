/*
Various widgets
 */
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class UIWidgets {
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
}