import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/Messages/debug_message.dart';
import 'package:flutter_app/utils/serial.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../Messages/message.dart';
import '../managers/ble_man.dart';
import '../managers/mqtt_man.dart';
import 'btuart.dart';
import 'log.dart';
import 'mac.dart';

/// Una classe che rappresenta un sensore
class Device extends ChangeNotifier {
  /// La seriale per scambiare messaggi con il sensore
  late BTUart btUart;

  /// Il dispositivo dal punto di vista di flutter_blue_plus
  late BluetoothDevice device;

  /// Lo stato del dispositivo
  /// TODO serve davvero?
  BluetoothDeviceState state = BluetoothDeviceState.connected;

  /// La lista dei messaggi scambiati col dispositivo
  final List<MessageWithDirection> messages = [];
  late Stream<MessageWithDirection> messagesStream;

  /// Il numero seriale del sensore
  late MacAddress serialNumber;

  /// Indica se il sensore si sta riscaldando
  late bool isHeating = true;

  /// Timer usato per richiedere messaggi periodicamente
  late Timer timer;

  Device(ScanResult result, this.btUart) {
    device = result.device;
    Log.d("Inizializzazione di ${device.name} - ${device.id}");
    // Rifa il calcolo del numero seriale
    serialNumber = BLEManager.processAdv(result.advertisementData)!;



    messagesStream = btUart.txCharacteristic.value
        .map((value) {
          // Crea un messaggio da un valore
          final Message? message = SerialComm.receive(value);
          if (message != null) {
            return MessageWithDirection(
                MessageDirection.received, DateTime.now(), message);
          }
          return null;
        })
        .where((message) => message != null)
        .cast<MessageWithDirection>()
        .asBroadcastStream();

    messagesStream.listen((message) {
      // Salva i messaggi scambiati
      messages.add(message);
      notifyListeners();
    });

    messagesStream.listen((message) {
      Log.v("Message received");
      // Manda i messaggi ricevuti su MQTT
      if (message.direction == MessageDirection.received) {
        MqttManager(mac: serialNumber).publish(message.message);
      }
    });

    // Riflette lo stato del dispositivo
    device.state.listen((event) {
      state = event;
      // Diciamolo al manager
      if (state == BluetoothDeviceState.disconnected) {
        device.disconnect();
        timer.cancel();
        BLEManager().disconnect(this);
      }
    });

    messagesStream
        .where((msg) => msg.direction == MessageDirection.received)
        .map((msg) => msg.message)
        .where((message) => message is DebugMessage)
        .cast<DebugMessage>()
        .listen((msg) {
          // Quando riceviamo un messaggio di debug,
          // controlliamo se il sensore si sta riscaldando.
      if (isHeating) {
        // Il sensore è pronto se la differenza tra la temperatura
        // del sensore vicino e quella del sensore lontano è maggiore di 3
        isHeating = (msg.rawData - msg.temperature).abs() <= 3;
        // Fix, quando il sensore sta partendo, la temperatura è 0
        if (msg.rawData == 0) {
          isHeating = true;
        }
        if (!isHeating) {
          // Riprogrammiamo il timer per chiedere messaggi
          // meno frequentemente
          timer.cancel();
          timer = Timer.periodic(
              const Duration(seconds: 60), (_) => periodicallyRequest);
        }
      }
      Log.l("Diff: ${(msg.rawData - msg.temperature).abs()}");
    });

    // Messaggi da mandare alla connessione
    Future.delayed(const Duration(milliseconds: 300))
        .then((value) => BLEManager.sendMsg(this, MessageTypes.msgRequest3));
    Future.delayed(const Duration(milliseconds: 600))
        .then((value) => BLEManager.sendMsg(this, MessageTypes.msgRequest1));
    Future.delayed(const Duration(milliseconds: 2000))
        .then((value) => BLEManager.sendMsg(this, MessageTypes.msgRequest0));

    // Chiede un messaggio di debug ogni 30 secondi
    timer = Timer.periodic(
        const Duration(seconds: 30), (_) => periodicallyRequest());
  }

  /// Richiede periodicamente messaggi al sensore
  void periodicallyRequest() {
    Log.d("Chiedo dati al sensore");
    BLEManager.sendMsg(this, MessageTypes.msgRequest0);
    Future.delayed(const Duration(milliseconds: 500))
        .then((value) => BLEManager.sendMsg(this, MessageTypes.msgRequest3));
  }
}
