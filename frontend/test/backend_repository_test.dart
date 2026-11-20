import 'dart:typed_data';

import 'package:cultiva_plus/data/api_client.dart';
import 'package:cultiva_plus/data/backend_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('envía altas, cambios y acciones a sus rutas HTTP', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://cultiva.test/api/v1/'));
    final repository = BackendRepository(
      apiClient: ApiClient(
        dio: dio,
        refreshDio: Dio(BaseOptions(baseUrl: 'https://cultiva.test/api/v1/')),
        tokenStorage: _MemoryTokenStorage(),
      ),
    );
    final requests = <({String method, String path, Object? body})>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add((
            method: options.method,
            path: options.uri.path,
            body: options.data,
          ));
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              data: options.method == 'PATCH' && options.data == null
                  ? null
                  : {'id': 7},
            ),
          );
        },
      ),
    );
    const body = {'cicloId': 4, 'cantidad': '12.5'};

    await repository.create('cosechas', body: body);
    await repository.update('cosechas/7', body: body);
    await repository.patchAction('ventas/9/cancelar');

    expect(requests, [
      (
        method: 'POST',
        path: '/api/v1/cosechas',
        body: body,
      ),
      (
        method: 'PATCH',
        path: '/api/v1/cosechas/7',
        body: body,
      ),
      (
        method: 'PATCH',
        path: '/api/v1/ventas/9/cancelar',
        body: null,
      ),
    ]);
  });

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

  test('descarga exportaciones y carga adjuntos como multipart', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://cultiva.test/api/v1/'));
    final repository = BackendRepository(
      apiClient: ApiClient(
        dio: dio,
        refreshDio: Dio(BaseOptions(baseUrl: 'https://cultiva.test/api/v1/')),
        tokenStorage: _MemoryTokenStorage(),
      ),
    );
    final requests = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (options.path.endsWith('exportaciones/rentabilidad')) {
            handler.resolve(
              Response<List<int>>(
                requestOptions: options,
                data: [1, 2, 3],
                headers: Headers.fromMap({
                  'content-disposition': ['attachment; filename="reporte.pdf"'],
                  'content-type': ['application/pdf'],
                }),
              ),
            );
            return;
          }
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {'id': 12},
            ),
          );
        },
      ),
    );

    final download = await repository.download(
      'reportes/exportaciones/rentabilidad',
      queryParameters: const {'formato': 'pdf'},
    );
    final attachment = await repository.uploadAttachment(
      'gastos/12/adjuntos',
      filename: 'ticket.pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(download.bytes, [1, 2, 3]);
    expect(download.filename, 'reporte.pdf');
    expect(download.contentType, 'application/pdf');
    expect(attachment['id'], 12);
    expect(requests[0].queryParameters, {'formato': 'pdf'});
    expect(requests[1].method, 'POST');
    expect(requests[1].data, isA<FormData>());
    expect((requests[1].data as FormData).files.single.key, 'archivo');
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
