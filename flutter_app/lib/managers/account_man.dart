/*
Class to manage accounts registered in the http server
 */
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_app/managers/mqtt_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:flutter_app/utils/device.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:crypto/crypto.dart';

import '../utils/log.dart';

class AccConsts {
  static const String server = 'modena.davidepalma.it';
  static const String httpPort = '80';
  static const String httpsPort = '443';
  static const String urlLogin = '/login';
  static const String urlRegister = '/signup';
  static const String urlCheckMac = '/checkMac';
  static const String urlGetPlaces = '/nearby';
  static const String urlUserInfo = '/user';
  static const String urlPlace = '/place/';
  static const int apiVersion = 1;
  static const int shaIterations = 1000;

}

class AccountManager {
  static final AccountManager _instance = AccountManager._internal();

  factory AccountManager() {
    return _instance;
  }

  AccountManager._internal() {
    Log.l('AccountManager initializing...');
    dio.options.baseUrl =
    'https://${AccConsts.server}:${AccConsts.httpsPort}/api/v${AccConsts.apiVersion}';
    Log.l('AccountManager initialized');

  }

  final Dio dio = Dio();
  final PrefManager prefManager = PrefManager();

  // a stream to notify the app when the login status changes
  final StreamController<bool> _loginStatusController = StreamController<bool>.broadcast();
  Stream<bool> get loginStatus => _loginStatusController.stream;


  Future<bool> login() async {
    Log.l('Logging in with cookie...');
    // First try to get user api with cookie
    try {
      Response response = await dio.get(AccConsts.urlUserInfo,
          options: Options(
              headers: {
                'Cookie': await prefManager.read(PrefConstants.cookie) as String
              }
          )
      );
      if (response.statusCode == 200) {
        Log.l('Logged in with cookie');
        String username = response.data['name'];
        String email = response.data['email'];
        // save the username and password
        PrefManager().saveAccountData(username, email);
        _loginStatusController.add(true);
        return true;
      } else {
        Log.l('Cookie login failed');
        AccountManager().logout();
        return false;
      }
    } on DioError catch (e) {
      Log.l('Error while logging in with cookie: ${e.message}');
    } catch (e) {
      Log.l('Error while logging in with cookie: ${e.toString()}');
    }
    return false;
  }

  Future<bool> areDataSaved() async {
    if (await prefManager.read(PrefConstants.cookie) != null) {
      return true;
    }
    return false;
  }

  Future<bool> loginWith(String email, String password) async {
    // crypt the password with sha256 1 milion times
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    for (int i = 0; i < AccConsts.shaIterations; i++) {
      digest = sha256.convert(digest.bytes);
    }

    // set the body
    var body = jsonEncode({
      'email': email,
      'password': digest.toString(),
    });
    // FIXME
    // notify the stream
    // send the request
    Response? response;
    try {
      response = await dio.post(AccConsts.urlLogin, data: body);
      if (response.statusCode == 200) {
        // login successful, query user api

        // Get the cookie from the headers response
        String cookie = response.headers['set-cookie']![0];
        // Save the cookie in the secure storage
        prefManager.write("cookie", cookie);
        response = await dio.get(AccConsts.urlUserInfo,
            options: Options(
                headers: {
                  'Cookie': await prefManager.read(PrefConstants.cookie) as String
                }
            )
        );
        if (response.statusCode == 200) {
          String username = response.data['name'];
          String email = response.data['email'];
          // save the username and password
          PrefManager().saveAccountData(username, email);
          // notify the stream
          _loginStatusController.add(true);
          return true;
        } else {
          Log.l('Error while logging in: ${response.statusCode}');
          return false;
        }
        return true;
      } else {
        // login failed
        return false;
      }
    } catch (e) {
      Log.v(e.toString());
      return false;
    }
    // check the response

  }

  Future<bool> register(
      String email, String username, String password) async {
    // crypt the password with sha256 1 milion times
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    for (int i = 0; i < AccConsts.shaIterations; i++) {
      digest = sha256.convert(digest.bytes);
    }
    var body = jsonEncode({
      'email': email,
      'password': digest.toString(),
      'name': username,
    });
    Response? response;
    // send the request
    try {
      response = await dio.post(AccConsts.urlRegister, data: body);
    } catch (e) {
      Log.v(e.toString());
      return false;
    }
    // check the response
    if (response.statusCode == 200) {
      // save account data in the local storage
      prefManager.saveAccountData(username, email);
      // save cookie
      String cookie = response.headers['set-cookie']![0];
      prefManager.write("cookie", cookie);
      // get mqtt credentials
      Map<String,String> mqttCredentials = await getMqttCredentials();
      MqttManager.instance.tryLogin();
      // login successful
      return true;
    } else {
      // login failed
      return false;
    }
  }

  Future<bool> checkIfValid(MacAddress mac) async {
    // Check if a mac address is original, if not, return false
    // First ensure we are logged in
    if (await areDataSaved()) {
      // TODO check if the token is valid
      return true;
      var body = FormData.fromMap({
        'macAddress': mac.toString(),
      });
      // send the request
      Response response =
          await dio.post(AccConsts.urlCheckMac, data: body);
      Log.v(response.data);
      // check the response
      if (response.statusCode == 200) {
        // mac is original
        return true;
      } else {
        // mac is spoofed
        return false;
      }
    } else {
      return false;
    }

  }

  void refreshMqtt() {
    getMqttCredentials().then((mqttCredentials) {
      prefManager.saveMqttData(
          mqttCredentials['username']! ,
          mqttCredentials['password']!);
      MqttManager.instance.tryLogin();
    });
  }

  // Method to get mqtt credentials
  Future<Map<String, String>> getMqttCredentials() async {
    if (await areDataSaved()) {
      // check if there are
      // TODO
      return {'username': 'test', 'password': 'test2'};
    } else {
      return Future.error('Not logged in');
    }
  }

  // A method that, given a coordinate, gives
  // a list of places nearby. Every place has these properties:
  // Name of the place, location of the place, air quality (express with a number)
  Future<List<Place>> getNearbyPlaces(LatLng position) async {
    // ensure we are logged in
    await areDataSaved();
    Log.v("Getting nearby places...");
    // Ask to the server, sending position as a post request
    var body = jsonEncode({
      'lat': position.latitude,
      'lon': position.longitude,
    });
    // Read authentication cookie
    String cookie = await prefManager.read("cookie") as String;
    // send the request
    Response? response;
    try {
      response = await dio.post(AccConsts.urlGetPlaces,
          data: body, options: Options(headers: {'cookie': cookie}));
    } catch (e) {
      Log.v(e.toString());
      return [];
    }
    // check the response
    if (response.statusCode == 200) {
      // parse response json to return places
      List<Place> places = [];
      for (var place in response.data) {
        Log.v("Place: ${place['name']}");
        places.add(Place.fromJson(place));
      }
      return places;
    } else {
      return Future.error('Error getting nearby places');
    }
  }

  Future<Place> getPlace(int placeId) async {
    Log.l("Getting place with id $placeId");
    //call the place api to get details
    // Read authentication cookie
    String cookie = await prefManager.read("cookie") as String;
    // send the request
    Response? response;
    try {
      response = await dio.get(AccConsts.urlPlace + placeId.toString(),
          options: Options(headers: {'cookie': cookie}));
    } catch (e) {
      Log.v(e.toString());
      return Future.error('Error getting place');
    }
    // check the response
    if (response.statusCode == 200) {
      // parse response json to return places
      Log.l("Place: ${response.data['name']}");
      return Place.fromJson(response.data);
    } else {
      return Future.error('Error getting place');
    }
  }
  Future<void> logout() async {
    // Call the logout api
    // Read authentication cookie
    // String cookie = PrefManager().read("cookie") as String;
    // send the request
    // dio.post(AccConsts.urlLogout, options: Options(headers: {'cookie': cookie}));
    // delete cookie
    await PrefManager().delete(PrefConstants.cookie);
    // delete account data
    await PrefManager().delete(PrefConstants.username);
    await PrefManager().delete(PrefConstants.email);
    // delete mqtt data
    await PrefManager().delete(PrefConstants.mqttUsername);
    await PrefManager().delete(PrefConstants.mqttPassword);

  }
}

class Place {
  late int id;
  // Defines a place
  late String name;
  late int co2Level;
  late LatLng location;

  Place(this.id, this.name, this.co2Level, this.location);

  // fromJson
  Place.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    try {
    co2Level = json['co2'];
    } catch (e) {
      co2Level = 400;
    }
    location = LatLng(json['lat'], json['lon']);
  }


}