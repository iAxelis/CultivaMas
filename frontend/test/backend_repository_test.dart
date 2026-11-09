import 'package:cultiva_plus/data/api_client.dart';
import 'package:cultiva_plus/data/backend_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recorre todas las páginas y conserva el orden del backend', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://cultiva.test/api/v1/'));
    final repository = BackendRepository(
      apiClient: ApiClient(
        dio: dio,
        refreshDio: Dio(BaseOptions(baseUrl: 'https://cultiva.test/api/v1/')),
        tokenStorage: _MemoryTokenStorage(),
      ),
    );
    final requestedPages = <int>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final page = options.queryParameters['page'] as int;
          requestedPages.add(page);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'data': [
                  {'id': page},
                ],
                'meta': {'page': page, 'totalPages': 2},
              },
            ),
          );
        },
      ),
    );

    final rows = await repository.list(
      'ciclos',
      queryParameters: const {'page': 1, 'limit': 100},
    );

    expect(requestedPages, [1, 2]);
    expect(rows.map((row) => row['id']), [1, 2]);
  });
}

class _MemoryTokenStorage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;

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
