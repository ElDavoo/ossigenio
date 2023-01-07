import 'package:flutter/foundation.dart';

import 'constants.dart';

/// A class that represents a mac address.
///
/// A Mac address is a Uint8List of length 6.
class MacAddress {
  final Uint8List mac;
  late final Uint8List _oui;
  // Currently unused
  // late final Uint8List _nic;

  /// Throws an [ArgumentError] if [mac] is not of length 6.
  /// Throws an [ArgumentError] if [mac] is not a valid mac address.
  MacAddress(this.mac) {
    if (mac.length != 6) {
      throw ArgumentError('Mac address must be 6 bytes long');
    }

    _oui = mac.sublist(0, 3);
    // _nic = mac.sublist(3, 6);

    bool ok = false;
    for (Uint8List oui in C.bt.allowedOUIs) {
      if (listEquals(_oui, oui)) {
        ok = true;
        break;
      }
    }

    if (!ok) {
      throw ArgumentError('Mac address is not of allowed vendors');
    }

  }

  /// Returns the mac address as a string, without symbols
  @override
  String toString() {
    return mac.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Returns the mac address as an integer
  int toInt() {
    return mac.fold(
        0, (previousValue, element) => (previousValue << 8) + element);
  }
}