import 'mock_users.dart';

class MockAuthService {
  const MockAuthService();

  Future<MockUserAccount?> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final normalizedEmail = email.trim().toLowerCase();
    for (final account in mockUsers) {
      if (account.email == normalizedEmail && account.password == password) {
        return account;
      }
    }
    return null;
  }
}
