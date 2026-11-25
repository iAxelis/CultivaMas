import 'dart:typed_data';

import 'package:cultiva_plus/data/auth_service.dart';
import 'package:cultiva_plus/data/backend_repository.dart';
import 'package:cultiva_plus/data/models.dart';
import 'package:cultiva_plus/data/store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'applies record edit and delete permissions by author and role',
    () async {
      final store = AppStore(
        authService: _TestAuthService(
          AppUser(
            id: '42',
            name: 'Usuario',
            email: 'usuario@example.test',
            role: UserRole.capturista,
          ),
        ),
        loadRemoteDataOnSignIn: false,
      );
      await store.signIn(email: 'usuario@example.test', password: 'password');

      final ownRecord = _record(createdById: '42');
      final otherRecord = _record(createdById: '84');

      expect(store.canEditRecord(ownRecord), isTrue);
      expect(store.canEditRecord(otherRecord), isFalse);
      expect(store.canDeleteRecord(ownRecord), isFalse);

      await store.signOut();
      final adminStore = AppStore(
        authService: _TestAuthService(
          AppUser(
            id: '84',
            name: 'Administrador',
            email: 'admin@example.test',
            role: UserRole.admin,
          ),
        ),
        loadRemoteDataOnSignIn: false,
      );
      await adminStore.signIn(
        email: 'admin@example.test',
        password: 'password',
      );
      expect(adminStore.canEditRecord(otherRecord), isTrue);
      expect(adminStore.canDeleteRecord(otherRecord), isTrue);
    },
  );

  test('downloads attachments using the short-lived server token', () async {
    final repository = _AttachmentRepository();
    final store = AppStore(backendRepository: repository);

    final file = await store.downloadAttachment('19');

    expect(repository.readPath, 'adjuntos/19/enlace-descarga');
    expect(repository.downloadPath, 'adjuntos/descarga');
    expect(repository.downloadQuery, {'token': 'signed-token'});
    expect(file.filename, 'comprobante.pdf');
    expect(file.bytes, [1, 2, 3]);
  });
}

ActivityRecord _record({required String createdById}) => ActivityRecord(
  id: '19',
  title: 'Actividad',
  detail: 'Riego',
  kind: 'Actividad',
  date: DateTime(2026, 5, 1),
  resourcePath: 'actividades',
  createdById: createdById,
);

class _TestAuthService implements AuthService {
  const _TestAuthService(this.user);

  final AppUser user;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => user;

  @override
  Future<AppUser?> restoreSession() async => user;

  @override
  Future<void> signOut() async {}
}

class _AttachmentRepository extends BackendRepository {
  String? readPath;
  String? downloadPath;
  Map<String, Object?>? downloadQuery;

  @override
  Future<Map<String, dynamic>> read(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) async {
    readPath = path;
    return {'token': 'signed-token'};
  }

  @override
  Future<DownloadedFile> download(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) async {
    downloadPath = path;
    downloadQuery = queryParameters;
    return DownloadedFile(
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'comprobante.pdf',
      contentType: 'application/pdf',
    );
  }
}
