import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/auth_service.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../access/access_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    timer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: AppColors.green,
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: controller,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: .9, end: 1).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      'assets/brand-logo.svg',
                      semanticsLabel: 'Logo de Cultiva+',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cultiva+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cada parcela cuenta',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool showPassword = false;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (isLoading || !formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final account = await const MockAuthService().signIn(
        email: emailController.text,
        password: passwordController.text,
      );
      if (!mounted) return;
      final store = context.read<AppStore>();
      final user = account == null
          ? null
          : store.userForLogin(account.email, account.role);
      if (user == null || !user.active) {
        setState(() {
          errorMessage = 'Correo o contraseña incorrectos.';
          isLoading = false;
        });
        return;
      }
      store.signIn(user);
      context.go(user.role == UserRole.capturista ? '/capture' : '/home');
    } finally {
      if (mounted && isLoading) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessScaffold(
      compactBrand: true,
      appName: 'Cultiva+',
      child: Column(
        children: [
          Text(
            'Iniciar sesión',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 7),
          Text(
            'Ingresa tus datos para continuar a Rancho Los Pinos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  enabled: !isLoading,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'nombre@rancho.mx',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(email)) {
                      return 'Escribe un correo electrónico válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  enabled: !isLoading,
                  controller: passwordController,
                  obscureText: !showPassword,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: showPassword
                          ? 'Ocultar contraseña'
                          : 'Mostrar contraseña',
                      onPressed: isLoading
                          ? null
                          : () => setState(() => showPassword = !showPassword),
                      icon: Icon(
                        showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'Escribe tu contraseña.' : null,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Expanded(child: Text('Acceso de demostración')),
                    const Spacer(),
                    Flexible(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text(
                                'La recuperación de contraseña no está disponible en este demo.',
                              ),
                            ),
                          ),
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                  ],
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: isLoading ? null : submit,
                  child: isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Validando...'),
                          ],
                        )
                      : const Text('Entrar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              Text(
                '¿Aún no tienes cuenta?',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: () => context.push('/company/new'),
                child: const Text('Regístrate'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Usa una de las cuentas de prueba documentadas en README.md.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class CompanyFormScreen extends StatefulWidget {
  const CompanyFormScreen({super.key});

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: 'Ramón Ortega');
  final emailController = TextEditingController(text: 'ramon@lospinos.mx');
  final phoneController = TextEditingController(text: '951 555 0142');
  final passwordController = TextEditingController(text: 'campoclaro');
  final companyController = TextEditingController(text: 'Rancho Los Pinos');
  final legalNameController =
      TextEditingController(text: 'Agrícola Los Pinos SPR de RL');
  final rfcController = TextEditingController(text: 'RLP010203XX0');
  String state = 'Oaxaca';
  String plan = 'Productor';
  bool accepted = false;
  bool showPassword = false;
  bool showAcceptedError = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    companyController.dispose();
    legalNameController.dispose();
    rfcController.dispose();
    super.dispose();
  }

  String? requiredValue(String? value) =>
      (value ?? '').trim().isEmpty ? 'Este campo es obligatorio.' : null;

  void submit() {
    FocusScope.of(context).unfocus();
    setState(() => showAcceptedError = !accepted);
    if (!formKey.currentState!.validate() || !accepted) return;
    final store = context.read<AppStore>();
    store.signIn(store.users.firstWhere((user) => user.role == UserRole.admin));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return AccessScaffold(
      compactBrand: true,
      appName: 'Cultiva+',
      onBack: () => context.go('/login'),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registro empresarial',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 7),
            Text(
              'Todos los datos se usan únicamente en este demo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            const _AccessFormSection('Administrador'),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Nombre completo'),
              validator: requiredValue,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration:
                  const InputDecoration(labelText: 'Correo electrónico'),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                  return 'Escribe un correo electrónico válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(labelText: 'Teléfono'),
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                return digits.length < 10
                    ? 'Escribe un teléfono de al menos 10 dígitos.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: !showPassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Contraseña',
                helperText: 'Mínimo 8 caracteres',
                suffixIcon: IconButton(
                  tooltip: showPassword
                      ? 'Ocultar contraseña'
                      : 'Mostrar contraseña',
                  onPressed: () => setState(() => showPassword = !showPassword),
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) => (value ?? '').length < 8
                  ? 'Usa al menos 8 caracteres.'
                  : null,
            ),
            const SizedBox(height: 22),
            const _AccessFormSection('Empresa'),
            TextFormField(
              controller: companyController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre comercial'),
              validator: requiredValue,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: legalNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Razón social'),
              validator: requiredValue,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: rfcController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 13,
              decoration: const InputDecoration(
                labelText: 'RFC',
                counterText: '',
              ),
              validator: (value) {
                final rfc = (value ?? '').trim().toUpperCase();
                if (!RegExp(r'^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$').hasMatch(rfc)) {
                  return 'Escribe un RFC válido de 12 o 13 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: state,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: const [
                DropdownMenuItem(value: 'Oaxaca', child: Text('Oaxaca')),
                DropdownMenuItem(value: 'Puebla', child: Text('Puebla')),
                DropdownMenuItem(value: 'Veracruz', child: Text('Veracruz')),
              ],
              onChanged: (value) => setState(() => state = value ?? state),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: plan,
              decoration: const InputDecoration(labelText: 'Plan'),
              items: const [
                DropdownMenuItem(value: 'Básico', child: Text('Básico')),
                DropdownMenuItem(value: 'Productor', child: Text('Productor')),
                DropdownMenuItem(
                  value: 'Profesional',
                  child: Text('Profesional'),
                ),
              ],
              onChanged: (value) => setState(() => plan = value ?? plan),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: accepted,
              onChanged: (value) => setState(() {
                accepted = value ?? false;
                showAcceptedError = false;
              }),
              title: const Text(
                'Acepto continuar con el plan seleccionado en este demo.',
                style: TextStyle(fontSize: 12),
              ),
              subtitle: showAcceptedError
                  ? const Text(
                      'Debes aceptar el plan para continuar.',
                      style: TextStyle(color: AppColors.red),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: submit,
              child: const Text('Crear cuenta'),
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                Text(
                  '¿Ya tienes una cuenta?',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Inicia sesión'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessFormSection extends StatelessWidget {
  const _AccessFormSection(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.title,
    required this.current,
    required this.body,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final String current;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppStore>().role;
    final destinations = switch (role) {
      UserRole.admin => const [
          ('home', 'Tablero', AppGlyphType.dashboard, '/home'),
          ('cycles', 'Ciclos', AppGlyphType.sprout, '/cycles'),
          ('capture', 'Capturar', AppGlyphType.add, '/capture'),
          ('more', 'Más', AppGlyphType.more, '/more'),
        ],
      UserRole.capturista => const [
          ('capture', 'Capturar', AppGlyphType.add, '/capture'),
          ('cycles', 'Mis ciclos', AppGlyphType.sprout, '/cycles'),
          ('records', 'Bitácora', AppGlyphType.records, '/records'),
          ('more', 'Más', AppGlyphType.more, '/more'),
        ],
      UserRole.contador => const [
          ('home', 'Finanzas', AppGlyphType.chart, '/home'),
          ('sales', 'Ventas', AppGlyphType.sales, '/sales'),
          ('cycles', 'Ciclos', AppGlyphType.sprout, '/cycles'),
          ('more', 'Más', AppGlyphType.more, '/more'),
        ],
    };
    final selected =
        math.max(0, destinations.indexWhere((item) => item.$1 == current));
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (role != UserRole.capturista)
            IconButton(
              onPressed: () => context.push('/alerts'),
              icon: const Badge(
                backgroundColor: AppColors.red,
                label: Text('2'),
                child: Icon(Icons.notifications_none_rounded, size: 28),
              ),
            ),
          if (current == 'more')
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: () {
                context.read<AppStore>().signOut();
                context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded,
                  size: 30, color: AppColors.red),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: SafeArea(
        top: false,
        child: ClipRRect(
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: NavigationBar(
            selectedIndex: selected,
            destinations: [
              for (final item in destinations)
                NavigationDestination(
                  icon: item.$1 == 'records'
                      ? Badge(
                          label: Text(
                              '${context.watch<AppStore>().records.length}'),
                          child: AppGlyph(item.$3, size: 28),
                        )
                      : AppGlyph(item.$3, size: 28),
                  label: item.$2,
                ),
            ],
            onDestinationSelected: (index) =>
                context.go(destinations[index].$4),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    if (store.role == UserRole.capturista) return const CaptureHomeScreen();
    final income =
        store.cycles.fold<double>(0, (sum, item) => sum + item.income);
    final cost = store.cycles
        .where((item) => item.status != CycleStatus.planificado)
        .fold<double>(0, (sum, item) => sum + item.cost);
    final receivable = store.sales.fold<double>(
      0,
      (sum, sale) => sum + (sale.cancelled ? 0 : sale.total - sale.paid),
    );
    return AppShell(
      title: store.role == UserRole.contador
          ? 'Finanzas'
          : 'Buen día, ${store.currentUser.name.split(' ').first}',
      current: 'home',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Text(
            'Rancho Los Pinos · Oaxaca',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          HeroCard(
            eyebrow: 'Ganancia acumulada',
            value: money.format(income - cost),
            subtitle:
                '${((income - cost) / income * 100).toStringAsFixed(1)}% de margen',
            trailing: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.trending_up_rounded,
                  color: Colors.white, size: 30),
            ),
          ),
          if (store.role == UserRole.admin) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/catalog-form/client'),
                    icon: const Icon(Icons.person_add_alt_rounded),
                    label: const Text('Nuevo cliente'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/form/cycle'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nuevo ciclo'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: .92,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatTile(
                  label: 'Ingresos',
                  value: money.format(income),
                  icon: Icons.savings_rounded),
              StatTile(
                label: 'Costo total',
                value: money.format(cost),
                icon: Icons.payments_rounded,
                color: AppColors.earth,
              ),
              StatTile(
                label: 'Margen',
                value:
                    '${((income - cost) / income * 100).toStringAsFixed(1)}%',
                icon: Icons.percent_rounded,
              ),
              StatTile(
                label: 'Por cobrar',
                value: money.format(receivable),
                icon: Icons.schedule_rounded,
                color: AppColors.amber,
              ),
            ],
          ),
          const SizedBox(height: 20),
          MonthlySummary(income: income, cost: cost),
          const SizedBox(height: 24),
          const SectionTitle('Punto de equilibrio'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                            label: 'Costo por kg',
                            value: moneyExact.format(10.49)),
                      ),
                      Expanded(
                        child: _Metric(
                            label: 'Precio promedio',
                            value: moneyExact.format(14.76)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const MiniBar(
                    label: 'Cobertura del costo',
                    value: '41% arriba',
                    progress: .71,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'La marca verde representa el precio promedio de venta.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Producción'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.greenSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.strongGreenSurface),
            ),
            child: const Wrap(
              runSpacing: 16,
              children: [
                _CompactStat(label: 'Cosechado', value: '23,800 kg'),
                _CompactStat(label: 'Merma poscosecha', value: '620 kg'),
                _CompactStat(label: 'Merma en campo', value: '410 kg'),
                _CompactStat(label: 'Disponibles', value: '2,200 kg'),
                _CompactStat(label: 'Costo / ha', value: '\$24,705'),
                _CompactStat(label: 'Rendimiento', value: '2,070 kg/ha'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle(
            'Alertas',
            action: TextButton(
              onPressed: () => context.push('/module/alertas'),
              child: const Text('Ver todas'),
            ),
          ),
          const SizedBox(height: 12),
          const InfoBanner(
            title: 'Cobro vencido · severidad alta',
            text: 'V-1037 tiene 12 días de atraso. Saldo pendiente: \$26,600.',
            tone: AppColors.red,
            icon: Icons.warning_rounded,
          ),
          const SizedBox(height: 10),
          const InfoBanner(
            title: 'Cobro tardío',
            text:
                'V-1042 no registra movimiento desde hace 8 días. Saldo: \$20,000.',
            tone: AppColors.amber,
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 24),
          SectionTitle(
            'Rentabilidad por ciclo',
            action: TextButton(
              onPressed: () => context.push('/module/comparativo'),
              child: const Text('Comparar'),
            ),
          ),
          const SizedBox(height: 12),
          for (final cycle in store.cycles) ...[
            CycleCard(cycle: cycle),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 23)),
      ],
    );
  }
}

class MonthlySummary extends StatefulWidget {
  const MonthlySummary({
    required this.income,
    required this.cost,
    super.key,
  });

  final double income;
  final double cost;

  @override
  State<MonthlySummary> createState() => _MonthlySummaryState();
}

class _MonthlySummaryState extends State<MonthlySummary> {
  static const periods = <String, _ChartPeriod>{
    'Sem': _ChartPeriod(
      labels: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'],
      income: [34, 42, 51, 48, 62],
      cost: [25, 29, 34, 31, 40],
    ),
    'Mes': _ChartPeriod(
      labels: ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'],
      income: [52, 68, 61, 86],
      cost: [38, 45, 43, 56],
    ),
    'Año': _ChartPeriod(
      labels: ['T1', 'T2', 'T3', 'T4'],
      income: [58, 72, 81, 92],
      cost: [44, 53, 59, 67],
    ),
  };

  String selectedPeriod = 'Mes';

  @override
  Widget build(BuildContext context) {
    final data = periods[selectedPeriod]!;
    final maxValue = data.income.fold<int>(
      0,
      (maximum, value) => math.max(maximum, value),
    );
    final margin = widget.income == 0
        ? 0
        : ((widget.income - widget.cost) / widget.income * 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DATOS EN TIEMPO REAL',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Resumen mensual',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: const [
                    ButtonSegment(value: 'Sem', label: Text('Sem')),
                    ButtonSegment(value: 'Mes', label: Text('Mes')),
                    ButtonSegment(value: 'Año', label: Text('Año')),
                  ],
                  selected: {selectedPeriod},
                  onSelectionChanged: (selection) {
                    setState(() => selectedPeriod = selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                _ChartLegend(color: AppColors.green, label: 'Ingresos'),
                SizedBox(width: 16),
                _ChartLegend(color: AppColors.earth, label: 'Gastos'),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 116,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < data.labels.length; index++)
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _ComparisonBar(
                                  value: data.income[index],
                                  maxValue: maxValue,
                                  color: AppColors.green,
                                ),
                                _ComparisonBar(
                                  value: data.cost[index],
                                  maxValue: maxValue,
                                  color: AppColors.earth,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                _SummaryMetric(
                    label: 'INGRESOS', value: money.format(widget.income)),
                _SummaryMetric(
                    label: 'GASTOS', value: money.format(widget.cost)),
                _SummaryMetric(
                    label: 'MARGEN', value: '${margin.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPeriod {
  const _ChartPeriod({
    required this.labels,
    required this.income,
    required this.cost,
  });

  final List<String> labels;
  final List<int> income;
  final List<int> cost;
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 12,
          height: 84 * value / maxValue,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: Theme.of(context).textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 66) / 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class CaptureHomeScreen extends StatelessWidget {
  const CaptureHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final options = [
      ('Actividad', Icons.agriculture_rounded, 'activity'),
      ('Gasto', Icons.receipt_long_rounded, 'expense'),
      ('Cosecha', Icons.inventory_2_rounded, 'harvest'),
      ('Merma', Icons.compost_rounded, 'loss'),
      if (store.role == UserRole.admin)
        ('Nuevo ciclo', Icons.add_business_rounded, 'cycle'),
    ];
    return AppShell(
      title: store.role == UserRole.capturista
          ? 'Hola, ${store.currentUser.name.split(' ').first}'
          : 'Captura rápida',
      current: 'capture',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/form/activity'),
        icon: const AppGlyph(AppGlyphType.add, color: Colors.white),
        label: const Text('Nuevo registro'),
      ),
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () =>
            Future<void>.delayed(const Duration(milliseconds: 450)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoBanner(
                text:
                    'Registra lo que ocurrió hoy. Los datos se guardan en la bitácora del ciclo.',
                tone: AppColors.green,
                icon: Icons.touch_app_rounded,
              ),
              const SizedBox(height: 24),
              const SectionTitle('¿Qué quieres registrar?'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.22,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final option in options)
                    Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => context.push('/form/${option.$3}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconBox(option.$2),
                              const Spacer(),
                              Text(option.$1,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 2),
                              const Text('Nuevo registro'),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionTitle('Mis ciclos abiertos'),
              const SizedBox(height: 12),
              for (final cycle in store.cycles.where(
                (item) =>
                    item.status == CycleStatus.activo ||
                    item.status == CycleStatus.suspendido,
              )) ...[
                CycleCard(cycle: cycle, hideMoney: true),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              const SectionTitle('Últimos registros'),
              const SizedBox(height: 12),
              Text(
                'Edita rápidamente cualquier captura reciente sin salir de esta pantalla.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RecordCount(
                    icon: Icons.inventory_2_rounded,
                    label: 'cosechas',
                    count: store.records
                        .where((item) => item.kind == 'Cosecha')
                        .length,
                  ),
                  _RecordCount(
                    icon: Icons.receipt_long_rounded,
                    label: 'gastos',
                    count: store.records
                        .where((item) => item.kind == 'Gasto')
                        .length,
                  ),
                  _RecordCount(
                    icon: Icons.agriculture_rounded,
                    label: 'actividades',
                    count: store.records
                        .where((item) => item.kind == 'Actividad')
                        .length,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _RecordsChart(records: store.records),
              const SizedBox(height: 12),
              if (store.records.isEmpty)
                EmptyState(
                  title: 'Sin registros aún',
                  message: 'Toca + para crear tu primer registro',
                  actionLabel: 'Nuevo registro',
                  onAction: () => context.push('/form/activity'),
                )
              else ...[
                SizedBox(
                  height: 230,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: math.min(6, store.records.length),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final record = store.records[index];
                      return SizedBox(
                        width: 260,
                        child: _RecentRecordCard(
                          record: record,
                          onEdit: () =>
                              _editRecentRecord(context, store, record),
                          onDelete: () =>
                              _deleteRecentRecord(context, store, record),
                        ),
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/records'),
                    child: const Text('Ver todos'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordsChart extends StatelessWidget {
  const _RecordsChart({required this.records});
  final List<ActivityRecord> records;

  @override
  Widget build(BuildContext context) {
    final values = [
      (
        'Cosecha',
        AppColors.green,
        records.where((item) => item.kind == 'Cosecha').length
      ),
      (
        'Gasto',
        AppColors.earth,
        records.where((item) => item.kind == 'Gasto').length
      ),
      (
        'Actividad',
        AppColors.blue,
        records.where((item) => item.kind == 'Actividad').length
      ),
      (
        'Merma',
        AppColors.amber,
        records.where((item) => item.kind == 'Merma').length
      ),
    ];
    final maxValue = values.fold<int>(1, (max, item) => math.max(max, item.$3));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: AppGlyph(AppGlyphType.chart, color: AppColors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resumen de movimientos',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Distribución actual',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text('${records.length}',
                    style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 16),
            for (final item in values) ...[
              Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Text(item.$1,
                        style: Theme.of(context).textTheme.labelMedium),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: item.$3 / maxValue,
                        color: item.$2,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 18,
                    child: Text(
                      '${item.$3}',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              if (item != values.last) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentRecordCard extends StatelessWidget {
  const _RecentRecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final ActivityRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _recordColor(record.kind);
    final displayValue = record.value == null
        ? null
        : record.unit == 'MXN'
            ? money.format(record.value)
            : '${quantity.format(record.value)} kg';
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusPill(
                    record.kind == 'Cobro'
                        ? 'Pagado'
                        : record.kind == 'Venta'
                            ? 'Pendiente'
                            : 'Borrador',
                    color,
                    icon: Icons.circle,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('dd MMM · HH:mm', 'es_MX').format(record.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconBox(_recordIcon(record.kind), color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Text(
                          record.detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayValue ?? record.kind,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.green,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Editar registro',
                    onPressed: onEdit,
                    icon: const AppGlyph(AppGlyphType.edit, size: 19),
                  ),
                  IconButton(
                    tooltip: 'Eliminar registro',
                    color: AppColors.red,
                    onPressed: onDelete,
                    icon: const AppGlyph(AppGlyphType.delete,
                        size: 19, color: AppColors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordCount extends StatelessWidget {
  const _RecordCount({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.green),
      label: Text('$count $label'),
      side: const BorderSide(color: AppColors.border),
      backgroundColor: AppColors.section,
      visualDensity: VisualDensity.compact,
    );
  }
}

IconData _recordIcon(String kind) => switch (kind) {
      'Cosecha' => Icons.inventory_2_rounded,
      'Gasto' => Icons.receipt_long_rounded,
      'Venta' => Icons.local_shipping_rounded,
      'Cobro' => Icons.payments_rounded,
      _ => Icons.agriculture_rounded,
    };

Color _recordColor(String kind) => switch (kind) {
      'Gasto' => AppColors.earth,
      'Merma' => AppColors.amber,
      'Venta' => AppColors.blue,
      'Cobro' => AppColors.green,
      'Ciclo' => AppColors.blue,
      _ => AppColors.green,
    };

Future<void> _deleteRecentRecord(
  BuildContext context,
  AppStore store,
  ActivityRecord record,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const AppGlyph(AppGlyphType.delete, color: AppColors.red),
      title: const Text('¿Eliminar registro?'),
      content: Text(
        'Se quitará “${record.title}” y se actualizarán de inmediato la gráfica y los indicadores.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final index = store.deleteRecord(record);
  if (index < 0) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Registro eliminado. Vistas sincronizadas.'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => store.restoreRecord(record, index),
        ),
      ),
    );
}

Future<void> _editRecentRecord(
  BuildContext context,
  AppStore store,
  ActivityRecord record,
) async {
  final title = TextEditingController(text: record.title);
  final detail = TextEditingController(text: record.detail);
  final value = TextEditingController(
    text: record.value == null ? '' : record.value!.toStringAsFixed(2),
  );
  var selectedKind = record.kind;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Editar registro',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'Concepto',
                  helperText: 'Identifica el movimiento en la bitácora.',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedKind,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  helperText: 'Clasificación usada por reportes y gráficos.',
                ),
                items: [
                  'Actividad',
                  'Gasto',
                  'Cosecha',
                  'Merma',
                  'Venta',
                  'Cobro',
                  'Ciclo'
                ]
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setSheetState(() => selectedKind = value);
                  }
                },
              ),
              if (selectedKind == 'Gasto' || selectedKind == 'Cosecha') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: value,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: selectedKind == 'Gasto'
                        ? 'Monto del gasto'
                        : 'Cantidad cosechada',
                    prefixText: selectedKind == 'Gasto' ? '\$ ' : null,
                    suffixText: selectedKind == 'Cosecha' ? ' kg' : null,
                    helperText:
                        'Actualiza automáticamente los indicadores del ciclo.',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Fecha',
                  hintText:
                      DateFormat('dd/MM/yyyy', 'es_MX').format(record.date),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detail,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  helperText: 'Información adicional del registro.',
                ),
              ),
              const SizedBox(height: 12),
              const InfoBanner(
                title: 'Edición sincronizada',
                text:
                    'El cambio se reflejará en la bitácora y las vistas relacionadas en memoria.',
                tone: AppColors.blue,
                icon: Icons.sync_rounded,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      if (title.text.trim().isEmpty) return;
                      final hasMetric =
                          selectedKind == 'Gasto' || selectedKind == 'Cosecha';
                      final metric = hasMetric
                          ? double.tryParse(value.text)
                          : null;
                      if (hasMetric && (metric == null || metric <= 0)) return;
                      final syncedDetail = selectedKind == 'Gasto'
                          ? detail.text.replaceFirst(
                              RegExp(r'\$[0-9,.]+'),
                              moneyExact.format(metric),
                            )
                          : selectedKind == 'Cosecha'
                              ? detail.text.replaceFirst(
                                  RegExp(
                                    r'[0-9,.]+\s*(?:kg|ton|caja(?:\s+18\s+kg)?)',
                                    caseSensitive: false,
                                  ),
                                  '${quantity.format(metric)} kg',
                                )
                              : detail.text;
                      store.editRecord(
                        record,
                        title.text.trim(),
                        syncedDetail.trim(),
                        kind: selectedKind,
                        value: metric,
                      );
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    ),
  );
  title.dispose();
  detail.dispose();
  value.dispose();
}

class CycleCard extends StatelessWidget {
  const CycleCard({required this.cycle, this.hideMoney = false, super.key});

  final FarmCycle cycle;
  final bool hideMoney;

  @override
  Widget build(BuildContext context) {
    final status = cycleStatusStyle(cycle.status);
    return Hero(
      tag: 'cycle-${cycle.id}',
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/cycles/${cycle.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const IconBox(Icons.grass_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cycle.crop,
                              style: Theme.of(context).textTheme.titleMedium),
                          Text('${cycle.parcel} · ${cycle.area} ha'),
                        ],
                      ),
                    ),
                    StatusPill(status.label, status.color, icon: status.icon),
                  ],
                ),
                const SizedBox(height: 16),
                MiniBar(
                  label: 'Meta de producción',
                  value:
                      '${quantity.format(cycle.harvestedKg)} / ${quantity.format(cycle.goalKg)} kg',
                  progress: cycle.harvestedKg / cycle.goalKg,
                ),
                if (!hideMoney) ...[
                  const Divider(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: cycle.profit >= 0 ? 'Ganancia' : 'Pérdida',
                          value: money.format(cycle.profit),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CyclesScreen extends StatefulWidget {
  const CyclesScreen({super.key});

  @override
  State<CyclesScreen> createState() => _CyclesScreenState();
}

class _CyclesScreenState extends State<CyclesScreen> {
  String filter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final visible = filter == 'Todos'
        ? store.cycles
        : store.cycles.where((cycle) {
            return cycleStatusStyle(cycle.status).label ==
                filter.replaceAll('s', '');
          }).toList();
    return AppShell(
      title: store.role == UserRole.capturista ? 'Mis ciclos' : 'Ciclos',
      current: 'cycles',
      floatingActionButton: store.role == UserRole.capturista
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/form/cycle'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo ciclo'),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final label in [
                  'Todos',
                  'Activos',
                  'Planificados',
                  'Finalizados',
                  'Cerrados'
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: FilterChip(
                        label: Text(label),
                        selected: filter == label,
                        onSelected: (_) => setState(() => filter = label),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (visible.isEmpty)
            EmptyState(
              title: 'No hay ciclos aquí',
              message:
                  'Prueba otro filtro o crea un ciclo para comenzar a registrar.',
              actionLabel: 'Quitar filtro',
              onAction: () => setState(() => filter = 'Todos'),
            )
          else
            for (final cycle in visible) ...[
              CycleCard(
                  cycle: cycle, hideMoney: store.role == UserRole.capturista),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class CycleDetailScreen extends StatelessWidget {
  const CycleDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final cycle = store.cycle(id);
    final status = cycleStatusStyle(cycle.status);
    final canSeeMoney = store.role != UserRole.capturista;
    return DefaultTabController(
      length: canSeeMoney ? 4 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cycle.crop),
              Text(
                cycle.parcel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              const Tab(text: 'Resumen'),
              const Tab(text: 'Campo'),
              if (canSeeMoney) const Tab(text: 'Dinero'),
              const Tab(text: 'Historial'),
            ],
          ),
          actions: [
            if (store.role == UserRole.admin &&
                cycle.status != CycleStatus.cerrado &&
                cycle.status != CycleStatus.planificado)
              IconButton(
                tooltip: 'Cerrar ciclo',
                onPressed: () => context.push('/form/close?cycle=${cycle.id}'),
                icon: const Icon(Icons.lock_outline_rounded),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child:
                    StatusPill(status.label, status.color, icon: status.icon),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _CycleSummary(cycle: cycle),
            _CycleField(cycle: cycle),
            if (canSeeMoney) _CycleMoney(cycle: cycle),
            _CycleHistory(cycle: cycle),
          ],
        ),
      ),
    );
  }
}

class _CycleSummary extends StatelessWidget {
  const _CycleSummary({required this.cycle});

  final FarmCycle cycle;

  @override
  Widget build(BuildContext context) {
    final progress = (cycle.harvestedKg / cycle.goalKg).clamp(0, 1).toDouble();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeroCard(
          eyebrow: 'Resultado del ciclo',
          value: money.format(cycle.profit),
          subtitle: cycle.income == 0
              ? 'Aún sin ingresos registrados'
              : 'Margen ${(cycle.margin * 100).toStringAsFixed(2)}% · ROI ${(cycle.roi * 100).toStringAsFixed(2)}%',
          trailing: SizedBox(
            width: 66,
            height: 66,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: Colors.white24,
                  color: AppColors.lime,
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Producción acumulada'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 150,
              child: CustomPaint(
                size: Size.infinite,
                painter: ProductionPainter(progress: progress),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Ingreso contra costo'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                MiniBar(
                  label: 'Ingreso',
                  value: money.format(cycle.income),
                  progress: cycle.income / math.max(cycle.income, cycle.cost),
                ),
                const SizedBox(height: 16),
                MiniBar(
                  label: 'Costo',
                  value: money.format(cycle.cost),
                  progress: cycle.cost / math.max(cycle.income, cycle.cost),
                  color: AppColors.earth,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Costo por categoría'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                MiniBar(
                    label: 'Insumos',
                    value: money.format(cycle.cost * .42),
                    progress: .42),
                const SizedBox(height: 16),
                MiniBar(
                  label: 'Mano de obra',
                  value: money.format(cycle.cost * .31),
                  progress: .31,
                  color: AppColors.blue,
                ),
                const SizedBox(height: 16),
                MiniBar(
                  label: 'Maquinaria',
                  value: money.format(cycle.cost * .18),
                  progress: .18,
                  color: AppColors.amber,
                ),
                const SizedBox(height: 16),
                MiniBar(
                  label: 'Otros',
                  value: money.format(cycle.cost * .09),
                  progress: .09,
                  color: AppColors.tertiaryInk,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const InfoBanner(
          title: 'Contra el ciclo anterior',
          text: 'El rendimiento subió 8.4% y el costo por kg bajó \$1.20.',
          tone: AppColors.green,
          icon: Icons.compare_arrows_rounded,
        ),
        const SizedBox(height: 20),
        const SectionTitle('Ficha del ciclo'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const IconBox(Icons.square_foot_rounded),
                title: const Text('Superficie'),
                trailing: Text('${cycle.area} ha'),
              ),
              ListTile(
                leading: const IconBox(Icons.scale_rounded),
                title: const Text('Cosechado'),
                trailing: Text('${quantity.format(cycle.harvestedKg)} kg'),
              ),
              ListTile(
                leading: const IconBox(Icons.payments_rounded),
                title: const Text('Costo por kg'),
                trailing: Text(moneyExact.format(cycle.costPerKg)),
              ),
              ListTile(
                leading: const IconBox(Icons.sell_rounded),
                title: const Text('Precio promedio'),
                trailing: Text(moneyExact.format(cycle.pricePerKg)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class ProductionPainter extends CustomPainter {
  ProductionPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final target = Paint()
      ..color = AppColors.amber
      ..strokeWidth = 2;
    final line = Paint()
      ..color = AppColors.green
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (double x = 0; x < size.width; x += 12) {
      canvas.drawLine(
        Offset(x, size.height * .18),
        Offset(math.min(x + 6, size.width), size.height * .18),
        target,
      );
    }
    final path = Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * .25,
        size.height * .86,
        size.width * .28,
        size.height * .54,
        size.width * .5,
        size.height * .56,
      )
      ..cubicTo(
        size.width * .72,
        size.height * .57,
        size.width * .72,
        size.height * .28,
        size.width,
        size.height * (1 - progress),
      );
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant ProductionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CycleField extends StatelessWidget {
  const _CycleField({required this.cycle});

  final FarmCycle cycle;

  @override
  Widget build(BuildContext context) {
    final locked = cycle.status == CycleStatus.finalizado ||
        cycle.status == CycleStatus.cerrado;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (locked)
          const InfoBanner(
            title: 'Captura bloqueada',
            text:
                'Este ciclo está finalizado. Los cobros pendientes siguen disponibles.',
            tone: AppColors.amber,
            icon: Icons.lock_rounded,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.agriculture_rounded, size: 18),
                label: const Text('Actividad'),
                onPressed: () =>
                    context.push('/form/activity?cycle=${cycle.id}'),
              ),
              ActionChip(
                avatar: const Icon(Icons.inventory_2_rounded, size: 18),
                label: const Text('Cosecha'),
                onPressed: () =>
                    context.push('/form/harvest?cycle=${cycle.id}'),
              ),
              ActionChip(
                avatar: const Icon(Icons.compost_rounded, size: 18),
                label: const Text('Merma'),
                onPressed: () => context.push('/form/loss?cycle=${cycle.id}'),
              ),
            ],
          ),
        const SizedBox(height: 20),
        const SectionTitle('Movimientos de campo'),
        const SizedBox(height: 12),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: PlainLeadingIcon(Icons.inventory_2_rounded),
                title: Text('Cosecha · 1,250 kg'),
                subtitle: Text('12 jun · Calidad Primera'),
                trailing: StatusPill('Primera', AppColors.green,
                    icon: Icons.grade_rounded),
              ),
              Divider(height: 1, indent: 68),
              ListTile(
                leading: PlainLeadingIcon(Icons.agriculture_rounded),
                title: Text('Aplicación foliar'),
                subtitle: Text('11 jun · Desarrollo'),
                trailing: StatusPill('Hecha', AppColors.blue,
                    icon: Icons.check_rounded),
              ),
              Divider(height: 1, indent: 68),
              ListTile(
                leading: PlainLeadingIcon(Icons.compost_rounded,
                    color: AppColors.earth),
                title: Text('Merma poscosecha · 85 kg'),
                subtitle: Text('10 jun · Daño mecánico'),
                trailing: StatusPill('Merma', AppColors.earth,
                    icon: Icons.remove_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CycleMoney extends StatelessWidget {
  const _CycleMoney({required this.cycle});

  final FarmCycle cycle;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppStore>().role;
    if (role == UserRole.capturista) {
      return const EmptyState(
        title: 'Acceso restringido',
        message:
            'Tu rol registra campo, pero no puede consultar costos, ventas ni cobros.',
        actionLabel: 'Entendido',
        onAction: _noop,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Costo',
                value: money.format(cycle.cost),
                icon: Icons.payments_rounded,
                color: AppColors.earth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: 'Ingreso',
                value: money.format(cycle.income),
                icon: Icons.savings_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/form/expense?cycle=${cycle.id}'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Gasto'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.push('/form/sale?cycle=${cycle.id}'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Venta'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Últimos movimientos'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const PlainLeadingIcon(Icons.receipt_long_rounded,
                    color: AppColors.earth),
                title: const Text('Fertilizante foliar'),
                subtitle: const Text('Agroinsumos Oaxaca · 11 jun'),
                trailing: Text(money.format(8450)),
              ),
              const Divider(height: 1, indent: 68),
              ListTile(
                leading: const PlainLeadingIcon(Icons.local_shipping_rounded),
                title: const Text('Venta V-1042'),
                subtitle: const Text('Central de Abastos · 4,200 kg'),
                trailing: Text(money.format(62000)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _noop() {}

class _CycleHistory extends StatelessWidget {
  const _CycleHistory({required this.cycle});

  final FarmCycle cycle;

  @override
  Widget build(BuildContext context) {
    final records = context.watch<AppStore>().records;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  PlainLeadingIcon(
                    _recordIcon(record.kind),
                    color: _recordColor(record.kind),
                  ),
                  if (index < records.length - 1)
                    const Expanded(
                        child: VerticalDivider(width: 40, thickness: 2)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(record.detail),
                      const SizedBox(height: 4),
                      Text(shortDate.format(record.date),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<AppStore>().sales;
    return AppShell(
      title: 'Ventas',
      current: 'sales',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/form/sale'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva venta'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          const InfoBanner(
            text:
                'El estado de cobro se calcula automáticamente con los cobros y la fecha de vencimiento.',
            tone: AppColors.blue,
          ),
          const SizedBox(height: 16),
          for (final sale in sales.where((item) => !item.cancelled)) ...[
            SaleCard(sale: sale),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class SaleCard extends StatelessWidget {
  const SaleCard({required this.sale, super.key});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final style = paymentStatusStyle(sale.status);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/sales/${sale.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const IconBox(Icons.local_shipping_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sale.client,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('${sale.id} · ${quantity.format(sale.kg)} kg'),
                      ],
                    ),
                  ),
                  StatusPill(style.label, style.color, icon: Icons.circle),
                ],
              ),
              const Divider(height: 28),
              Row(
                children: [
                  Expanded(
                      child: _Metric(
                          label: 'Total', value: money.format(sale.total))),
                  Expanded(
                    child: _Metric(
                      label: 'Saldo',
                      value: money.format(sale.total - sale.paid),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SaleDetailScreen extends StatelessWidget {
  const SaleDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final sale = store.sales.firstWhere((item) => item.id == id);
    final style = paymentStatusStyle(sale.status);
    return Scaffold(
      appBar: AppBar(
        title: Text('Venta ${sale.id}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: StatusPill(style.label, style.color)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeroCard(
            eyebrow: 'Total de la venta',
            value: money.format(sale.total),
            subtitle: '${quantity.format(sale.kg)} kg · ${sale.client}',
          ),
          const SizedBox(height: 20),
          const SectionTitle('Renglones'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Calidad Primera'),
                  subtitle:
                      Text('${quantity.format(sale.kg * .75)} kg × \$15.20'),
                  trailing: Text(money.format(sale.total * .78)),
                ),
                ListTile(
                  title: const Text('Calidad Segunda'),
                  subtitle:
                      Text('${quantity.format(sale.kg * .25)} kg × \$12.80'),
                  trailing: Text(money.format(sale.total * .22)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Cobros'),
          const SizedBox(height: 12),
          if (sale.paid > 0)
            Card(
              child: ListTile(
                leading: const IconBox(Icons.payments_rounded),
                title: Text(money.format(sale.paid)),
                subtitle:
                    Text('Transferencia · ${shortDate.format(DateTime.now())}'),
                trailing: const StatusPill('Aplicado', AppColors.green,
                    icon: Icons.check_rounded),
              ),
            )
          else
            const InfoBanner(
              title: 'Sin cobros',
              text:
                  'Registra un cobro para actualizar el saldo y el estado automáticamente.',
              tone: AppColors.amber,
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: sale.paid >= sale.total
                ? null
                : () => context.push('/form/payment?sale=${sale.id}'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Registrar cobro'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: sale.cancelled
                ? null
                : () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Cancelar venta'),
                        content: const Text(
                          'La venta se conservará en la auditoría y los kg volverán a estar disponibles.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Volver'),
                          ),
                          FilledButton(
                            onPressed: () {
                              store.cancelSale(sale);
                              Navigator.pop(dialogContext);
                              context.pop();
                            },
                            child: const Text('Cancelar venta'),
                          ),
                        ],
                      ),
                    ),
            icon: const Icon(Icons.block_rounded, color: AppColors.red),
            label: const Text('Cancelar venta',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final records = context.watch<AppStore>().records;
    return AppShell(
      title: 'Mi bitácora',
      current: 'records',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          const InfoBanner(
            text:
                'Aquí aparecen tus capturas recientes. Los importes no se muestran para tu rol.',
            tone: AppColors.green,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                for (final record in records)
                  ListTile(
                    leading: IconBox(_recordIcon(record.kind)),
                    title: Text(record.title),
                    subtitle: Text(
                      record.kind == 'Gasto'
                          ? '${record.detail.split('·').first} · Importe restringido'
                          : record.detail,
                    ),
                    trailing: Text(
                      DateFormat('dd MMM', 'es_MX').format(record.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppStore>().role;
    final roleLabel = switch (role) {
      UserRole.admin => 'Administrador',
      UserRole.capturista => 'Capturista',
      UserRole.contador => 'Contador',
    };
    final groups = <String, List<(String, IconData, String)>>{
      if (role != UserRole.capturista)
        'FINANZAS': [
          (
            'Cuentas por cobrar',
            Icons.receipt_long_outlined,
            'cuentas-por-cobrar'
          ),
          ('Gastos', Icons.payments_outlined, 'gastos'),
          ('Reportes', Icons.assessment_outlined, 'reportes'),
          ('Comparativo', Icons.compare_arrows_outlined, 'comparativo'),
        ],
      'OPERACIÓN': [
        ('Predios y parcelas', Icons.map_outlined, 'predios'),
        if (role != UserRole.capturista)
          ('Proveedores', Icons.local_shipping_outlined, 'proveedores'),
        if (role != UserRole.capturista)
          ('Clientes', Icons.people_outline, 'clientes'),
        ('Categorías de gasto', Icons.category_outlined, 'categorias'),
        if (role != UserRole.capturista)
          ('Alertas', Icons.notifications_active_outlined, 'alertas'),
      ],
      if (role == UserRole.admin)
        'ADMINISTRACIÓN': [
          (
            'Usuarios y permisos',
            Icons.admin_panel_settings_outlined,
            'usuarios'
          ),
          ('Mi empresa', Icons.business_outlined, 'empresa'),
          ('Bitácora de auditoría', Icons.fact_check_outlined, 'auditoria'),
        ],
      'CUENTA': [
        ('Perfil', Icons.account_circle_outlined, 'perfil'),
        ('Ayuda', Icons.help_outline_rounded, 'ayuda'),
      ],
    };
    return AppShell(
      title: 'Más',
      current: 'more',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rancho Los Pinos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Plan Crecimiento · $roleLabel',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const StatusPill('ACTIVA', AppColors.lime,
                    icon: Icons.verified_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (final group in groups.entries) ...[
            Text(group.key, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final item in group.value)
                    ListTile(
                      leading: SizedBox(
                        width: 40,
                        child: Icon(
                          item.$2,
                          size: 28,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                      title: Text(item.$1),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/module/${item.$3}'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class ModuleScreen extends StatelessWidget {
  const ModuleScreen({required this.slug, super.key});

  final String slug;

  static const titles = {
    'cuentas-por-cobrar': 'Cuentas por cobrar',
    'gastos': 'Gastos',
    'reportes': 'Reportes',
    'comparativo': 'Comparativo',
    'predios': 'Predios y parcelas',
    'proveedores': 'Proveedores',
    'clientes': 'Clientes',
    'categorias': 'Categorías de gasto',
    'alertas': 'Alertas',
    'usuarios': 'Usuarios y permisos',
    'empresa': 'Mi empresa',
    'auditoria': 'Bitácora de auditoría',
    'perfil': 'Perfil',
    'ayuda': 'Ayuda',
  };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    if (!store.canAccess(slug)) {
      return Scaffold(
        appBar: AppBar(title: Text(titles[slug] ?? 'Módulo')),
        body: EmptyState(
          title: 'Acceso restringido',
          message: 'Tu rol no puede consultar este módulo ni sus datos.',
          actionLabel: 'Volver',
          onAction: () => context.pop(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(titles[slug] ?? 'Módulo')),
      body: _moduleBody(context),
    );
  }

  Widget _moduleBody(BuildContext context) {
    return switch (slug) {
      'cuentas-por-cobrar' => const _ReceivablesModule(),
      'gastos' => const _ExpensesModule(),
      'predios' => const _PropertiesModule(),
      'clientes' => const _ClientsModule(),
      'usuarios' => const _UsersModule(),
      'auditoria' => const _AuditModule(),
      'alertas' => const _AlertsModule(),
      'comparativo' => const _ComparisonModule(),
      'categorias' => const _CategoriesModule(),
      'proveedores' => const _SuppliersModule(),
      'reportes' => const _ReportsModule(),
      'empresa' => const _CompanyModule(),
      'perfil' => const _ProfileModule(),
      'ayuda' => const _HelpModule(),
      _ => const EmptyState(
          title: 'Módulo sin datos',
          message: 'Agrega el primer registro para comenzar.',
          actionLabel: 'Agregar',
          onAction: _noop,
        ),
    };
  }
}

class _ReceivablesModule extends StatefulWidget {
  const _ReceivablesModule();

  @override
  State<_ReceivablesModule> createState() => _ReceivablesModuleState();
}

class _ReceivablesModuleState extends State<_ReceivablesModule> {
  PaymentStatus? filter;

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<AppStore>().sales.where((sale) =>
        sale.paid < sale.total && (filter == null || sale.status == filter));
    final total =
        sales.fold<double>(0, (sum, sale) => sum + sale.total - sale.paid);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeroCard(
          eyebrow: 'Saldo por cobrar',
          value: money.format(total),
          subtitle: '${sales.length} ventas con saldo',
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in <(String, PaymentStatus?)>[
                ('Todas', null),
                ('Pendiente', PaymentStatus.pendiente),
                ('Parcial', PaymentStatus.parcial),
                ('Vencida', PaymentStatus.vencida),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: filter == option.$2,
                    label: Text(option.$1),
                    onSelected: (_) => setState(() => filter = option.$2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (sales.isEmpty)
          EmptyState(
            title: 'Sin cuentas en este filtro',
            message: 'Prueba otro estado de cobro para ver resultados.',
            actionLabel: 'Ver todas',
            onAction: () => setState(() => filter = null),
          ),
        for (final sale in sales) ...[
          SaleCard(sale: sale),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => context.push('/form/payment?sale=${sale.id}'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Registrar cobro · F-13'),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ExpensesModule extends StatelessWidget {
  const _ExpensesModule();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const InfoBanner(
          text: 'Junio acumula \$31,450 en gastos operativos.',
          tone: AppColors.earth,
          icon: Icons.receipt_long_rounded,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const IconBox(Icons.science_rounded),
                title: const Text('Fertilizante foliar'),
                subtitle: const Text('Agroinsumos Oaxaca · 11 jun'),
                trailing: Text(money.format(8450)),
              ),
              ListTile(
                leading: const IconBox(Icons.engineering_rounded),
                title: const Text('Jornal de cosecha'),
                subtitle: const Text('Mano de obra · 10 jun'),
                trailing: Text(money.format(12000)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PropertiesModule extends StatelessWidget {
  const _PropertiesModule();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final canEdit = store.role == UserRole.admin;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoBanner(
          title:
              canEdit ? 'Administración habilitada' : 'Vista de solo lectura',
          text: canEdit
              ? 'Crea predios y parcelas sin superar la superficie disponible.'
              : 'Tu rol puede consultar la estructura, pero no modificarla.',
          tone: AppColors.green,
          icon: Icons.map_rounded,
        ),
        const SizedBox(height: 16),
        if (store.properties.isEmpty)
          EmptyState(
            title: 'Aún no hay predios',
            message: 'Crea el primer predio para organizar sus parcelas.',
            actionLabel: canEdit ? 'Crear predio' : 'Entendido',
            onAction: canEdit
                ? () => context.push('/catalog-form/property')
                : () => context.pop(),
          ),
        for (final property in store.properties) ...[
          SectionTitle(
            property.name,
            action: canEdit
                ? TextButton(
                    onPressed: () => context.push('/catalog-form/property'),
                    child: const Text('+ Predio'),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  MiniBar(
                    label: 'Superficie ocupada',
                    value:
                        '${property.occupiedArea.toStringAsFixed(1)} / ${property.area.toStringAsFixed(1)} ha',
                    progress: property.occupiedArea / property.area,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${property.location} · ${property.availableArea.toStringAsFixed(1)} ha disponibles',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final parcel in property.parcels)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const IconBox(Icons.landscape_rounded),
                      title: Text(parcel.name),
                      subtitle: Text(
                        '${parcel.area.toStringAsFixed(1)} ha · ${parcel.soil}',
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/catalog-form/parcel'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar parcela · F-04'),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _ClientsModule extends StatelessWidget {
  const _ClientsModule();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(painter: DonutPainter()),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FACTURACIÓN POR CANAL'),
                      SizedBox(height: 10),
                      Text('● 52% Mayoreo'),
                      Text('● 31% Restaurantes'),
                      Text('● 17% Mercado local'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (store.clients.isEmpty)
          EmptyState(
            title: 'Aún no hay clientes',
            message: 'Agrega un comprador para registrar ventas y canales.',
            actionLabel: 'Agregar cliente',
            onAction: () => context.push('/catalog-form/client'),
          )
        else
          Card(
            child: Column(
              children: [
                for (final client in store.clients)
                  ListTile(
                    leading: IconBox(
                      Icons.handshake_rounded,
                      color: client.active
                          ? AppColors.green
                          : AppColors.tertiaryInk,
                    ),
                    title: Text(client.name),
                    subtitle: Text(
                      'ID ${client.id} · Empresa ${client.companyId}\n'
                      '${client.rfc.isEmpty ? 'Sin RFC' : client.rfc} · ${client.kind}\n'
                      '${client.phone.isEmpty ? 'Sin teléfono' : client.phone} · '
                      '${client.email.isEmpty ? 'Sin correo' : client.email}',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Acciones del cliente',
                      onSelected: (value) {
                        if (value == 'toggle') store.togglePartner(client);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              client.active
                                  ? Icons.person_off_rounded
                                  : Icons.person_add_alt_1_rounded,
                            ),
                            title: Text(
                                client.active ? 'Desactivar' : 'Reactivar'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push('/catalog-form/client'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Agregar cliente'),
        ),
      ],
    );
  }
}

class DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;
    paint.color = AppColors.green;
    canvas.drawArc(
        rect.deflate(10), -.5 * math.pi, 1.04 * math.pi, false, paint);
    paint.color = AppColors.lime;
    canvas.drawArc(
        rect.deflate(10), .54 * math.pi, .62 * math.pi, false, paint);
    paint.color = AppColors.blue;
    canvas.drawArc(
        rect.deflate(10), 1.16 * math.pi, .34 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UsersModule extends StatelessWidget {
  const _UsersModule();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoBanner(
          title: '${store.users.length} de 5 usuarios',
          text:
              'Tu plan permite agregar ${5 - store.users.length} personas más.',
          tone: AppColors.green,
          icon: Icons.group_add_rounded,
        ),
        const SizedBox(height: 12),
        MiniBar(
          label: 'Uso del plan',
          value: '${(store.users.length / 5 * 100).round()}%',
          progress: store.users.length / 5,
        ),
        const SizedBox(height: 20),
        if (store.users.isEmpty)
          EmptyState(
            title: 'Aún no hay usuarios',
            message: 'Agrega una persona y asigna uno de los roles del MVP.',
            actionLabel: 'Agregar usuario',
            onAction: () => context.push('/catalog-form/user'),
          ),
        for (final user in store.users) ...[
          _UserCard(
            user: user,
            permissions: switch (user.role) {
              UserRole.admin => '19 permisos · Control total',
              UserRole.capturista => 'Actividad · Gasto · Cosecha · Merma',
              UserRole.contador => 'Finanzas · Ventas · Cobros · Reportes',
            },
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: store.users.length >= 5
              ? null
              : () => context.push('/catalog-form/user'),
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Agregar usuario · F-02'),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Catálogo de 19 permisos'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final permission in AppStore.permissions)
              StatusPill(permission, AppColors.green,
                  icon: Icons.check_rounded),
          ],
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.permissions,
  });

  final AppUser user;
  final String permissions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: IconBox(
          Icons.badge_rounded,
          color: user.active ? AppColors.green : AppColors.tertiaryInk,
        ),
        title: Text(user.name),
        subtitle: Text(permissions),
        trailing: PopupMenuButton<String>(
          tooltip: 'Acciones del usuario',
          onSelected: (value) {
            if (value == 'toggle') context.read<AppStore>().toggleUser(user);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: user != context.read<AppStore>().currentUser,
              value: 'toggle',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(user.active
                    ? Icons.block_rounded
                    : Icons.check_circle_rounded),
                title: Text(user.active ? 'Desactivar' : 'Reactivar'),
              ),
            ),
          ],
          child: StatusPill(
            user.active ? user.role.name.toUpperCase() : 'INACTIVO',
            user.active ? AppColors.green : AppColors.tertiaryInk,
            icon: user.active
                ? Icons.verified_user_rounded
                : Icons.person_off_rounded,
          ),
        ),
      ),
    );
  }
}

class _AuditModule extends StatelessWidget {
  const _AuditModule();

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<AppStore>().auditEntries;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const InfoBanner(
          text:
              'La auditoría conserva modificaciones y cancelaciones; ningún movimiento se borra.',
          tone: AppColors.blue,
        ),
        const SizedBox(height: 16),
        for (final entry in entries) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${shortDate.format(entry.date)} · ${entry.detail} · IP ${entry.ip}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (entry.before != null) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ANTERIOR\n${entry.before}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.red,
                                ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded),
                        Expanded(
                          child: Text(
                            'NUEVO\n${entry.after}',
                            textAlign: TextAlign.end,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.green,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AlertsModule extends StatefulWidget {
  const _AlertsModule();

  @override
  State<_AlertsModule> createState() => _AlertsModuleState();
}

class _AlertsModuleState extends State<_AlertsModule> {
  String filter = 'Todas';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final alerts = store.alerts;
    final visible = filter == 'Todas'
        ? alerts
        : alerts.where((alert) => alert.severity == filter).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final value in [
                'Todas',
                'Alta',
                'Media',
                'Baja',
                'Informativa'
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: filter == value,
                    label: Text(value),
                    onSelected: (_) => setState(() => filter = value),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          EmptyState(
            title: 'Sin alertas',
            message: 'No hay alertas para esta severidad.',
            actionLabel: 'Ver todas',
            onAction: () => setState(() => filter = 'Todas'),
          )
        else
          for (final alert in visible) ...[
            Dismissible(
              key: ObjectKey(alert),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.red, size: 28),
              ),
              onDismissed: (_) {
                final index = store.deleteAlert(alert);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('${alert.title} eliminada'),
                      action: SnackBarAction(
                        label: 'Deshacer',
                        onPressed: () => store.restoreAlert(alert, index),
                      ),
                    ),
                  );
              },
              child: InfoBanner(
                title: '${alert.title} · ${alert.severity}',
                text: alert.detail,
                tone: alert.severity == 'Alta'
                    ? AppColors.red
                    : alert.severity == 'Media'
                        ? AppColors.amber
                        : AppColors.blue,
                icon: Icons.warning_rounded,
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _ComparisonModule extends StatelessWidget {
  const _ComparisonModule();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        InfoBanner(
          text: 'Compara rendimiento económico y productivo entre ciclos.',
          tone: AppColors.green,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: StatusPill('Tomate · P3', AppColors.green,
                    icon: Icons.eco_rounded)),
            SizedBox(width: 8),
            Expanded(
                child: StatusPill('Chile · P1', AppColors.amber,
                    icon: Icons.eco_rounded)),
          ],
        ),
        SizedBox(height: 20),
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                MiniBar(
                    label: 'Margen · Tomate', value: '28.93%', progress: .78),
                SizedBox(height: 16),
                MiniBar(
                  label: 'Margen · Chile',
                  value: '-35.06%',
                  progress: .18,
                  color: AppColors.red,
                ),
                Divider(height: 32),
                _ComparisonRow(
                    label: 'Costo / kg', left: '\$10.49', right: '\$12.68'),
                _ComparisonRow(
                    label: 'Rendimiento / ha',
                    left: '3,280 kg',
                    right: '2,278 kg'),
                _ComparisonRow(label: 'ROI', left: '40.70%', right: '-25.96%'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.left,
    required this.right,
  });
  final String label;
  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: Text(
              left,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.green, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              right,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  color: AppColors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesModule extends StatelessWidget {
  const _CategoriesModule();

  @override
  Widget build(BuildContext context) {
    final canEdit = context.watch<AppStore>().role == UserRole.admin;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoBanner(
          title:
              canEdit ? 'Administración habilitada' : 'Vista de solo lectura',
          text: 'Las categorías del sistema no se pueden eliminar.',
          tone: AppColors.blue,
          icon: Icons.account_tree_rounded,
        ),
        const SizedBox(height: 16),
        const _CategoryCard(
          title: 'Insumos',
          children: ['Semillas', 'Fertilizantes', 'Agroquímicos'],
        ),
        const SizedBox(height: 12),
        const _CategoryCard(
          title: 'Mano de obra',
          children: ['Jornales', 'Cosecha', 'Supervisión'],
        ),
        const SizedBox(height: 12),
        const _CategoryCard(
          title: 'Maquinaria',
          children: ['Renta', 'Combustible', 'Mantenimiento'],
        ),
        if (canEdit) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Categoría personalizada guardada en el demo')),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nueva categoría personalizada'),
          ),
        ],
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.title, required this.children});

  final String title;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const IconBox(Icons.account_tree_rounded),
        title: Text(title),
        children: [
          for (final child in children)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              title: Text(child),
              trailing: const Icon(Icons.drag_handle_rounded),
            ),
        ],
      ),
    );
  }
}

class _SuppliersModule extends StatelessWidget {
  const _SuppliersModule();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final suppliers = store.suppliers;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const InfoBanner(
          title: 'Proveedores activos',
          text:
              'Consulta saldo e historial; desactivar conserva todas las compras.',
          tone: AppColors.green,
          icon: Icons.storefront_rounded,
        ),
        const SizedBox(height: 16),
        if (suppliers.isEmpty)
          EmptyState(
            title: 'Aún no hay proveedores',
            message:
                'Agrega proveedores para seleccionarlos al registrar gastos.',
            actionLabel: 'Agregar proveedor',
            onAction: () => context.push('/catalog-form/supplier'),
          )
        else
          Card(
            child: Column(
              children: [
                for (final supplier in suppliers)
                  ListTile(
                    leading: const IconBox(Icons.storefront_rounded),
                    title: Text(supplier.name),
                    subtitle: Text('${supplier.kind} · ${supplier.detail}'),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Acciones del proveedor',
                      onSelected: (value) {
                        if (value == 'toggle') store.togglePartner(supplier);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              supplier.active
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            title: Text(
                                supplier.active ? 'Desactivar' : 'Reactivar'),
                          ),
                        ),
                      ],
                      child: StatusPill(
                        supplier.active ? 'Activo' : 'Inactivo',
                        supplier.active
                            ? AppColors.green
                            : AppColors.tertiaryInk,
                        icon: supplier.active
                            ? Icons.verified_rounded
                            : Icons.pause_circle_rounded,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.push('/catalog-form/supplier'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Agregar proveedor'),
        ),
      ],
    );
  }
}

class _ReportsModule extends StatefulWidget {
  const _ReportsModule();

  @override
  State<_ReportsModule> createState() => _ReportsModuleState();
}

class _ReportsModuleState extends State<_ReportsModule> {
  String selectedPeriod = 'Este ciclo';
  String selectedCycle = 'Todos';

  @override
  Widget build(BuildContext context) {
    void simulateExport(String title) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('$title listo para exportar · simulación sin archivo real'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedPeriod,
                decoration: const InputDecoration(labelText: 'Periodo'),
                items: const [
                  DropdownMenuItem(
                      value: 'Este ciclo', child: Text('Este ciclo')),
                  DropdownMenuItem(
                      value: '12 meses', child: Text('Últimos 12 meses')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => selectedPeriod = value);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedCycle,
                decoration: const InputDecoration(labelText: 'Ciclo'),
                items: const [
                  DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'Tomate', child: Text('Tomate · P3')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => selectedCycle = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const InfoBanner(
          title: 'Exportación simulada',
          text:
              'PDF, Excel y Compartir confirman la acción sin generar archivos reales.',
          tone: AppColors.blue,
          icon: Icons.ios_share_rounded,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              for (final report in const [
                'Rentabilidad por ciclo',
                'Costos por categoría',
                'Producción y mermas',
              ])
                ListTile(
                  leading: const IconBox(Icons.assessment_rounded),
                  title: Text(report),
                  subtitle: const Text('PDF · Excel · Compartir'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => simulateExport(report),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompanyModule extends StatelessWidget {
  const _CompanyModule();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        HeroCard(
          eyebrow: 'Suscripción activa',
          value: 'Plan Crecimiento',
          subtitle: 'Renovación · 30 sep 2026',
        ),
        SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: IconBox(Icons.apartment_rounded),
                title: Text('Rancho Los Pinos'),
                subtitle: Text('Agrícola Los Pinos SPR de RL'),
              ),
              ListTile(
                leading: IconBox(Icons.badge_rounded),
                title: Text('RFC'),
                trailing: Text('RLP010203XX0'),
              ),
              ListTile(
                leading: IconBox(Icons.currency_exchange_rounded),
                title: Text('Moneda'),
                trailing: Text('MXN'),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        SectionTitle('Límites del plan'),
        SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                MiniBar(label: 'Usuarios', value: '3 / 5', progress: .6),
                SizedBox(height: 16),
                MiniBar(label: 'Parcelas', value: '4 / 10', progress: .4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileModule extends StatelessWidget {
  const _ProfileModule();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final role = store.role;
    final user = store.currentUser;
    final roleName = switch (role) {
      UserRole.admin => 'Administrador',
      UserRole.capturista => 'Capturista',
      UserRole.contador => 'Contador',
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeroCard(
          eyebrow: roleName,
          value: user.name,
          subtitle: '${user.email} · ${user.phone}',
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const IconBox(Icons.manage_accounts_rounded),
                title: const Text('Datos personales'),
                subtitle: const Text('Nombre, correo y teléfono'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _editProfile(context, store, user),
              ),
              ListTile(
                leading: const IconBox(Icons.password_rounded),
                title: const Text('Cambiar contraseña'),
                subtitle: const Text('Acción simulada en este wireframe'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _changePassword(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _editProfile(
    BuildContext context, AppStore store, AppUser user) async {
  final name = TextEditingController(text: user.name);
  final email = TextEditingController(text: user.email);
  final phone = TextEditingController(text: user.phone);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editar datos personales',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                if (name.text.trim().isEmpty || !email.text.contains('@')) {
                  return;
                }
                store.updateCurrentUser(
                  name: name.text.trim(),
                  email: email.text.trim(),
                  phone: phone.text.trim(),
                );
                Navigator.pop(sheetContext);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    ),
  );
  name.dispose();
  email.dispose();
  phone.dispose();
}

Future<void> _changePassword(BuildContext context) async {
  final current = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setModalState) {
        final valid = current.text.length >= 4 &&
            password.text.length >= 8 &&
            password.text == confirmation.text;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Cambiar contraseña',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Usa al menos 8 caracteres para proteger tu cuenta.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: current,
                  obscureText: true,
                  onChanged: (_) => setModalState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  onChanged: (_) => setModalState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                    helperText: 'Mínimo 8 caracteres.',
                    prefixIcon: Icon(Icons.password_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmation,
                  obscureText: true,
                  onChanged: (_) => setModalState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    errorText: confirmation.text.isNotEmpty &&
                            password.text != confirmation.text
                        ? 'Las contraseñas no coinciden'
                        : null,
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: valid
                          ? () {
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Contraseña actualizada')),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  current.dispose();
  password.dispose();
  confirmation.dispose();
}

class _HelpModule extends StatelessWidget {
  const _HelpModule();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const InfoBanner(
          title: '¿Cómo podemos ayudarte?',
          text: 'Consulta respuestas y guías adaptadas a tu rol.',
          tone: AppColors.green,
          icon: Icons.help_rounded,
        ),
        const SizedBox(height: 20),
        const SectionTitle('Preguntas frecuentes'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              for (final question in const [
                '¿Cómo se calcula la ganancia?',
                '¿Por qué la merma en campo no resta kg?',
                '¿Cómo registro un cobro?',
              ])
                ExpansionTile(
                  title: Text(question),
                  children: const [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'Consulta la regla de negocio y los pasos detallados dentro del manual de uso.',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Manuales por rol'),
        const SizedBox(height: 12),
        const Card(
          child: Column(
            children: [
              ListTile(
                  title: Text('Manual del Administrador'),
                  trailing: Text('PDF')),
              ListTile(
                  title: Text('Manual del Capturista'), trailing: Text('PDF')),
              ListTile(
                  title: Text('Manual del Contador'), trailing: Text('PDF')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Canal de soporte simulado')),
          ),
          icon: const Icon(Icons.support_agent_rounded),
          label: const Text('Contactar soporte'),
        ),
      ],
    );
  }
}
