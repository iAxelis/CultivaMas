import 'package:cultiva_plus/data/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'adjunta el access token como Bearer a las peticiones autenticadas',
    () async {
      final dio = Dio();
      final client = ApiClient(
        dio: dio,
        refreshDio: Dio(),
        tokenStorage: _MemoryTokenStorage(accessToken: 'access-token'),
      );
      String? authorization;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            authorization = options.headers['Authorization'] as String?;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: {'ok': true},
              ),
            );
          },
        ),
      );

      await client.dio.get<Map<String, dynamic>>('empresas/mi-empresa');

      expect(authorization, startsWith('Bearer '));
    },
  );
}

class _MemoryTokenStorage implements TokenStorage {
  _MemoryTokenStorage({this.accessToken});

  final String? accessToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> clearTokens() async {}
}
