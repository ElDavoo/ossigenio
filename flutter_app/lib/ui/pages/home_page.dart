import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../managers/ble_man.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../Messages/co2_message.dart';
import '../../Messages/debug_message.dart';
import '../../Messages/feedback_message.dart';
import '../../Messages/message.dart';
import '../widgets/debug_tab.dart';
import '../../utils/device.dart';
import '../../utils/log.dart';
import '../widgets/device_tab.dart';
import 'login_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //BLEManager bleManager = BLEManager();
  // get BLEManager from ChangeNotifierProvider

  StreamSubscription? _log;
  Device? _device;

  void _init() {
    // Read the device mac address from shared preferences
    PrefManager().read(PrefConstants.deviceMac).then((value) {
      /*if (value != null) {
        // Attempt to connect to the device
        bleManager.connectToDevice(value);
      }*/
    });
    _log = Log.addListener(context);
  }

  @override
  void initState() {
    super.initState();
    _init();
    //bleManager.startBLEScan();
  }

  @override
  void dispose() {
    BLEManager().stopBLEScan();
    _log?.cancel();
    super.dispose();
  }

  static Widget spinText(String text) {

    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircularProgressIndicator(),
            Text(text),
          ],
        ));
  }
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return DefaultTabController(
        initialIndex: 0,
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              // TODO: Dynamically change the accounts icon based on account status
              leading: IconButton(
                icon: const Icon(Icons.no_accounts),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
              title: Text(AppLocalizations.of(context)!.title),
              bottom: const TabBar(
                tabs: <Widget>[
                  Tab(
                    text: 'Device',
                  ),
                  Tab(
                    text: 'Messages (debug)',
                  ),
                ],
              ),
              actions: const [
                Icon(Icons.more_vert),
              ],
            ),
            body: FutureBuilder<ScanResult>(
                future: BLEManager().startBLEScan(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return FutureBuilder<Device>(
                      future: BLEManager().connectToDevice(snapshot.data!),
                       builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          _device = snapshot.data;
                          return ChangeNotifierProvider(
                            create: (context) => _device!,
                            child: TabBarView(
                              children: <Widget>[
                                Consumer<Device>(
                                  builder: (context, device, child) {
                                    return DeviceTab(device: device);
                                  },
                                ),
                                Consumer<Device>(
                                  builder: (context, device, child) {
                                    // Put debug tab here
                                    return DebugTab(device: device);
                                  },
                                ),
                              ],
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text("${snapshot.error}");
                        }
                        return spinText("Connessione...");
                       },);
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }
                  // By default, show a loading spinner.
                  return spinText("Scansione...");
                })));
  }


}
