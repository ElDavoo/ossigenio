import 'package:flutter/material.dart';
import 'package:flutter_app/managers/mqtt_man.dart';

import '../../managers/gps_man.dart';
import '../../utils/place.dart';

// A stateful widget which gets the list of nearby places
// And asks the user to select one of them
// And saves the selection in its state
class WhereAreYou extends StatefulWidget {
  // A function which is called when the user selects a place
  final Function(Place? place) onPlaceSelected;

  const WhereAreYou({Key? key, required this.onPlaceSelected})
      : super(key: key);

  @override
  WhereAreYouState createState() => WhereAreYouState();
}

class WhereAreYouState extends State<WhereAreYou> {
  Place? selectedPlace;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Dove ti trovi?", style: TextStyle(fontSize: 22)),
        //Padding to separate the text from the dropdown
        //const Padding(padding: EdgeInsets.all(10.0)),
        StreamBuilder(
          stream: GpsManager().placeStream.stream,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              List<DropdownMenuItem<Place>> items =
                  snapshot.data.map<DropdownMenuItem<Place>>((Place value) {
                return DropdownMenuItem<Place>(
                  value: value,
                  child: Text(value.name),
                );
              }).toList();
              // Add a "None" item to the list
              items.add(const DropdownMenuItem<Place>(
                value: null,
                child: Text("Nessuno"),
              ));
              return DropdownButton<Place>(
                // Check if the value is in the value list
                value: MqttManager.place,
                onChanged: (Place? newValue) {
                  widget.onPlaceSelected(newValue);
                  selectedPlace = newValue;
                },
                items: items,
              );
            } else {
              return const Text("Loading...");
            }
          },
        )
      ],
    );
  }
}
