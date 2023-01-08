import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/utils/ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../managers/account_man.dart';
import '../../utils/place.dart';
import '../../utils/prediction.dart';

/// Pagina che mostra le predizioni di un luogo
class PredictionPlace extends StatefulWidget {
  final Place place;

  const PredictionPlace({Key? key, required this.place}) : super(key: key);

  @override
  PredictionPlaceState createState() => PredictionPlaceState();
}

class PredictionPlaceState extends State<PredictionPlace> {
  late final Future<List<Prediction>> future;

  @override
  void initState() {
    super.initState();
    future = AccountManager().getPredictions(widget.place.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name),
      ),
      body: Container(
        decoration: UI.gradientBox(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Widget that contains the place's co2level
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context)!.predictionPlaceSummary(
                      widget.place.name, widget.place.co2Level),
                  style: const TextStyle(fontSize: 40),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(AppLocalizations.of(context)!.predictionIntro,
                    style: const TextStyle(fontSize: 30)),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  height: 300,
                  child: FutureBuilder<List<Prediction>>(
                      future: future,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return LineChart(
                            LineChartData(
                              lineTouchData: LineTouchData(enabled: false),
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                show: true,
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: rightTitles(),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 24,
                              minY: 400,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: getSpots(snapshot.data!),
                                  isCurved: true,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text("${snapshot.error}");
                        }
                        return UI.spinText(
                            AppLocalizations.of(context)!.predictionLoading);
                      }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Converte una lista di predizioni in una lista di punti per il grafico
  List<FlSpot> getSpots(List<Prediction> snapshot) {
    // Converte una lista di predizioni in una lista di coppie di numeri
    final List<Map<String, double>> list = snapshot
        .map((e) => {'t': 0.toDouble(), 'c': e.co2.toDouble()})
        .toList();
    for (int i = 0; i < list.length; i++) {
      list[i]['t'] = i.toDouble();
    }
    return list.map((e) => FlSpot(e['t']!, e['c']!)).toList();
  }

  AxisTitles rightTitles() {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: bottomTitleWidgets,
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black87,
      fontFamily: 'Digital',
      fontSize: 16,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(hhmm(value), style: style),
    );
  }

  /// Restituisce l'orario in HH:MM di [offset] ore in avanti.
  String hhmm(double offset) {
    final int off = offset.toInt();
    final DateTime now = DateTime.now();
    final String hour = ((now.hour + off) % 24).toString();
    final String minutes = now.minute.toString().padLeft(2, '0');
    return '$hour:$minutes';
  }
}
