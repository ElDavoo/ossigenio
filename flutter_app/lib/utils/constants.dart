import 'dart:typed_data';

import 'package:flutter_app/utils/server.dart';
import 'package:permission_handler/permission_handler.dart';

/// Class that holds all the constants used in the app.
class C {
  AccConsts acc = const AccConsts();
}

class AccConsts {
  const AccConsts();

  // TODO use this list instead of the others
  static List<Server> servers = [
    const Server("modena.davidepalma.it", 443),
    const Server("modena.davidepalma.it", 80),
  ];
  static const String server = 'modena.davidepalma.it';
  static const String httpPort = '80';
  static const String httpsPort = '443';
  static const String urlLogin = '/login';
  static const String urlRegister = '/signup';
  static const String urlCheckMac = '/checkMac';
  static const String urlGetPlaces = '/nearby';
  static const String urlUserInfo = '/user';
  static const String urlPlace = '/place/';
  static const String urlPlaces = '/places';
  static const String urlPredictions = '/predictions/';
  static const int apiVersion = 1;
  static const int shaIterations = 1000;

}

/// Classe che contiene le costanti usate nell'ambito del Bluetooth.
class BTConst {
  /// Lista dei nomi consentiti per i dispositivi.
  static const List<String> allowedNames = [
    'Adafruit Bluefruit LE',
    'AirQualityMonitor',
    'AirQualityMonitorEBV',
  ];

  /// L'UUID del servizio di comunicazione usato nel BLE.
  static const nordicUARTID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  /// La caratteristica di scrittura usata nel BLE.
  static const nordicUARTRXID = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  /// La caratteristica di lettura usata nel BLE.
  static const nordicUARTTXID = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  /// Lista degli OUI consentiti per i dispositivi.
  static final List<Uint8List> allowedOUIs = [
    Uint8List.fromList([0xEF, 0x41, 0xB7]),
    Uint8List.fromList([0xE6, 0x4A, 0x29]),
    Uint8List.fromList([0xC4, 0x4F, 0x33]),
  ];

  /// Questo intero viene trasmesso dal dispositivo per distinguerlo
  /// dagli altri dispositivi.
  static int manufacturerId = 0xF175;
}

class MqttConsts {
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

class PrefConstants {
  static const String deviceMac = "deviceMac";
  static const String email = "email";
  static const String username = "username";
  static const String dataVersion = "dataVersion";
  static const String mqttUsername = "mqttUsername";
  static const String mqttPassword = "mqttPassword";
  static const String cookie = "cookie";
  static int dataVersionValue = 0;
}

class PermConstants{
  const PermConstants();

  static const List<Permission> permissions = [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ];
}