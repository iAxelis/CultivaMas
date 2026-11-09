import 'package:dio/dio.dart';

import 'api_client.dart';
import 'models.dart';

abstract interface class AuthService {
  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser?> restoreSession();
  Future<void> signOut();
}

class BackendAuthService implements AuthService {
  BackendAuthService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        'auth/login',
        data: {'correo': email.trim().toLowerCase(), 'contrasena': password},
        options: Options(extra: {'skipAuthRefresh': true}),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException('El servidor devolvió una respuesta vacía.');
      }
      final user = _userFromJson(data['usuario']);
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      if (accessToken is! String || refreshToken is! String) {
        throw const ApiException('La respuesta de autenticación no es válida.');
      }
      await _apiClient.tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return user;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AppUser?> restoreSession() async {
    final accessToken = await _apiClient.tokenStorage.readAccessToken();
    final refreshToken = await _apiClient.tokenStorage.readRefreshToken();
    if (accessToken == null && refreshToken == null) return null;

    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        'auth/me',
      );
      return _userFromJson(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> signOut() async {
    final refreshToken = await _apiClient.tokenStorage.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _apiClient.dio.post<void>(
          'auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    } finally {
      await _apiClient.tokenStorage.clearTokens();
    }
  }

  AppUser _userFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const ApiException('El perfil recibido del servidor no es válido.');
    }
    final role = switch (value['rol']) {
      'ADMIN' => UserRole.admin,
      'CAPTURISTA' => UserRole.capturista,
      'CONTADOR' => UserRole.contador,
      _ => throw const ApiException('El servidor devolvió un rol desconocido.'),
    };
    final nombre = value['nombre'];
    final apellido = value['apellido'];
    final correo = value['correo'];
    if (nombre is! String || correo is! String) {
      throw const ApiException('El perfil recibido del servidor no es válido.');
    }
    return AppUser(
      name: [
        nombre,
        if (apellido is String && apellido.isNotEmpty) apellido,
      ].join(' '),
      email: correo,
      role: role,
    );
  }
}
