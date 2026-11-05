import 'package:cultiva_plus/data/store.dart';
import 'package:cultiva_plus/features/operations/forms.dart';
import 'package:cultiva_plus/features/screens/screens.dart';
import 'package:cultiva_plus/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('el login no desborda en el alto reportado por Chrome', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(460, 1164);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openLogin(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra el splash y después va directamente al login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Bienvenido'), findsNothing);
    expect(find.text('Ver Guía de Estilos'), findsNothing);
    expect(find.text('CAMBIAR ROL DEL DEMO'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('autentica y redirige automáticamente los tres perfiles', (
    tester,
  ) async {
    await _openLogin(tester);
    await _signIn(tester, 'ramon@lospinos.mx', 'Admin123!');
    expect(find.text('Buen día, Ramón'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _signOut(tester);
    await _signIn(tester, 'luis@lospinos.mx', 'Campo123!');
    expect(find.text('Hola, Luis'), findsOneWidget);
    GoRouter.of(tester.element(find.text('Hola, Luis'))).go('/users');
    await tester.pumpAndSettle();
    expect(find.text('Hola, Luis'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _signOut(tester);
    await _signIn(tester, 'marta@lospinos.mx', 'Finanzas123!');
    expect(find.text('Finanzas'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rechaza credenciales incorrectas y permite reintentar', (
    tester,
  ) async {
    await _openLogin(tester);
    await _signIn(tester, 'ramon@lospinos.mx', 'incorrecta');

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Buen día, Ramón'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permite cambiar el periodo del tablero y cerrar sesión', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openLogin(tester);
    await _signIn(tester, 'ramon@lospinos.mx', 'Admin123!');

    expect(find.text('Resumen mensual'), findsOneWidget);
    await tester.ensureVisible(find.text('Año'));
    await tester.tap(find.text('Año'));
    await tester.pumpAndSettle();
    expect(find.text('T1'), findsOneWidget);

    await _signOut(tester);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permite cambiar actividad y responsable del formulario', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStore(),
        child: const MaterialApp(
          home: DataFormScreen(type: 'activity', cycleId: 'tomate-p3'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riego').last);
    await tester.pumpAndSettle();
    expect(find.text('Riego'), findsOneWidget);

    await tester.tap(dropdowns.at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ramón Ortega').last);
    await tester.pumpAndSettle();
    expect(find.text('Ramón Ortega'), findsOneWidget);
  });
}

Widget _app() {
  return ChangeNotifierProvider(
    create: (_) => AppStore(),
    child: const AgroApp(),
  );
}

Future<void> _openLogin(WidgetTester tester) async {
  await tester.pumpWidget(_app());
  await tester.pump(const Duration(milliseconds: 1100));
  await tester.pumpAndSettle();
  expect(find.text('Iniciar sesión'), findsOneWidget);
}

Future<void> _signIn(WidgetTester tester, String email, String password) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await tester.tap(find.text('Entrar'));
  await tester.pump();
  expect(find.text('Validando...'), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 550));
  await tester.pumpAndSettle();
}

Future<void> _signOut(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text('Más')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Cerrar sesión'));
  await tester.pumpAndSettle();
}
