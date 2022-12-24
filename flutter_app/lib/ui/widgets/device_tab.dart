/*
A stateless widgets that show the data of a device
 */
import 'package:flutter/material.dart';

import '../../Messages/co2_message.dart';
import '../../Messages/debug_message.dart';
import '../../Messages/feedback_message.dart';
import '../../Messages/message.dart';
import '../../managers/ble_man.dart';
import '../../utils/device.dart';
import '../../utils/ui.dart';

class DeviceTab extends StatelessWidget {
  final Device device;

  const DeviceTab({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
                  stream: device.messagesStream,
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
                        final FeedbackMessage msg =
                        snapshot.data!.message as FeedbackMessage;
                        co2 = msg.co2;
                      }
                    }
                    return UIWidgets.buildGauge('CO2', 150, 2000, co2);
                  }),
            ),
          ),
          // Add a card with the device address
          Card(
            child: Center(
              child: StreamBuilder<MessageWithDirection>(
                  stream: device.messagesStream,
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
                    return UIWidgets.buildGauge('°C', 0, 30, temp);
                  }),
            ),
          ),
          // Add a card with the device rssi
          Card(
            child: Center(
              child: StreamBuilder<MessageWithDirection>(
                  stream: device.messagesStream,
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
                    return UIWidgets.buildGauge('💧', 0, 100, hum);
                  }),
            ),
          ),
          // Add a card with the device battery
          Card(
            child: Center(
              child: StreamBuilder<MessageWithDirection>(
                  stream: device.messagesStream,
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
                    return UIWidgets.buildGauge('raw', 0, 500, data);
                  }),
            ),
          ),
          Card(
            child: Center(
              child: StreamBuilder<int>(
                  stream: BLEManager.rssiStream(device),
                  builder: (context, snapshot) {
                    int data = 0;
                    if (snapshot.hasData) {
                      // abs of rssi
                      data = snapshot.data!.abs();
                    }
                    return UIWidgets.buildGauge(data.toString(), 40, 100, data);
                  }),
            ),
          ),
        ],
      ),
      onRefresh: () {
        return refresh(device);
      },
    );
  }

  static Future<void> refresh(Device device) async {
    BLEManager.sendMsg(device, MessageTypes.msgRequest1);
    //BLEManager().serial?.sendMsg(MessageTypes.msgRequest2);
    //Wait to get a packet from the device, so listen to the stream for one packet
    await device.messagesStream.first;
  }


}