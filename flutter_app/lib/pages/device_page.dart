import 'package:flutter/material.dart';
import 'package:flutter_app/Messages/message.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../utils/device.dart';
import '../Messages/co2_message.dart';
import '../managers/ble_man.dart';

class DevicePage extends StatefulWidget {
  final Device devic;

  const DevicePage({Key? key, required this.devic}) : super(key: key);

  @override
  _DevicePageState createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  // Override back button and disconnect
  Future<bool> _onWillPop() async {
    widget.devic.bleManager.disconnect();
    return true;
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
                    // Add a 2x2 grid
                    GridView.count(
                      crossAxisCount: 2,
                      children: <Widget>[
                        // Add a card with the device name
                        Card(
                          child: Center(
                            child:
                                // Gauge which listens to message stream
                                StreamBuilder<MessageWithDirection>(
                                    stream:
                                        widget.devic.bleManager.messagesStream,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        // If message contains a co2 field
                                        if (snapshot.data!.message.type ==
                                            MessageTypes.co2Message) {
                                          // Cast to CO2Message
                                          final CO2Message msg = snapshot
                                              .data!.message as CO2Message;
                                          return buildGauge(
                                              'CO2', 0, 500, msg.co2);
                                        }
                                      }
                                      return buildGauge('CO2', 0, 500, 0);
                                    }),
                          ),
                        ),
                        // Add a card with the device address
                        const Card(
                          child: Center(
                            child: Placeholder(),
                          ),
                        ),
                        // Add a card with the device rssi
                        const Card(
                          child: Center(
                            child: Placeholder(),
                          ),
                        ),
                        // Add a card with the device battery
                        const Card(
                          child: Center(
                            child: Placeholder(),
                          ),
                        ),
                      ],
                    ),

                    Column(
                      children: <Widget>[
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                widget.devic.bleManager.serial
                                    ?.sendMsg(MessageTypes.msgRequest0);
                              },
                              child: const Text('Request 0'),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.devic.bleManager.serial
                                    ?.sendMsg(MessageTypes.msgRequest1);
                              },
                              child: const Text('Request 1'),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.devic.bleManager.serial
                                    ?.sendMsg(MessageTypes.msgRequest2);
                              },
                              child: const Text('Request 2'),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.devic.bleManager.serial
                                    ?.sendMsg(MessageTypes.msgRequest3);
                              },
                              child: const Text('Request 3'),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.devic.bleManager.serial
                                    ?.sendMsg(MessageTypes.msgRequest4);
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
                    )
                  ],
                ))));
  }
}
