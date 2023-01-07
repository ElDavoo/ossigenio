import 'dart:convert';

import 'package:flutter_app/Messages/feedback_message.dart';
import 'package:flutter_app/Messages/startup_message.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_buffers.dart';

import '../Messages/co2_message.dart';
import '../Messages/debug_message.dart';
import '../Messages/message.dart';
import '../utils/constants.dart';
import '../utils/log.dart';
import '../utils/mac.dart';
import '../utils/place.dart';

/// Classe che gestisce la connessione al server MQTT
class MqttManager {
  static final MqttManager instance = MqttManager._internal();

  factory MqttManager({required mac}) {
    instance.mac = mac;
    return instance;
  }

  /// Il posto selezionato dall'utente
  static Place? place;

  /// Il MAC address del dispositivo
  late MacAddress mac;

  /// Il client MQTT
  MqttServerClient client = MqttServerClient(C.mqtt.server, '');

  MqttManager._internal() {
    Log.d("Initializing");
    tryLogin();
    Log.d("Initialized");
  }

  void tryLogin() {
    _login().then((value) => client);
  }

  /// Effettua il login al server MQTT con le credenziali salvate
  ///
  /// Questo metodo legge le credenziali MQTT dallo storage
  /// e prova a connettersi al server MQTT.
  Future<MqttServerClient> _loginFromSecureStorage() async {
    if (await PrefManager().areMqttDataSaved()) {
      final String username = await PrefManager().read(C.pref.mqttUsername) as String;
      final String password = await PrefManager().read(C.pref.mqttPassword) as String;
      Log.d('Credenziali lette');

      try {
        return await _connect(username, password);
      } catch (e) {
        await PrefManager().delete(C.pref.mqttUsername);
        await PrefManager().delete(C.pref.mqttPassword);
        return Future.error(e);
      }
    } else {
      return Future.error('Credenziali non salvate');
    }
  }

  /// Effettua il login al server MQTT
  ///
  /// Prova prima a connettersi con le credenziali salvate.
  /// Se non salvate, prova ad ottenerle dal server
  /// e a connettersi con queste.
  Future<MqttServerClient> _login() async {
    Log.d('Tentativo di login');
    try {
      return await _loginFromSecureStorage();
    } catch (e) {
      // Ottiene nuove credenziali dal server
      final Map<String, String> creds = await AccountManager().getMqttCredentials();
      // Salva le credenziali nel secure storage
      PrefManager().write(C.pref.mqttUsername, creds['username']!);
      PrefManager().write(C.pref.mqttPassword, creds['password']!);
      // Riprova a connettersi
      return await _loginFromSecureStorage();
    }
  }

  /// Metodo per connettersi al server MQTT con le credenziali fornite
  ///
  /// Se la connessione ha successo, viene salvato il client MQTT
  Future<MqttServerClient> _connect(String username, String password) async {
    client =
        MqttServerClient.withPort(C.mqtt.server, username, C.mqtt.mqttPort);

    // TODO
    //client.secure = true;
    client.logging(on: false);

    try {

      Log.d('Connessione al server MQTT');
      MqttConnectionStatus? status = await client.connect(username, password);
      while (status?.state == MqttConnectionState.connecting) {
        Log.d('Attendo...');
        await Future.delayed(const Duration(seconds: 1));
      }
      if (status?.state == MqttConnectionState.connected) {
        Log.v('Connesso al server MQTT');
        return client;
      } else {
        return Future.error("Errore di connessione");
      }

    } catch (e) {
      return Future.error("Errore: $e");
    }

  }

  /// Metodo per inviare un messaggio al server MQTT
  void publish(Message message) {
    // Ritorna se il client non è connesso
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      Log.d('Not connected to mqtt server');
      return;
    }
    // Chiama la funzione specifica in base al tipo di messaggio
    if (message is CO2Message) {
      _publishCo2(message);
    } else if (message is DebugMessage) {
      _publishDebug(message);
    } else if (message is FeedbackMessage) {
      _publishFeedback(message);
    } else if (message is StartupMessage) {
      _publishStartup(message);
    }
  }

  /// Pubblica un messaggio di CO2.
  void _publishCo2(CO2Message message) {
    final int deviceId = mac.toInt();

    final String topic = '${C.mqtt.rootTopic}$deviceId/';

    _sendInt('$topic${C.mqtt.co2Topic}', message.co2);
    _sendInt('$topic${C.mqtt.humidityTopic}', message.humidity);
    _sendInt('$topic${C.mqtt.temperatureTopic}', message.temperature);

    // Costruisce il messaggio combinato
    Map<String, dynamic> payload = message.toDict();
    // Aggiunge il posto selezionato, se presente
    if (place != null) {
      payload['place'] = place?.id;
    }

    // Invia il payload combinato
    _sendDict('$topic${C.mqtt.combinedTopic}', payload);

  }

  /// Pubblica un messaggio di debug.
  void _publishDebug(DebugMessage message) {
    final int deviceId = mac.toInt();

    final String topic = '${C.mqtt.rootTopic}$deviceId/';

    _sendInt('$topic${C.mqtt.debugTopic}', message.rawData);
    _sendInt('$topic${C.mqtt.humidityTopic}', message.humidity);
    _sendInt('$topic${C.mqtt.temperatureTopic}', message.temperature);

    // Costruisce il messaggio combinato
    Map<String, dynamic> payload = message.toDict();
    // Aggiunge il posto selezionato, se presente
    if (place != null) {
      payload['place'] = place?.id;
    }

    // Invia il payload combinato
    _sendDict('$topic${C.mqtt.combinedTopic}', payload);

  }

  /// Pubblica un messaggio di feedback.
  void _publishFeedback(FeedbackMessage message) {
    final int deviceId = mac.toInt();
    final String topic = '${C.mqtt.rootTopic}$deviceId/';

    _sendInt('$topic${C.mqtt.co2Topic}', message.co2);
    _sendInt('$topic${C.mqtt.humidityTopic}', message.humidity);
    _sendInt('$topic${C.mqtt.temperatureTopic}', message.temperature);
    _sendInt('$topic${C.mqtt.feedbackTopic}', message.feedback.index);

    // Costruisce il messaggio combinato
    Map<String, dynamic> payload = message.toDict();
    // Aggiunge il posto selezionato, se presente
    if (place != null) {
      payload['place'] = place?.id;
    }

    // Invia il payload combinato
    _sendDict('$topic${C.mqtt.combinedTopic}', payload);
  }

  /// Pubblica un messaggio di startup.
  void _publishStartup(StartupMessage message) {
    final int deviceId = mac.toInt();
    final String topic = '${C.mqtt.rootTopic}$deviceId/';

    _sendInt('$topic${C.mqtt.modelTopic}', message.model);
    _sendInt('$topic${C.mqtt.versionTopic}', message.version);
    _sendInt('$topic${C.mqtt.batteryTopic}', message.battery);

    // Costruisce il messaggio combinato
    Map<String, dynamic> payload = message.toDict();
    // Aggiunge il posto selezionato, se presente
    if (place != null) {
      payload['place'] = place?.id;
    }
    // Invia il payload combinato
    _sendDict('$topic${C.mqtt.combinedTopic}', payload);
  }

  /// Invia un messaggio di tipo intero
  void _sendInt(String topic, int value) {
    client.publishMessage(
        topic, MqttQos.atMostOnce, _stringToBuffer(value.toString()));
  }

  /// Invia un messaggio su MQTT in formato JSON
  void _sendDict(String topic, Map<String, dynamic> dict) {
    client.publishMessage(
        topic, MqttQos.atMostOnce, _stringToBuffer(jsonEncode(dict)));
  }

  /// Converte una stringa in un buffer di byte
  static Uint8Buffer _stringToBuffer(String s) {
    final Uint8Buffer result = Uint8Buffer(s.length);
    // Converte la stringa in byte
    for (int i = 0; i < s.length; i++) {
      result[i] = s.codeUnitAt(i);
    }
    return result;
  }
}
