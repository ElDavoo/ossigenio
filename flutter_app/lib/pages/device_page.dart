import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/Messages/feedback_message.dart';
import 'package:flutter_app/Messages/message.dart';
import 'package:flutter_app/utils/serial.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../utils/device.dart';
import '../Messages/co2_message.dart';
import '../Messages/debug_message.dart';
import '../managers/ble_man.dart';
import '../utils/log.dart';
/*
class DevicePage extends StatefulWidget {
  final Device devic;

  const DevicePage({Key? key, required this.devic}) : super(key: key);

  @override
  _DevicePageState createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {

  StreamSubscription ?_log;

  @override
  void initState(){
    super.initState();
    _log ??= Log.addListener(context);

  }

  @override
  void dispose() {
    super.dispose();
    _log?.cancel();
  }

  // Override back button and disconnect
  Future<bool> _onWillPop() async {
    BLEManager().disconnect();
    return true;
  }



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: DefaultTabController(
            initialIndex: 0,
            length: 2,
            child: Scaffold(
                appBar: AppBar(
                  title: const Text('Device'),
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
                ),
                body: TabBarView(
                  children: <Widget>[
                    RefreshIndicator(
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
                                            final CO2Message msg = snapshot
                                                .data!.message as CO2Message;
                                            co2 = msg.co2;
                                          }
                                          if (snapshot.data!.message.type ==
                                              MessageTypes.feedbackMessage) {
                                            final FeedbackMessage msg = snapshot
                                                .data!
                                                .message as FeedbackMessage;
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
                                  stream:
                                      BLEManager().messagesStream,
                                  builder: (context, snapshot) {
                                    int temp = 0;
                                    if (snapshot.hasData) {
                                      // If message contains a co2 field
                                      if (snapshot.data!.message.type ==
                                          MessageTypes.co2Message) {
                                        // Cast to CO2Message
                                        final CO2Message msg = snapshot
                                            .data!.message as CO2Message;
                                        temp = msg.temperature;
                                      }
                                      if (snapshot.data!.message.type ==
                                          MessageTypes.feedbackMessage) {
                                        final FeedbackMessage msg = snapshot
                                            .data!.message as FeedbackMessage;
                                        temp = msg.temperature;
                                      }
                                      if (snapshot.data!.message.type ==
                                          MessageTypes.debugMessage) {
                                        final FeedbackMessage msg = snapshot
                                            .data!.message as FeedbackMessage;
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
                                  stream:
                                      BLEManager().messagesStream,
                                  builder: (context, snapshot) {
                                    int hum = 0;
                                    if (snapshot.hasData) {
                                      // If message contains a co2 field
                                      if (snapshot.data!.message.type ==
                                          MessageTypes.co2Message) {
                                        // Cast to CO2Message
                                        final CO2Message msg = snapshot
                                            .data!.message as CO2Message;
                                        hum = msg.humidity;
                                      }
                                      if (snapshot.data!.message.type ==
                                          MessageTypes.feedbackMessage) {
                                        final FeedbackMessage msg = snapshot
                                            .data!.message as FeedbackMessage;
                                        hum = msg.humidity;
                                      }
                                      if (snapshot.data!.message.type ==
                                          MessageTypes.debugMessage) {
                                        final FeedbackMessage msg = snapshot
                                            .data!.message as FeedbackMessage;
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
                                  stream:
                                      BLEManager().messagesStream,
                                  builder: (context, snapshot) {
                                    int data = 0;
                                    if (snapshot.hasData) {
                                      // If message contains a co2 field
                                      if (snapshot.data!.message.type ==
                                          MessageTypes.debugMessage) {
                                        final DebugMessage msg = snapshot
                                            .data!.message as DebugMessage;
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
                      },
                    ),
                    Column(
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

                              // Change page if connected
                              if (bleManager.device != null){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => DevicePage(devic: bleManager.device!)),
                                );
                              }
                              return Container();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ))));
  }


}
*/