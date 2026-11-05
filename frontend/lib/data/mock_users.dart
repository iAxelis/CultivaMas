import 'models.dart';

class MockUserAccount {
  const MockUserAccount({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  final String name;
  final String email;
  final String password;
  final UserRole role;
}

const mockUsers = [
  MockUserAccount(
    name: 'Ramón Ortega',
    email: 'ramon@lospinos.mx',
    password: 'Admin123!',
    role: UserRole.admin,
  ),
  MockUserAccount(
    name: 'Luis Pérez',
    email: 'luis@lospinos.mx',
    password: 'Campo123!',
    role: UserRole.capturista,
  ),
  MockUserAccount(
    name: 'Marta Rangel',
    email: 'marta@lospinos.mx',
    password: 'Finanzas123!',
    role: UserRole.contador,
  ),
];
