/*
Class to handle connections to mqtt server using mqtt5_client package
 */
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import '../Messages/message.dart';
import '../Messages/co2_message.dart';
import '../utils/log.dart';

class MqttConstants {
  static const String server = 'modena.davidepalma.it';
  static const int mqttsPort = 8080;
  static const String co2Topic = 'co2';
  static const int mqttPort = 1883;
}

class MqttManager {

  late MqttServerClient client;
  // method to connect to the mqtt server
  void connect(String username, String password) async {
    // create the client mqtts://modena.davidepalma.it:8080
    // TODO add the client id

    client = MqttServerClient.withPort(
        MqttConstants.server,
        'test',
        MqttConstants.mqttPort);
    //client.secure = true;
    // set the port
    client.logging(on: true);
    // TODO set the username and password
    try {
      await client.connect('test', 'test2').then((value) => Log.l(value.toString()));
    } catch (e) {
      Log.l(e.toString());
    }
  }
  //constructor
  MqttManager() {
    // connect to the mqtt server
    connect('test', 'test2');
  }
  //method to disconnect from the mqtt server
  void disconnect() {
    client.disconnect();
  }
  //method to publish a Message to the mqtt server
  void publish(Message message) {
    // check the type of the message
    if (message is CO2Message) {
      // publish the message
      // TODO device id = ?
      publishCo2(message);
    }
  }
  void publishCo2(CO2Message message) {
    // publish the message
    // TODO device id = ?
    client.publishMessage('deviceId/$MqttConstants.co2', MqttQos.atMostOnce, intToBuffer(message.co2));
  }
  Uint8Buffer intToBuffer(int i) {
    var result = Uint8Buffer(4);
    result.buffer.asByteData().setInt32(0, i);
    return result;
  }

}