import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
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
  UserRole role = UserRole.capturista;
  String clientType = 'OTRO';
  bool active = true;

  @override
  void dispose() {
    name.dispose();
    detail.dispose();
    area.dispose();
    rfc.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
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
    final property = store.properties.first;
    final parsedArea = double.tryParse(area.text) ?? 0;
    final valid = name.text.trim().isNotEmpty &&
        (widget.type != 'property' || parsedArea > 0) &&
        (widget.type != 'parcel' || store.canAddParcel(property, parsedArea)) &&
        (widget.type != 'user' || detail.text.contains('@'));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: valid ? () => _save(store, property) : null,
          child: const Text('Guardar'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.type == 'parcel') ...[
            InfoBanner(
              title: '${property.availableArea.toStringAsFixed(1)} ha disponibles',
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
        'user' => 'Nombre completo',
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

  List<Widget> _specificFields(AppStore store, FarmProperty property) {
    if (widget.type == 'property' || widget.type == 'parcel') {
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
          child: TextFormField(
            controller: detail,
            decoration: InputDecoration(
              hintText: widget.type == 'parcel'
                  ? 'Franco arcilloso'
                  : 'Santa María del Tule, Oaxaca',
            ),
          ),
        ),
        const SizedBox(height: 20),
        const FieldBlock(
          label: 'Coordenadas',
          help: 'Opcional en este wireframe.',
          child: TextField(
            decoration: InputDecoration(hintText: '17.0466, -96.6360'),
          ),
        ),
      ];
    }
    if (widget.type == 'user') {
      return [
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
      const SizedBox(height: 20),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Estado activo'),
        subtitle: const Text('Activo por defecto'),
        value: active,
        onChanged: (value) => setState(() => active = value),
      ),
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

  void _save(AppStore store, FarmProperty property) {
    switch (widget.type) {
      case 'property':
        store.addProperty(
          FarmProperty(
            id: 'property-${store.properties.length + 1}',
            name: name.text,
            area: double.tryParse(area.text) ?? 0,
            location: detail.text,
            parcels: [],
          ),
        );
        break;
      case 'parcel':
        store.addParcel(
          property,
          Parcel(
            id: 'parcel-${property.parcels.length + 1}',
            name: name.text,
            area: double.tryParse(area.text) ?? 0,
            soil: detail.text,
          ),
        );
        break;
      case 'user':
        store.addUser(AppUser(name: name.text, email: detail.text, role: role));
        break;
      case 'client':
        store.addClient(
          BusinessPartner(
            id: 'client-${store.clients.length + 1}',
            name: name.text,
            kind: clientType,
            detail: detail.text,
            rfc: rfc.text,
            phone: phone.text,
            email: email.text,
            active: active,
          ),
        );
        break;
      case 'supplier':
        store.addSupplier(
          BusinessPartner(
            id: 'supplier-${store.suppliers.length + 1}',
            name: name.text,
            kind: 'Insumos',
            detail: detail.text,
            rfc: rfc.text,
            phone: phone.text,
            email: email.text,
            address: address.text,
            active: active,
          ),
        );
        break;
      default:
        store.addRecord('$title guardado', name.text, 'Catálogo');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro guardado en memoria')),
    );
    context.pop();
  }
}
