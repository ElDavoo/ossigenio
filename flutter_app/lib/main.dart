import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

/// The base class for the different types of items the list can contain.
abstract class ListItem {
  /// The title line to show in a list item.
  Widget buildTitle(BuildContext context);

  /// The subtitle line, if any, to show in a list item.
  Widget buildSubtitle(BuildContext context);
}

/// A ListItem that contains data to display a heading.
class HeadingItem implements ListItem {
  final String heading;

  HeadingItem(this.heading);

  @override
  Widget buildTitle(BuildContext context) {
    return Text(
      heading,
      style: Theme.of(context).textTheme.headline5,
    );
  }

  @override
  Widget buildSubtitle(BuildContext context) => const SizedBox.shrink();
}

/// A ListItem that contains data to display a message.
class MessageItem implements ListItem {
  final String sender;
  final String body;

  MessageItem(this.sender, this.body);

  @override
  Widget buildTitle(BuildContext context) => Text(sender);

  @override
  Widget buildSubtitle(BuildContext context) => Text(body);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
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

class MyAppp extends StatelessWidget {
  const MyAppp({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'Basic List';

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(title),
        ),
        body: ListView(
          children: const <Widget>[
            ListTile(
              leading: Icon(Icons.map),
              title: Text('Map'),
            ),
            ListTile(
              leading: Icon(Icons.photo_album),
              title: Text('Album'),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Phone'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<String> propList = ["brown", "blue", "green", "yellow", "red"];

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
      // Ask for bluettoth_scan permission using the permission library
      // https://pub.dev/packages/permission_handler
      Permission.bluetoothScan.request();


      //Create a new instance of FlutterBlue
      FlutterBlue flutterBlue = FlutterBlue.instance;
      //Start scanning
      flutterBlue.startScan(timeout: Duration(seconds: 4));
      //Listen to scan results
      var subscription = flutterBlue.scanResults.listen((results) {
        // do something with scan results
        for (ScanResult r in results) {
          print('${r.device.name} found! rssi: ${r.rssi}');
        }
      });
      // Stop scanning
      flutterBlue.stopScan();
    });
  }

  Future<void> _requestPermissions() async {
    // Ask for bluettoth_scan permission using the permission library
    // https://pub.dev/packages/permission_handler
    // You can request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetoothScan,
Permission.location,
      Permission.bluetoothConnect,
    ].request();

    // check if status is null
    if (statuses[Permission.bluetoothScan] != null) {
      if(statuses[Permission.bluetoothScan]!.isDenied){ //check each permission status after.
        print("Location permission is denied.");
      }

      if(statuses[Permission.locationWhenInUse]!.isDenied){ //check each permission status after.
        print("Camera permission is denied.");
      }
    }


  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        leading: Icon(Icons.no_accounts),
        title: Text(widget.title),
        actions: const [
          Icon(Icons.more_vert),
        ],
      ),
      body:
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
      Column(

          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[

            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            TextButton(
              onPressed: _requestPermissions,
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
              onPressed: _scan,
              child: Container(
                color: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: const Text(
                  'scan',
                  style: TextStyle(color: Colors.white, fontSize: 13.0),
                ),
              ),
            ),
            // Add a list view to display the scan results
            ListView.builder(
              shrinkWrap: true,
              itemCount: propList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(propList[index]),
                );
              },
            ),
          ],

        ),

      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _scan() {
    //Create a new instance of FlutterBlue
    FlutterBlue flutterBlue = FlutterBlue.instance;
    //Start scanning
    flutterBlue.startScan(timeout: Duration(seconds: 4));
    //Listen to scan results
    var subscription = flutterBlue.scanResults.listen((results) {
      // do something with scan results
      setState(() {
        for (ScanResult r in results) {
          print('${r.device.name} found! rssi: ${r.rssi}');
          propList.add(r.device.name);
        }
      });
    });
    // Stop scanning
    flutterBlue.stopScan();
  }
}
