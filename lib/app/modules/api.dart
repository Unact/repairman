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
  final httpClient = http.Client();
  String _token;

  get loggedUser => User.currentUser();

  Future<dynamic> _sendRawRequest(
    String httpMethod,
    String apiMethod,
    Map<String, String> headers,
    [String body]
  ) async {
    http.Request request = http.Request(httpMethod, Uri.parse(App.application.config.apiBaseUrl + apiMethod));
    if (headers != null) request.headers.addAll(headers);
    if (body != null) request.body = body;

    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Repairman': '${App.application.config.packageInfo.version}'
    });

    try {
      return parseResponse(await http.Response.fromStream(await httpClient.send(request)));
    } catch(e) {
      if (e is SocketException || e is http.ClientException || e is HandshakeException) {
        throw ApiConnException();
      } else {
        rethrow;
      }
    }
  }

  Future<dynamic> _sendRequest(
    String httpMethod,
    String apiMethod,
    Map<String, String> headers,
    [String body = '']
  ) async {
    if (_token != null) {
      headers.addAll({
        'Authorization': 'RApi client_id=${App.application.config.clientId},token=$_token',
        'FirebaseToken': '${loggedUser.firebaseToken}'
      });
    }

    try {
      return await _sendRawRequest(httpMethod, apiMethod, headers, body);
    } on AuthException {
      await relogin();
      return await _sendRequest(httpMethod, apiMethod, headers, body);
    }
  }

  Future<dynamic> get(String method) async {
    return await _sendRequest('GET', method, {});
  }

  Future<dynamic> post(String method, {body}) async {
    return await _sendRequest('POST', method, {}, _encoder.convert(body));
  }

  Future<void> resetPassword(String username) async {
    await _sendRequest('POST', 'v1/reset_password', {
      'Authorization': 'RApi client_id=${App.application.config.clientId},login=$username'
    });
  }

  Future<void> login(String username, String password) async {
    User user = loggedUser;
    await _authenticate(username, password);
    user.username = username;
    user.password = password;
    user.update();
  }

  Future<void> logout() async {
    _token = null;
    loggedUser.delete();
  }

  Future<void> relogin() async {
    _token = null;
    await _authenticate(loggedUser.username, loggedUser.password);
  }

  Future<void> _authenticate(String username, String password) async {
    dynamic response = await _sendRawRequest('POST', 'v1/authenticate', {
      'Authorization': 'RApi client_id=${App.application.config.clientId},login=$username,password=$password'
    });
    _token = response['token'];
  }

  dynamic parseResponse(http.Response response) {
      final int statusCode = response.statusCode;
      final String body = response.body;
      dynamic parsedResp;

      if (statusCode < 200) {
        throw ApiException('Ошибка при получении данных', statusCode);
      }

      if (statusCode >= 500) {
        throw ServerException(statusCode);
      }

      parsedResp = body.isEmpty ? Map<String, dynamic>() : _decoder.convert(body);

      if (statusCode == 401) {
        throw AuthException(parsedResp['error']);
      }

      if (statusCode >= 400) {
        throw ApiException(parsedResp['error'], statusCode);
      }

      return parsedResp;
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

class ServerException extends ApiException {
  ServerException(statusCode) : super('Нет связи с сервером', statusCode);
}

class ApiConnException extends ApiException {
  ApiConnException() : super('Нет связи', 503);
}
