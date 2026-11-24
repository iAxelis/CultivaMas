import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/api_client.dart';
import '../../data/models.dart';
import '../../data/store.dart';

class CatalogFormScreen extends StatefulWidget {
  const CatalogFormScreen({required this.type, this.recordId, super.key});

  final String type;
  final String? recordId;

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
  String? selectedPropertyId;
  String selectedSoilType = '';
  bool active = true;
  bool isSaving = false;
  bool _initialized = false;

  double? get _areaValue =>
      double.tryParse(area.text.trim().replaceAll(',', '.'));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized || widget.recordId == null) return;
    _initialized = true;
    final store = context.read<AppStore>();
    switch (widget.type) {
      case 'property':
        for (final item in store.properties) {
          if (item.id == widget.recordId) {
            name.text = item.name;
            area.text = item.area.toString();
            detail.text = item.location;
            break;
          }
        }
        break;
      case 'parcel':
        for (final item in store.properties) {
          for (final parcel in item.parcels) {
            if (parcel.id == widget.recordId) {
              name.text = parcel.name;
              area.text = parcel.area.toString();
              selectedPropertyId = item.id;
              selectedSoilType = parcel.soil;
              coordinates.text =
                  parcel.coordinates.trim() == ',' ? '' : parcel.coordinates;
            }
          }
        }
        break;
      case 'client':
      case 'supplier':
        final partners =
            widget.type == 'client' ? store.clients : store.suppliers;
        for (final partner in partners) {
          if (partner.id == widget.recordId) {
            name.text = partner.name;
            rfc.text = partner.rfc;
            phone.text = partner.phone;
            email.text = partner.email;
            address.text = partner.address;
            clientType = partner.kind;
            active = partner.active;
            break;
          }
        }
        break;
      case 'user':
        for (final user in store.users) {
          if (user.id == widget.recordId) {
            final nameParts = user.name.trim().split(RegExp(r'\s+'));
            name.text = nameParts.first;
            lastName.text = nameParts.skip(1).join(' ');
            detail.text = user.email;
            phone.text = user.phone;
            role = user.role;
            active = user.active;
            break;
          }
          break;
        }
    }
  }

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
        'property' => _isEditing ? 'Editar predio' : 'Nuevo predio · F-03',
        'parcel' => _isEditing ? 'Editar parcela' : 'Nueva parcela · F-04',
        'user' => _isEditing ? 'Editar usuario' : 'Nuevo usuario · F-02',
        'client' => _isEditing ? 'Editar cliente' : 'Nuevo cliente',
        'supplier' => _isEditing ? 'Editar proveedor' : 'Nuevo proveedor',
        _ => 'Nuevo registro',
      };

  bool get _isEditing => widget.recordId != null;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final property =
        store.properties.isEmpty
            ? null
            : store.properties.firstWhere(
              (item) => item.id == selectedPropertyId,
              orElse: () => store.properties.first,
            );
    final parsedArea = _areaValue ?? 0;
    final quotas = store.companyProfile?['cuotas'];
    final maxUsers =
        quotas is Map
            ? int.tryParse('${quotas['maxUsuarios']}') ?? 0
            : store.isAuthenticated
            ? 0
            : 5;
    final activeUsers =
        quotas is Map
            ? int.tryParse('${quotas['usuariosActivos']}') ?? store.users.length
            : store.users.length;
    final hasUserQuota =
        maxUsers > 0 && activeUsers < maxUsers;
    final hasValidCoordinates =
        _coordinateValues != null || coordinates.text.trim().isEmpty;
    final valid = name.text.trim().isNotEmpty &&
        hasValidCoordinates &&
        (widget.type != 'property' ||
            parsedArea > 0 &&
                (!_isEditing ||
                    property != null && parsedArea >= property.occupiedArea)) &&
        (widget.type != 'parcel' ||
            property != null &&
                (store.canAddParcel(property, parsedArea) ||
                    _isEditing &&
                        property.parcels.any(
                          (parcel) => parcel.id == widget.recordId,
                        ) &&
                        parsedArea <=
                            property.availableArea +
                                property.parcels
                                    .firstWhere(
                                      (parcel) => parcel.id == widget.recordId,
                                    )
                                    .area)) &&
        (widget.type != 'user' ||
            detail.text.contains('@') &&
                lastName.text.trim().isNotEmpty &&
                (_isEditing || password.text.length >= 6) &&
                (_isEditing || hasUserQuota));
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
              title:
                  maxUsers > 0
                      ? '$activeUsers de $maxUsers usuarios'
                      : 'Cuota de usuarios no disponible',
              text:
                  maxUsers > 0
                      ? 'Quedan ${maxUsers - activeUsers} lugares en el plan actual.'
                      : 'No se pudo consultar el límite vigente del plan.',
              tone:
                  hasUserQuota ? AppColors.green : AppColors.amber,
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
    if (widget.type == 'property') {
      return [
        FieldBlock(
          label: 'Superficie',
          help: 'Superficie total del predio en hectáreas.',
          child: TextFormField(
            controller: area,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(suffixText: 'ha'),
          ),
        ),
        const SizedBox(height: 20),
        FieldBlock(
          label: 'Ubicación',
          help: 'Municipio y estado (opcional).',
          child: TextFormField(
            controller: detail,
            decoration: const InputDecoration(hintText: 'Municipio, estado'),
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
              errorText:
                  coordinates.text.trim().isNotEmpty &&
                          _coordinateValues == null
                      ? 'Usa latitud, longitud con coordenadas válidas.'
                      : null,
            ),
          ),
        ),
      ];
    }
    if (widget.type == 'parcel') {
      if (property == null) return const [];
      final soilTypes = store.catalogs['soilTypes'] ?? [];
      final soilNames = soilTypes.map((row) => '${row['nombre']}').toList();
      if (store.isAuthenticated &&
          soilNames.isNotEmpty &&
          !soilNames.contains(selectedSoilType)) {
        selectedSoilType = soilNames.first;
      }
      return [
        if (store.properties.length > 1) ...[
          FieldBlock(
            label: 'Predio',
            help: 'Selecciona dónde se creará la parcela.',
            child: DropdownButtonFormField<String>(
              initialValue: property.id,
              items: [
                for (final item in store.properties)
                  DropdownMenuItem(value: item.id, child: Text(item.name)),
              ],
              onChanged:
                  (value) => setState(() => selectedPropertyId = value),
            ),
          ),
          const SizedBox(height: 20),
        ],
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
          help: _isEditing
              ? 'El correo de acceso no se puede cambiar desde esta pantalla.'
              : 'Se usará para iniciar sesión.',
          child: TextFormField(
            controller: detail,
            onChanged: (_) => setState(() {}),
            readOnly: _isEditing,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'usuario@rancho.mx'),
          ),
        ),
        if (!_isEditing) ...[
        const SizedBox(height: 20),
        FieldBlock(
          label: 'Contraseña temporal',
          help: 'Mínimo 6 caracteres; el usuario podrá cambiarla después.',
          child: TextFormField(
            controller: password,
            onChanged: (_) => setState(() {}),
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Contraseña temporal',
            ),
          ),
        ),
        ],
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
            final body = {
              'nombre': name.text.trim(),
              'superficieTotal': _areaValue!,
              if (detail.text.trim().isNotEmpty)
                'ubicacion': detail.text.trim(),
              ..._coordinatesPayload(),
            };
            if (_isEditing) {
              await store.updateResource(
                'predios/${widget.recordId}',
                body: body,
              );
            } else {
              await store.createResource(
                'predios',
                body: body,
              );
            }
          } else {
            store.addProperty(
              FarmProperty(
                id: 'property-${store.properties.length + 1}',
                name: name.text.trim(),
                area: _areaValue!,
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
            final body = {
                'predioId': _numericId(property.id, 'predio'),
                'nombre': name.text.trim(),
                'superficie': _areaValue!,
                if (soil != null)
                  'tipoSueloId': _numericId('${soil['id']}', 'tipo de suelo'),
                ..._coordinatesPayload(),
              };
            if (_isEditing) {
              await store.updateResource(
                'parcelas/${widget.recordId}',
                body: body,
              );
            } else {
              await store.createResource('parcelas', body: body);
            }
          } else {
            store.addParcel(
              property,
              Parcel(
                id: 'parcel-${property.parcels.length + 1}',
                name: name.text.trim(),
                area: _areaValue!,
                soil: detail.text.trim(),
                coordinates: coordinates.text.trim(),
              ),
            );
          }
          break;
        case 'user':
          if (store.isAuthenticated) {
            final body = _isEditing
                ? {
                    'nombre': name.text.trim(),
                    'apellido': lastName.text.trim(),
                    'rolCodigo': switch (role) {
                      UserRole.admin => 'ADMIN',
                      UserRole.capturista => 'CAPTURISTA',
                      UserRole.contador => 'CONTADOR',
                    },
                    if (phone.text.trim().isNotEmpty)
                      'telefono': phone.text.trim(),
                  }
                : {
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
              };
            if (_isEditing) {
              await store.updateResource(
                'usuarios/${widget.recordId}',
                body: body,
              );
            } else {
              await store.createResource('usuarios', body: body);
            }
          } else {
            store.addUser(
              AppUser(name: '${name.text.trim()} ${lastName.text.trim()}', email: detail.text.trim(), role: role),
            );
          }
          break;
        case 'client':
          if (store.isAuthenticated) {
            final body = {
                'nombre': name.text.trim(),
                'tipo': clientType,
                if (rfc.text.trim().isNotEmpty) 'rfc': rfc.text.trim(),
                if (phone.text.trim().isNotEmpty)
                  'telefono': phone.text.trim(),
                if (email.text.trim().isNotEmpty)
                  'correo': email.text.trim(),
              };
            if (_isEditing) {
              await store.updateResource(
                'clientes/${widget.recordId}',
                body: body,
              );
            } else {
              await store.createResource('clientes', body: body);
            }
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
            final body = {
                'nombre': name.text.trim(),
                if (rfc.text.trim().isNotEmpty) 'rfc': rfc.text.trim(),
                if (phone.text.trim().isNotEmpty)
                  'telefono': phone.text.trim(),
                if (email.text.trim().isNotEmpty)
                  'correo': email.text.trim(),
                if (address.text.trim().isNotEmpty)
                  'direccion': address.text.trim(),
              };
            if (_isEditing) {
              await store.updateResource(
                'proveedores/${widget.recordId}',
                body: body,
              );
            } else {
              await store.createResource('proveedores', body: body);
            }
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
                    ? _isEditing
                        ? 'Cambios guardados en el servidor.'
                        : 'Registro guardado en el servidor.'
                    : 'Se guardó, pero no se pudo actualizar la información: ${store.dataError}'
                : _isEditing
                    ? 'Cambios guardados.'
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
