import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_app/managers/mqtt_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:flutter_app/ui/pages/place_page.dart';
import 'package:latlong2/latlong.dart';

import '../utils/constants.dart';
import '../utils/log.dart';
import '../utils/mac.dart';
import '../utils/place.dart';
import '../utils/prediction.dart';

/// Classe per gestire le API e le richieste HTTP verso il server.
class AccountManager {
  static final AccountManager _instance = AccountManager._internal();

  factory AccountManager() {
    return _instance;
  }

  AccountManager._internal();

  static final Dio dio = Dio(BaseOptions(
    baseUrl:
        'https://${C.acc.server}:${C.acc.httpsPort}/api/v${C.acc.apiVersion}',
  ));

  /// Effettua una richiesta HTTP GET.
  Future<Response> get(String url, String cookie) async {
    return await dio.get(url,
        options: Options(headers: {
          'Cookie': cookie,
        }));
  }

  /// Prova ad effettuare il login con le credenziali salvate.
  Future<bool> login() async {
    Log.d('Logging in with saved credentials...');
    final String? cookie = await PrefManager().read(C.pref.cookie);
    if (cookie == null) {
      Log.d('No saved credentials');
      return false;
    }
    try {
      Response response = await get(C.acc.urlUserInfo, cookie);
      if (response.statusCode == 200) {
        Log.d('Logged in with cookie');
        String username = response.data['name'];
        String email = response.data['email'];
        PrefManager().saveAccountData(username, email);
        return true;
      } else {
        Log.l('Login fallito, codice ${response.statusCode}');
        AccountManager().logout();
        return false;
      }
    } on DioError catch (e) {
      Log.v('Error while logging in with cookie: ${e.message}');
    } catch (e) {
      Log.v('Error while logging in with cookie: ${e.toString()}');
    }
    return false;
  }

  /// Ritorna true se l'utente è loggato, false altrimenti.
  Future<bool> ensureLoggedIn() async {
    if (await PrefManager().read(C.pref.cookie) != null) {
      return true;
    }
    return false;
  }

  /// Effettua il login con una coppia username-password.
  Future<bool> loginWith(String email, String password) async {
    // Imposta il corpo della richiesta
    final String body = jsonEncode({
      'email': email,
      // Cifra la password prima di mandarla al server
      'password': cipher(password),
    });

    Response? response;

    try {
      response = await dio.post(C.acc.urlLogin, data: body);

      if (response.statusCode == 200) {
        // Salva il cookie e i dati dell'utente
        String cookie = response.headers['set-cookie']![0];
        PrefManager().write("cookie", cookie);
        response = await get(C.acc.urlUserInfo, cookie);
        if (response.statusCode == 200) {
          String username = response.data['name'];
          String email = response.data['email'];
          PrefManager().saveAccountData(username, email);
          return true;
        } else {
          Log.l('Errore del server: ${response.statusCode}');
          return false;
        }
      } else {
        Log.l("Login fallito, codice ${response.statusCode}");
        return false;
      }
    } catch (e) {
      Log.v(e.toString());
      return false;
    }
  }

  /// Cifra la password con SHA256 per shaIterations volte.
  String cipher(String password) {
    Digest digest = sha256.convert(utf8.encode(password));
    for (int i = 0; i < C.acc.shaIterations - 1; i++) {
      digest = sha256.convert(digest.bytes);
    }
    return digest.toString();
  }

  /// Effettua la registrazione con email, nome utente e password.
  Future<bool> register(
      {required String email,
      required String name,
      required String password}) async {
    final String body = jsonEncode({
      'email': email,
      // Cifra la password prima di mandarla al server
      'password': cipher(password),
      'name': name,
    });

    final Response? response;
    try {
      // Invia la richiesta
      response = await dio.post(C.acc.urlRegister, data: body);
    } catch (e) {
      Log.v(e.toString());
      return false;
    }

    if (response.statusCode == 200) {
      // Se la registrazione è avvenuta,
      // salva i dati dell'utente
      PrefManager().saveAccountData(name, email);
      final String cookie = response.headers['set-cookie']![0];
      PrefManager().write("cookie", cookie);
      // FIXME Ottieni le credenziali mqtt
      MqttManager.instance.tryLogin();
      return true;
    } else {
      Log.l("Registrazione fallita, codice ${response.statusCode}");
      return false;
    }
  }

  /// Controlla se il dispositivo è originale
  ///
  /// Ritorna true se il dispositivo è originale, false altrimenti.
  /// Viene mandato il MAC address del dispositivo al server.
  Future<bool> checkIfValid(MacAddress mac) async {
    if (await ensureLoggedIn()) {
      final String body = jsonEncode({
        'id': mac.toString(),
      });

      String cookie = await PrefManager().read(C.pref.cookie) as String;

      Response response = await dio.post(C.acc.urlCheckMac, data: body,
          options: Options(headers: {
            'Cookie': cookie,
          }));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  /// Ottiene le credenziali MQTT, le salva e prova a connettersi.
  ///
  /// TODO
  void refreshMqtt() {
    getMqttCredentials().then((mqttCredentials) {
      PrefManager().saveMqttData(
          mqttCredentials['username']!, mqttCredentials['password']!);
      MqttManager.instance.tryLogin();
    });
  }

  /// Ottiene le credenziali MQTT dal server.
  ///
  /// TODO
  Future<Map<String, String>> getMqttCredentials() async {
    if (await ensureLoggedIn()) {
      return {'username': 'test', 'password': 'test2'};
    } else {
      return Future.error('Not logged in');
    }
  }

  /// Restituisce i luoghi vicino all'utente.
  ///
  /// Restituisce i luoghi in un raggio di 100 metri.
  Future<List<Place>> getNearbyPlaces(LatLng position) async {
    if (!await ensureLoggedIn()) {
      return Future.error('Not logged in');
    }

    Log.d("Ottengo i posti vicino a me");
    final String body = jsonEncode({
      'lat': position.latitude,
      'lon': position.longitude,
    });

    final String cookie = await PrefManager().read("cookie") as String;

    final Response? response;
    try {
      response = await dio.post(C.acc.urlGetPlaces,
          data: body, options: Options(headers: {'cookie': cookie}));
    } catch (e) {
      Log.l(e.toString());
      return [];
    }

    if (response.statusCode == 200) {
      // Parsing del json
      List<Place> places = [];
      for (var place in response.data) {
        places.add(Place.fromJson(place));
      }
      Log.d("Ho ottenuto ${places.length} posti vicino a me");
      return places;
    } else {
      return Future.error('Error ${response.statusCode}');
    }
  }

  /// Restituisce gli N luoghi più vicini.
  ///
  /// Un metodo che, data una posizione, restituisce
  /// una lista di N luoghi più vicini, indipendentemente
  /// dalla disstanza.
  Future<List<Place>> getPlaces(LatLng position) async {
    if (!await ensureLoggedIn()) {
      return Future.error('Not logged in');
    }

    Log.l("Carico i posti vicino a me...");

    final String body = jsonEncode({
      'lat': position.latitude,
      'lon': position.longitude,
    });

    final String cookie = await PrefManager().read(C.pref.cookie) as String;

    final Response? response;
    try {
      response = await dio.post(C.acc.urlPlaces,
          data: body, options: Options(headers: {'cookie': cookie}));
    } catch (e) {
      Log.v("Errore: $e");
      return [];
    }

    if (response.statusCode == 200) {
      // Prende tutti i posti e li converte in oggetti Place
      List<Place> places = [];
      for (var place in response.data) {
        places.add(Place.fromJson(place));
      }
      Log.d("Trovati ${places.length} posti");
      return places;
    } else {
      return Future.error('Errore dal server: ${response.statusCode}');
    }
  }

  /// Dato l'id di un luogo, restituisce le informazioni
  ///
  /// Un metodo che, dato l'id di un luogo, restituisce
  /// le informazioni relative a quel luogo.
  Future<Place> getPlace(int placeId) async {
    if (!await ensureLoggedIn()) {
      return Future.error('Accesso non effettuato');
    }

    Log.d("Cerco le info del posto $placeId");

    final String cookie = await PrefManager().read("cookie") as String;

    final Response? response;
    try {
      response = await get(C.acc.urlPlace + placeId.toString(), cookie);
    } catch (e) {
      Log.v(e.toString());
      return Future.error('Errore: $e');
    }

    if (response.statusCode == 200) {
      // Parsa il json e restituisce il luogo
      Log.d("Place: ${response.data['name']} restituito");
      return Place.fromJson(response.data);
    } else {
      return Future.error('Errore dal server: ${response.statusCode}');
    }
  }

  /// Effettua il logout.
  Future<void> logout() async {
    // TODO chiama l'api di logout
    // Call the logout api
    // Read authentication cookie
    // String cookie = PrefManager().read("cookie") as String;
    // send the request
    // dio.post(C.acc.urlLogout, options: Options(headers: {'cookie': cookie}));
    // delete cookie
    await PrefManager().delete(C.pref.cookie);
    // delete account data
    await PrefManager().delete(C.pref.username);
    await PrefManager().delete(C.pref.email);
    // delete mqtt data
    await PrefManager().delete(C.pref.mqttUsername);
    await PrefManager().delete(C.pref.mqttPassword);
  }

  /// Restituisce la lista delle predizioni.
  ///
  /// Un metodo che, dato l'id di un luogo, restituisce
  /// la lista delle predizioni della CO2 per quel luogo.
  /// Le predizioni sono 1 per ora per 24 ore.
  Future<List<Prediction>> getPredictions(int id) async {
    if (!await ensureLoggedIn()) {
      return Future.error('Accesso non effettuato');
    }

    final String cookie = await PrefManager().read("cookie") as String;

    return get(C.acc.urlPredictions + id.toString(), cookie).then((response) {
      if (response.statusCode == 200) {
        // Parsa tutte le predizioni dal json e le restituisce
        List<Prediction> predictions = [];
        for (var prediction in response.data) {
          predictions.add(Prediction.fromJson(prediction));
        }
        return predictions;
      } else {
        return Future.error('Errore dal server: ${response.statusCode}');
      }
    });
  }
}
