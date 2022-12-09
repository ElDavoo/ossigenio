import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../managers/ble_man.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../managers/perm_man.dart';
import '../utils/device.dart';
import 'device_page.dart';


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
  BLEManager get bleManager => context.read<BLEManager>();
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TODO: Dynamically change the accounts icon based on account status
        leading: const Icon(Icons.no_accounts),
        title: Text(AppLocalizations.of(context)!.title),
        actions: const [
          Icon(Icons.more_vert),
        ],
      ),
      body:
      Stack(
        children:[
          //futurebuilder
          // if scan is in progress show loading screen
          //else nothing
          StreamBuilder(stream: bleManager.isScanning(), builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data == true) {
              return const Center(child: CircularProgressIndicator());
            }
            if (bleManager.devices.isEmpty) {
              return Center(child: Text(
                AppLocalizations.of(context)!.noDevicesFound,
              ));
            }
            return Container();
          }),
          Column(

            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget> [
                  TextButton(
                    onPressed: () async {
                      // Check if the app has the required permissions
                      if (await PermissionManager().checkPermissions()) {
                        ScaffoldMessenger.of(context).showSnackBar(PermissionManager.snackBarOk);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(PermissionManager.snackBarFail);
                      }
                    },
                    child: Container(
                      color: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: Text(
                        AppLocalizations.of(context)!.requestPermissionButton,
                        style: const TextStyle(color: Colors.white, fontSize: 13.0),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: bleManager.startBLEScan,
                    child: Container(
                      color: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: Text(
                        AppLocalizations.of(context)!.startScanButton,
                        style: const TextStyle(color: Colors.white, fontSize: 13.0),
                      ),
                    ),
                  ),
                  // if isScanning show progress
                  TextButton(
                    onPressed: bleManager.stopBLEScan,
                    child: Container(
                      color: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: Text(
                        AppLocalizations.of(context)!.stopScanButton,
                        style: const TextStyle(color: Colors.white, fontSize: 13.0),
                      ),
                    ),
                  ),
                  // Show circular progress bar if isScanning
                ],
              ),
              Expanded(child:
              // Add a ListView that uses Consumer to build
              // its items.
              Consumer<BLEManager>(
                builder: (context, bleManager, child) {
                  return ListView.builder(
                    itemCount: bleManager.devices.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(bleManager.devices[index].name),
                        subtitle: Text(bleManager.devices[index].id.toString()),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DevicePage(devic: Device(bleManager.devices[index]))),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              ),
            ],

          ),
        ],
      ),

    );
  }

}