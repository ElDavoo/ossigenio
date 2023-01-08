import 'dart:async';

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

  /// Stream di posti vicini all'utente
  final StreamController<List<Place>> placeStream =
      StreamController<List<Place>>.broadcast();

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
        placeStream.add(list);
      });
    });
    Log.d('Inizializzato');
  }

  /// Filtra le posizioni ricevute
  ///
  /// Questp metodo filtra le posizioni ricevute in modo da non
  /// aggiornare la posizione se non è precisa o non è cambiata.
  /// Tuttavia, la prima posizione sarà ottenuta con criteri
  /// meno rigidi, per velocizzare l'avvio dell'app.
  static bool _filterEvent(Position pos) {
    // Criteri se la posizione è la prima
    if (position == null) {
      return pos.accuracy < 50 && pos.speed < 10 && !pos.isMocked;
    }

    // Non considerare posizioni a meno di 30 metri dall'ultima
    if (position != null &&
        Geolocator.distanceBetween(pos.latitude, pos.longitude,
                position!.latitude, position!.longitude) <
            30) {
      return false;
    }

    return !pos.isMocked &&
        pos.accuracy < 30 &&
        pos.speed < 3 &&
        pos.speedAccuracy < 2;
  }
}
