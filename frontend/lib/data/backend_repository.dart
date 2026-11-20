import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_client.dart';

class DownloadedFile {
  const DownloadedFile({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String? contentType;
}

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

  Future<DownloadedFile> download(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) async {
    try {
      final response = await _apiClient.dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );
      final contentDisposition =
          response.headers.value('content-disposition') ?? '';
      final filename =
          RegExp(
            'filename="([^"]+)"',
            caseSensitive: false,
          ).firstMatch(contentDisposition)?.group(1)?.trim();
      final safeFilename =
          filename == null || filename.isEmpty
              ? 'cultiva-exportacion'
              : filename;
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw const ApiException('El servidor devolvió un archivo vacío.');
      }
      return DownloadedFile(
        bytes: Uint8List.fromList(data),
        filename: safeFilename,
        contentType: response.headers.value(Headers.contentTypeHeader),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> uploadAttachment(
    String path, {
    required String filename,
    required Uint8List bytes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'archivo': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _apiClient.dio.post<dynamic>(path, data: formData);
      return _objectFromJson(response.data);
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
