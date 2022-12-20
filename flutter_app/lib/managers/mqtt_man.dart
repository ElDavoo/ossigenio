/*
Class to handle connections to mqtt server using mqtt5_client package
 */
import 'package:flutter_app/Messages/feedback_message.dart';
import 'package:flutter_app/Messages/startup_message.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:flutter_app/utils/device.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import '../Messages/debug_message.dart';
import '../Messages/message.dart';
import '../Messages/co2_message.dart';
import '../utils/log.dart';

class MqttConstants {
  static const String server = 'modena.davidepalma.it';
  static const int mqttsPort = 8080;
  static const String rootTopic = 'sensors/';

  static const String co2Topic = 'co2';
  static const String humidityTopic = 'humidity';
  static const String temperatureTopic = 'temperature';
  static const String debugTopic = 'rawData';
  static const String feedbackTopic = 'feedback';
  static const String modelTopic = 'model';
  static const String versionTopic = 'version';
  static const String batteryTopic = 'battery';
  static const String combinedTopic = 'combined';
  static const int mqttPort = 1883;
}

class MqttManager {
  static final MqttManager _instance = MqttManager._internal();

  factory MqttManager({required MacAddress mac}) {
    _instance.mac = mac;
    return _instance;
  }

  late MacAddress mac;

  late Future<bool> _haveCredentials;

  MqttManager._internal() {
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
      var creds = await AccountManager().getMqttCredentials();
      // Save credentials
      PrefManager().write(PrefConstants.mqttUsername, creds['username']!);
      PrefManager().write(PrefConstants.mqttPassword, creds['password']!);
      // Try to login again
      return await loginFromSecureStorage();
    }
  }

  // fake client, while we wait for the real one to be ready
  MqttServerClient client = MqttServerClient(MqttConstants.server, '');

  // method to connect to the mqtt server
  Future<MqttServerClient> connect(String username, String password) async {
    // create the client mqtts://modena.davidepalma.it:8080
    // The client ID is the username
    Log.l('Connecting to mqtt server...');

    client = MqttServerClient.withPort(
        MqttConstants.server, username, MqttConstants.mqttPort);
    //client.secure = true;
    // set the port
    client.logging(on: true);
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
    String deviceId = mac.toString();

    String topic = '${MqttConstants.rootTopic}$deviceId/';
    client.publishMessage('$topic${MqttConstants.co2Topic}', MqttQos.atMostOnce,
        stringToBuffer(message.co2.toString()));
    client.publishMessage('$topic${MqttConstants.humidityTopic}',
        MqttQos.atMostOnce, stringToBuffer(message.humidity.toString()));
    client.publishMessage('$topic${MqttConstants.temperatureTopic}',
        MqttQos.atMostOnce, stringToBuffer(message.temperature.toString()));
    // Build the combined payload as json string
    String combinedPayload =
        '{"co2": ${message.co2}, "humidity": ${message.humidity}, "temperature": ${message.temperature}}';
    client.publishMessage('$topic${MqttConstants.combinedTopic}',
        MqttQos.atMostOnce, stringToBuffer(combinedPayload));
  }

  void publishDebug(DebugMessage message) {
    // publish the message
    String deviceId = mac.toString();
    String topic = '${MqttConstants.rootTopic}$deviceId/';
    client.publishMessage('$topic${MqttConstants.debugTopic}',
        MqttQos.atMostOnce, stringToBuffer(message.rawData.toString()));
    client.publishMessage('$topic${MqttConstants.humidityTopic}',
        MqttQos.atMostOnce, stringToBuffer(message.humidity.toString()));
    client.publishMessage('$topic${MqttConstants.temperatureTopic}',
        MqttQos.atMostOnce, stringToBuffer(message.temperature.toString()));
    // Build the combined payload as json string
    String combinedPayload =
        '{"rawData": ${message.rawData}, "humidity": ${message.humidity}, "temperature": ${message.temperature}}';
    client.publishMessage('$topic${MqttConstants.combinedTopic}',
        MqttQos.atMostOnce, stringToBuffer(combinedPayload));
  }

  void publishFeedback(FeedbackMessage message) {
    // publish the message
    String deviceId = mac.toString();
    String topic = '${MqttConstants.rootTopic}$deviceId/';
    client.publishMessage('$topic${MqttConstants.co2Topic}', MqttQos.atMostOnce,
        stringToBuffer(message.co2.toString()));
    client.publishMessage('$topic${MqttConstants.humidityTopic}',
        MqttQos.atMostOnce, stringToBuffer(message.humidity.toString()));
    client.publishMessage('$topic${MqttConstants.temperatureTopic}',
        MqttQos.atMostOnce, stringToBuffer(message.temperature.toString()));
    client.publishMessage('$topic${MqttConstants.feedbackTopic}',
        MqttQos.atMostOnce, stringToBuffer(message.feedback.toString()));
    // Build the combined payload as json string
    String combinedPayload =
        '{"co2": ${message.co2}, "humidity": ${message.humidity}, "temperature": ${message.temperature}, "feedback": ${message.feedback}}';
    client.publishMessage('$topic${MqttConstants.combinedTopic}',
        MqttQos.atMostOnce, stringToBuffer(combinedPayload));
  }

  void publishStartup(StartupMessage message) {
    // publish the message
    String deviceId = mac.toString();
    String topic = '${MqttConstants.rootTopic}$deviceId/';
    client.publishMessage('$topic${MqttConstants.modelTopic}',
        MqttQos.atMostOnce, stringToBuffer(message.model.toString()));
    client.publishMessage('$topic${MqttConstants.versionTopic}',
        MqttQos.atMostOnce, stringToBuffer(message.version.toString()));
    client.publishMessage('$topic${MqttConstants.batteryTopic}',
        MqttQos.atMostOnce, stringToBuffer(message.battery.toString()));
    // Build the combined payload as json string
    String combinedPayload =
        '{"model": ${message.model}, "version": ${message.version}, "battery": ${message.battery}}';
    client.publishMessage('$topic${MqttConstants.combinedTopic}',
        MqttQos.atMostOnce, stringToBuffer(combinedPayload));
  }

  Uint8Buffer intToBuffer(int i) {
    var result = Uint8Buffer(4);
    result.buffer.asByteData().setInt32(0, i);
    return result;
  }

  Uint8Buffer stringToBuffer(String s) {
    var result = Uint8Buffer(s.length);
    // convert the string to a list of bytes
    for (int i = 0; i < s.length; i++) {
      result[i] = s.codeUnitAt(i);
    }
    return result;
  }


}
