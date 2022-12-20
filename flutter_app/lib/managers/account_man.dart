/*
Class to manage accounts registered in the http server
 */
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:flutter_app/utils/device.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/log.dart';

class AccConsts {
  static const String server = 'modena.davidepalma.it';
  static const String httpPort = '80';
  static const String httpsPort = '443';
  static const String urlLogin = '/login';
  static const String urlRegister = '/signUp';
  static const String urlCheckMac = '/checkMac';
  static const int apiVersion = 0;

}

class AccountManager {
  static final AccountManager _instance = AccountManager._internal();

  factory AccountManager() {
    return _instance;
  }

  AccountManager._internal() {
    dio.options.baseUrl =
    'https://${AccConsts.server}:${AccConsts.httpsPort}/api/${AccConsts.apiVersion}';
    Log.l('AccountManager initialized');
    // TODO retrieve token or usename/password from secure storage
    _isLoggedIn = login();
  }

  final Dio dio = Dio();
  final PrefManager prefManager = PrefManager();

  late final Future<bool> _isLoggedIn;

  // a stream to notify the app when the login status changes
  final StreamController<bool> _loginStatusController = StreamController<bool>.broadcast();
  Stream<bool> get loginStatus => _loginStatusController.stream;


  Future<bool> login() async {
    Log.l('Logging in...');
    if (await areDataSaved()) {
      Log.l('Data saved');
      String username = await prefManager.read(PrefConstants.username) as String;
      String password = await prefManager.read(PrefConstants.password) as String;
      bool areSavedValid = await loginWith(username, password);
      if (areSavedValid) {
        Log.l('Saved credentials are valid');
        return true;
      } else {
        Log.l('Saved credentials are not valid');
        await prefManager.delete(PrefConstants.username);
        await prefManager.delete(PrefConstants.password);
        return false;
      }
    } else {
      Log.l('Data not saved');
      return false;
    }
  }

  Future<bool> areDataSaved() async {
    if (await prefManager.read(PrefConstants.username) != null &&
        await prefManager.read(PrefConstants.password) != null) {
      return true;
    }
    return false;
  }

  Future<bool> loginWith(String username, String password) async {
    // set the body
    var body = {
      'inputName': username,
      'inputPassword': password,
    };
    // FIXME
    // notify the stream
    _loginStatusController.add(true);
    prefManager.saveAccountData(username, password);
    return true;
    // send the request
    Response response = await dio.post(AccConsts.urlLogin, data: body);
    Log.v(response.data);
    // check the response
    if (response.statusCode == 200) {
      // login successful, save data
      prefManager.saveAccountData(username, password);
      return true;
    } else {
      // login failed
      return false;
    }
  }

  Future<bool> register(
      String email, String username, String password) async {
    // set the body as multipart form
    var body = FormData.fromMap({
      'inputEmail': email,
      'inputName': username,
      'inputPassword': password,
    });
    // send the request
    Response response =
        await dio.post(AccConsts.urlRegister, data: body);
    Log.v(response.data);
    // check the response
    if (response.statusCode == 200) {
      // save account data in the local storage
      prefManager.saveAccountData(username, password);
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
    if (await _isLoggedIn) {
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

  // Method to get mqtt credentials
  Future<Map<String, String>> getMqttCredentials() async {
    if (await _isLoggedIn) {
      // check if there are
      // TODO
      return {'username': 'test', 'password': 'test2'};
    } else {
      return Future.error('Not logged in');
    }
  }
}
