import 'package:flutter/material.dart';
import 'package:flutter_app/managers/ble_man.dart';
import 'package:flutter_app/utils/ui.dart';

import '../widgets/air_quality_device.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  HomeTabState createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            children: <Widget>[
              ValueListenableBuilder(
                  valueListenable: BLEManager().dvc,
                  builder: (context, dvc, _) {
                    if (dvc == null) {
                      return const SizedBox();
                    }
                    return UI.buildCard(AirQualityDevice(device: dvc));
                  }),
            ],
          )),
    );
  }
}
