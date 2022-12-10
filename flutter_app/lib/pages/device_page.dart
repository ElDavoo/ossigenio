import 'package:flutter/material.dart';
import 'package:flutter_app/Messages/message.dart';
import 'package:provider/provider.dart';

import '../../utils/device.dart';
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
                    const Placeholder(),
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
                )],
                ))));
  }
}
