/*
A stateless widget build from a Device.
It shows data in a cool way, with radiants
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Messages/message.dart';
import '../../managers/ble_man.dart';
import '../../utils/device.dart';

class DebugTab extends StatefulWidget {
  final Device device;

  const DebugTab({Key? key, required this.device}) : super(key: key);

  @override
  _DebugTabState createState() => _DebugTabState();
}

class _DebugTabState extends State<DebugTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.serialNumber.toString()),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Wrap(
              children: [
                TextButton(
                  onPressed: () {
                    BLEManager.sendMsg(widget.device, MessageTypes.msgRequest0);
                  },
                  child: const Text('Request 0'),
                ),
                TextButton(
                  onPressed: () {
                    BLEManager.sendMsg(widget.device, MessageTypes.msgRequest1);
                  },
                  child: const Text('Request 1'),
                ),
                TextButton(
                  onPressed: () {
                    BLEManager.sendMsg(widget.device, MessageTypes.msgRequest2);
                  },
                  child: const Text('Request 2'),
                ),
                TextButton(
                  onPressed: () {
                    BLEManager.sendMsg(widget.device, MessageTypes.msgRequest3);
                  },
                  child: const Text('Request 3'),
                ),
                TextButton(
                  onPressed: () {
                    BLEManager.sendMsg(widget.device, MessageTypes.msgRequest4);
                  },
                  child: const Text('Request 4'),
                ),
              ],
            ),
            Expanded(
              //Consumer of blemanager
              child:
                  // streambuilder
                  StreamBuilder<MessageWithDirection>(
                      stream: widget.device.messagesStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ListView.builder(
                            itemCount: widget.device.messages.length,
                            itemBuilder: (context, index) {
                              return Text(widget.device.messages[index].toString(),
                                  style: const TextStyle(fontSize: 13));
                            },
                          );
                        } else {
                          return const Text('No data');
                        }
                      }),
            ),
          ],
        ),
      ),
    );
  }
}
