import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/user.dart';
import 'package:repairman/config/app_config.dart';

class Api {
  Api(AppConfig config);

  final JsonDecoder _decoder = JsonDecoder();
  final JsonEncoder _encoder = JsonEncoder();
  String _token;
  User _loggedUser;

  get loggedUser {
    _loggedUser = _loggedUser ?? User.currentUser();
    return _loggedUser;
  }

  bool isLogged() {
    return loggedUser.isLogged();
  }

  Future<dynamic> get(String method) async {
    try {
      return parseResponse(await _get(method));
    } on AuthException {
      if (isLogged()) {
        await relogin();
        return parseResponse(await _get(method));
      }
    } on SocketException {
      throw ApiConnException();
    }
  }

  Future<dynamic> post(String method, {body}) async {
    try {
      return parseResponse(await _post(method, body));
    } on AuthException {
      if (isLogged()) {
        await relogin();
        return parseResponse(await _post(method, body));
      }
    } on SocketException {
      throw ApiConnException();
    }
  }

  Future<http.Response> _get(String method) async {
    return await http.get(
      App.application.config.apiBaseUrl + method,
      headers: {
        'Authorization': 'RApi client_id=${App.application.config.clientId},token=$_token',
        'FirebaseToken': '${loggedUser.firebaseToken}',
        'Repairman': '${App.application.config.packageInfo.version}',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    );
  }

  Future<http.Response> _post(String method, body) async {
    return await http.post(
      App.application.config.apiBaseUrl + method,
      body: _encoder.convert(body),
      headers: {
        'Authorization': 'RApi client_id=${App.application.config.clientId},token=$_token',
        'FirebaseToken': '${loggedUser.firebaseToken}',
        'Repairman': '${App.application.config.packageInfo.version}',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    );
  }

  Future<void> resetPassword(String username) async {
    try {
      http.Response response = await http.post(
        App.application.config.apiBaseUrl + 'v1/reset_password',
        headers: {
          'Authorization': 'RApi client_id=${App.application.config.clientId},login=$username'
        }
      );

      parseResponse(response);
    } on SocketException {
      throw ApiConnException();
    }
  }

  Future<void> login(String username, String password) async {
    await _authenticate(username, password);
    _loggedUser.username = username;
    _loggedUser.password = password;
    _loggedUser.update();
  }

  Future<void> logout() async {
    _loggedUser.delete();
    _token = null;
  }

  Future<void> relogin() async {
    await _authenticate(loggedUser.username, loggedUser.password);
  }

  Future<void> _authenticate(String username, String password) async {
    try {
      http.Response response = await http.post(
        App.application.config.apiBaseUrl + 'v1/authenticate',
        headers: {
          'Authorization': 'RApi client_id=${App.application.config.clientId},login=$username,password=$password'
        }
      );

      _token = parseResponse(response)['token'];
    } on SocketException {
      throw ApiConnException();
    }
  }

  dynamic parseResponse(http.Response response) {
      final int statusCode = response.statusCode;
      final String body = response.body;
      dynamic parsedResp;

      if (statusCode < 200) {
        throw ApiException('Ошибка при получении данных', statusCode);
      } else {
        parsedResp = _decoder.convert(body);
      }

      if (statusCode == 401) {
        throw AuthException(parsedResp['error']);
      }
      if (statusCode >= 400) {
        throw ApiException(parsedResp['error'], statusCode);
      }

      return _decoder.convert(body);
  }
}

class ApiException implements Exception {
  String errorMsg;
  int statusCode;

  ApiException(this.errorMsg, this.statusCode);
}

class AuthException extends ApiException {
  AuthException(errorMsg) : super(errorMsg, 401);
}

class ApiConnException extends ApiException {
  ApiConnException() : super('Нет связи', 503);
}
