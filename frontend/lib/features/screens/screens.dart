import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validation.dart';
import '../../core/widgets.dart';
import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../../data/backend_repository.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../access/access_widgets.dart';
import '../operations/record_management.dart';

Future<void> _downloadReport(
  BuildContext context, {
  required String path,
  required String format,
}) async {
  try {
    final file = await BackendRepository().download(
      path,
      queryParameters: {'formato': format},
    );
    if (!context.mounted) return;
    final filename = file.filename.split(RegExp(r'[/\\]')).last;
    final dot = filename.lastIndexOf('.');
    final extension = dot > 0 ? filename.substring(dot + 1) : format;
    final name = dot > 0 ? filename.substring(0, dot) : filename;
    await FileSaver.instance.saveFile(
      name: name,
      bytes: file.bytes,
      fileExtension: extension,
      mimeType: switch (format) {
        'pdf' => MimeType.pdf,
        'xlsx' => MimeType.microsoftExcel,
        'csv' => MimeType.csv,
        _ => MimeType.other,
      },
    );
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  } on PlatformException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'No se pudo guardar el reporte.'),
        ),
      );
    }
  }
}

Future<void> _confirmSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Quieres salir de tu cuenta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await context.read<AppStore>().signOut();
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  } finally {
    if (context.mounted) context.go('/login');
  }
}

Future<void> _deleteResource(
  BuildContext context,
  AppStore store, {
  required String path,
  required String label,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text('Eliminar $label'),
          content: const Text(
            'Esta acción dará de baja el registro. Si tiene información asociada, el servidor puede impedirlo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
  );
  if (confirmed != true) return;
  try {
    await store.deleteResource(path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label eliminado correctamente.')));
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> logoOpacity;
  late final Animation<double> titleOpacity;
  late final Animation<double> taglineOpacity;
  late final Animation<double> progressOpacity;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    logoOpacity = CurvedAnimation(
      parent: controller,
      curve: const Interval(0, .58, curve: Curves.easeOut),
    );
    titleOpacity = CurvedAnimation(
      parent: controller,
      curve: const Interval(.16, .7, curve: Curves.easeOut),
    );
    taglineOpacity = CurvedAnimation(
      parent: controller,
      curve: const Interval(.3, .84, curve: Curves.easeOut),
    );
    progressOpacity = CurvedAnimation(
      parent: controller,
      curve: const Interval(.46, 1, curve: Curves.easeOut),
    );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: logoOpacity,
                child: ScaleTransition(
                  scale: Tween<double>(begin: .94, end: 1).animate(
                    CurvedAnimation(
                      parent: controller,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: Container(
                    width: 112,
                    height: 112,
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/CultivaLogo.png',
                      semanticLabel: 'Logo de Cultiva+',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: titleOpacity,
                child: ScaleTransition(
                  scale: Tween<double>(begin: .96, end: 1).animate(
                    CurvedAnimation(
                      parent: controller,
                      curve: const Interval(
                        .16,
                        .7,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Cultiva+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: taglineOpacity,
                child: ScaleTransition(
                  scale: Tween<double>(begin: .96, end: 1).animate(
                    CurvedAnimation(
                      parent: controller,
                      curve: const Interval(
                        .3,
                        .84,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Cada parcela cuenta',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: progressOpacity,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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

class RecoveryPasswordScreen extends StatefulWidget {
  const RecoveryPasswordScreen({this.initialToken = '', super.key});

  final String initialToken;

  @override
  State<RecoveryPasswordScreen> createState() => _RecoveryPasswordScreenState();
}

class _RecoveryPasswordScreenState extends State<RecoveryPasswordScreen> {
  final token = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  final apiClient = ApiClient();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    token.text = recoveryTokenFromInput(widget.initialToken);
  }

  @override
  void dispose() {
    token.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (isSaving) return;
    if (token.text.trim().isEmpty ||
        password.text.length < 6 ||
        password.text != confirmation.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Revisa el enlace y confirma una contraseña de al menos 6 caracteres.',
          ),
        ),
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      await apiClient.dio.post<void>(
        'auth/contrasena/restablecer',
        data: {
          'token': recoveryTokenFromInput(token.text),
          'nuevaContrasena': password.text,
        },
        options: Options(extra: {'skipAuthRefresh': true}),
      );
      if (!mounted) return;
      await apiClient.tokenStorage.clearTokens();
      if (!mounted) return;
      await context.read<AppStore>().signOut();
      if (!mounted) return;
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña restablecida. Ya puedes iniciar sesión.'),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.fromDio(error).message)),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Ingresa el token del correo y elige una contraseña nueva. El enlace vence a los 15 minutos.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: token,
            decoration: const InputDecoration(
              labelText: 'Token o enlace de recuperación',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              helperText: 'Mínimo 6 caracteres.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: confirmation,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar contraseña',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isSaving ? null : _submit,
            child: Text(isSaving ? 'Guardando…' : 'Restablecer contraseña'),
          ),
        ],
      ),
    );
  }
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
      final store = context.read<AppStore>();
      await store.signIn(
        email: emailController.text,
        password: passwordController.text,
      );
      if (!mounted) return;
      context.go(store.role == UserRole.capturista ? '/capture' : '/home');
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          errorMessage =
              error.statusCode == 401
                  ? 'Correo o contraseña incorrectos.'
                  : error.message;
        });
      }
    } finally {
      if (mounted && isLoading) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _recoverPassword() async {
    final email = TextEditingController(text: emailController.text);
    final token = TextEditingController();
    final password = TextEditingController();
    final confirmation = TextEditingController();
    final apiClient = ApiClient();
    var codeSent = false;
    var isSubmittingRecovery = false;
    String? dialogError;
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  title: Text(
                    codeSent ? 'Restablecer contraseña' : 'Recuperar acceso',
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!codeSent) ...[
                          const Text(
                            'Te enviaremos un enlace si el correo está registrado.',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'Si el correo está registrado, recibirás instrucciones. Revisa spam. En desarrollo con MAIL_TRANSPORT=log, busca el enlace en la consola del backend. Puedes pegar aquí el token o el enlace completo.',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: token,
                            decoration: const InputDecoration(
                              labelText: 'Token o enlace de recuperación',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Nueva contraseña',
                              helperText: 'Mínimo 6 caracteres.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: confirmation,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar contraseña',
                            ),
                          ),
                        ],
                        if (dialogError != null) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              dialogError!,
                              style: TextStyle(
                                color:
                                    Theme.of(dialogContext).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isSubmittingRecovery
                              ? null
                              : () => Navigator.pop(dialogContext),
                      child: const Text('Cerrar'),
                    ),
                    FilledButton(
                      onPressed:
                          isSubmittingRecovery
                              ? null
                              : () async {
                                setDialogState(() {
                                  isSubmittingRecovery = true;
                                  dialogError = null;
                                });
                                try {
                                  if (!codeSent) {
                                    final address = email.text.trim();
                                    if (!RegExp(
                                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                    ).hasMatch(address)) {
                                      setDialogState(
                                        () =>
                                            dialogError =
                                                'Escribe un correo electrónico válido.',
                                      );
                                      return;
                                    }
                                    await apiClient.dio.post<void>(
                                      'auth/contrasena/solicitar-recuperacion',
                                      data: {'correo': address.toLowerCase()},
                                      options: Options(
                                        extra: {'skipAuthRefresh': true},
                                      ),
                                    );
                                    if (!dialogContext.mounted) return;
                                    setDialogState(() => codeSent = true);
                                  } else {
                                    final recoveryToken =
                                        recoveryTokenFromInput(token.text);
                                    if (recoveryToken.isEmpty ||
                                        password.text.length < 6 ||
                                        password.text != confirmation.text) {
                                      setDialogState(
                                        () =>
                                            dialogError =
                                                'Revisa el token y confirma una contraseña de al menos 6 caracteres.',
                                      );
                                      return;
                                    }
                                    await apiClient.dio.post<void>(
                                      'auth/contrasena/restablecer',
                                      data: {
                                        'token': recoveryToken,
                                        'nuevaContrasena': password.text,
                                      },
                                      options: Options(
                                        extra: {'skipAuthRefresh': true},
                                      ),
                                    );
                                    if (!dialogContext.mounted) return;
                                    Navigator.pop(dialogContext);
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Contraseña restablecida. Ya puedes iniciar sesión.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } on DioException catch (error) {
                                  if (dialogContext.mounted) {
                                    setDialogState(
                                      () =>
                                          dialogError =
                                              ApiException.fromDio(
                                                error,
                                              ).message,
                                    );
                                  }
                                } on ApiException catch (error) {
                                  if (dialogContext.mounted) {
                                    setDialogState(
                                      () => dialogError = error.message,
                                    );
                                  }
                                } finally {
                                  if (dialogContext.mounted) {
                                    setDialogState(
                                      () => isSubmittingRecovery = false,
                                    );
                                  }
                                }
                              },
                      child: Text(codeSent ? 'Restablecer' : 'Enviar enlace'),
                    ),
                  ],
                ),
          ),
    );
    email.dispose();
    token.dispose();
    password.dispose();
    confirmation.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleError = errorMessage ?? context.watch<AppStore>().startupError;
    return AccessScaffold(
      compactBrand: true,
      appName: 'Cultiva+',
      child: Column(
        children: [
          Text(
            'Iniciar sesión',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            'Ingresa tus credenciales para continuar.',
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
                    if (!RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(email)) {
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
                      tooltip:
                          showPassword
                              ? 'Ocultar contraseña'
                              : 'Mostrar contraseña',
                      onPressed:
                          isLoading
                              ? null
                              : () =>
                                  setState(() => showPassword = !showPassword),
                      icon: Icon(
                        showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator:
                      (value) =>
                          (value ?? '').isEmpty
                              ? 'Escribe tu contraseña.'
                              : null,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Spacer(),
                    Flexible(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: isLoading ? null : _recoverPassword,
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                  ],
                ),
                if (visibleError != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      visibleError,
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
                  child:
                      isLoading
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
            'Usa las credenciales de tu empresa.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class CompanyFormScreen extends StatefulWidget {
  const CompanyFormScreen({this.apiClient, super.key});

  final ApiClient? apiClient;

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final companyController = TextEditingController();
  final legalNameController = TextEditingController();
  final rfcController = TextEditingController();
  final otpController = TextEditingController();
  final addressController = TextEditingController();
  late final apiClient = widget.apiClient ?? ApiClient();
  String plan = 'Productor';
  bool accepted = false;
  bool showPassword = false;
  bool showAcceptedError = false;
  bool otpRequested = false;
  bool isSubmitting = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    companyController.dispose();
    legalNameController.dispose();
    rfcController.dispose();
    otpController.dispose();
    addressController.dispose();
    super.dispose();
  }

  String? requiredValue(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Este campo es obligatorio.';
    if (text.length < 3) {
      return 'El nombre comercial debe tener al menos 3 caracteres.';
    }
    return null;
  }

  Map<String, Object?> _registrationBody() {
    final administratorName = nameController.text.trim().split(RegExp(r'\s+'));
    return {
      'nombre': companyController.text.trim(),
      if (legalNameController.text.trim().isNotEmpty)
        'razonSocial': legalNameController.text.trim(),
      if (rfcController.text.trim().isNotEmpty)
        'rfc': rfcController.text.trim().toUpperCase(),
      'correo': emailController.text.trim().toLowerCase(),
      if (phoneController.text.trim().isNotEmpty)
        'telefono': phoneController.text.trim(),
      if (addressController.text.trim().isNotEmpty)
        'direccion': addressController.text.trim(),
      'planCodigo': switch (plan) {
        'Básico' => 'BASICO',
        'Profesional' => 'PROFESIONAL',
        _ => 'PRODUCTOR',
      },
      'usuarioNombre': administratorName.first,
      'usuarioApellido': administratorName.skip(1).join(' '),
      'usuarioCorreo': emailController.text.trim().toLowerCase(),
      'usuarioContrasena': passwordController.text,
      if (phoneController.text.trim().isNotEmpty)
        'usuarioTelefono': phoneController.text.trim(),
    };
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    setState(() => showAcceptedError = !accepted);
    if (!formKey.currentState!.validate() || !accepted) return;
    if (otpRequested && !RegExp(r'^\d{6}$').hasMatch(otpController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El código debe tener 6 dígitos.')),
      );
      return;
    }

    setState(() => isSubmitting = true);
    final store = context.read<AppStore>();
    try {
      if (!otpRequested) {
        await apiClient.dio.post<void>(
          'empresas/registro/solicitar-codigo',
          data: _registrationBody(),
          options: Options(extra: {'skipAuthRefresh': true}),
        );
        if (!mounted) return;
        setState(() => otpRequested = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enviamos un código de verificación a tu correo.'),
          ),
        );
      } else {
        final response = await apiClient.dio.post<Map<String, dynamic>>(
          'empresas/registro/confirmar',
          data: {
            'correo': emailController.text.trim().toLowerCase(),
            'codigo': otpController.text.trim(),
          },
          options: Options(extra: {'skipAuthRefresh': true}),
        );
        final data = response.data;
        final accessToken = data?['accessToken'];
        final refreshToken = data?['refreshToken'];
        if (accessToken is! String || refreshToken is! String) {
          throw const ApiException(
            'El servidor no devolvió los tokens de la nueva cuenta.',
          );
        }
        await apiClient.tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await store.restoreSession();
        if (!store.isAuthenticated) {
          throw ApiException(
            store.startupError ?? 'No se pudo iniciar la sesión creada.',
          );
        }
        if (!mounted) return;
        context.go('/home');
      }
    } on DioException catch (error) {
      if (mounted) {
        final apiError = ApiException.fromDio(error);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError.message)));
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
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
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            Text(
              otpRequested
                  ? 'Ingresa el código enviado para confirmar tu correo.'
                  : 'Crea la cuenta de tu empresa y verifica el correo del administrador.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            const _AccessFormSection('Administrador'),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Nombre y apellido'),
              validator: (value) {
                final parts = (value ?? '').trim().split(RegExp(r'\s+'));
                if (parts.length < 2 ||
                    parts.first.length < 2 ||
                    parts.skip(1).join(' ').length < 2) {
                  return 'Escribe al menos nombre y apellido.';
                }
                if (parts.first.length > 80 ||
                    parts.skip(1).join(' ').length > 80) {
                  return 'El nombre y apellido deben tener máximo 80 caracteres cada uno.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              enabled: !otpRequested,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Correo de administrador y empresa',
              ),
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
              ),
              validator: validatePhoneNumber,
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
                  tooltip:
                      showPassword
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
              validator:
                  (value) =>
                      (value ?? '').length < 8
                          ? 'Usa al menos 8 caracteres.'
                          : null,
            ),
            const SizedBox(height: 22),
            const _AccessFormSection('Empresa'),
            TextFormField(
              controller: companyController,
              textCapitalization: TextCapitalization.words,
              maxLength: 150,
              decoration: const InputDecoration(labelText: 'Nombre comercial'),
              validator: requiredValue,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: legalNameController,
              textCapitalization: TextCapitalization.words,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Razón social (opcional)',
              ),
              validator: (value) {
                final legalName = (value ?? '').trim();
                if (legalName.isNotEmpty && legalName.length < 3) {
                  return 'Escribe al menos 3 caracteres o deja el campo vacío.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: rfcController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 13,
              decoration: const InputDecoration(
                labelText: 'RFC (opcional)',
                counterText: '',
              ),
              validator: (value) {
                final rfc = (value ?? '').trim().toUpperCase();
                if (rfc.isEmpty) return null;
                if (!RegExp(r'^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$').hasMatch(rfc)) {
                  return 'Escribe un RFC válido de 12 o 13 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección de la empresa (opcional)',
              ),
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
            if (otpRequested) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Código de verificación',
                  hintText: '000000',
                  counterText: '',
                ),
                validator: (value) {
                  if (otpRequested &&
                      !RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')) {
                    return 'Ingresa los 6 dígitos enviados por correo.';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: accepted,
              onChanged:
                  (value) => setState(() {
                    accepted = value ?? false;
                    showAcceptedError = false;
                  }),
              title: const Text(
                'Acepto continuar con el plan seleccionado.',
                style: TextStyle(fontSize: 12),
              ),
              subtitle:
                  showAcceptedError
                      ? const Text(
                        'Debes aceptar el plan para continuar.',
                        style: TextStyle(color: AppColors.red),
                      )
                      : null,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: isSubmitting ? null : submit,
              child:
                  isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(
                        otpRequested
                            ? 'Verificar y crear cuenta'
                            : 'Enviar código',
                      ),
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
    final store = context.watch<AppStore>();
    final role = store.role;
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
    final selected = math.max(
      0,
      destinations.indexWhere((item) => item.$1 == current),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (role != UserRole.capturista)
            IconButton(
              onPressed: () => context.push('/alerts'),
              icon:
                  store.alerts.isEmpty
                      ? const Icon(Icons.notifications_none_rounded, size: 28)
                      : Badge(
                        backgroundColor: AppColors.red,
                        label: Text('${store.alerts.length}'),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 28,
                        ),
                      ),
            ),
          if (current == 'more')
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(
                Icons.logout_rounded,
                size: 30,
                color: AppColors.red,
              ),
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
                  icon:
                      item.$1 == 'records'
                          ? Badge(
                            label: Text(
                              '${context.watch<AppStore>().records.length}',
                            ),
                            child: AppGlyph(item.$3, size: 28),
                          )
                          : AppGlyph(item.$3, size: 28),
                  label: item.$2,
                ),
            ],
            onDestinationSelected:
                (index) => context.go(destinations[index].$4),
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
    final income = store.cycles.fold<double>(
      0,
      (sum, item) => sum + item.income,
    );
    final cost = store.cycles
        .where((item) => item.status != CycleStatus.planificado)
        .fold<double>(0, (sum, item) => sum + item.cost);
    final receivable = store.sales.fold<double>(
      0,
      (sum, sale) => sum + (sale.cancelled ? 0 : sale.total - sale.paid),
    );
    final harvestedKg = store.cycles.fold<double>(
      0,
      (sum, cycle) => sum + cycle.harvestedKg,
    );
    final lostKg = store.records
        .where((record) => record.kind == 'Merma')
        .fold<double>(0, (sum, record) => sum + (record.value ?? 0));
    final soldKg = store.sales
        .where((sale) => !sale.cancelled)
        .fold<double>(0, (sum, sale) => sum + sale.kg);
    final availableKg = store.cycles.fold<double>(
      0,
      (sum, cycle) => sum + store.availableKg(cycle),
    );
    final plantedArea = store.cycles.fold<double>(
      0,
      (sum, cycle) => sum + cycle.area,
    );
    final costPerKg = harvestedKg == 0 ? 0 : cost / harvestedKg;
    final yieldPerHa = plantedArea == 0 ? 0 : harvestedKg / plantedArea;
    final salesKg = soldKg;
    final averagePricePerKg =
        salesKg == 0
            ? 0
            : store.sales
                    .where((sale) => !sale.cancelled)
                    .fold<double>(0, (sum, sale) => sum + sale.total) /
                salesKg;
    final costCoverage = costPerKg == 0 ? 0 : averagePricePerKg / costPerKg;
    return AppShell(
      title:
          store.role == UserRole.contador
              ? 'Finanzas'
              : 'Buen día, ${store.currentUser.name.split(' ').first}',
      current: 'home',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          if (store.isLoadingData) const LinearProgressIndicator(),
          if (store.dataError != null) ...[
            InfoBanner(
              title: 'No se pudieron cargar los datos',
              text: store.dataError!,
              tone: AppColors.red,
              icon: Icons.cloud_off_rounded,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Datos de ${store.currentUser.email}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          HeroCard(
            eyebrow: 'Ganancia acumulada',
            value: money.format(income - cost),
            subtitle:
                '${(income == 0 ? 0 : (income - cost) / income * 100).toStringAsFixed(1)}% de margen',
            trailing: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: Colors.white,
                size: 30,
              ),
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
                icon: Icons.savings_rounded,
              ),
              StatTile(
                label: 'Costo total',
                value: money.format(cost),
                icon: Icons.payments_rounded,
                color: AppColors.earth,
              ),
              StatTile(
                label: 'Margen',
                value:
                    '${(income == 0 ? 0 : (income - cost) / income * 100).toStringAsFixed(1)}%',
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
          if (harvestedKg > 0 && salesKg > 0) ...[
            const SizedBox(height: 24),
            const SectionTitle('Costo y precio por kilogramo'),
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
                            value: moneyExact.format(costPerKg),
                          ),
                        ),
                        Expanded(
                          child: _Metric(
                            label: 'Precio promedio',
                            value: moneyExact.format(averagePricePerKg),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    MiniBar(
                      label: 'Precio contra costo',
                      value:
                          costCoverage >= 1
                              ? 'Cubre el costo'
                              : 'No cubre el costo',
                      progress: costCoverage.clamp(0, 1).toDouble(),
                      color:
                          costCoverage >= 1 ? AppColors.green : AppColors.amber,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (harvestedKg > 0 || lostKg > 0) ...[
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
              child: Wrap(
                runSpacing: 16,
                children: [
                  _CompactStat(
                    label: 'Cosechado',
                    value: '${quantity.format(harvestedKg)} kg',
                  ),
                  _CompactStat(
                    label: 'Merma',
                    value: '${quantity.format(lostKg)} kg',
                  ),
                  _CompactStat(
                    label: 'Vendido',
                    value: '${quantity.format(soldKg)} kg',
                  ),
                  _CompactStat(
                    label: 'Disponible',
                    value: '${quantity.format(availableKg)} kg',
                  ),
                  _CompactStat(
                    label: 'Costo por kg',
                    value: moneyExact.format(costPerKg),
                  ),
                  _CompactStat(
                    label: 'Rendimiento',
                    value: '${quantity.format(yieldPerHa)} kg/ha',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SectionTitle(
            'Alertas',
            action: TextButton(
              onPressed: () => context.push('/module/alertas'),
              child: const Text('Ver todas'),
            ),
          ),
          const SizedBox(height: 12),
          if (store.alerts.isEmpty)
            const EmptyState(
              title: 'Sin alertas',
              message: 'Las alertas aparecerán cuando haya datos que revisar.',
              actionLabel: 'Entendido',
              onAction: _noop,
            )
          else
            for (final alert in store.alerts) ...[
              InfoBanner(
                title: alert.title,
                text: alert.detail,
                tone:
                    alert.severity.toLowerCase() == 'alta'
                        ? AppColors.red
                        : alert.severity.toLowerCase() == 'media'
                        ? AppColors.amber
                        : AppColors.green,
                icon: Icons.notifications_active_outlined,
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 24),
          SectionTitle(
            'Rentabilidad por ciclo',
            action: TextButton(
              onPressed: () => context.push('/module/comparativo'),
              child: const Text('Comparar'),
            ),
          ),
          const SizedBox(height: 12),
          if (store.cycles.isEmpty)
            EmptyState(
              title: 'Aún no hay ciclos',
              message:
                  'Registra tu predio y una parcela para poder crear el primer ciclo.',
              actionLabel: 'Configurar predios',
              onAction: () => context.push('/module/predios'),
            )
          else
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
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: 23),
        ),
      ],
    );
  }
}

class MonthlySummary extends StatefulWidget {
  const MonthlySummary({required this.income, required this.cost, super.key});

  final double income;
  final double cost;

  @override
  State<MonthlySummary> createState() => _MonthlySummaryState();
}

class _MonthlySummaryState extends State<MonthlySummary> {
  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(widget.income, widget.cost);
    final margin =
        widget.income == 0
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
                        'DATOS REGISTRADOS',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Resumen financiero',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            MiniBar(
              label: 'Ingresos',
              value: money.format(widget.income),
              progress: maxValue == 0 ? 0 : widget.income / maxValue,
            ),
            const SizedBox(height: 16),
            MiniBar(
              label: 'Gastos',
              value: money.format(widget.cost),
              progress: maxValue == 0 ? 0 : widget.cost / maxValue,
              color: AppColors.earth,
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                _SummaryMetric(
                  label: 'INGRESOS',
                  value: money.format(widget.income),
                ),
                _SummaryMetric(
                  label: 'GASTOS',
                  value: money.format(widget.cost),
                ),
                _SummaryMetric(
                  label: 'MARGEN',
                  value: '${margin.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ],
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
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
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
      title:
          store.role == UserRole.capturista
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
        onRefresh: store.loadWorkspace,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (store.isLoadingData) const LinearProgressIndicator(),
              if (store.dataError != null) ...[
                InfoBanner(
                  title: 'No se pudieron cargar los datos',
                  text: store.dataError!,
                  tone: AppColors.red,
                  icon: Icons.cloud_off_rounded,
                ),
                const SizedBox(height: 12),
              ],
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
                              Text(
                                option.$1,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
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
                    count:
                        store.records
                            .where((item) => item.kind == 'Cosecha')
                            .length,
                  ),
                  _RecordCount(
                    icon: Icons.receipt_long_rounded,
                    label: 'gastos',
                    count:
                        store.records
                            .where((item) => item.kind == 'Gasto')
                            .length,
                  ),
                  _RecordCount(
                    icon: Icons.agriculture_rounded,
                    label: 'actividades',
                    count:
                        store.records
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
                          hideMoney: store.role == UserRole.capturista,
                          canEdit: store.canEditRecord(record),
                          canDelete: store.canDeleteRecord(record),
                          onEdit:
                              () => _editRecentRecord(context, store, record),
                          onDelete:
                              () => _deleteRecentRecord(context, store, record),
                          onAttachments:
                              () => showRecordAttachmentsSheet(
                                context,
                                store,
                                record,
                              ),
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
        records.where((item) => item.kind == 'Cosecha').length,
      ),
      (
        'Gasto',
        AppColors.earth,
        records.where((item) => item.kind == 'Gasto').length,
      ),
      (
        'Actividad',
        AppColors.blue,
        records.where((item) => item.kind == 'Actividad').length,
      ),
      (
        'Merma',
        AppColors.amber,
        records.where((item) => item.kind == 'Merma').length,
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
                      Text(
                        'Resumen de movimientos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Distribución actual',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${records.length}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final item in values) ...[
              Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Text(
                      item.$1,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
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
    required this.hideMoney,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
    required this.onAttachments,
  });

  final ActivityRecord record;
  final bool hideMoney;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAttachments;

  @override
  Widget build(BuildContext context) {
    final color = _recordColor(record.kind);
    final displayValue =
        record.kind == 'Gasto' && hideMoney
            ? 'Importe restringido'
            : record.value == null
            ? null
            : record.unit == 'MXN'
            ? money.format(record.value)
            : '${quantity.format(record.value)} kg';
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            canEdit
                ? onEdit
                : record.attachmentEntityPath != null
                ? onAttachments
                : null,
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
                        Text(
                          record.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
                  if (record.attachmentEntityPath != null)
                    IconButton(
                      tooltip: 'Ver archivos adjuntos',
                      onPressed: onAttachments,
                      icon: const Icon(Icons.attach_file_rounded),
                    ),
                  if (canEdit) ...[
                    IconButton.filledTonal(
                      tooltip: 'Editar registro',
                      onPressed: onEdit,
                      icon: const AppGlyph(AppGlyphType.edit, size: 19),
                    ),
                  ],
                  if (canDelete)
                    IconButton(
                      tooltip: 'Eliminar registro',
                      color: AppColors.red,
                      onPressed: onDelete,
                      icon: const AppGlyph(
                        AppGlyphType.delete,
                        size: 19,
                        color: AppColors.red,
                      ),
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
    builder:
        (dialogContext) => AlertDialog(
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
  if (store.isAuthenticated) {
    final path = record.resourcePath;
    final id = record.id;
    if (path == null || id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar el registro.')),
      );
      return;
    }
    try {
      await store.deleteResource('$path/$id');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${record.kind} eliminado correctamente.')),
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
    return;
  }
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
  if (store.isAuthenticated) {
    await showRecordEditSheet(context, store, record);
    return;
  }
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
    builder:
        (sheetContext) => StatefulBuilder(
          builder:
              (sheetContext, setSheetState) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
                ),
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
                        Text(
                          'Editar registro',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: title,
                          decoration: const InputDecoration(
                            labelText: 'Concepto',
                            helperText:
                                'Identifica el movimiento en la bitácora.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedKind,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            helperText:
                                'Clasificación usada por reportes y gráficos.',
                          ),
                          items:
                              [
                                    'Actividad',
                                    'Gasto',
                                    'Cosecha',
                                    'Merma',
                                    'Venta',
                                    'Cobro',
                                    'Ciclo',
                                  ]
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setSheetState(() => selectedKind = value);
                            }
                          },
                        ),
                        if (selectedKind == 'Gasto' ||
                            selectedKind == 'Cosecha') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: value,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText:
                                  selectedKind == 'Gasto'
                                      ? 'Monto del gasto'
                                      : 'Cantidad cosechada',
                              prefixText:
                                  selectedKind == 'Gasto' ? '\$ ' : null,
                              suffixText:
                                  selectedKind == 'Cosecha' ? ' kg' : null,
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
                            hintText: DateFormat(
                              'dd/MM/yyyy',
                              'es_MX',
                            ).format(record.date),
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
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
                                    selectedKind == 'Gasto' ||
                                    selectedKind == 'Cosecha';
                                final metric =
                                    hasMetric
                                        ? double.tryParse(value.text)
                                        : null;
                                if (hasMetric &&
                                    (metric == null || metric <= 0)) {
                                  return;
                                }
                                final syncedDetail =
                                    selectedKind == 'Gasto'
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
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                              ),
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
                          Text(
                            cycle.crop,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
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
    final visible =
        filter == 'Todos'
            ? store.cycles
            : store.cycles.where((cycle) {
              return cycleStatusStyle(cycle.status).label ==
                  filter.replaceAll('s', '');
            }).toList();
    return AppShell(
      title: store.role == UserRole.capturista ? 'Mis ciclos' : 'Ciclos',
      current: 'cycles',
      floatingActionButton:
          store.role == UserRole.capturista
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
                  'Cerrados',
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
                cycle: cycle,
                hideMoney: store.role == UserRole.capturista,
              ),
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
              Text(cycle.parcel, style: Theme.of(context).textTheme.bodySmall),
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
                child: StatusPill(
                  status.label,
                  status.color,
                  icon: status.icon,
                ),
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
    final store = context.watch<AppStore>();
    final progress =
        cycle.goalKg <= 0
            ? 0.0
            : (cycle.harvestedKg / cycle.goalKg).clamp(0, 1).toDouble();
    final financialMax = math.max(cycle.income, cycle.cost);
    final expenses =
        store.records
            .where(
              (record) => record.cycleId == cycle.id && record.kind == 'Gasto',
            )
            .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeroCard(
          eyebrow: 'Resultado del ciclo',
          value: money.format(cycle.profit),
          subtitle:
              cycle.income == 0
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
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
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
            child: MiniBar(
              label: 'Cosechado / meta',
              value:
                  '${quantity.format(cycle.harvestedKg)} / ${quantity.format(cycle.goalKg)} kg',
              progress: progress,
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
                  progress: financialMax == 0 ? 0 : cycle.income / financialMax,
                ),
                const SizedBox(height: 16),
                MiniBar(
                  label: 'Costo',
                  value: money.format(cycle.cost),
                  progress: financialMax == 0 ? 0 : cycle.cost / financialMax,
                  color: AppColors.earth,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Gastos registrados'),
        const SizedBox(height: 12),
        if (expenses.isEmpty)
          const EmptyState(
            title: 'Sin gastos registrados',
            message: 'Los gastos de este ciclo aparecerán aquí.',
            actionLabel: 'Entendido',
            onAction: _noop,
          )
        else
          Card(
            child: Column(
              children: [
                for (final expense in expenses)
                  ListTile(
                    leading: const IconBox(Icons.receipt_long_rounded),
                    title: Text(expense.title),
                    subtitle: Text(
                      [
                        if (expense.detail.isNotEmpty) expense.detail,
                        shortDate.format(expense.date),
                      ].join(' · '),
                    ),
                    trailing: Text(money.format(expense.value ?? 0)),
                  ),
              ],
            ),
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

class _CycleField extends StatelessWidget {
  const _CycleField({required this.cycle});

  final FarmCycle cycle;

  @override
  Widget build(BuildContext context) {
    final records =
        context
            .watch<AppStore>()
            .records
            .where(
              (record) => record.cycleId == cycle.id && record.kind != 'Gasto',
            )
            .toList();
    final locked =
        cycle.status == CycleStatus.finalizado ||
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
                onPressed:
                    () => context.push('/form/activity?cycle=${cycle.id}'),
              ),
              ActionChip(
                avatar: const Icon(Icons.inventory_2_rounded, size: 18),
                label: const Text('Cosecha'),
                onPressed:
                    () => context.push('/form/harvest?cycle=${cycle.id}'),
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
        if (records.isEmpty)
          const EmptyState(
            title: 'Sin movimientos de campo',
            message: 'Las actividades, cosechas y mermas aparecerán aquí.',
            actionLabel: 'Entendido',
            onAction: _noop,
          )
        else
          Card(
            child: Column(
              children: [
                for (final record in records)
                  ListTile(
                    leading: IconBox(switch (record.kind) {
                      'Cosecha' => Icons.inventory_2_rounded,
                      'Merma' => Icons.compost_rounded,
                      _ => Icons.agriculture_rounded,
                    }),
                    title: Text(record.title),
                    subtitle: Text(
                      [
                        shortDate.format(record.date),
                        if (record.detail.isNotEmpty) record.detail,
                      ].join(' · '),
                    ),
                    trailing:
                        record.value == null
                            ? null
                            : Text(
                              '${quantity.format(record.value)} ${record.unit ?? ''}'
                                  .trim(),
                            ),
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
    final store = context.watch<AppStore>();
    final role = store.role;
    final expenses =
        store.records
            .where(
              (record) => record.cycleId == cycle.id && record.kind == 'Gasto',
            )
            .toList();
    final sales =
        store.sales
            .where((sale) => sale.cycleId == cycle.id && !sale.cancelled)
            .toList();
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
                onPressed:
                    () => context.push('/form/expense?cycle=${cycle.id}'),
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
        const SectionTitle('Movimientos financieros'),
        const SizedBox(height: 12),
        if (expenses.isEmpty && sales.isEmpty)
          const EmptyState(
            title: 'Sin movimientos financieros',
            message: 'Los gastos y ventas aparecerán aquí.',
            actionLabel: 'Entendido',
            onAction: _noop,
          )
        else
          Card(
            child: Column(
              children: [
                for (final expense in expenses)
                  ListTile(
                    leading: const PlainLeadingIcon(
                      Icons.receipt_long_rounded,
                      color: AppColors.earth,
                    ),
                    title: Text(expense.title),
                    subtitle: Text(
                      [
                        if (expense.detail.isNotEmpty) expense.detail,
                        shortDate.format(expense.date),
                      ].join(' · '),
                    ),
                    trailing: Text(money.format(expense.value ?? 0)),
                  ),
                for (final sale in sales)
                  ListTile(
                    leading: const PlainLeadingIcon(
                      Icons.local_shipping_rounded,
                    ),
                    title: Text('Venta ${sale.id}'),
                    subtitle: Text(
                      '${sale.client} · ${quantity.format(sale.kg)} kg',
                    ),
                    trailing: Text(money.format(sale.total)),
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
    final records =
        context
            .watch<AppStore>()
            .records
            .where((record) => record.cycleId == cycle.id)
            .toList();
    if (records.isEmpty) {
      return const EmptyState(
        title: 'Sin historial',
        message: 'Los registros de este ciclo aparecerán aquí.',
        actionLabel: 'Entendido',
        onAction: _noop,
      );
    }
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
                      child: VerticalDivider(width: 40, thickness: 2),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(record.detail),
                      const SizedBox(height: 4),
                      Text(
                        shortDate.format(record.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
                        Text(
                          sale.client,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
                      label: 'Total',
                      value: money.format(sale.total),
                    ),
                  ),
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
          const SectionTitle('Resumen'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Cantidad'),
                  trailing: Text('${quantity.format(sale.kg)} kg'),
                ),
                ListTile(
                  title: const Text('Precio promedio'),
                  trailing: Text(
                    moneyExact.format(sale.kg == 0 ? 0 : sale.total / sale.kg),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Archivos de la venta'),
          Card(
            child: ListTile(
              leading: const IconBox(Icons.attach_file_rounded),
              title: const Text('Comprobantes y documentos'),
              subtitle: const Text('Consultar, descargar o agregar archivos'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap:
                  () => showAttachmentsSheet(
                    context,
                    store,
                    path: 'ventas/${sale.id}/adjuntos',
                    title: 'Venta ${sale.id}',
                  ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Cobros'),
          const SizedBox(height: 12),
          _SalePaymentHistory(
            key: ValueKey('${sale.id}-${sale.paid}'),
            store: store,
            saleId: sale.id,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed:
                sale.paid >= sale.total
                    ? null
                    : () => context.push('/form/payment?sale=${sale.id}'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Registrar cobro'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
                sale.cancelled
                    ? null
                    : () => showDialog<void>(
                      context: context,
                      builder:
                          (dialogContext) => AlertDialog(
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
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  try {
                                    await store.cancelSale(sale);
                                    if (!context.mounted) return;
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    context.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          store.dataError == null
                                              ? 'Venta cancelada en el servidor.'
                                              : 'La venta se canceló, pero no se pudo actualizar la información: ${store.dataError}',
                                        ),
                                      ),
                                    );
                                  } on ApiException catch (error) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error.message)),
                                    );
                                  }
                                },
                                child: const Text('Cancelar venta'),
                              ),
                            ],
                          ),
                    ),
            icon: const Icon(Icons.block_rounded, color: AppColors.red),
            label: const Text(
              'Cancelar venta',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalePaymentHistory extends StatefulWidget {
  const _SalePaymentHistory({
    required this.store,
    required this.saleId,
    super.key,
  });

  final AppStore store;
  final String saleId;

  @override
  State<_SalePaymentHistory> createState() => _SalePaymentHistoryState();
}

class _SalePaymentHistoryState extends State<_SalePaymentHistory> {
  late Future<List<Map<String, dynamic>>> _payments;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _payments = widget.store.listResource(
      'ventas/${widget.saleId}/cobros',
      queryParameters: const {'page': 1, 'limit': 100},
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _payments,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        final message =
            error is ApiException
                ? error.message
                : 'No se pudieron cargar los cobros.';
        return InfoBanner(
          title: 'Historial no disponible',
          text: message,
          tone: AppColors.red,
          icon: Icons.cloud_off_rounded,
        );
      }
      final payments = snapshot.data ?? const [];
      if (payments.isEmpty) {
        return const InfoBanner(
          title: 'Sin cobros',
          text:
              'Registra un cobro para actualizar el saldo y el estado automáticamente.',
          tone: AppColors.amber,
        );
      }
      return Column(
        children: [
          for (final payment in payments)
            Card(
              child: ListTile(
                leading: const IconBox(Icons.payments_rounded),
                title: Text(money.format(_parseAmount(payment['monto']))),
                subtitle: Text(
                  [
                    _paymentDate(payment['fecha']),
                    _paymentMethod(payment['metodo']),
                    if (payment['referencia'] is String &&
                        (payment['referencia'] as String).isNotEmpty)
                      payment['referencia'] as String,
                  ].join(' · '),
                ),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Acciones del cobro',
                  onSelected: (action) {
                    final id = payment['id']?.toString();
                    if (id == null || id.isEmpty) return;
                    switch (action) {
                      case 'attachments':
                        showAttachmentsSheet(
                          context,
                          widget.store,
                          path: 'cobros/$id/adjuntos',
                          title: 'Cobro $id',
                        );
                        break;
                      case 'annul':
                        _confirmAnnulPayment(id);
                        break;
                    }
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(
                          value: 'attachments',
                          child: Text('Archivos adjuntos'),
                        ),
                        PopupMenuItem(
                          value: 'annul',
                          child: Text('Anular cobro'),
                        ),
                      ],
                ),
              ),
            ),
        ],
      );
    },
  );

  double _parseAmount(Object? value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  String _paymentDate(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? 'Fecha desconocida'
        : DateFormat('dd MMM yyyy', 'es_MX').format(date);
  }

  String _paymentMethod(Object? value) => switch (value) {
    'EFECTIVO' => 'Efectivo',
    'TRANSFERENCIA' => 'Transferencia',
    'CHEQUE' => 'Cheque',
    'TARJETA' => 'Tarjeta',
    'OTRO' => 'Otro',
    _ => 'Método no especificado',
  };

  Future<void> _confirmAnnulPayment(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('¿Anular cobro?'),
            content: const Text(
              'El cobro se conservará en la auditoría y el saldo de la venta se recalculará.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Anular cobro'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.store.annulPayment(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.store.dataError == null
                ? 'Cobro anulado correctamente.'
                : 'Se anuló, pero no se pudo actualizar la información: ${widget.store.dataError}',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final records = store.records;
    return AppShell(
      title: 'Mi bitácora',
      current: 'records',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('dd MMM', 'es_MX').format(record.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (store.canEditRecord(record) ||
                            store.canDeleteRecord(record) ||
                            record.attachmentEntityPath != null)
                          PopupMenuButton<String>(
                            tooltip: 'Acciones del registro',
                            onSelected: (action) {
                              switch (action) {
                                case 'edit':
                                  _editRecentRecord(context, store, record);
                                  break;
                                case 'delete':
                                  _deleteRecentRecord(context, store, record);
                                  break;
                                case 'attachments':
                                  showRecordAttachmentsSheet(
                                    context,
                                    store,
                                    record,
                                  );
                                  break;
                              }
                            },
                            itemBuilder:
                                (_) => [
                                  if (record.attachmentEntityPath != null)
                                    const PopupMenuItem(
                                      value: 'attachments',
                                      child: Text('Archivos adjuntos'),
                                    ),
                                  if (store.canEditRecord(record))
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Editar'),
                                    ),
                                  if (store.canDeleteRecord(record))
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Eliminar'),
                                    ),
                                ],
                          ),
                      ],
                    ),
                    onTap:
                        record.attachmentEntityPath != null
                            ? () => showRecordAttachmentsSheet(
                              context,
                              store,
                              record,
                            )
                            : store.canEditRecord(record)
                            ? () => _editRecentRecord(context, store, record)
                            : null,
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
    final store = context.watch<AppStore>();
    final role = store.role;
    final rawCompanyName = store.companyProfile?['nombre'];
    final companyName =
        rawCompanyName is String && rawCompanyName.trim().isNotEmpty
            ? rawCompanyName.trim()
            : 'Mi empresa';
    final rawPlan = store.companyProfile?['plan'];
    final rawPlanName = rawPlan is Map ? rawPlan['nombre'] : null;
    final planName =
        rawPlanName is String && rawPlanName.isNotEmpty ? rawPlanName : null;
    final rawSubscription = store.companyProfile?['estadoSuscripcion'];
    final subscription = rawSubscription is String ? rawSubscription : null;
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
            'cuentas-por-cobrar',
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
        ('Categorías de gastos', Icons.category_outlined, 'categorias'),
        if (role != UserRole.capturista)
          ('Alertas', Icons.notifications_active_outlined, 'alertas'),
      ],
      if (role == UserRole.admin)
        'ADMINISTRACIÓN': [
          (
            'Usuarios y permisos',
            Icons.admin_panel_settings_outlined,
            'usuarios',
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
                      Text(
                        companyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        [if (planName != null) planName, roleLabel].join(' · '),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (subscription != null)
                  StatusPill(
                    subscription,
                    subscription == 'ACTIVA' || subscription == 'PRUEBA'
                        ? AppColors.lime
                        : AppColors.red,
                    icon:
                        subscription == 'ACTIVA' || subscription == 'PRUEBA'
                            ? Icons.verified_rounded
                            : Icons.warning_rounded,
                  ),
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
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
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
    'categorias': 'Categorías de gastos',
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
      _ => EmptyState(
        title: 'Módulo sin datos',
        message: 'Agrega el primer registro para comenzar.',
        actionLabel: 'Agregar',
        onAction: () {
          context.push('/capture');
        },
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
    final sales = context.watch<AppStore>().sales.where(
      (sale) =>
          sale.paid < sale.total && (filter == null || sale.status == filter),
    );
    final total = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.total - sale.paid,
    );
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
    final expenses =
        context
            .watch<AppStore>()
            .records
            .where((record) => record.kind == 'Gasto')
            .toList();
    final total = expenses.fold<double>(
      0,
      (sum, record) => sum + (record.value ?? 0),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoBanner(
          text:
              '${expenses.length} gastos registrados · ${money.format(total)} en total.',
          tone: AppColors.earth,
          icon: Icons.receipt_long_rounded,
        ),
        const SizedBox(height: 16),
        if (expenses.isEmpty)
          EmptyState(
            title: 'Sin gastos registrados',
            message: 'Los gastos capturados aparecerán aquí.',
            actionLabel: 'Registrar gasto',
            onAction: () => context.push('/form/expense'),
          )
        else
          Card(
            child: Column(
              children: [
                for (final record in expenses)
                  ListTile(
                    leading: const IconBox(Icons.receipt_long_rounded),
                    title: Text(record.title),
                    subtitle: Text(
                      '${shortDate.format(record.date)} · ${record.detail}',
                    ),
                    trailing: Text(money.format(record.value ?? 0)),
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
          text:
              canEdit
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
            onAction:
                canEdit
                    ? () => context.push('/catalog-form/property')
                    : () => context.pop(),
          ),
        for (final property in store.properties) ...[
          SectionTitle(
            property.name,
            action:
                canEdit
                    ? PopupMenuButton<String>(
                      tooltip: 'Acciones del predio',
                      onSelected: (value) {
                        if (value == 'edit') {
                          context.push(
                            '/catalog-form/property?id=${property.id}',
                          );
                        } else if (value == 'delete') {
                          _deleteResource(
                            context,
                            store,
                            path: 'predios/${property.id}',
                            label: 'predio',
                          );
                        }
                      },
                      itemBuilder:
                          (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Editar predio'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Dar de baja'),
                            ),
                          ],
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
                      trailing:
                          canEdit
                              ? PopupMenuButton<String>(
                                tooltip: 'Acciones de la parcela',
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    context.push(
                                      '/catalog-form/parcel?id=${parcel.id}',
                                    );
                                  } else if (value == 'delete') {
                                    _deleteResource(
                                      context,
                                      store,
                                      path: 'parcelas/${parcel.id}',
                                      label: 'parcela',
                                    );
                                  }
                                },
                                itemBuilder:
                                    (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar parcela'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Dar de baja'),
                                      ),
                                    ],
                              )
                              : null,
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
    final channels = <String, int>{};
    for (final client in store.clients.where((item) => item.active)) {
      channels.update(client.kind, (count) => count + 1, ifAbsent: () => 1);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              const ListTile(
                title: Text('Clientes activos por canal'),
                leading: IconBox(Icons.storefront_rounded),
              ),
              if (channels.isEmpty)
                const ListTile(title: Text('Aún no hay canales registrados.'))
              else
                for (final entry in channels.entries)
                  ListTile(
                    title: Text(entry.key),
                    trailing: Text('${entry.value}'),
                  ),
            ],
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
                      color:
                          client.active
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
                    trailing:
                        store.isAuthenticated
                            ? PopupMenuButton<String>(
                              tooltip: 'Acciones del cliente',
                              onSelected: (value) {
                                if (value == 'edit') {
                                  context.push(
                                    '/catalog-form/client?id=${client.id}',
                                  );
                                } else if (value == 'delete') {
                                  _deleteResource(
                                    context,
                                    store,
                                    path: 'clientes/${client.id}',
                                    label: 'cliente',
                                  );
                                }
                              },
                              itemBuilder:
                                  (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Editar'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Dar de baja'),
                                    ),
                                  ],
                            )
                            : PopupMenuButton<String>(
                              tooltip: 'Acciones del cliente',
                              onSelected: (value) {
                                if (value == 'toggle') {
                                  store.togglePartner(client);
                                }
                              },
                              itemBuilder:
                                  (_) => [
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
                                          client.active
                                              ? 'Desactivar'
                                              : 'Reactivar',
                                        ),
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

class _UsersModule extends StatelessWidget {
  const _UsersModule();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final usage = store.companyProfile?['cuotas'];
    final maxUsers =
        usage is Map
            ? int.tryParse('${usage['maxUsuarios']}') ?? 0
            : store.isAuthenticated
            ? 0
            : 5;
    final activeUsers =
        usage is Map
            ? int.tryParse('${usage['usuariosActivos']}') ?? store.users.length
            : store.users.length;
    final hasQuota = maxUsers > 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoBanner(
          title:
              hasQuota
                  ? '$activeUsers de $maxUsers usuarios'
                  : 'Cuota de usuarios no disponible',
          text:
              hasQuota
                  ? 'Tu plan permite agregar ${math.max(0, maxUsers - activeUsers)} personas más.'
                  : 'No se pudo consultar el límite vigente del plan.',
          tone: AppColors.green,
          icon: Icons.group_add_rounded,
        ),
        const SizedBox(height: 12),
        MiniBar(
          label: 'Uso del plan',
          value: hasQuota ? '${(activeUsers / maxUsers * 100).round()}%' : '—',
          progress: hasQuota ? activeUsers / maxUsers : 0,
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
          onPressed:
              !hasQuota || activeUsers >= maxUsers
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
              StatusPill(
                permission,
                AppColors.green,
                icon: Icons.check_rounded,
              ),
          ],
        ),
      ],
    );
  }
}

Future<void> _toggleUser(
  BuildContext context,
  AppStore store,
  AppUser user,
) async {
  try {
    await store.toggleUser(user);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          store.isAuthenticated
              ? 'Estado del usuario actualizado en el servidor.'
              : 'Estado del usuario actualizado.',
        ),
      ),
    );
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.permissions});

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
            if (value == 'toggle') {
              _toggleUser(context, context.read<AppStore>(), user);
            } else if (value == 'edit' && user.id != null) {
              context.push('/catalog-form/user?id=${user.id}');
            } else if (value == 'delete' && user.id != null) {
              _deleteResource(
                context,
                context.read<AppStore>(),
                path: 'usuarios/${user.id}',
                label: 'usuario',
              );
            }
          },
          itemBuilder:
              (_) => [
                PopupMenuItem(
                  enabled:
                      user.id != null &&
                      user != context.read<AppStore>().currentUser,
                  value: 'edit',
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_rounded),
                    title: Text('Editar'),
                  ),
                ),
                PopupMenuItem(
                  enabled: user != context.read<AppStore>().currentUser,
                  value: 'toggle',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      user.active
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                    ),
                    title: Text(user.active ? 'Desactivar' : 'Reactivar'),
                  ),
                ),
              ],
          child: StatusPill(
            user.active ? user.role.name.toUpperCase() : 'INACTIVO',
            user.active ? AppColors.green : AppColors.tertiaryInk,
            icon:
                user.active
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
                  Text(
                    entry.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
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
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: AppColors.red),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded),
                        Expanded(
                          child: Text(
                            'NUEVO\n${entry.after}',
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: AppColors.green),
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
    final visible =
        filter == 'Todas'
            ? alerts
            : alerts.where((alert) => alert.severity == filter).toList();
    Widget alertItem(ProfitabilityAlert alert) {
      final tone =
          alert.severity == 'Alta'
              ? AppColors.red
              : alert.severity == 'Media'
              ? AppColors.amber
              : AppColors.blue;
      void dismissAlert() {
        final index = store.deleteAlert(alert);
        if (index < 0 || !context.mounted) return;
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
      }

      final card = Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_rounded, color: tone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${alert.title} · ${alert.severity}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(alert.detail),
                    TextButton.icon(
                      onPressed:
                          () => showDialog<void>(
                            context: context,
                            builder:
                                (dialogContext) => AlertDialog(
                                  title: Text(alert.title),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        StatusPill(alert.severity, tone),
                                        const SizedBox(height: 12),
                                        Text(alert.detail),
                                        if (alert.observed?.isNotEmpty ??
                                            false) ...[
                                          const SizedBox(height: 16),
                                          _AlertDetailRow(
                                            label: 'Valor observado',
                                            value: alert.observed!,
                                          ),
                                        ],
                                        if (alert.threshold?.isNotEmpty ??
                                            false) ...[
                                          const SizedBox(height: 8),
                                          _AlertDetailRow(
                                            label: 'Umbral de referencia',
                                            value: alert.threshold!,
                                          ),
                                        ],
                                        if ((alert.referenceType?.isNotEmpty ??
                                                false) ||
                                            (alert.referenceId?.isNotEmpty ??
                                                false)) ...[
                                          const SizedBox(height: 8),
                                          _AlertDetailRow(
                                            label: 'Registro relacionado',
                                            value: [
                                              if (alert
                                                      .referenceType
                                                      ?.isNotEmpty ??
                                                  false)
                                                alert.referenceType!,
                                              if (alert
                                                      .referenceId
                                                      ?.isNotEmpty ??
                                                  false)
                                                '#${alert.referenceId}',
                                            ].join(' '),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(dialogContext),
                                      child: const Text('Cerrar'),
                                    ),
                                  ],
                                ),
                          ),
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('Ver detalles'),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Quitar alerta',
                onPressed: dismissAlert,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      );
      return Dismissible(
        key: ValueKey(alert.key),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.red,
            size: 28,
          ),
        ),
        onDismissed: (_) => dismissAlert(),
        child: card,
      );
    }

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
                'Informativa',
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
            alertItem(alert),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _AlertDetailRow extends StatelessWidget {
  const _AlertDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      Text(value),
    ],
  );
}

class _ComparisonModule extends StatelessWidget {
  const _ComparisonModule();

  @override
  Widget build(BuildContext context) {
    final cycles = context.watch<AppStore>().cycles;
    if (cycles.length < 2) {
      return EmptyState(
        title: 'Se necesitan dos ciclos',
        message:
            'Cuando haya dos ciclos cargados podrás comparar sus resultados.',
        actionLabel: 'Ver ciclos',
        onAction: () => context.push('/cycles'),
      );
    }
    final left = cycles[0];
    final right = cycles[1];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const InfoBanner(
          text: 'Comparación con datos sincronizados de los ciclos.',
          tone: AppColors.green,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('${left.crop} · ${left.parcel}')),
            const SizedBox(width: 12),
            Expanded(child: Text('${right.crop} · ${right.parcel}')),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                MiniBar(
                  label: 'Margen · ${left.crop}',
                  value: '${(left.margin * 100).toStringAsFixed(2)}%',
                  progress: left.margin.clamp(0, 1).toDouble(),
                  color: left.profit < 0 ? AppColors.red : AppColors.green,
                ),
                const SizedBox(height: 16),
                MiniBar(
                  label: 'Margen · ${right.crop}',
                  value: '${(right.margin * 100).toStringAsFixed(2)}%',
                  progress: right.margin.clamp(0, 1).toDouble(),
                  color: right.profit < 0 ? AppColors.red : AppColors.green,
                ),
                const Divider(height: 32),
                _ComparisonRow(
                  label: 'Costo / kg',
                  left: money.format(left.costPerKg),
                  right: money.format(right.costPerKg),
                ),
                _ComparisonRow(
                  label: 'Rendimiento / ha',
                  left:
                      '${quantity.format(left.area == 0 ? 0 : left.harvestedKg / left.area)} kg',
                  right:
                      '${quantity.format(right.area == 0 ? 0 : right.harvestedKg / right.area)} kg',
                ),
                _ComparisonRow(
                  label: 'ROI',
                  left: '${(left.roi * 100).toStringAsFixed(2)}%',
                  right: '${(right.roi * 100).toStringAsFixed(2)}%',
                ),
                _ComparisonRow(
                  label: 'Ganancia',
                  left: money.format(left.profit),
                  right: money.format(right.profit),
                ),
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
                color: AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              right,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w700,
              ),
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
    final store = context.watch<AppStore>();
    final canEdit = store.isAuthenticated && store.role == UserRole.admin;
    final categories = store.catalogs['expenseCategories'] ?? [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoBanner(
          title:
              canEdit ? 'Administración habilitada' : 'Vista de solo lectura',
          text:
              'Las categorías del sistema no se pueden eliminar. Las personalizadas se pueden quitar si no tienen subcategorías ni gastos registrados.',
          tone: AppColors.blue,
          icon: Icons.account_tree_rounded,
        ),
        const SizedBox(height: 16),
        if (categories.isEmpty)
          const InfoBanner(
            title: 'Sin categorías de gastos',
            text: 'No hay categorías disponibles en el catálogo del servidor.',
            tone: AppColors.amber,
          )
        else
          for (final category in categories) ...[
            _CategoryCard(
              category: category,
              onDelete:
                  (id, name) =>
                      _deleteExpenseCategory(context, store, id, name),
            ),
            const SizedBox(height: 12),
          ],
        if (canEdit) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _createExpenseCategory(context, store),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nueva categoría personalizada'),
          ),
        ],
      ],
    );
  }
}

Future<void> _deleteExpenseCategory(
  BuildContext context,
  AppStore store,
  Object? id,
  String name,
) async {
  final categoryId = int.tryParse('$id');
  if (categoryId == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar la categoría.')),
      );
    }
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text('Eliminar categoría'),
          content: Text('¿Quieres eliminar la categoría "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await store.deleteResource('catalogos/categorias-gasto/$categoryId');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            store.dataError == null
                ? 'Categoría eliminada.'
                : 'Categoría eliminada, pero no se pudo actualizar: ${store.dataError}',
          ),
        ),
      );
    }
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

Future<void> _createExpenseCategory(
  BuildContext context,
  AppStore store,
) async {
  final name = TextEditingController();
  final description = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text('Nueva categoría'),
          content: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator:
                      (value) =>
                          (value ?? '').trim().length < 2
                              ? 'Escribe al menos 2 caracteres.'
                              : null,
                ),
                TextFormField(
                  controller: description,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
  );
  if (confirmed == true && context.mounted) {
    try {
      await store.createResource(
        'catalogos/categorias-gasto',
        body: {
          'nombre': name.text.trim(),
          if (description.text.trim().isNotEmpty)
            'descripcion': description.text.trim(),
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              store.dataError == null
                  ? 'Categoría guardada en el servidor.'
                  : 'Categoría guardada, pero no se pudo refrescar: ${store.dataError}',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
  name.dispose();
  description.dispose();
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onDelete});

  final Map<String, dynamic> category;
  final void Function(Object? id, String name) onDelete;

  @override
  Widget build(BuildContext context) {
    final title = '${category['nombre']}';
    final children = category['subcategorias'];
    final isCustom = category['esPersonalizada'] == true;
    return Card(
      child: ExpansionTile(
        leading: const IconBox(Icons.account_tree_rounded),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCustom)
              IconButton(
                tooltip: 'Eliminar categoría personalizada',
                onPressed: () => onDelete(category['id'], title),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
        children: [
          if (children is List)
            for (final child in children.whereType<Map>())
              ListTile(
                contentPadding: const EdgeInsets.only(left: 72, right: 16),
                title: Text('${child['nombre']}'),
                trailing:
                    child['esPersonalizada'] == true
                        ? IconButton(
                          tooltip: 'Eliminar subcategoría personalizada',
                          onPressed:
                              () => onDelete(child['id'], '${child['nombre']}'),
                          icon: const Icon(Icons.delete_outline_rounded),
                        )
                        : const Icon(Icons.drag_handle_rounded),
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
                    trailing:
                        store.isAuthenticated
                            ? PopupMenuButton<String>(
                              tooltip: 'Acciones del proveedor',
                              onSelected: (value) {
                                if (value == 'edit') {
                                  context.push(
                                    '/catalog-form/supplier?id=${supplier.id}',
                                  );
                                } else if (value == 'delete') {
                                  _deleteResource(
                                    context,
                                    store,
                                    path: 'proveedores/${supplier.id}',
                                    label: 'proveedor',
                                  );
                                }
                              },
                              itemBuilder:
                                  (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Editar'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Dar de baja'),
                                    ),
                                  ],
                            )
                            : PopupMenuButton<String>(
                              tooltip: 'Acciones del proveedor',
                              onSelected: (value) {
                                if (value == 'toggle') {
                                  store.togglePartner(supplier);
                                }
                              },
                              itemBuilder:
                                  (_) => [
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
                                          supplier.active
                                              ? 'Desactivar'
                                              : 'Reactivar',
                                        ),
                                      ),
                                    ),
                                  ],
                              child: StatusPill(
                                supplier.active ? 'Activo' : 'Inactivo',
                                supplier.active
                                    ? AppColors.green
                                    : AppColors.tertiaryInk,
                                icon:
                                    supplier.active
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
  String? selectedCycleId;
  String selectedFormat = 'pdf';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final cycles = store.cycles;
    final activeSelection =
        cycles.any((cycle) => cycle.id == selectedCycleId)
            ? selectedCycleId
            : null;
    final visibleCycles =
        activeSelection == null
            ? cycles
            : cycles.where((cycle) => cycle.id == activeSelection).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (cycles.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: activeSelection,
            decoration: const InputDecoration(labelText: 'Ciclo'),
            items: [
              for (final cycle in cycles)
                DropdownMenuItem(
                  value: cycle.id,
                  child: Text('${cycle.crop} · ${cycle.parcel}'),
                ),
            ],
            onChanged: (value) => setState(() => selectedCycleId = value),
          ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedFormat,
          decoration: const InputDecoration(labelText: 'Formato de descarga'),
          items: const [
            DropdownMenuItem(value: 'pdf', child: Text('PDF')),
            DropdownMenuItem(value: 'xlsx', child: Text('Excel (XLSX)')),
            DropdownMenuItem(value: 'csv', child: Text('CSV')),
          ],
          onChanged:
              (value) => setState(() {
                if (value != null) selectedFormat = value;
              }),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed:
                  () => _downloadReport(
                    context,
                    path: 'reportes/exportaciones/rentabilidad',
                    format: selectedFormat,
                  ),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Exportar rentabilidad'),
            ),
            OutlinedButton.icon(
              onPressed:
                  () => _downloadReport(
                    context,
                    path: 'reportes/exportaciones/cuentas-por-cobrar',
                    format: selectedFormat,
                  ),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Exportar cartera'),
            ),
            if (activeSelection != null) ...[
              OutlinedButton.icon(
                onPressed:
                    () => _downloadReport(
                      context,
                      path: 'reportes/exportaciones/ciclos/$activeSelection',
                      format: selectedFormat,
                    ),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Exportar ciclo'),
              ),
              Builder(
                builder: (context) {
                  final selected = cycles.firstWhere(
                    (cycle) => cycle.id == activeSelection,
                  );
                  final parcelId = selected.parcelId;
                  if (parcelId == null) return const SizedBox.shrink();
                  return OutlinedButton.icon(
                    onPressed:
                        () => _downloadReport(
                          context,
                          path:
                              'reportes/exportaciones/parcelas/$parcelId/comparativo',
                          format: selectedFormat,
                        ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Exportar comparativo de parcela'),
                  );
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        const InfoBanner(
          title: 'Indicadores sincronizados',
          text:
              'Los indicadores se calculan con ciclos, gastos, cosechas y ventas recibidos del servidor.',
          tone: AppColors.blue,
          icon: Icons.ios_share_rounded,
        ),
        const SizedBox(height: 12),
        if (visibleCycles.isEmpty)
          EmptyState(
            title: 'Sin ciclos para reportar',
            message: 'Los reportes aparecerán cuando la API devuelva ciclos.',
            actionLabel: 'Ver ciclos',
            onAction: () => context.push('/cycles'),
          )
        else
          for (final cycle in visibleCycles) ...[
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const IconBox(Icons.assessment_rounded),
                    title: Text('${cycle.crop} · ${cycle.parcel}'),
                    subtitle: Text('Estado: ${cycle.status.name}'),
                  ),
                  ListTile(
                    title: const Text('Costo total'),
                    trailing: Text(money.format(cycle.cost)),
                  ),
                  ListTile(
                    title: const Text('Ingresos'),
                    trailing: Text(money.format(cycle.income)),
                  ),
                  ListTile(
                    title: const Text('Ganancia'),
                    trailing: Text(money.format(cycle.profit)),
                  ),
                  ListTile(
                    title: const Text('Cosecha'),
                    trailing: Text('${quantity.format(cycle.harvestedKg)} kg'),
                  ),
                  ListTile(
                    title: const Text('Costo por kg'),
                    trailing: Text(money.format(cycle.costPerKg)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _CompanyModule extends StatelessWidget {
  const _CompanyModule();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final company = store.companyProfile;
    final plan = company?['plan'];
    final quotas = company?['cuotas'];
    final planName = plan is Map ? '${plan['nombre']}' : 'Plan';
    final maxUsers =
        quotas is Map ? int.tryParse('${quotas['maxUsuarios']}') ?? 0 : 0;
    final activeUsers =
        quotas is Map ? int.tryParse('${quotas['usuariosActivos']}') ?? 0 : 0;
    final maxParcels =
        quotas is Map ? int.tryParse('${quotas['maxParcelas']}') ?? 0 : 0;
    final activeParcels =
        quotas is Map ? int.tryParse('${quotas['parcelasActivas']}') ?? 0 : 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (company == null)
          InfoBanner(
            title: 'Datos de empresa no disponibles',
            text:
                store.dataError ??
                'Inicia sesión como administrador para consultar la empresa.',
            tone: AppColors.amber,
          )
        else ...[
          HeroCard(
            eyebrow: 'Suscripción · ${company['estadoSuscripcion'] ?? '—'}',
            value: planName,
            subtitle:
                plan is Map
                    ? '\$${plan['precioMensual'] ?? '—'} MXN / mes'
                    : 'Información del plan',
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const IconBox(Icons.apartment_rounded),
                  title: Text('${company['nombre'] ?? 'Empresa'}'),
                  subtitle: Text('${company['razonSocial'] ?? ''}'),
                ),
                ListTile(
                  leading: const IconBox(Icons.alternate_email_rounded),
                  title: const Text('Correo'),
                  trailing: Text('${company['correo'] ?? '—'}'),
                ),
                ListTile(
                  leading: const IconBox(Icons.badge_rounded),
                  title: const Text('RFC'),
                  trailing: Text('${company['rfc'] ?? '—'}'),
                ),
                ListTile(
                  leading: const IconBox(Icons.currency_exchange_rounded),
                  title: const Text('Moneda'),
                  trailing: Text('${company['moneda'] ?? '—'}'),
                ),
                if (company['telefono'] != null)
                  ListTile(
                    leading: const IconBox(Icons.phone_rounded),
                    title: const Text('Teléfono'),
                    trailing: Text('${company['telefono']}'),
                  ),
                if (company['direccion'] != null)
                  ListTile(
                    leading: const IconBox(Icons.location_on_rounded),
                    title: const Text('Dirección'),
                    subtitle: Text('${company['direccion']}'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionTitle(
            'Límites del plan',
            action: TextButton(
              onPressed: () => _editCompany(context, store, company),
              child: const Text('Editar datos'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  MiniBar(
                    label: 'Usuarios',
                    value: '$activeUsers / $maxUsers',
                    progress: maxUsers == 0 ? 0 : activeUsers / maxUsers,
                  ),
                  const SizedBox(height: 16),
                  MiniBar(
                    label: 'Parcelas',
                    value: '$activeParcels / $maxParcels',
                    progress: maxParcels == 0 ? 0 : activeParcels / maxParcels,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> _editCompany(
  BuildContext context,
  AppStore store,
  Map<String, dynamic> company,
) async {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: '${company['nombre'] ?? ''}');
  final legalName = TextEditingController(
    text: '${company['razonSocial'] ?? ''}',
  );
  final email = TextEditingController(text: '${company['correo'] ?? ''}');
  final phone = TextEditingController(
    text: normalizePhoneNumber('${company['telefono'] ?? ''}'),
  );
  final address = TextEditingController(text: '${company['direccion'] ?? ''}');
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text('Editar empresa'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre comercial',
                    ),
                    validator:
                        (value) =>
                            (value ?? '').trim().length < 3
                                ? 'Escribe al menos 3 caracteres.'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: legalName,
                    decoration: const InputDecoration(
                      labelText: 'Razón social',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator:
                        (value) => validateEmailAddress(value, required: true),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)',
                    ),
                    validator: validatePhoneNumber,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
  );
  if (confirmed == true && context.mounted) {
    try {
      await store.updateResource(
        'empresas/mi-empresa',
        body: {
          'nombre': name.text.trim(),
          if (legalName.text.trim().isNotEmpty)
            'razonSocial': legalName.text.trim(),
          'correo': email.text.trim(),
          if (phone.text.trim().isNotEmpty) 'telefono': phone.text.trim(),
          if (address.text.trim().isNotEmpty) 'direccion': address.text.trim(),
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              store.dataError == null
                  ? 'Empresa actualizada.'
                  : 'Empresa actualizada, pero no se pudo refrescar: ${store.dataError}',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
  name.dispose();
  legalName.dispose();
  email.dispose();
  phone.dispose();
  address.dispose();
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
                subtitle: Text(
                  store.isAuthenticated && role != UserRole.admin
                      ? 'Solo un administrador puede actualizar el perfil'
                      : 'Nombre, correo y teléfono',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap:
                    !store.isAuthenticated || role == UserRole.admin
                        ? () => _editProfile(context, store, user)
                        : null,
              ),
              ListTile(
                leading: const IconBox(Icons.password_rounded),
                title: const Text('Cambiar contraseña'),
                subtitle: const Text('Actualiza tu contraseña de acceso'),
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
  BuildContext context,
  AppStore store,
  AppUser user,
) async {
  final name = TextEditingController(text: user.name);
  final email = TextEditingController(text: user.email);
  final phone = TextEditingController(text: normalizePhoneNumber(user.phone));
  final formKey = GlobalKey<FormState>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder:
        (sheetContext) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editar datos personales',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (value) {
                      final parts = (value ?? '').trim().split(RegExp(r'\s+'));
                      return parts.length < 2 ||
                              parts.first.length < 2 ||
                              parts.skip(1).join(' ').length < 2
                          ? 'Escribe nombre y apellido.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    enabled: !store.isAuthenticated,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator:
                        (value) =>
                            store.isAuthenticated
                                ? null
                                : validateEmailAddress(value, required: true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                    validator: validatePhoneNumber,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final nameParts = name.text.trim().split(RegExp(r'\s+'));
                      try {
                        if (store.isAuthenticated) {
                          final userId = int.tryParse(user.id ?? '');
                          if (userId == null) {
                            throw const ApiException(
                              'No se pudo identificar al usuario actual.',
                            );
                          }
                          await store.updateResource(
                            'usuarios/$userId',
                            body: {
                              'nombre': nameParts.first,
                              'apellido': nameParts.skip(1).join(' '),
                              if (phone.text.trim() !=
                                  normalizePhoneNumber(user.phone))
                                'telefono': phone.text.trim(),
                            },
                          );
                        }
                        store.updateCurrentUser(
                          name: name.text.trim(),
                          email:
                              store.isAuthenticated
                                  ? user.email
                                  : email.text.trim(),
                          phone: phone.text.trim(),
                        );
                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        if (context.mounted && store.isAuthenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                store.dataError == null
                                    ? 'Perfil actualizado en el servidor.'
                                    : 'Perfil actualizado, pero no se pudo refrescar: ${store.dataError}',
                              ),
                            ),
                          );
                        }
                      } on ApiException catch (error) {
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Guardar cambios'),
                  ),
                ],
              ),
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
  final store = context.read<AppStore>();
  final formKey = GlobalKey<FormState>();
  final apiClient = ApiClient();
  final pageContext = context;
  final isBackendSession = store.isAuthenticated;
  var isSaving = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder:
        (sheetContext) => StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Cambiar contraseña',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Usa al menos 8 caracteres para proteger tu cuenta.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: current,
                        obscureText: true,
                        onChanged: (_) => setModalState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Contraseña actual',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        validator:
                            (value) =>
                                (value ?? '').isEmpty
                                    ? 'Escribe tu contraseña actual.'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: password,
                        obscureText: true,
                        onChanged: (_) => setModalState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Nueva contraseña',
                          helperText: 'Mínimo 8 caracteres.',
                          prefixIcon: Icon(Icons.password_rounded),
                        ),
                        validator:
                            (value) =>
                                (value ?? '').length < 8
                                    ? 'Usa al menos 8 caracteres.'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmation,
                        obscureText: true,
                        onChanged: (_) => setModalState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña',
                          prefixIcon: Icon(Icons.verified_user_outlined),
                        ),
                        validator:
                            (value) =>
                                value != password.text
                                    ? 'Las contraseñas no coinciden.'
                                    : null,
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
                            onPressed:
                                isSaving
                                    ? null
                                    : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setModalState(() => isSaving = true);
                                      try {
                                        if (isBackendSession) {
                                          await apiClient.dio.patch<void>(
                                            'auth/contrasena/cambiar',
                                            data: {
                                              'contrasenaActual': current.text,
                                              'nuevaContrasena': password.text,
                                            },
                                          );
                                          await apiClient.tokenStorage
                                              .clearTokens();
                                          await store.signOut();
                                        }
                                        if (!sheetContext.mounted) return;
                                        Navigator.pop(sheetContext);
                                        if (pageContext.mounted) {
                                          if (isBackendSession) {
                                            pageContext.go('/login');
                                          }
                                          ScaffoldMessenger.of(
                                            pageContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isBackendSession
                                                    ? 'La contraseña se actualizó.'
                                                    : 'Contraseña actualizada.',
                                              ),
                                            ),
                                          );
                                        }
                                      } on DioException catch (error) {
                                        if (sheetContext.mounted) {
                                          ScaffoldMessenger.of(
                                            sheetContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                ApiException.fromDio(
                                                  error,
                                                ).message,
                                              ),
                                            ),
                                          );
                                        }
                                      } on ApiException catch (error) {
                                        if (sheetContext.mounted) {
                                          ScaffoldMessenger.of(
                                            sheetContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(error.message),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (sheetContext.mounted) {
                                          setModalState(() => isSaving = false);
                                        }
                                      }
                                    },
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                            label: Text(
                              isSaving ? 'Actualizando…' : 'Confirmar cambio',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
    final role = context.watch<AppStore>().role;
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
              for (final item in const [
                (
                  '¿Cómo se calcula la rentabilidad?',
                  'El reporte compara los ingresos de venta con los costos registrados en el ciclo. Al guardar nuevos movimientos, sincroniza la pantalla o vuelve a abrir el reporte para ver los indicadores actualizados.',
                ),
                (
                  '¿Por qué la merma puede no descontar kilos?',
                  'La merma se valida con la unidad de peso, su etapa y, cuando aplica, la cosecha de origen. Revisa que el registro esté ligado al ciclo y a la cosecha correctos; la API rechazará cambios que rompan el balance de masa.',
                ),
                (
                  '¿Cómo registro un cobro?',
                  'Abre Ventas, selecciona una venta y toca “Registrar cobro”. Captura fecha, monto y método de pago. El saldo pendiente y el estado se recalculan automáticamente.',
                ),
                (
                  '¿Puedo editar o eliminar una captura?',
                  'Puedes editar movimientos propios desde la bitácora cuando el servidor lo permite (por autoría, ventana de edición y estado del ciclo). La baja de movimientos y la eliminación de archivos requieren permisos de administrador.',
                ),
                (
                  '¿Cómo consulto archivos y exportaciones?',
                  'Usa el menú de acciones del registro o de la venta para agregar, consultar y descargar archivos. En Reportes selecciona PDF, XLSX o CSV y toca la opción de exportación.',
                ),
              ])
                ExpansionTile(
                  title: Text(item.$1),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(item.$2),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Accesos rápidos'),
        Card(
          child: Column(
            children: [
              if (role != UserRole.contador)
                ListTile(
                  leading: const Icon(Icons.add_circle_outline_rounded),
                  title: const Text('Capturar movimiento'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/capture'),
                ),
              if (role != UserRole.contador)
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Abrir bitácora'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/records'),
                ),
              if (role != UserRole.capturista)
                ListTile(
                  leading: const Icon(Icons.point_of_sale_outlined),
                  title: const Text('Consultar ventas'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/sales'),
                ),
              if (role != UserRole.capturista)
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('Abrir reportes'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/reports'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          title: 'Contacto de soporte no configurado',
          text:
              'Esta versión incluye guías y reportes descargables. Para habilitar contacto directo hace falta configurar un correo o canal oficial de soporte.',
          tone: AppColors.blue,
          icon: Icons.info_outline_rounded,
        ),
      ],
    );
  }
}
