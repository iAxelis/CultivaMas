import 'package:cultiva_plus/core/theme.dart';
import 'package:cultiva_plus/data/api_client.dart';
import 'package:cultiva_plus/data/auth_service.dart';
import 'package:cultiva_plus/data/models.dart';
import 'package:cultiva_plus/data/store.dart';
import 'package:cultiva_plus/features/catalog/catalog_forms.dart';
import 'package:cultiva_plus/features/operations/forms.dart';
import 'package:cultiva_plus/features/screens/screens.dart';
import 'package:cultiva_plus/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('muestra el nombre y plan de la empresa autenticada', (
    tester,
  ) async {
    final store = AppStore(loadRemoteDataOnSignIn: false)
      ..companyProfile = {
        'nombre': 'Mi Finca',
        'estadoSuscripcion': 'PRUEBA',
        'plan': {'nombre': 'Productor'},
      };

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: const MaterialApp(home: MoreScreen()),
      ),
    );

    expect(find.text('Mi Finca'), findsOneWidget);
    expect(find.text('Productor · Administrador'), findsOneWidget);
    expect(find.text('PRUEBA'), findsOneWidget);
    expect(find.text('Rancho Los Pinos'), findsNothing);
  });

  testWidgets(
    'envía el registro con los campos requeridos y datos opcionales vacíos',
    (tester) async {
      Map<String, dynamic>? sentBody;
      final dio = Dio(BaseOptions(baseUrl: 'https://cultiva.test/api/v1/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sentBody = Map<String, dynamic>.from(options.data as Map);
            handler.resolve(
              Response<void>(requestOptions: options, statusCode: 200),
            );
          },
        ),
      );
      final apiClient = ApiClient(
        dio: dio,
        refreshDio: Dio(BaseOptions(baseUrl: 'https://cultiva.test/api/v1/')),
        tokenStorage: _MemoryTokenStorage(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppStore(loadRemoteDataOnSignIn: false),
          child: MaterialApp(home: CompanyFormScreen(apiClient: apiClient)),
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Maria Lopez');
      await tester.enterText(fields.at(1), 'maria@finca.test');
      await tester.enterText(fields.at(3), 'ClaveSegura123');
      await tester.enterText(fields.at(4), 'Mi Finca');
      await tester.ensureVisible(
        find.text('Acepto continuar con el plan seleccionado.'),
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.ensureVisible(find.text('Enviar código'));
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Enviamos un código'), findsOneWidget);
      expect(sentBody?['nombre'], 'Mi Finca');
      expect(sentBody?['usuarioNombre'], 'Maria');
      expect(sentBody?['usuarioApellido'], 'Lopez');
      expect(sentBody?.containsKey('razonSocial'), isFalse);
      expect(sentBody?.containsKey('rfc'), isFalse);
      expect(sentBody?.containsKey('telefono'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

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

  testWidgets('mantiene el mismo fundido y escala al navegar entre pantallas', (
    tester,
  ) async {
    await _openLogin(tester);
    GoRouter.of(
      tester.element(find.text('Iniciar sesión')),
    ).push('/company/new');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(ScaleTransition), findsWidgets);
    expect(find.byType(SlideTransition), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('usa la misma transición de página en todas las plataformas', () {
    final transitions =
        buildTheme().pageTransitionsTheme.builders.values.toSet();

    expect(transitions, hasLength(1));
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
    expect(find.byType(SlideTransition), findsNothing);
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

  testWidgets('solicita confirmación antes de cerrar sesión', (tester) async {
    await _openLogin(tester);
    await _signIn(tester, 'ramon@lospinos.mx', 'Admin123!');

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Más'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('¿Quieres salir de tu cuenta?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
    expect(find.text('¿Quieres salir de tu cuenta?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra el resumen financiero vacío y permite cerrar sesión', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openLogin(tester);
    await _signIn(tester, 'ramon@lospinos.mx', 'Admin123!');

    expect(find.text('Resumen financiero'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay ciclos'), findsOneWidget);
    expect(find.text('T1'), findsNothing);

    await _signOut(tester);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permite cambiar actividad y responsable del formulario', (
    tester,
  ) async {
    final store =
        AppStore(loadRemoteDataOnSignIn: false)
          ..cycles.add(
            FarmCycle(
              id: '1',
              parcelId: '1',
              parcel: 'Parcela 1',
              crop: 'Cultivo',
              varietyId: '1',
              status: CycleStatus.activo,
              area: 1,
              cost: 0,
              income: 0,
              harvestedKg: 0,
              goalKg: 100,
            ),
          )
          ..catalogs['activityTypes'] = [
            {'id': 1, 'nombre': 'Aplicación foliar'},
            {'id': 2, 'nombre': 'Riego'},
          ]
          ..users.add(
            AppUser(
              id: '1',
              name: 'Ramón Ortega',
              email: 'ramon@finca.test',
              role: UserRole.admin,
            ),
          );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => store,
        child: const MaterialApp(
          home: DataFormScreen(type: 'activity', cycleId: '1'),
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

  testWidgets('gastos y ventas no desbordan en pantallas estrechas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store =
        AppStore(loadRemoteDataOnSignIn: false)
          ..cycles.add(
            FarmCycle(
              id: '1',
              parcelId: '1',
              parcel: 'Parcela 1',
              crop: 'Cultivo',
              varietyId: '1',
              status: CycleStatus.activo,
              area: 1,
              cost: 0,
              income: 0,
              harvestedKg: 500,
              goalKg: 1000,
            ),
          )
          ..catalogs['expenseCategories'] = [
            {'id': 1, 'nombre': 'Insumos'},
          ]
          ..clients.add(
            BusinessPartner(
              id: '1',
              name: 'Cliente con nombre largo',
              kind: 'OTRO',
              detail: '',
            ),
          );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: const MaterialApp(
          home: DataFormScreen(type: 'expense', cycleId: '1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: const MaterialApp(
          home: DataFormScreen(type: 'sale', cycleId: '1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('explica el requisito de parcela antes de crear un ciclo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStore(loadRemoteDataOnSignIn: false),
        child: const MaterialApp(home: DataFormScreen(type: 'cycle')),
      ),
    );

    expect(find.text('Necesitas una parcela disponible'), findsOneWidget);
    expect(find.text('Configurar predios'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra el formulario de ciclo con parcela y variedad reales', (
    tester,
  ) async {
    final store =
        AppStore(loadRemoteDataOnSignIn: false)
          ..properties.add(
            FarmProperty(
              id: '1',
              name: 'Predio 1',
              area: 5,
              location: 'Localidad',
              parcels: [
                Parcel(id: '1', name: 'Parcela 1', area: 2, soil: 'Franco'),
              ],
            ),
          )
          ..catalogs['varieties'] = [
            {'id': 1, 'nombre': 'Variedad 1'},
          ];
    expect(store.properties, hasLength(1));
    expect(store.catalogs['varieties'], hasLength(1));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => store,
        child: const MaterialApp(home: DataFormScreen(type: 'cycle')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Necesitas una parcela disponible'), findsNothing);
    expect(find.text('No hay variedades disponibles'), findsNothing);
    expect(find.text('PARCELA DISPONIBLE'), findsOneWidget);
    expect(find.text('VARIEDAD'), findsOneWidget);
    expect(find.text('FECHA DE INICIO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permite crear un predio cuando la cuenta todavía está vacía', (
    tester,
  ) async {
    final store = AppStore(loadRemoteDataOnSignIn: false);
    final router = GoRouter(
      initialLocation: '/properties/form/property',
      routes: [
        GoRoute(
          path: '/properties',
          builder: (_, __) => const Scaffold(body: Text('Predios')),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, __) => const Scaffold(),
              routes: [
                GoRoute(
                  path: 'property',
                  builder: (_, __) => const CatalogFormScreen(type: 'property'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => store,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.text('SUPERFICIE'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Mi predio');
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), '2,5');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(store.properties, hasLength(1));
    expect(store.properties.single.name, 'Mi predio');
    expect(store.properties.single.area, 2.5);
    expect(tester.takeException(), isNull);
    router.dispose();
  });

  testWidgets('precarga el token al abrir un enlace de recuperación', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RecoveryPasswordScreen(
          initialToken:
              'http://localhost:8080/restablecer-contrasena#token=reset-123',
        ),
      ),
    );

    final tokenField = tester.widget<TextField>(find.byType(TextField).first);
    expect(tokenField.controller!.text, 'reset-123');
    expect(find.text('Restablecer contraseña'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Widget _app() {
  return ChangeNotifierProvider(
    create:
        (_) => AppStore(
          authService: _TestAuthService(),
          loadRemoteDataOnSignIn: false,
        ),
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
  await tester.tap(find.text('Cerrar sesión').last);
  await tester.pumpAndSettle();
}

class _TestAuthService implements AuthService {
  static const _accounts = {
    'ramon@lospinos.mx': ('Admin123!', 'Ramón Ortega', UserRole.admin),
    'luis@lospinos.mx': ('Campo123!', 'Luis Pérez', UserRole.capturista),
    'marta@lospinos.mx': ('Finanzas123!', 'Marta Rangel', UserRole.contador),
  };

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.$1 != password) {
      throw const ApiException('Credenciales incorrectas.', statusCode: 401);
    }
    return AppUser(name: account.$2, email: email, role: account.$3);
  }

  @override
  Future<AppUser?> restoreSession() async => null;

  @override
  Future<void> signOut() async {}
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
