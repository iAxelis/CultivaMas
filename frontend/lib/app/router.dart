import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../data/store.dart';
import '../features/catalog/catalog_forms.dart';
import '../features/operations/forms.dart';
import '../features/screens/screens.dart';

String _homeFor(UserRole role) =>
    role == UserRole.capturista ? '/capture' : '/home';

GoRouter createAppRouter(AppStore store) => GoRouter(
  initialLocation: '/splash',
  refreshListenable: store,
  redirect: (context, state) {
    final path = state.uri.path;
    final isPublicRoute =
        path == '/splash' || path == '/login' || path == '/company/new';

    if (!store.isAuthenticated) {
      return isPublicRoute ? null : '/login';
    }
    if (isPublicRoute) return _homeFor(store.role);

    final role = store.role;
    if ((path == '/home' || path == '/sales' || path.startsWith('/sales/')) &&
        role == UserRole.capturista) {
      return '/capture';
    }
    if (path == '/capture' && role == UserRole.contador) return '/home';
    if (path == '/records' && role == UserRole.contador) return '/home';
    if ((path == '/properties' ||
            path == '/receivables' ||
            path == '/clients' ||
            path == '/suppliers' ||
            path == '/expense-categories' ||
            path == '/users' ||
            path == '/company' ||
            path == '/audit' ||
            path == '/alerts' ||
            path == '/comparison' ||
            path == '/reports' ||
            path == '/profile' ||
            path == '/help') &&
        !store.canAccess(_moduleSlugForPath[path]!)) {
      return _homeFor(role);
    }
    if (path.startsWith('/module/')) {
      final slug = path.substring('/module/'.length);
      if (!store.canAccess(slug)) return _homeFor(role);
    }
    if (path.startsWith('/catalog-form/') && role != UserRole.admin) {
      return _homeFor(role);
    }
    if (path.startsWith('/form/')) {
      final type = path.substring('/form/'.length);
      final allowed = switch (role) {
        UserRole.admin => true,
        UserRole.capturista => const {
          'activity',
          'expense',
          'harvest',
          'loss',
        }.contains(type),
        UserRole.contador => const {'sale', 'payment'}.contains(type),
      };
      if (!allowed) return _homeFor(role);
    }
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/company/new',
      builder: (_, __) => const CompanyFormScreen(),
    ),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/capture', builder: (_, __) => const CaptureHomeScreen()),
    GoRoute(path: '/cycles', builder: (_, __) => const CyclesScreen()),
    GoRoute(
      path: '/cycles/:id',
      builder: (_, state) => CycleDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/sales', builder: (_, __) => const SalesScreen()),
    GoRoute(
      path: '/sales/:id',
      builder: (_, state) => SaleDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/records', builder: (_, __) => const RecordsScreen()),
    GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
    GoRoute(
      path: '/properties',
      builder: (_, __) => const ModuleScreen(slug: 'predios'),
    ),
    GoRoute(
      path: '/receivables',
      builder: (_, __) => const ModuleScreen(slug: 'cuentas-por-cobrar'),
    ),
    GoRoute(
      path: '/clients',
      builder: (_, __) => const ModuleScreen(slug: 'clientes'),
    ),
    GoRoute(
      path: '/suppliers',
      builder: (_, __) => const ModuleScreen(slug: 'proveedores'),
    ),
    GoRoute(
      path: '/expense-categories',
      builder: (_, __) => const ModuleScreen(slug: 'categorias'),
    ),
    GoRoute(
      path: '/users',
      builder: (_, __) => const ModuleScreen(slug: 'usuarios'),
    ),
    GoRoute(
      path: '/company',
      builder: (_, __) => const ModuleScreen(slug: 'empresa'),
    ),
    GoRoute(
      path: '/audit',
      builder: (_, __) => const ModuleScreen(slug: 'auditoria'),
    ),
    GoRoute(
      path: '/alerts',
      builder: (_, __) => const ModuleScreen(slug: 'alertas'),
    ),
    GoRoute(
      path: '/comparison',
      builder: (_, __) => const ModuleScreen(slug: 'comparativo'),
    ),
    GoRoute(
      path: '/reports',
      builder: (_, __) => const ModuleScreen(slug: 'reportes'),
    ),
    GoRoute(
      path: '/profile',
      builder: (_, __) => const ModuleScreen(slug: 'perfil'),
    ),
    GoRoute(
      path: '/help',
      builder: (_, __) => const ModuleScreen(slug: 'ayuda'),
    ),
    GoRoute(
      path: '/catalog-form/:type',
      builder:
          (_, state) => CatalogFormScreen(type: state.pathParameters['type']!),
    ),
    GoRoute(
      path: '/module/:slug',
      builder: (_, state) => ModuleScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/form/:type',
      builder:
          (_, state) => DataFormScreen(
            type: state.pathParameters['type']!,
            cycleId: state.uri.queryParameters['cycle'],
            saleId: state.uri.queryParameters['sale'],
          ),
    ),
  ],
  errorBuilder:
      (_, __) =>
          const Scaffold(body: Center(child: Text('Pantalla no encontrada'))),
);

const _moduleSlugForPath = {
  '/properties': 'predios',
  '/receivables': 'cuentas-por-cobrar',
  '/clients': 'clientes',
  '/suppliers': 'proveedores',
  '/expense-categories': 'categorias',
  '/users': 'usuarios',
  '/company': 'empresa',
  '/audit': 'auditoria',
  '/alerts': 'alertas',
  '/comparison': 'comparativo',
  '/reports': 'reportes',
  '/profile': 'perfil',
  '/help': 'ayuda',
};
