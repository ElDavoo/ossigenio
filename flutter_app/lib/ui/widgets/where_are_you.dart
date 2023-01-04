import 'package:flutter/material.dart';

import '../../managers/account_man.dart';
import '../../managers/gps_man.dart';

// A stateful widget which gets the list of nearby places
// And asks the user to select one of them
// And saves the selection in its state
class WhereAreYou extends StatefulWidget {
  Place? selectedPlace;

  WhereAreYou({Key? key}) : super(key: key);

  @override
  _WhereAreYouState createState() => _WhereAreYouState();
}

class _WhereAreYouState extends State<WhereAreYou> {
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
            return DropdownButton<Place>(
              value: widget.selectedPlace,
              onChanged: (Place? newValue) {
                setState(() {
                  widget.selectedPlace = newValue!;
                });
              },
              items: snapshot.data.map<DropdownMenuItem<Place>>((Place value) {
                return DropdownMenuItem<Place>(
                  value: value,
                  child: Text(value.name),
                );
              }).toList(),
          );
            } else {
              return const Text("Loading...");
            }
          },)
      ],
    );
  }
}