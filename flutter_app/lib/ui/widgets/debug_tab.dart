/*
A stateless widget build from a Device.
It shows data in a cool way, with radiants
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Messages/message.dart';
import '../../managers/ble_man.dart';
import '../../utils/device.dart';

class DebugTab extends StatelessWidget {
  final Device device;

  const DebugTab({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Wrap(
          children: [
            TextButton(
              onPressed: () {
                BLEManager.sendMsg(device, MessageTypes.msgRequest0);
              },
              child: const Text('Request 0'),
            ),
            TextButton(
              onPressed: () {
                BLEManager.sendMsg(device, MessageTypes.msgRequest1);
              },
              child: const Text('Request 1'),
            ),
            TextButton(
              onPressed: () {
                BLEManager.sendMsg(device, MessageTypes.msgRequest2);
              },
              child: const Text('Request 2'),
            ),
            TextButton(
              onPressed: () {
                BLEManager.sendMsg(device, MessageTypes.msgRequest3);
              },
              child: const Text('Request 3'),
            ),
            TextButton(
              onPressed: () {
                BLEManager.sendMsg(device, MessageTypes.msgRequest4);
              },
              child: const Text('Request 4'),
            ),
          ],
        ),
        Expanded(
          //Consumer of blemanager
          child:
          // changenotifierprovider

          Consumer<Device>(
            builder: (context, device, child) {
              return ListView.builder(
                itemCount: device.messages.length,
                itemBuilder: (context, index) {
                  return Text(device.messages[index].toString(),
                      style: const TextStyle(fontSize: 13));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}