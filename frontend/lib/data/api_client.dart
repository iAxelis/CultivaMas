import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clearTokens();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'cultiva_access_token';
  static const _refreshTokenKey = 'cultiva_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final body = response?.data;
    final messageValue = body is Map ? body['message'] : null;
    final message = switch (messageValue) {
      String value => value,
      List values => values.whereType<String>().join(' '),
      _ when response == null =>
        'No se pudo conectar con el servidor. Verifica la conexión y la URL de la API.',
      _ => 'Ocurrió un error al comunicarse con el servidor.',
    };
    final codeValue = body is Map ? body['codigo'] ?? body['code'] : null;
    return ApiException(
      message,
      statusCode: response?.statusCode,
      code: codeValue is String ? codeValue : null,
    );
  }

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({TokenStorage? tokenStorage, Dio? dio, Dio? refreshDio})
    : tokenStorage = tokenStorage ?? SecureTokenStorage(),
      dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: const {'Accept': 'application/json'},
            ),
          ),
      refreshDio =
          refreshDio ??
          Dio(
            BaseOptions(
              baseUrl: _apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: const {'Accept': 'application/json'},
            ),
          ) {
    this.dio.interceptors.add(
      _AuthInterceptor(
        dio: this.dio,
        refreshDio: this.refreshDio,
        tokenStorage: this.tokenStorage,
      ),
    );
  }

  static const _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
  static bool get hasProductionBaseUrl {
    final uri = Uri.tryParse(_configuredBaseUrl.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return false;
    }
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
    final reservedHost =
        host == 'localhost' ||
        host.endsWith('.localhost') ||
        host == 'test' ||
        host.endsWith('.test') ||
        host == 'example' ||
        host.endsWith('.example') ||
        host.endsWith('.invalid') ||
        host == 'example.com' ||
        host.endsWith('.example.com') ||
        host == 'ejemplo.com' ||
        host.endsWith('.ejemplo.com');
    final pathSegments =
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    return pathSegments.length >= 2 &&
        pathSegments[pathSegments.length - 2] == 'api' &&
        pathSegments.last == 'v1' &&
        !reservedHost;
  }

  static final _apiBaseUrl =
      _configuredBaseUrl.endsWith('/')
          ? _configuredBaseUrl
          : '$_configuredBaseUrl/';

  final Dio dio;
  final Dio refreshDio;
  final TokenStorage tokenStorage;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required this.dio,
    required this.refreshDio,
    required this.tokenStorage,
  });

  final Dio dio;
  final Dio refreshDio;
  final TokenStorage tokenStorage;
  Completer<String?>? _refreshCompleter;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode != 401 ||
        error.requestOptions.extra['skipAuthRefresh'] == true) {
      handler.next(error);
      return;
    }

    final currentAccessToken = await tokenStorage.readAccessToken();
    final sentAccessToken = error.requestOptions.headers['Authorization'];
    if (currentAccessToken != null &&
        sentAccessToken != 'Bearer $currentAccessToken') {
      await _retry(error.requestOptions, currentAccessToken, handler);
      return;
    }

    var completer = _refreshCompleter;
    if (completer == null) {
      completer = Completer<String?>();
      _refreshCompleter = completer;
      unawaited(_refreshTokens(completer));
    }

    final accessToken = await completer.future;
    if (accessToken == null) {
      handler.next(error);
      return;
    }
    await _retry(error.requestOptions, accessToken, handler);
  }

  Future<void> _refreshTokens(Completer<String?> completer) async {
    try {
      final refreshToken = await tokenStorage.readRefreshToken();
      if (refreshToken == null) {
        await tokenStorage.clearTokens();
        completer.complete(null);
        return;
      }

      final response = await refreshDio.post<Map<String, dynamic>>(
        'auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final accessToken = response.data?['accessToken'];
      final rotatedRefreshToken = response.data?['refreshToken'];
      if (accessToken is! String || rotatedRefreshToken is! String) {
        throw const FormatException('Respuesta inválida al renovar la sesión.');
      }
      await tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: rotatedRefreshToken,
      );
      completer.complete(accessToken);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await tokenStorage.clearTokens();
      }
      completer.complete(null);
    } on FormatException {
      completer.complete(null);
    } finally {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }

  Future<void> _retry(
    RequestOptions request,
    String accessToken,
    ErrorInterceptorHandler handler,
  ) async {
    request
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..extra['skipAuthRefresh'] = true;
    try {
      handler.resolve(await dio.fetch<dynamic>(request));
    } on DioException catch (error) {
      handler.next(error);
    }
  }
}
