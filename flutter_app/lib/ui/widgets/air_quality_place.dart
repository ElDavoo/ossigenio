import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../managers/account_man.dart';
import '../../utils/place.dart';
import '../../utils/ui.dart';
import 'air_quality.dart';

/// Un widget che, dato un id di posto, ne visualizza la qualità
class AirQualityPlace extends StatefulWidget {
  final int placeId;

  const AirQualityPlace({Key? key, required this.placeId}) : super(key: key);

  @override
  AirQualityPlaceState createState() => AirQualityPlaceState();
}

class AirQualityPlaceState extends State<AirQualityPlace> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Place>(
        future: AccountManager().getPlace(widget.placeId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return AirQuality(
              co2:
                  snapshot.data!.co2Level > 400 ? snapshot.data!.co2Level : 400,
            );
          }
          return UI.spinText(AppLocalizations.of(context)!.loading);
        });
  }
}
