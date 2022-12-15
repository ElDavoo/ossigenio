/*
Class to manage accounts registered in the http server
 */
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/log.dart';

class AccountConstants{
  static const String server = 'modena.davidepalma.it';
  static const String port = '80';
  static const String urlLogin = '/login';
  static const String urlRegister = '/signUp';
}

class AccountManager{

  static final AccountManager _instance = AccountManager._internal();

  factory AccountManager() {
    return _instance;
  }

  AccountManager._internal();


  static Future<bool> login(String username, String password) async {
    // use dio
    Dio dio = Dio();
    // set the base url
    dio.options.baseUrl = 'http://${AccountConstants.server}:${AccountConstants.port}';
    // set the headers
    /*dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };*/
    // set the body
    var body = {
      'inputName': username,
      'inputPassword': password,
    };
    // send the request
    Response response = await dio.post(AccountConstants.urlLogin, data: body);
    Log.v(response.data);
    // check the response
    if (response.statusCode == 200) {
      // login successful
      return true;
    } else {
      // login failed
      return false;
    }
  }
  static Future<bool> register(String email, String username, String password) async {
    // use dio
    Dio dio = Dio();
    // set the base url
    dio.options.baseUrl = 'http://${AccountConstants.server}:${AccountConstants.port}';
    // set the headers
    /*dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };*/
    // set the body as multipart form
    var body = FormData.fromMap({
      'inputEmail': email,
      'inputName': username,
      'inputPassword': password,
    });
    // send the request
    Response response = await dio.post(AccountConstants.urlRegister, data: body);
    Log.v(response.data);
    // check the response
    if (response.statusCode == 200) {
      // save account data in the local storage

      // login successful
      return true;
    } else {
      // login failed
      return false;
    }
  }
}