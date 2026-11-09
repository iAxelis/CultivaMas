import 'package:dio/dio.dart';

import 'api_client.dart';

class BackendRepository {
  BackendRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> read(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) async {
    try {
      final response = await _apiClient.dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return _objectFromJson(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> list(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) async {
    final paginated =
        queryParameters.containsKey('page') ||
        queryParameters.containsKey('limit');
    final rows = <Map<String, dynamic>>[];
    final pageValue = queryParameters['page'];
    var page = pageValue is int ? pageValue : 1;
    while (true) {
      try {
        final response = await _apiClient.dio.get<dynamic>(
          path,
          queryParameters: {...queryParameters, if (paginated) 'page': page},
        );
        final body = response.data;
        final records =
            body is List
                ? body
                : body is Map
                ? body['data']
                : null;
        if (records is! List) {
          throw const ApiException(
            'La API devolvió una lista con formato inválido.',
          );
        }
        rows.addAll(records.map(_objectFromJson));
        if (!paginated || body is! Map || body['meta'] is! Map) break;
        final totalPages = (body['meta'] as Map)['totalPages'];
        final lastPage = int.tryParse(totalPages?.toString() ?? '');
        if (lastPage == null || page >= lastPage) break;
        page++;
      } on DioException catch (error) {
        throw ApiException.fromDio(error);
      }
    }
    return rows;
  }

  Future<Map<String, dynamic>> create(
    String path, {
    required Map<String, Object?> body,
  }) async {
    try {
      final response = await _apiClient.dio.post<dynamic>(path, data: body);
      return _objectFromJson(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> update(
    String path, {
    required Map<String, Object?> body,
  }) async {
    try {
      final response = await _apiClient.dio.patch<dynamic>(path, data: body);
      return _objectFromJson(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> patchAction(String path) async {
    try {
      await _apiClient.dio.patch<void>(path);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _apiClient.dio.delete<void>(path);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static Map<String, dynamic> _objectFromJson(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const ApiException('La API devolvió un objeto con formato inválido.');
  }
}
