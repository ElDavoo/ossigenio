/*
Class to handle connections to mqtt server using mqtt5_client package
 */
import 'dart:convert';

import 'package:flutter_app/Messages/feedback_message.dart';
import 'package:flutter_app/Messages/startup_message.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import '../Messages/debug_message.dart';
import '../Messages/message.dart';
import '../Messages/co2_message.dart';
import '../utils/constants.dart';
import '../utils/log.dart';
import '../utils/mac.dart';



class MqttManager {
  static final MqttManager instance = MqttManager._internal();

  static Place? place;

  factory MqttManager({required MacAddress mac}) {
    instance.mac = mac;
    return instance;
  }

  late MacAddress mac;

  MqttManager._internal() {
    tryLogin();
  }

  void tryLogin() {
    login().then((value) => client );
  }

  Future<MqttServerClient> loginFromSecureStorage() async {
    Log.l('Logging in from secure storage...');
    if (await PrefManager().areMqttDataSaved()) {
      Log.l('Data saved');
      String username = await PrefManager().read(PrefConstants.mqttUsername) as String;
      String password = await PrefManager().read(PrefConstants.mqttPassword) as String;
      try {
        return await connect(username, password);
      } catch (e) {
        // delete saved data
        await PrefManager().delete(PrefConstants.mqttUsername);
        await PrefManager().delete(PrefConstants.mqttPassword);
        return Future.error(e);
      }
    } else {
      return Future.error('No credentials saved');
    }
  }

  Future<MqttServerClient> login() async {
    Log.l('Logging in...');
    // Try to login with saved credentials.
    // if it fails, get new credentials from server and try again.
    try {
      return await loginFromSecureStorage();
    } catch (e) {
      // Get new credentials from server
      Map<String,String> creds = await AccountManager().getMqttCredentials();
      // Save credentials
      PrefManager().write(PrefConstants.mqttUsername, creds['username']!);
      PrefManager().write(PrefConstants.mqttPassword, creds['password']!);
      // Try to login again
      return await loginFromSecureStorage();
    }
  }

  // fake client, while we wait for the real one to be ready
  MqttServerClient client = MqttServerClient(MqttConsts.server, '');

  // method to connect to the mqtt server
  Future<MqttServerClient> connect(String username, String password) async {
    // create the client mqtts://modena.davidepalma.it:8080
    // The client ID is the username
    Log.l('Connecting to mqtt server...');

    client = MqttServerClient.withPort(
        MqttConsts.server, username, MqttConsts.mqttPort);
    //client.secure = true;
    // set the port
    client.logging(on: false);
    // TODO set the username and password
    try {
      Log.l('Trying to connect...');
      MqttConnectionStatus? status = await client
          .connect(username, password);
      while (status?.state == MqttConnectionState.connecting) {
        Log.l('Connecting...');
        await Future.delayed(const Duration(seconds: 1));
      }
      if (status?.state ==  MqttConnectionState.connected) {
        Log.v('Connected to the mqtt server');
        return client;
      } else {
        return Future.error("mqtt can't connect");
      }
    } catch (e) {
      return Future.error("mqtt can't connect");
    }
  }

  //constructor

  //method to disconnect from the mqtt server
  void disconnect() {
    client.disconnect();
  }

  //method to publish a Message to the mqtt server
  void publish(Message message) {
    // Check that we are connected, otherwise return
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      Log.v('Not connected to mqtt server');
      return;
    }
    // check the type of the message
    if (message is CO2Message) {
      // publish the message
      // TODO device id = ?
      publishCo2(message);
    }
    if (message is DebugMessage) {
      // publish the message
      // TODO device id = ?
      publishDebug(message);
    }
    if (message is FeedbackMessage) {
      // publish the message
      // TODO device id = ?
      publishFeedback(message);
    }
    if (message is StartupMessage) {
      // publish the message
      // TODO device id = ?
      publishStartup(message);
    }
  }

  void publishCo2(CO2Message message) {
    // publish the message
    int deviceId = mac.toInt();

    String topic = '${MqttConsts.rootTopic}$deviceId/';
    sendInt('$topic${MqttConsts.co2Topic}', message.co2);
    sendInt('$topic${MqttConsts.humidityTopic}', message.humidity);
    sendInt('$topic${MqttConsts.temperatureTopic}', message.temperature);
    // Build the combined payload
    Map <String, dynamic> payload = message.toDict();
    // Get the selected place
    if (place != null) {
      payload['place'] = place?.id;

    }

    sendDict('$topic${MqttConsts.combinedTopic}', payload);
  }

  void publishDebug(DebugMessage message) {
    // publish the message
    int deviceId = mac.toInt();
    String topic = '${MqttConsts.rootTopic}$deviceId/';
    sendInt('$topic${MqttConsts.debugTopic}', message.rawData);
    sendInt('$topic${MqttConsts.humidityTopic}', message.humidity);
    sendInt('$topic${MqttConsts.temperatureTopic}', message.temperature);
    // Build the combined payload as json string
    sendDict('$topic${MqttConsts.combinedTopic}', message.toDict());
  }

  void publishFeedback(FeedbackMessage message) {
    // publish the message
    int deviceId = mac.toInt();
    String topic = '${MqttConsts.rootTopic}$deviceId/';
    sendInt('$topic${MqttConsts.co2Topic}', message.co2);
    sendInt('$topic${MqttConsts.humidityTopic}',message.humidity);
    sendInt('$topic${MqttConsts.temperatureTopic}', message.temperature);
    sendInt('$topic${MqttConsts.feedbackTopic}', message.feedback.index);
    // Build the combined payload
    sendDict('$topic${MqttConsts.combinedTopic}', message.toDict());
  }

  void publishStartup(StartupMessage message) {
    // publish the message
    int deviceId = mac.toInt();
    String topic = '${MqttConsts.rootTopic}$deviceId/';
    sendInt('$topic${MqttConsts.modelTopic}',message.model);
    sendInt('$topic${MqttConsts.versionTopic}', message.version);
    sendInt('$topic${MqttConsts.batteryTopic}', message.battery);
    // Build the combined payload
    sendDict('$topic${MqttConsts.combinedTopic}', message.toDict());
  }

  void sendInt(String topic, int value) {
    client.publishMessage(topic, MqttQos.atMostOnce, stringToBuffer(value.toString()));
  }

  void sendDict(String topic, Map<String, dynamic> dict) {
    client.publishMessage(topic, MqttQos.atMostOnce, stringToBuffer(jsonEncode(dict)));
  }

  static Uint8Buffer intToBuffer(int i) {
    var result = Uint8Buffer(4);
    result.buffer.asByteData().setInt32(0, i);
    return result;
  }

  static Uint8Buffer stringToBuffer(String s) {
    var result = Uint8Buffer(s.length);
    // convert the string to a list of bytes
    for (int i = 0; i < s.length; i++) {
      result[i] = s.codeUnitAt(i);
    }
    return result;
  }


}
