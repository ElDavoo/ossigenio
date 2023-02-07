import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../utils/log.dart';
import '../utils/place.dart';

/// Classe che gestisce la posizione
class GpsManager {
  static final GpsManager _instance = GpsManager._internal();

  factory GpsManager() {
    return _instance;
  }

  /// Impostazioni di localizzazione
  static const LocationSettings _locationSettings = LocationSettings(
    // Abbiamo bisogno della precisione massima
    accuracy: LocationAccuracy.best,
  );

  /// L'ultima posizione dell'utente
  static LatLng? position;

  /// Lo stream di posizioni
  final Stream<Position> _poStream =
      Geolocator.getPositionStream(locationSettings: _locationSettings);

  /// Lista di posti vicini all'utente
  final ValueNotifier<List<Place>?> placeStream = ValueNotifier(null);

  GpsManager._internal() {
    Log.d("Inizializzazione");
    // Quando viene ricevuta una posizione affidabile,
    // la memorizziamo e la notifichiamo
    _poStream.where((event) => _filterEvent(event)).map((event) {
      return LatLng(event.latitude, event.longitude);
    }).listen((event) {
      Log.d('Posizione aggiornata');
      position = event;
      // Ottiene la lista dei luoghi vicini e la aggiunge
      AccountManager()
          .getNearbyPlaces(LatLng(event.latitude, event.longitude))
          .then((list) {
        placeStream.value = list;
      });
    });
    Log.d('Inizializzato');
  }

  /// Filtra le posizioni ricevute
  ///
  /// Questo metodo filtra le posizioni ricevute in modo da non
  /// aggiornare la posizione se non è precisa o non è cambiata.
  /// Tuttavia, la prima posizione sarà ottenuta con criteri
  /// meno rigidi, per velocizzare l'avvio dell'app.
  static bool _filterEvent(Position pos) {
    // Criteri se la posizione è la prima
    if (position == null) {
      return pos.accuracy < 80 && pos.speed < 15 && !pos.isMocked;
    }

    // Non considerare posizioni a meno di 100 metri dall'ultima
    if (Geolocator.distanceBetween(pos.latitude, pos.longitude,
            position!.latitude, position!.longitude) <
        100) {
      return false;
    }

    return !pos.isMocked &&
        pos.accuracy < 40 &&
        pos.speed < 4 &&
        pos.speedAccuracy < 2;
  }
}
