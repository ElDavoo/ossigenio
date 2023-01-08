import 'package:flutter/material.dart';
import 'package:flutter_app/managers/ble_man.dart';
import 'package:flutter_app/managers/gps_man.dart';
import 'package:flutter_app/managers/mqtt_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:flutter_app/ui/widgets/where_are_you.dart';
import 'package:flutter_app/utils/ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../utils/constants.dart';
import '../../utils/log.dart';
import '../../utils/place.dart';
import '../widgets/air_quality_device.dart';
import '../widgets/air_quality_place.dart';

class NewHomePage extends StatefulWidget {
  const NewHomePage({Key? key}) : super(key: key);

  @override
  NewHomePageState createState() => NewHomePageState();
}

class NewHomePageState extends State<NewHomePage>
    with AutomaticKeepAliveClientMixin<NewHomePage> {
  String name = 'null';

  @override
  void initState() {
    super.initState();
    // Se la posizione viene aggiornata e il luogo
    // selezionato non è più in lista, seleziona automaticamente
    // il null place
    GpsManager().placeStream.stream.listen((event) {
      if (!event.contains(MqttManager.place)) {
        setState(() {
          _onSelectedPlace(null);
        });
      }
    });
    // Get the name of the user from the preferences
    // and display it in the greeting text
    PrefManager().read(C.pref.username).then((value) {
      if (value != null) {
        setState(() {
          name = value;
        });
      }
    });
  }

  /// Gestisce il cambio di luogo selezionato.
  void _onSelectedPlace(Place? place) {
    if (place != null) {
      Log.d(AppLocalizations.of(context)!.placeSelected(place.name));
    } else {
      Log.d(AppLocalizations.of(context)!.placeNotSelected);
    }
    setState(() {
      MqttManager.place = place;
    });
  }

  /// Costruisce il testo che saluta l'utente.
  Widget _greetingText(String name) {
    const stylesmall = TextStyle(
        fontSize: 60.0, color: Colors.black87, fontWeight: FontWeight.w300);
    const stylebig = TextStyle(
      fontWeight: FontWeight.w500,
      color: Colors.blueAccent,
      fontSize: 90.0,
      shadows: <Shadow>[
        Shadow(
          offset: Offset(0.0, 0.0),
          blurRadius: 12.0,
          color: Colors.blueAccent,
        ),
        Shadow(
          offset: Offset(0.0, 0.0),
          blurRadius: 200.0,
          color: Color(0x330000FF),
        ),
      ],
    );
    return RichText(
      text: TextSpan(
        style: stylesmall,
        children: [
          _centeredTextSpan(AppLocalizations.of(context)!.greeting, stylesmall),
          _centeredTextSpan(name, stylebig),
        ],
      ),
    );
  }

  WidgetSpan _centeredTextSpan(String text, TextStyle style) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Text(text, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Column(
            children: <Widget>[
              UI.buildCard(
                FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topLeft,
                  child: _greetingText(name),
                ),
              ),
              UI.buildCard(WhereAreYou(
                onPlaceSelected: _onSelectedPlace,
              )),
              // Se non c'è un sensore collegato e viene selezionato un luogo,
              // mostra la qualità dell'aria del luogo selezionato
              if (MqttManager.place != null && BLEManager().dvc.value == null)
                UI.buildCard(AirQualityPlace(placeId: MqttManager.place!.id)),
              ValueListenableBuilder(
                valueListenable: BLEManager().dvc,
                builder: (context, dvc, child) {
                  if (dvc == null) {
                    return const SizedBox();
                  }
                  return UI.buildCard(AirQualityDevice(device: dvc));
                }
              ),
            ],
          )),
    );
  }

  // Vogliamo che la pagina rimanga in memoria
  @override
  bool get wantKeepAlive => true;
}
