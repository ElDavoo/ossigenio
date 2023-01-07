import 'dart:typed_data';

import 'package:flutter_app/utils/server.dart';
import 'package:permission_handler/permission_handler.dart';

/// Class that holds all the constants used in the app.
class C {
  static const AccConsts acc = AccConsts();
  static const PermConsts perm = PermConsts();
  static const PrefConsts pref = PrefConsts();
  static const BTConsts bt = BTConsts();
  static const MqttConsts mqtt = MqttConsts();
}

class AccConsts {
  const AccConsts();

  // TODO use this list instead of the others
  static List<Server> servers = [
    const Server("modena.davidepalma.it", 443),
    const Server("modena.davidepalma.it", 80),
  ];

  String get server => 'modena.davidepalma.it';

  String get httpPort => '80';

  String get httpsPort => '443';

  String get urlLogin => '/login';

  String get urlRegister => '/signup';

  String get urlCheckMac => '/checkMac';

  String get urlGetPlaces => '/nearby';

  String get urlUserInfo => '/user';

  String get urlPlace => '/place/';

  String get urlPlaces => '/places';

  String get urlPredictions => '/predictions/';

  int get apiVersion => 1;

  int get shaIterations => 1001;
}

/// Classe che contiene le costanti usate nell'ambito del Bluetooth.
class BTConsts {
  const BTConsts();

  /// Lista dei nomi consentiti per i dispositivi.
  List<String> get allowedNames => [
        'Adafruit Bluefruit LE',
        'AirQualityMonitor',
        'AirQualityMonitorEBV',
        'Ossigenio',
      ];

  /// L'UUID del servizio di comunicazione usato nel BLE.
  String get nordicUARTID => '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

  /// La caratteristica di scrittura usata nel BLE.
  String get nordicUARTRXID => '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  /// La caratteristica di lettura usata nel BLE.
  String get nordicUARTTXID => '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  /// Lista degli OUI consentiti per i dispositivi.
  List<Uint8List> get allowedOUIs => [
        Uint8List.fromList([0xEF, 0x41, 0xB7]),
        Uint8List.fromList([0xE6, 0x4A, 0x29]),
        Uint8List.fromList([0xC4, 0x4F, 0x33]),
      ];

  /// Questo intero viene trasmesso dal dispositivo per distinguerlo
  /// dagli altri dispositivi.
  int get manufacturerId => 0xF175;
}

class MqttConsts {
  const MqttConsts();

  String get server => 'modena.davidepalma.it';

  int get mqttsPort => 8080;

  String get rootTopic => 'sensors/';

  String get co2Topic => 'co2';

  String get humidityTopic => 'humidity';

  String get temperatureTopic => 'temperature';

  String get debugTopic => 'rawData';

  String get feedbackTopic => 'feedback';

  String get modelTopic => 'model';

  String get versionTopic => 'version';

  String get batteryTopic => 'battery';

  String get combinedTopic => 'combined';

  int get mqttPort => 1883;
}

class PrefConsts {
  const PrefConsts();

  String get deviceMac => "deviceMac";

  String get email => "email";

  String get username => "username";

  String get dataVersion => "dataVersion";

  String get mqttUsername => "mqttUsername";

  String get mqttPassword => "mqttPassword";

  String get cookie => "cookie";
  static int dataVersionValue = 0;
}

class PermConsts {
  const PermConsts();

  List<Permission> get permissions => [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ];
}
