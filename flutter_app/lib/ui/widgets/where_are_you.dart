import 'package:flutter/material.dart';
import 'package:flutter_app/managers/mqtt_man.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../managers/gps_man.dart';
import '../../utils/place.dart';
import '../../utils/ui.dart';

/// Un widget che chiede all'utente dove si trova
class WhereAreYou extends StatefulWidget {
  // Una funzione chiamata quando l'utente ha selezionato un posto
  final Function(Place? place) onPlaceSelected;

  const WhereAreYou({Key? key, required this.onPlaceSelected})
      : super(key: key);

  @override
  WhereAreYouState createState() => WhereAreYouState();
}

class WhereAreYouState extends State<WhereAreYou> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(AppLocalizations.of(context)!.whereAreYou,
            style: const TextStyle(fontSize: 22)),
        ValueListenableBuilder(
            valueListenable: GpsManager().placeStream,
            builder: (context, place, _) {
              if (place.isEmpty) {
                return UI.spinText(AppLocalizations.of(context)!.loading);
              }
              List<DropdownMenuItem<Place>> items =
                  place.map<DropdownMenuItem<Place>>((Place value) {
                return DropdownMenuItem<Place>(
                  value: value,
                  child: Text(value.name),
                );
              }).toList();
              // Add a "None" item to the list
              items.add(DropdownMenuItem<Place>(
                value: null,
                child: Text(AppLocalizations.of(context)!.noPlaceSelected),
              ));
              return DropdownButton<Place>(
                // Check if the value is in the value list
                value: MqttManager.place.value,
                onChanged: (Place? newValue) {
                  widget.onPlaceSelected(newValue);
                },
                items: items,
              );
            }),
      ],
    );
  }
}
