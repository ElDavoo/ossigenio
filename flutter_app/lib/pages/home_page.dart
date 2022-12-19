import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../managers/ble_man.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../managers/perm_man.dart';
import '../Messages/co2_message.dart';
import '../Messages/debug_message.dart';
import '../Messages/feedback_message.dart';
import '../Messages/message.dart';
import '../utils/device.dart';
import '../utils/log.dart';
import 'device_page.dart';
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

  BLEManager get bleManager => context.read<BLEManager>();

  void _init() {
    bleManager.startBLEScan();
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
    bleManager.stopBLEScan();
    _log?.cancel();
    super.dispose();
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
          body:
          TabBarView(

            children: <Widget>[
              Consumer<BLEManager>(
                builder: (context, bleManager, child) {
                  if (bleManager.device != null) {
                    return DevicePage();
                  } else {
                    return const Center(
                      child: Text('No device connected')
                    );
                  }
                },
              ),

              debugPage(),
            ],
          ),
        ));
  }

  //Build a gauge with minimum, maximum and current value
  Widget buildGauge(String title, int min, int max, int value) {
    return Stack(
      children: [
        SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
                minimum: min.toDouble(),
                maximum: max.toDouble(),
                ranges: <GaugeRange>[
                  GaugeRange(
                      startValue: min.toDouble(),
                      endValue: max.toDouble(),
                      gradient: const SweepGradient(
                          colors: <Color>[Colors.green, Colors.red],
                          stops: <double>[0.25, 0.75]),
                      startWidth: 10,
                      endWidth: 10),
                ],
                pointers: <GaugePointer>[
                  NeedlePointer(
                      value: value.toDouble(),
                      enableAnimation: true,
                      animationType: AnimationType.ease,
                      animationDuration: 500,
                      needleColor: Colors.red,
                      needleStartWidth: 1,
                      needleEndWidth: 5,
                      lengthUnit: GaugeSizeUnit.factor,
                      needleLength: 0.8,
                      knobStyle: const KnobStyle(
                          knobRadius: 0,
                          sizeUnit: GaugeSizeUnit.factor,
                          color: Colors.red))
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                      widget: Text(title,
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold)),
                      angle: 90,
                      positionFactor: 0.1)
                ])
          ],
        ),
        if (value == 0)
          Container(
            color: Colors.white.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Future<void> refresh() async {
    BLEManager().sendMsg(MessageTypes.msgRequest1);
    //BLEManager().serial?.sendMsg(MessageTypes.msgRequest2);
    //Wait to get a packet from the device, so listen to the stream for one packet
    await BLEManager().messagesStream?.first;
  }

  Widget debugPage() {
    return Column(
      children: <Widget>[
        Wrap(
          children: [
            TextButton(
              onPressed: () {
                BLEManager().sendMsg(MessageTypes.msgRequest0);
              },
              child: const Text('Request 0'),
            ),
            TextButton(
              onPressed: () {
                BLEManager().sendMsg(MessageTypes.msgRequest1);
              },
              child: const Text('Request 1'),
            ),
            TextButton(
              onPressed: () {
                BLEManager().sendMsg(MessageTypes.msgRequest2);
              },
              child: const Text('Request 2'),
            ),
            TextButton(
              onPressed: () {
                BLEManager().sendMsg(MessageTypes.msgRequest3);
              },
              child: const Text('Request 3'),
            ),
            TextButton(
              onPressed: () {
                BLEManager().sendMsg(MessageTypes.msgRequest4);
              },
              child: const Text('Request 4'),
            ),
          ],
        ),
        Expanded(
          //Consumer of blemanager
          child: Consumer<BLEManager>(
            builder: (context, bleManager, child) {
              return ListView.builder(
                itemCount: bleManager.messages.length,
                itemBuilder: (context, index) {
                  return Text(
                      bleManager.messages[index].toString(),
                      style: const TextStyle(fontSize: 13));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget DevicePage() {
    return               RefreshIndicator(
        child: GridView.count(
        crossAxisCount: 2,
        physics: const AlwaysScrollableScrollPhysics(),
    children: <Widget>[
    // Add a card with the device name
    Card(
    child: Center(
    child:
    // Gauge which listens to message stream
    StreamBuilder<MessageWithDirection>(
    stream: BLEManager().messagesStream,
    builder: (context, snapshot) {
    int co2 = 0;
    if (snapshot.hasData) {
    // If message contains a co2 field
    if (snapshot.data!.message.type ==
    MessageTypes.co2Message) {
    // Cast to CO2Message
    final CO2Message msg =
    snapshot.data!.message as CO2Message;
    co2 = msg.co2;
    }
    if (snapshot.data!.message.type ==
    MessageTypes.feedbackMessage) {
    final FeedbackMessage msg = snapshot
        .data!.message as FeedbackMessage;
    co2 = msg.co2;
    }
    }
    return buildGauge('CO2', 150, 2000, co2);
    }),
    ),
    ),
    // Add a card with the device address
    Card(
    child: Center(
    child: StreamBuilder<MessageWithDirection>(
    stream: BLEManager().messagesStream,
    builder: (context, snapshot) {
    int temp = 0;
    if (snapshot.hasData) {
    // If message contains a co2 field
    if (snapshot.data!.message.type ==
    MessageTypes.co2Message) {
    // Cast to CO2Message
    final CO2Message msg =
    snapshot.data!.message as CO2Message;
    temp = msg.temperature;
    }
    if (snapshot.data!.message.type ==
    MessageTypes.feedbackMessage) {
    final FeedbackMessage msg =
    snapshot.data!.message as FeedbackMessage;
    temp = msg.temperature;
    }
    if (snapshot.data!.message.type ==
    MessageTypes.debugMessage) {
    final FeedbackMessage msg =
    snapshot.data!.message as FeedbackMessage;
    temp = msg.temperature;
    }
    }
    return buildGauge('°C', 0, 30, temp);
    }),
    ),
    ),
    // Add a card with the device rssi
    Card(
    child: Center(
    child: StreamBuilder<MessageWithDirection>(
    stream: BLEManager().messagesStream,
    builder: (context, snapshot) {
    int hum = 0;
    if (snapshot.hasData) {
    // If message contains a co2 field
    if (snapshot.data!.message.type ==
    MessageTypes.co2Message) {
    // Cast to CO2Message
    final CO2Message msg =
    snapshot.data!.message as CO2Message;
    hum = msg.humidity;
    }
    if (snapshot.data!.message.type ==
    MessageTypes.feedbackMessage) {
    final FeedbackMessage msg =
    snapshot.data!.message as FeedbackMessage;
    hum = msg.humidity;
    }
    if (snapshot.data!.message.type ==
    MessageTypes.debugMessage) {
    final FeedbackMessage msg =
    snapshot.data!.message as FeedbackMessage;
    hum = msg.humidity;
    }
    }
    return buildGauge('💧', 0, 100, hum);
    }),
    ),
    ),
    // Add a card with the device battery
    Card(
    child: Center(
    child: StreamBuilder<MessageWithDirection>(
    stream: BLEManager().messagesStream,
    builder: (context, snapshot) {
    int data = 0;
    if (snapshot.hasData) {
    // If message contains a co2 field
    if (snapshot.data!.message.type ==
    MessageTypes.debugMessage) {
    final DebugMessage msg =
    snapshot.data!.message as DebugMessage;
    data = msg.rawData;
    }
    }
    return buildGauge('raw', 0, 500, data);
    }),
    ),
    ),
    ],
    ),
    onRefresh: () {
    return refresh();
    },);
  }
}
