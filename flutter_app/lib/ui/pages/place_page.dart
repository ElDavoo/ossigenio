import 'package:flutter/material.dart';

import '../../managers/account_man.dart';

// A stateful widget which takes a place,
// Asks the api for the predictions and displays them

class PredictionPlace extends StatefulWidget {
  Place place;

  PredictionPlace({Key? key, required this.place}) : super(key: key);

  @override
  _PredictionPlaceState createState() => _PredictionPlaceState();
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

class _PredictionPlaceState extends State<PredictionPlace> {
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
      body: FutureBuilder<List<Prediction>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(snapshot.data![index].timestamp.toString()),
                      subtitle: Text(snapshot.data![index].co2.toString()),
                    );
                  });
            }
            return const Text('No data');
          }),
    );
  }
}