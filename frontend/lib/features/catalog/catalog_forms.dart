import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/api_client.dart';
import '../../data/models.dart';
import '../../data/store.dart';

class CatalogFormScreen extends StatefulWidget {
  const CatalogFormScreen({required this.type, super.key});

  final String type;

  @override
  State<CatalogFormScreen> createState() => _CatalogFormScreenState();
}

class _CatalogFormScreenState extends State<CatalogFormScreen> {
  final name = TextEditingController();
  final detail = TextEditingController();
  final area = TextEditingController();
  final rfc = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final lastName = TextEditingController();
  final password = TextEditingController();
  final coordinates = TextEditingController();
  UserRole role = UserRole.capturista;
  String clientType = 'OTRO';
  String selectedSoilType = '';
  bool active = true;
  bool isSaving = false;

  @override
  void dispose() {
    name.dispose();
    detail.dispose();
    area.dispose();
    rfc.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    lastName.dispose();
    password.dispose();
    coordinates.dispose();
    super.dispose();
  }

  String get title => switch (widget.type) {
        'property' => 'Nuevo predio · F-03',
        'parcel' => 'Nueva parcela · F-04',
        'user' => 'Nuevo usuario · F-02',
        'client' => 'Nuevo cliente',
        'supplier' => 'Nuevo proveedor',
        _ => 'Nuevo registro',
      };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final property = store.properties.isEmpty ? null : store.properties.first;
    final parsedArea = double.tryParse(area.text) ?? 0;
    final hasValidCoordinates =
        _coordinateValues != null || coordinates.text.trim().isEmpty;
    final valid = name.text.trim().isNotEmpty &&
        hasValidCoordinates &&
        (widget.type != 'property' || parsedArea > 0) &&
        (widget.type != 'parcel' ||
            property != null && store.canAddParcel(property, parsedArea)) &&
        (widget.type != 'user' ||
            detail.text.contains('@') &&
                lastName.text.trim().isNotEmpty &&
                password.text.length >= 6);
    if (widget.type == 'parcel' && property == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyState(
          title: 'Primero crea un predio',
          message: 'Las parcelas deben pertenecer a un predio existente.',
          actionLabel: 'Crear predio',
          onAction: () => context.push('/form/property'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: valid && !isSaving ? () => _save(store, property) : null,
          child: Text(isSaving ? 'Guardando…' : 'Guardar'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.type == 'parcel') ...[
            InfoBanner(
              title: '${property!.availableArea.toStringAsFixed(1)} ha disponibles',
              text: 'La suma de parcelas no puede superar ${property.area.toStringAsFixed(1)} ha.',
              tone: parsedArea > property.availableArea ? AppColors.red : AppColors.green,
              icon: Icons.square_foot_rounded,
            ),
            const SizedBox(height: 20),
          ],
          if (widget.type == 'user') ...[
            InfoBanner(
              title: '${5 - store.users.length} lugares disponibles',
              text: 'Plan Crecimiento · ${store.users.length} de 5 usuarios.',
              tone: AppColors.green,
              icon: Icons.group_add_rounded,
            ),
            const SizedBox(height: 20),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FieldBlock(
                    label: _nameLabel,
                    help: 'Campo requerido.',
                    child: TextFormField(
                      controller: name,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(hintText: _nameHint),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._specificFields(store, property),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _nameLabel => switch (widget.type) {
        'property' => 'Nombre del predio',
        'parcel' => 'Nombre de la parcela',
        'user' => 'Nombre',
        'client' => 'Nombre o razón social',
        'supplier' => 'Nombre del proveedor',
        _ => 'Nombre',
      };

  String get _nameHint => switch (widget.type) {
        'property' => 'Predio El Encino',
        'parcel' => 'Parcela 5',
        'user' => 'Nombre del usuario',
        'client' => 'Cliente',
        'supplier' => 'Proveedor',
        _ => 'Nombre',
      };

  List<Widget> _specificFields(AppStore store, FarmProperty? property) {
    if (widget.type == 'property' || widget.type == 'parcel') {
      if (property == null) return const [];
      final soilTypes = store.catalogs['soilTypes'] ?? [];
      final soilNames = soilTypes.map((row) => '${row['nombre']}').toList();
      if (store.isAuthenticated &&
          soilNames.isNotEmpty &&
          !soilNames.contains(selectedSoilType)) {
        selectedSoilType = soilNames.first;
      }
      return [
        FieldBlock(
          label: 'Superficie',
          help: widget.type == 'parcel'
              ? 'No puede superar ${property.availableArea.toStringAsFixed(1)} ha disponibles.'
              : 'Superficie total del predio.',
          child: TextFormField(
            controller: area,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: 'ha',
              errorText: widget.type == 'parcel' &&
                      (double.tryParse(area.text) ?? 0) > property.availableArea
                  ? 'Supera la superficie disponible'
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 20),
        FieldBlock(
          label: widget.type == 'parcel' ? 'Tipo de suelo' : 'Ubicación',
          help: widget.type == 'parcel'
              ? 'Se usa en la ficha agronómica.'
              : 'Municipio y estado.',
          child: widget.type == 'parcel' && store.isAuthenticated
              ? DropdownButtonFormField<String>(
                  initialValue: soilNames.contains(selectedSoilType)
                      ? selectedSoilType
                      : null,
                  items: [
                    for (final soilType in soilNames)
                      DropdownMenuItem(value: soilType, child: Text(soilType)),
                  ],
                  onChanged: (value) => setState(
                    () => selectedSoilType = value ?? '',
                  ),
                )
              : TextFormField(
                  controller: detail,
                  decoration: InputDecoration(
                    hintText: widget.type == 'parcel'
                        ? 'Franco arcilloso'
                        : 'Santa María del Tule, Oaxaca',
                  ),
                ),
        ),
        const SizedBox(height: 20),
        FieldBlock(
          label: 'Coordenadas',
          help: 'Opcional: latitud, longitud.',
          child: TextFormField(
            controller: coordinates,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '17.0466, -96.6360',
              errorText: coordinates.text.trim().isNotEmpty &&
                      _coordinateValues == null
                  ? 'Usa latitud, longitud con coordenadas válidas.'
                  : null,
            ),
          ),
        ),
      ];
    }
    if (widget.type == 'user') {
      return [
        FieldBlock(
          label: 'Apellido',
          help: 'Campo requerido.',
          child: TextFormField(
            controller: lastName,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Apellido del usuario'),
          ),
        ),
        const SizedBox(height: 20),
        FieldBlock(
          label: 'Correo',
          help: 'Se usará para iniciar sesión.',
          child: TextFormField(
            controller: detail,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'usuario@rancho.mx'),
          ),
        ),
        const SizedBox(height: 20),
        FieldBlock(
          label: 'Contraseña temporal',
          help: 'Mínimo 6 caracteres; el usuario podrá cambiarla después.',
          child: TextFormField(
            controller: password,
            onChanged: (_) => setState(() {}),
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Contraseña temporal'),
          ),
        ),
        const SizedBox(height: 20),
        FieldBlock(
          label: 'Rol',
          help: 'Los permisos se derivan automáticamente del rol.',
          child: DropdownButtonFormField<UserRole>(
            initialValue: role,
            items: const [
              DropdownMenuItem(value: UserRole.admin, child: Text('Administrador · 19 permisos')),
              DropdownMenuItem(value: UserRole.capturista, child: Text('Capturista · 4 permisos')),
              DropdownMenuItem(value: UserRole.contador, child: Text('Contador · Finanzas')),
            ],
            onChanged: (value) => setState(() => role = value!),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final permission in _permissionsForRole(role))
              StatusPill(permission, AppColors.green, icon: Icons.check_rounded),
          ],
        ),
      ];
    }
    return [
      const FieldBlock(
        label: 'ID',
        help: 'Se genera automáticamente al guardar.',
        child: TextField(
          enabled: false,
          decoration: InputDecoration(hintText: 'Autogenerado'),
        ),
      ),
      const SizedBox(height: 20),
      const FieldBlock(
        label: 'Empresa ID',
        help: 'Tenant actual del registro.',
        child: TextField(
          enabled: false,
          decoration: InputDecoration(hintText: '1'),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'RFC',
        help: 'Opcional, máximo 13 caracteres.',
        child: TextFormField(
          controller: rfc,
          maxLength: 13,
          decoration: const InputDecoration(hintText: 'RFC'),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: FieldBlock(
              label: 'Teléfono',
              help: 'Opcional.',
              child: TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '951 555 0142'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FieldBlock(
              label: 'Correo',
              help: 'Opcional.',
              child: TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'correo@empresa.mx'),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (widget.type == 'client')
        FieldBlock(
          label: 'Tipo de cliente',
          help: 'Valor por defecto: OTRO.',
          child: DropdownButtonFormField<String>(
            initialValue: clientType,
            items: const [
              DropdownMenuItem(value: 'MERCADO_MAYOREO', child: Text('Mercado mayoreo')),
              DropdownMenuItem(value: 'DISTRIBUIDOR', child: Text('Distribuidor')),
              DropdownMenuItem(value: 'SUPERMERCADO', child: Text('Supermercado')),
              DropdownMenuItem(value: 'RESTAURANTE', child: Text('Restaurante')),
              DropdownMenuItem(value: 'EXPORTADOR', child: Text('Exportador')),
              DropdownMenuItem(value: 'MENUDEO', child: Text('Menudeo')),
              DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
            ],
            onChanged: (value) => setState(() => clientType = value!),
          ),
        )
      else
        FieldBlock(
          label: 'Dirección',
          help: 'Opcional, máximo 300 caracteres.',
          child: TextFormField(
            controller: address,
            decoration: const InputDecoration(hintText: 'Dirección completa'),
          ),
        ),
      if (!store.isAuthenticated) ...[
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Estado activo'),
          subtitle: const Text('Activo por defecto'),
          value: active,
          onChanged: (value) => setState(() => active = value),
        ),
      ],
    ];
  }

  List<String> _permissionsForRole(UserRole value) {
    return switch (value) {
      UserRole.admin => AppStore.permissions,
      UserRole.capturista => const [
          'actividad:crear',
          'gasto:crear',
          'cosecha:crear',
          'merma:crear',
        ],
      UserRole.contador => const [
          'tercero:administrar',
          'venta:ver',
          'venta:crear',
          'venta:cancelar',
          'cobro:ver',
          'cobro:crear',
          'reporte:ver',
          'reporte:exportar',
        ],
    };
  }

  List<double>? get _coordinateValues {
    final value = coordinates.text.trim();
    if (value.isEmpty) return null;
    final parts = value.split(',');
    if (parts.length != 2) return null;
    final latitude = double.tryParse(parts[0].trim());
    final longitude = double.tryParse(parts[1].trim());
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return [latitude, longitude];
  }

  Map<String, Object?> _coordinatesPayload() {
    final values = _coordinateValues;
    if (coordinates.text.trim().isNotEmpty && values == null) {
      throw const ApiException('Revisa el formato de las coordenadas.');
    }
    if (values == null) return const {};
    return {'latitud': values[0], 'longitud': values[1]};
  }

  int _numericId(String? value, String label) {
    final id = int.tryParse(value ?? '');
    if (id == null) throw ApiException('No se pudo identificar $label.');
    return id;
  }

  Future<void> _save(AppStore store, FarmProperty? property) async {
    if (isSaving) return;
    setState(() => isSaving = true);
    try {
      switch (widget.type) {
        case 'property':
          if (store.isAuthenticated) {
            await store.createResource(
              'predios',
              body: {
                'nombre': name.text.trim(),
                'superficieTotal': double.parse(area.text),
                if (detail.text.trim().isNotEmpty)
                  'ubicacion': detail.text.trim(),
                ..._coordinatesPayload(),
              },
            );
          } else {
            store.addProperty(
              FarmProperty(
                id: 'property-${store.properties.length + 1}',
                name: name.text.trim(),
                area: double.parse(area.text),
                location: detail.text.trim(),
                parcels: [],
              ),
            );
          }
          break;
        case 'parcel':
          if (property == null) {
            throw const ApiException('Selecciona un predio para la parcela.');
          }
          if (store.isAuthenticated) {
            final soilRows = store.catalogs['soilTypes'] ?? [];
            final soilRow = soilRows.where(
              (row) => '${row['nombre']}' == selectedSoilType,
            );
            final soil = soilRow.isEmpty ? null : soilRow.first;
            await store.createResource(
              'parcelas',
              body: {
                'predioId': _numericId(property.id, 'predio'),
                'nombre': name.text.trim(),
                'superficie': double.parse(area.text),
                if (soil != null)
                  'tipoSueloId': _numericId('${soil['id']}', 'tipo de suelo'),
                ..._coordinatesPayload(),
              },
            );
          } else {
            store.addParcel(
              property,
              Parcel(
                id: 'parcel-${property.parcels.length + 1}',
                name: name.text.trim(),
                area: double.parse(area.text),
                soil: detail.text.trim(),
                coordinates: coordinates.text.trim(),
              ),
            );
          }
          break;
        case 'user':
          if (store.isAuthenticated) {
            await store.createResource(
              'usuarios',
              body: {
                'nombre': name.text.trim(),
                'apellido': lastName.text.trim(),
                'correo': detail.text.trim(),
                'contrasena': password.text,
                'rolCodigo': switch (role) {
                  UserRole.admin => 'ADMIN',
                  UserRole.capturista => 'CAPTURISTA',
                  UserRole.contador => 'CONTADOR',
                },
                if (phone.text.trim().isNotEmpty)
                  'telefono': phone.text.trim(),
              },
            );
          } else {
            store.addUser(
              AppUser(name: '${name.text.trim()} ${lastName.text.trim()}', email: detail.text.trim(), role: role),
            );
          }
          break;
        case 'client':
          if (store.isAuthenticated) {
            await store.createResource(
              'clientes',
              body: {
                'nombre': name.text.trim(),
                'tipo': clientType,
                if (rfc.text.trim().isNotEmpty) 'rfc': rfc.text.trim(),
                if (phone.text.trim().isNotEmpty)
                  'telefono': phone.text.trim(),
                if (email.text.trim().isNotEmpty)
                  'correo': email.text.trim(),
              },
            );
          } else {
            store.addClient(
              BusinessPartner(
                id: 'client-${store.clients.length + 1}',
                name: name.text.trim(),
                kind: clientType,
                detail: detail.text,
                rfc: rfc.text,
                phone: phone.text,
                email: email.text,
                active: active,
              ),
            );
          }
          break;
        case 'supplier':
          if (store.isAuthenticated) {
            await store.createResource(
              'proveedores',
              body: {
                'nombre': name.text.trim(),
                if (rfc.text.trim().isNotEmpty) 'rfc': rfc.text.trim(),
                if (phone.text.trim().isNotEmpty)
                  'telefono': phone.text.trim(),
                if (email.text.trim().isNotEmpty)
                  'correo': email.text.trim(),
                if (address.text.trim().isNotEmpty)
                  'direccion': address.text.trim(),
              },
            );
          } else {
            store.addSupplier(
              BusinessPartner(
                id: 'supplier-${store.suppliers.length + 1}',
                name: name.text.trim(),
                kind: 'Insumos',
                detail: detail.text,
                rfc: rfc.text,
                phone: phone.text,
                email: email.text,
                address: address.text,
                active: active,
              ),
            );
          }
          break;
        default:
          throw const ApiException('Este catálogo no se puede guardar desde aquí.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            store.isAuthenticated
                ? store.dataError == null
                    ? 'Registro guardado en el servidor.'
                    : 'Se guardó, pero no se pudo actualizar la información: ${store.dataError}'
                : 'Registro guardado en memoria.',
          ),
        ),
      );
      context.pop();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }
}
