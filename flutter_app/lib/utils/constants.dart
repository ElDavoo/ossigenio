import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/utils/server.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

/// Class that holds all the constants used in the app.
class C {
  static const AccConsts acc = AccConsts();
  static const PermConsts perm = PermConsts();
  static const PrefConsts pref = PrefConsts();
  static const BTConsts bt = BTConsts();
  static const MqttConsts mqtt = MqttConsts();
  static const Clrs colors = Clrs();
  static const RangeQuotas quotas = RangeQuotas();

  /// DIEF, Modena
  static LatLng defaultLocation = LatLng(44.6291399, 10.9488126);

  /// Bound per restringere la mappa all'italia
  static LatLngBounds italyBounds = LatLngBounds(LatLng(48, 6), LatLng(36, 19));

  static const String fmtcStoreName = 'fmtc_store';

  static const String tileUrl =
      "https://tile.openstreetmap.org/{z}/{x}/{y}.png";

  static String catchWord(BuildContext context, int co2level) {
    if (co2level <= quotas.excellent) {
      return AppLocalizations.of(context)!.excellent;
    }
    if (co2level <= quotas.veryGood) {
      return AppLocalizations.of(context)!.verygood;
    }
    if (co2level <= quotas.good) return AppLocalizations.of(context)!.good;
    if (co2level <= quotas.acceptable) {
      return AppLocalizations.of(context)!.acceptable;
    }
    if (co2level <= quotas.bad) return AppLocalizations.of(context)!.bad;
    if (co2level <= quotas.veryBad) {
      return AppLocalizations.of(context)!.verybad;
    }
    return AppLocalizations.of(context)!.dangerous;
  }

  static String explanation(BuildContext context, int co2level) {
    if (co2level <= quotas.excellent) {
      return AppLocalizations.of(context)!.excellentExplanation;
    }
    if (co2level <= quotas.veryGood) {
      return AppLocalizations.of(context)!.verygoodExplanation;
    }
    if (co2level <= quotas.good) {
      return AppLocalizations.of(context)!.goodExplanation;
    }
    if (co2level <= quotas.acceptable) {
      return AppLocalizations.of(context)!.acceptableExplanation;
    }
    if (co2level <= quotas.bad) {
      return AppLocalizations.of(context)!.badExplanation;
    }
    if (co2level <= quotas.veryBad) {
      return AppLocalizations.of(context)!.verybadExplanation;
    }
    return AppLocalizations.of(context)!.dangerousExplanation;
  }
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

  String get placeTopic => 'place';

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

class Clrs {
  const Clrs();

  Color get cardBg => const Color.fromRGBO(255, 255, 255, 0.8);

  Color get inactiveSlider => Colors.blue;

  Color get activeSlider => Colors.red;

  Color get isHeatingBg => Colors.yellow.shade200;

  Color get endShade => const Color.fromRGBO(227, 252, 230, 0.9);

  Color get startShade => const Color.fromRGBO(111, 206, 250, 0.7);

  Color get blue1 => Colors.blue;

  Color get blue2 => Colors.blueAccent;

  Color get startLerp => Colors.blueAccent;

  Color get endLerp => Colors.red;

  Color get excellent => Colors.green;

  Color get veryGood => Colors.greenAccent;

  Color get good => Colors.yellow;

  Color get acceptable => Colors.orange;

  Color get bad => Colors.deepOrange;

  Color get veryBad => Colors.red;

  Color get dangerous => Colors.purple;
}

class RangeQuotas {
  const RangeQuotas();

  int get excellent => 450;

  int get veryGood => 600;

  int get good => 800;

  int get acceptable => 1000;

  int get bad => 1500;

  int get veryBad => 2500;

  int get dangerous => 4000;
}
