import 'package:cultiva_plus/data/api_client.dart';
import 'package:cultiva_plus/data/auth_service.dart';
import 'package:cultiva_plus/data/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inicia sesión con el contrato real y persiste ambos tokens', () async {
    final tokenStorage = _MemoryTokenStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://cultiva.test/api/v1/'));
    final apiClient = ApiClient(
      dio: dio,
      refreshDio: Dio(BaseOptions(baseUrl: 'https://cultiva.test/api/v1/')),
      tokenStorage: tokenStorage,
    );
    RequestOptions? request;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'accessToken': 'access-123',
                'refreshToken': 'refresh-456',
                'usuario': {
                  'id': 42,
                  'nombre': 'Ana',
                  'apellido': 'Productora',
                  'correo': 'ana@cultiva.test',
                  'empresaId': 7,
                  'rol': 'ADMIN',
                  'permisos': ['ciclo:crear'],
                },
              },
            ),
          );
        },
      ),
    );

    final user = await BackendAuthService(
      apiClient: apiClient,
    ).signIn(email: ' Ana@Cultiva.test ', password: 'Clave123!');

    expect(request?.uri.toString(), 'https://cultiva.test/api/v1/auth/login');
    expect(request?.data, {
      'correo': 'ana@cultiva.test',
      'contrasena': 'Clave123!',
    });
    expect(user.name, 'Ana Productora');
    expect(user.email, 'ana@cultiva.test');
    expect(user.role, UserRole.admin);
    expect(tokenStorage.accessToken, 'access-123');
    expect(tokenStorage.refreshToken, 'refresh-456');
  });
}

class _MemoryTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}
