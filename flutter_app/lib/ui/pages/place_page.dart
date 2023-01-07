import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/utils/ui.dart';

import '../../managers/account_man.dart';

// A stateful widget which takes a place,
// Asks the api for the predictions and displays them

class PredictionPlace extends StatefulWidget {
  final Place place;

  const PredictionPlace({Key? key, required this.place}) : super(key: key);

  @override
  PredictionPlaceState createState() => PredictionPlaceState();
}

// A Prediction is a pair of "timestamp - co2 level"
class Prediction {
  DateTime timestamp;
  int co2;

  Prediction(this.timestamp, this.co2);

  // fromJson constructor
  Prediction.fromJson(Map<String, dynamic> json)
      : timestamp = DateTime.parse(json['timestamp']),
        co2 = json['co2'];
}

class PredictionPlaceState extends State<PredictionPlace> {
  late Future<List<Prediction>> future;

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Widget that contains the place's co2level
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Al momento a ${widget.place.name} ci sono ${widget.place.co2Level} ppm di CO2",
                  style: const TextStyle(fontSize: 40),
                  textAlign: TextAlign.center,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Livelli di CO2 previsti per le prossime 24h'),
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
                              borderData: FlBorderData(show: true),
                              minX: 0,
                              maxX: 24,
                              minY: 400,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: getSpots(snapshot),
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
                        return UIWidgets.spinText("Sto predicendo il futuro...");
                      }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> getSpots(AsyncSnapshot<List<Prediction>> snapshot) {
    var list =
        snapshot.data!.map((e) => {'t': 0, 'c': e.co2.toDouble()}).toList();
    // Delete X and make it progressive
    for (int i = 0; i < list.length; i++) {
      list[i]['t'] = i.toDouble();
    }
    return list
        .map((e) => FlSpot(e['t']!.toDouble(), e['c']!.toDouble()))
        .toList();
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
      color: Colors.blueGrey,
      fontFamily: 'Digital',
      fontSize: 18,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(hhmm(value.toInt()), style: style),
    );
  }

  String hhmm(int offset) {
    // Get the current HH:MM
    var now = DateTime.now();
    var hour = (now.hour + offset) % 24;
    var minute = now.minute;
    return '$hour:$minute';
  }
}
