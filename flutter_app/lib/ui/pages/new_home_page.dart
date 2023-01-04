import 'package:flutter/material.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_app/managers/ble_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:flutter_app/ui/widgets/air_quality.dart';
import 'package:flutter_app/ui/widgets/where_are_you.dart';
// import gpsmanager
import 'package:flutter_app/managers/gps_man.dart';
import 'package:flutter_app/utils/ui.dart';


class NewHomePage extends StatefulWidget {
  const NewHomePage({Key? key}) : super(key: key);

  @override
  _NewHomePageState createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> with AutomaticKeepAliveClientMixin<NewHomePage> {
  get name => "null";

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
  WidgetSpan buildCenteredTextSpan({required String text, required TextStyle style}) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Text(text, style: style),
    );
  }
  @override
  Widget build(BuildContext context) {
    // Get the name of the user from the preferences
    // and display it in the greeting text
    String name = "null";
    PrefManager().read(PrefConstants.username).then((value) {
      if (value != null) {
        setState(() {
          name = value;
        });
      }
    });
    return Padding(
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 16),
        child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            UIWidgets.buildCard(FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topLeft,
                  child: greetingText(name),
                ),
              ),
            UIWidgets.buildCard(WhereAreYou()),
            StreamBuilder(
              stream: BLEManager().devicestream.stream,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return UIWidgets.buildCard(AirQualityLocal(device: snapshot.data));
                } else {
                  return UIWidgets.buildCard(const Text("Loading..."));
                }
              },
            )
          ],
        )));
  }

  @override
  bool get wantKeepAlive => true;
}
