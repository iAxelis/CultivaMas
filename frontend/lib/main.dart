import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/router.dart';
import 'core/theme.dart';
import 'data/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStore(),
      child: const AgroApp(),
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
      builder: (context, child) => ColoredBox(
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
