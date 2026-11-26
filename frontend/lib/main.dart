import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/router.dart';
import 'core/theme.dart';
import 'data/api_client.dart';
import 'data/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  if (kReleaseMode && !ApiClient.hasProductionBaseUrl) {
    runApp(const _ApiConfigurationRequiredApp());
    return;
  }
  final store = AppStore();
  await store.restoreSession();
  runApp(ChangeNotifierProvider(create: (_) => store, child: const AgroApp()));
}

class _ApiConfigurationRequiredApp extends StatelessWidget {
  const _ApiConfigurationRequiredApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No se configuró la URL HTTPS real del backend. '
            'Configura API_BASE_URL y vuelve a compilar la aplicación.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

class AgroApp extends StatefulWidget {
  const AgroApp({super.key});

  @override
  State<AgroApp> createState() => _AgroAppState();
}

class _AgroAppState extends State<AgroApp> {
  late final appRouter = createAppRouter(context.read<AppStore>());

  @override
  void dispose() {
    appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Cultiva+',
      theme: buildTheme(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      builder:
          (context, child) => ColoredBox(
            color: const Color(0xFFF1F3EC),
            child: Center(
              child: ConstrainedBox(
                key: const ValueKey('app-frame'),
                constraints: const BoxConstraints(maxWidth: 460),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF202A1E).withValues(alpha: .16),
                        blurRadius: 60,
                      ),
                    ],
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
    );
  }
}
