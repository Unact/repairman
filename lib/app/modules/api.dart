import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:repairman/app/app.dart';
import 'package:repairman/app/models/user.dart';

class Api {
  static String workingVersion;

  static Future<void> resetPassword(String username) async {
    await _request(
      'POST',
      'v1/reset_password',
      headers: {
        'Authorization': 'RApi client_id=${App.application.config.clientId},login=$username'
      }
    );
  }

  static Future<void> login(String username, String password) async {
    await User.currentUser.reset();
    await _authenticate(username, password);

    User.currentUser.username = username;
    User.currentUser.password = password;
    await User.currentUser.save();
    await User.currentUser.loadDataFromRemote();
  }

  static Future<void> logout() async {
    await User.currentUser.reset();
  }

  static Future<void> relogin() async {
    User.currentUser.token = null;
    await _authenticate(User.currentUser.username, User.currentUser.password);
  }

  static Future<dynamic> get(
    String method,
    {
      Map<String, String> headers,
      Map<String, dynamic> queryParameters,
    }
  ) async {
    return await request('GET', method, headers: headers, queryParameters: queryParameters);
  }

  static Future<dynamic> post(
    String method,
    {
      Map<String, String> headers,
      Map<String, dynamic> queryParameters,
      dynamic data,
      List<File> files = const [],
      String filesKey = 'files'
    }
  ) async {
    return await request(
      'POST',
      method,
      headers: headers,
      queryParameters: queryParameters,
      data: data,
      files: files,
      filesKey: filesKey
    );
  }

  static Future<dynamic> request(
    String method,
    String apiMethod,
    {
      Map<String, String> headers,
      Map<String, dynamic> queryParameters,
      dynamic data,
      List<File>files = const [],
      String filesKey = 'files'
    }
  ) async {
    dynamic dataToSend = data;

    if (data is! Map<String, dynamic> && files.isNotEmpty) {
      throw 'files not empty, data must be Map<String, dynamic>';
    }

    if (files.isNotEmpty) {
      dataToSend = _createFilesFormData(data, files, filesKey);
    }

    try {
      return await _request(method, apiMethod, headers: headers, data: dataToSend, queryParameters: queryParameters);
    } on AuthException {
      await relogin();

      if (dataToSend is FormData) {
        dataToSend = _createFilesFormData(data, files, filesKey);
      }

      return await _request(method, apiMethod, headers: headers, data: dataToSend, queryParameters: queryParameters);
    }
  }

  static Dio _createDio([Map<String, String> headers = const {}]) {
    if (headers == null) headers = {};

    if (User.currentUser.token != null) {
      headers.addAll({
        'Authorization': 'RApi client_id=${App.application.config.clientId},token=${User.currentUser.token}',
        'FirebaseToken': '${User.currentUser.firebaseToken}'
      });
    }

    headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Repairman': '${App.application.config.packageInfo.version}'
    });

    return Dio(BaseOptions(
      baseUrl: App.application.config.apiBaseUrl,
      connectTimeout: 100000,
      receiveTimeout: 100000,
      headers: headers,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ));
  }

  static void _onDioError(DioError e) {
    if (e.response != null) {
      final int statusCode = e.response.statusCode;
      final dynamic body = e.response.data;

      if (statusCode < 200) {
        throw ApiException('Ошибка при получении данных', statusCode);
      }

      if (statusCode >= 500) {
        throw ServerException(statusCode);
      }

      if (statusCode == 401) {
        throw AuthException(body['error']);
      }

      if (statusCode == 410) {
        workingVersion = body['working_version'];
        throw VersionException(body['error']);
      }

      if (statusCode >= 400) {
        throw ApiException(body['error'], statusCode);
      }
    } else {
      if (e.error is SocketException || e.error is HandshakeException) {
        throw ApiConnException();
      } else {
        throw e;
      }
    }
  }

  static FormData _createFilesFormData(Map<String, dynamic> data, List<File> files, String filesKey) {
    Map<String, dynamic> dataToAdd = data;
    dataToAdd[filesKey] = files.map(
      (file) => MultipartFile.fromBytes(file.readAsBytesSync(), filename: file.path.split('/').last)
    ).toList();

    return FormData.fromMap(dataToAdd);
  }

  static Future<dynamic> _request(
    String method,
    String apiMethod,
    {
      Map<String, String> headers,
      Map<String, dynamic> queryParameters,
      data
    }
  ) async {
    Dio dio = _createDio(headers);
    dio.options.method = method;

    try {
      return (await dio.request(apiMethod, data: data, queryParameters: queryParameters)).data;
    } on DioError catch(e) {
      _onDioError(e);
    }
  }

  static Future<void> _authenticate(String username, String password) async {
    dynamic response = await _request(
      'POST',
      'v1/authenticate',
      headers: {
        'Authorization': 'RApi client_id=${App.application.config.clientId},login=$username,password=$password'
      }
    );
    User.currentUser.token = response['token'];
    await User.currentUser.save();
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

class VersionException extends ApiException {
  VersionException(errorMsg) : super(errorMsg, 410);
}
