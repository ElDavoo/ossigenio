import 'package:flutter/material.dart';
import 'package:flutter_app/perm_man.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';
import 'ble_man.dart';
import 'package:riverpod/riverpod.dart';


void main() {
  /*runApp(
      MultiProvider(providers: [
        ChangeNotifierProvider(create: (context) => BLEManager()),
      ],
        child: const MyApp(),
      ));*/
  runApp(const MyApp());
}

final StateProvider<List<BluetoothDevice>> devices = StateProvider((ref) => []);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Quality Monitor',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Air Quality Monitor'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BLEManager bleManager = BLEManager();

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
        title: Text(widget.title),
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
            if (snapshot.hasData) {
              if (snapshot.data == true) {
                return const Center(child: CircularProgressIndicator());
              }
              else {
                if (bleManager.devices.isEmpty) {
                  return const Center(child: Text("No scan in progress"));
                } else {
                  return Container();
                }
              }
            }
            else {
              if (bleManager.devices.isEmpty) {
                return const Center(child: Text("No scan in progress"));
              } else {
                return Container();
              }
            }
          }),
          Column(

              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget> [
                    TextButton(
                      onPressed: PermissionManager().checkPermissions,
                      child: Container(
                        color: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: const Text(
                          'Request permission',
                          style: TextStyle(color: Colors.white, fontSize: 13.0),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: bleManager.startBLEScan,
                      child: Container(
                        color: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: const Text(
                          'scan',
                          style: TextStyle(color: Colors.white, fontSize: 13.0),
                        ),
                      ),
                    ),
    // if isScanning show progress
                    TextButton(
                      onPressed: bleManager.stopBLEScan,
                      child: Container(
                        color: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: const Text(
                          'stop scan',
                          style: TextStyle(color: Colors.white, fontSize: 13.0),
                        ),
                      ),
                    ),
                    // Show circular progress bar if isScanning
                  ],
                ),
                Expanded(child:
                // Add a ListView that uses Consumer to build
                // its items.
                ChangeNotifierProvider<BLEManager>(
                  create: (context) => bleManager,
                  child: Consumer<BLEManager>(
                    builder: (context, bleManager, child) {
                      return ListView.builder(
                        itemCount: bleManager.devices.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(bleManager.devices[index].name),
                            subtitle: Text(bleManager.devices[index].id.toString()),
                            onTap: () {
                              //bleManager.connectToDevice(bleManager.devices[index]);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                ),
              ],

        ),
      ],
          ),
    );
  }

}
