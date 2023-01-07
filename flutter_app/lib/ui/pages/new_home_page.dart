import 'package:flutter/material.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_app/managers/ble_man.dart';
import 'package:flutter_app/managers/mqtt_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:flutter_app/ui/widgets/where_are_you.dart';
import 'package:flutter_app/managers/gps_man.dart';
import 'package:flutter_app/utils/ui.dart';
import '../../utils/constants.dart';
import '../../utils/log.dart';
import '../widgets/air_quality_local.dart';
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
    GpsManager().placeStream.stream.listen((event) => onUpdatedPlaces(event));
  }
  void onSelectedPlace(Place? place) {
    if (place != null) {
      Log.l("Selected place: ${place.name}");
    } else {
      Log.l("Selected place: null");
    }
    setState(() {
      MqttManager.place = place;
    });
  }

  Widget greetingText(String name) {
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
        // Note: Styles for TextSpans must be explicitly defined.
        // Child text spans will inherit styles from parent
        style: stylesmall,
        children: [
          buildCenteredTextSpan(text: "Ciao, ", style: stylesmall),
          buildCenteredTextSpan(text: name, style: stylebig),
        ],
      ),
    );
  }

  WidgetSpan buildCenteredTextSpan(
      {required String text, required TextStyle style}) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Text(text, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Get the name of the user from the preferences
    // and display it in the greeting text

    PrefManager().read(PrefConstants.username).then((value) {
      if (value != null) {
        setState(() {
          name = value;
        });
      }
    });


    return Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: SingleChildScrollView(
            child: Column(
          children: <Widget>[
            UIWidgets.buildCard(
              FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.topLeft,
                child: greetingText(name),
              ),
            ),
            UIWidgets.buildCard(WhereAreYou(
              onPlaceSelected: onSelectedPlace,
            )),
            if (MqttManager.place != null && BLEManager().dvc == null)
              UIWidgets.buildCard(
                  AirQualityPlace(placeId: MqttManager.place!.id)),
            StreamBuilder(
              stream: BLEManager().disconnectstream.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Container();
                } else {
                  if (BLEManager().dvc != null) {
                          return UIWidgets.buildCard(
                              AirQualityLocal(device: BLEManager().dvc!));


                  } else {
                    return Container();
                  }
                }
              },
            ),
          ],
        )));
  }

  @override
  bool get wantKeepAlive => true;

  onUpdatedPlaces(List<Place> event) {
    if (!event.contains(MqttManager.place)) {
      setState(() {
        onSelectedPlace(null);
      });
    }
  }
}
