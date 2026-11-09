import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'backend_repository.dart';
import 'models.dart';

class AppStore extends ChangeNotifier {
  AppStore({
    AuthService? authService,
    BackendRepository? backendRepository,
    bool loadRemoteDataOnSignIn = true,
  }) : _authService = authService ?? BackendAuthService(),
       _backendRepository = backendRepository ?? BackendRepository(),
       _loadRemoteDataOnSignIn = loadRemoteDataOnSignIn;

  final AuthService _authService;
  final BackendRepository _backendRepository;
  final bool _loadRemoteDataOnSignIn;
  String? startupError;
  String? dataError;
  bool isLoadingData = false;
  final Map<String, List<Map<String, dynamic>>> catalogs = {};

  static const permissions = [
    'empresa:administrar',
    'usuario:administrar',
    'estructura:administrar',
    'catalogo:administrar',
    'tercero:administrar',
    'ciclo:crear',
    'ciclo:cerrar',
    'actividad:crear',
    'gasto:crear',
    'cosecha:crear',
    'merma:crear',
    'venta:ver',
    'venta:crear',
    'venta:cancelar',
    'cobro:ver',
    'cobro:crear',
    'reporte:ver',
    'reporte:exportar',
    'auditoria:ver',
  ];

  UserRole role = UserRole.admin;
  AppUser? _sessionUser;
  final List<FarmProperty> properties = [
    FarmProperty(
      id: 'encino',
      name: 'Predio El Encino',
      area: 12,
      location: 'Santa María del Tule, Oaxaca',
      parcels: [
        Parcel(
          id: 'p1',
          name: 'Parcela 1',
          area: 1.8,
          soil: 'Franco arcilloso',
        ),
        Parcel(
          id: 'p2',
          name: 'Parcela 2',
          area: 4.2,
          soil: 'Franco arcilloso',
        ),
        Parcel(
          id: 'p3',
          name: 'Parcela 3',
          area: 2.5,
          soil: 'Franco arcilloso',
        ),
        Parcel(id: 'p4', name: 'Parcela 4', area: 1.3, soil: 'Franco arenoso'),
      ],
    ),
  ];
  final List<BusinessPartner> clients = [
    BusinessPartner(
      id: 'c1',
      name: 'Central de Abastos',
      kind: 'MERCADO_MAYOREO',
      detail: 'Canal mayoreo',
      rfc: 'CAB920714K2A',
      phone: '951 555 0101',
      email: 'compras@central.mx',
    ),
    BusinessPartner(
      id: 'c2',
      name: 'Restaurantes del Valle',
      kind: 'RESTAURANTE',
      detail: 'Canal restaurante',
      rfc: 'RDV180322P8A',
      phone: '951 555 0132',
      email: 'compras@valle.mx',
    ),
    BusinessPartner(
      id: 'c3',
      name: 'Mercado Orgánico',
      kind: 'MENUDEO',
      detail: 'Contacto: Ana López',
      phone: '951 555 0180',
    ),
  ];
  final List<BusinessPartner> suppliers = [
    BusinessPartner(
      id: 's1',
      name: 'Agroinsumos Oaxaca',
      kind: 'Insumos',
      detail: '8 compras · \$18,450',
      rfc: 'AOA920714K2A',
      phone: '951 555 0161',
    ),
    BusinessPartner(
      id: 's2',
      name: 'Riegos del Sur',
      kind: 'Servicios',
      detail: '3 compras · \$12,000',
      phone: '951 555 0162',
    ),
    BusinessPartner(
      id: 's3',
      name: 'Semillas El Tule',
      kind: 'Semillas',
      detail: '5 compras · \$9,800',
      phone: '951 555 0163',
    ),
  ];
  final List<AppUser> users = [
    AppUser(
      name: 'Ramón Ortega',
      email: 'ramon@lospinos.mx',
      phone: '951 555 0142',
      role: UserRole.admin,
    ),
    AppUser(
      name: 'Luis Pérez',
      email: 'luis@lospinos.mx',
      phone: '951 555 0188',
      role: UserRole.capturista,
    ),
    AppUser(
      name: 'Marta Rangel',
      email: 'marta@lospinos.mx',
      phone: '951 555 0196',
      role: UserRole.contador,
    ),
  ];
  final List<AuditEntry> auditEntries = [
    AuditEntry(
      title: 'Ramón actualizó G-204',
      detail: 'Actualizar gasto',
      ip: '192.168.1.12',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      before: '\$7,900',
      after: '\$8,450',
    ),
  ];
  final List<ProfitabilityAlert> alerts = [
    ProfitabilityAlert(
      severity: 'Alta',
      title: 'Cobro vencido',
      detail: 'V-1037 · \$26,600 · 12 días',
    ),
    ProfitabilityAlert(
      severity: 'Media',
      title: 'Cobro tardío',
      detail: 'V-1042 · pago parcial sin movimiento en 8 días',
    ),
    ProfitabilityAlert(
      severity: 'Media',
      title: 'Costo por kg elevado',
      detail: 'Parcela 1 supera el precio promedio',
    ),
    ProfitabilityAlert(
      severity: 'Informativa',
      title: 'Meta productiva',
      detail: 'Tomate alcanzó 82%',
    ),
  ];
  final List<FarmCycle> cycles = [
    FarmCycle(
      id: 'tomate-p3',
      parcel: 'Parcela 3',
      crop: 'Tomate Saladette',
      status: CycleStatus.activo,
      area: 2.5,
      cost: 86000,
      income: 121000,
      harvestedKg: 8200,
      goalKg: 10000,
    ),
    FarmCycle(
      id: 'chile-p1',
      parcel: 'Parcela 1',
      crop: 'Chile de agua',
      status: CycleStatus.suspendido,
      area: 1.8,
      cost: 52000,
      income: 38500,
      harvestedKg: 4100,
      goalKg: 7000,
    ),
    FarmCycle(
      id: 'brocoli-p4',
      parcel: 'Parcela 4',
      crop: 'Brócoli',
      status: CycleStatus.planificado,
      area: 3,
      cost: 12000,
      income: 0,
      harvestedKg: 0,
      goalKg: 12000,
    ),
    FarmCycle(
      id: 'maiz-p2',
      parcel: 'Parcela 2',
      crop: 'Maíz',
      status: CycleStatus.finalizado,
      area: 4.2,
      cost: 64000,
      income: 88000,
      harvestedKg: 11500,
      goalKg: 11000,
    ),
  ];

  final List<Sale> sales = [
    Sale(
      id: 'V-1042',
      client: 'Central de Abastos',
      cycleId: 'tomate-p3',
      kg: 4200,
      total: 62000,
      paid: 42000,
      dueDate: DateTime.now().add(const Duration(days: 6)),
    ),
    Sale(
      id: 'V-1037',
      client: 'Restaurantes del Valle',
      cycleId: 'tomate-p3',
      kg: 1800,
      total: 26600,
      paid: 0,
      dueDate: DateTime.now().subtract(const Duration(days: 12)),
    ),
    Sale(
      id: 'V-1024',
      client: 'Mercado Orgánico',
      cycleId: 'maiz-p2',
      kg: 3000,
      total: 31000,
      paid: 31000,
      dueDate: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  final List<ActivityRecord> records = [
    ActivityRecord(
      title: 'Cosecha registrada',
      detail: 'Parcela 3 · 1,250 kg · Primera',
      kind: 'Cosecha',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      cycleId: 'tomate-p3',
      value: 1250,
      unit: 'kg',
    ),
    ActivityRecord(
      title: 'Aplicación foliar',
      detail: 'Parcela 3 · Desarrollo',
      kind: 'Actividad',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ActivityRecord(
      title: 'Compra de fertilizante',
      detail: 'Parcela 1 · \$8,450',
      kind: 'Gasto',
      date: DateTime.now().subtract(const Duration(days: 2)),
      cycleId: 'chile-p1',
      value: 8450,
      unit: 'MXN',
    ),
  ];

  FarmCycle cycle(String id) => cycles.firstWhere((item) => item.id == id);
  AppUser get currentUser =>
      _sessionUser ?? users.firstWhere((user) => user.role == role);
  bool get isAuthenticated => _sessionUser != null;
  bool notificationsEnabled = true;

  double availableKg(FarmCycle cycle) {
    final sold = sales
        .where((sale) => sale.cycleId == cycle.id && !sale.cancelled)
        .fold<double>(0, (sum, sale) => sum + sale.kg);
    return (cycle.harvestedKg - sold).clamp(0, double.infinity);
  }

  Future<void> restoreSession() async {
    try {
      final user = await _authService.restoreSession();
      if (user != null) {
        _sessionUser = user;
        role = user.role;
        _clearWorkspace();
        await loadWorkspace();
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        startupError = 'Tu sesión expiró. Inicia sesión de nuevo.';
      } else {
        startupError = error.message;
      }
    }
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    final user = await _authService.signIn(email: email, password: password);
    _sessionUser = user;
    role = user.role;
    startupError = null;
    _clearWorkspace();
    notifyListeners();
    if (_loadRemoteDataOnSignIn) await loadWorkspace();
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } finally {
      _sessionUser = null;
      role = UserRole.admin;
      _clearWorkspace();
      notifyListeners();
    }
  }

  Future<void> loadWorkspace() async {
    if (!isAuthenticated) return;
    isLoadingData = true;
    dataError = null;
    notifyListeners();
    try {
      final isAdmin = role == UserRole.admin;
      final isCapturista = role == UserRole.capturista;
      final canManagePartners = !isCapturista;
      final canViewSales = !isCapturista;
      final canViewActivities = !const {UserRole.contador}.contains(role);

      final requests = <String, Future<List<Map<String, dynamic>>>>{
        'cycles': _backendRepository.list(
          'ciclos',
          queryParameters: const {'page': 1, 'limit': 100},
        ),
        'activities':
            canViewActivities
                ? _backendRepository.list(
                  'actividades',
                  queryParameters: const {'page': 1, 'limit': 100},
                )
                : Future.value(const []),
        'expenses': _backendRepository.list(
          'gastos',
          queryParameters: const {'page': 1, 'limit': 100},
        ),
        'harvests':
            isCapturista || isAdmin
                ? _backendRepository.list(
                  'cosechas',
                  queryParameters: const {'page': 1, 'limit': 100},
                )
                : Future.value(const []),
        'losses':
            isCapturista || isAdmin
                ? _backendRepository.list(
                  'mermas',
                  queryParameters: const {'page': 1, 'limit': 100},
                )
                : Future.value(const []),
        'sales':
            canViewSales
                ? _backendRepository.list(
                  'ventas',
                  queryParameters: const {'page': 1, 'limit': 100},
                )
                : Future.value(const []),
        'properties':
            isAdmin
                ? _backendRepository.list('predios')
                : Future.value(const []),
        'parcels':
            isAdmin
                ? _backendRepository.list('parcelas')
                : Future.value(const []),
        'clients':
            canManagePartners
                ? _backendRepository.list(
                  'clientes',
                  queryParameters: const {'page': 1, 'limit': 100},
                )
                : Future.value(const []),
        'suppliers':
            canManagePartners
                ? _backendRepository.list(
                  'proveedores',
                  queryParameters: const {'page': 1, 'limit': 100},
                )
                : Future.value(const []),
        'expenseCategories': _backendRepository.list(
          'catalogos/categorias-gasto',
        ),
        'crops': _backendRepository.list('catalogos/cultivos'),
        'activityTypes': _backendRepository.list('catalogos/tipos-actividad'),
        'soilTypes': _backendRepository.list('catalogos/tipos-suelo'),
        'units': _backendRepository.list('catalogos/unidades-medida'),
        'lossReasons': _backendRepository.list('catalogos/motivos-merma'),
        'users':
            isAdmin
                ? _backendRepository.list('usuarios')
                : Future.value(const []),
        'audit':
            isAdmin
                ? _backendRepository.list(
                  'auditoria',
                  queryParameters: const {'page': 1, 'limit': 100},
                )
                : Future.value(const []),
      };

      final results = await Future.wait(
        requests.entries.map(
          (entry) async => MapEntry(entry.key, await entry.value),
        ),
      );
      final data = Map<String, List<Map<String, dynamic>>>.fromEntries(results);
      final varietyGroups = await Future.wait(
        data['crops']!.map(
          (crop) => _backendRepository.list(
            'catalogos/cultivos/${_id(crop['id'])}/variedades',
          ),
        ),
      );
      data['varieties'] = varietyGroups.expand((group) => group).toList();
      catalogs
        ..clear()
        ..addEntries(
          [
            'expenseCategories',
            'crops',
            'activityTypes',
            'soilTypes',
            'units',
            'lossReasons',
            'varieties',
          ].map((key) => MapEntry(key, data[key]!)),
        );
      _loadProperties(data['properties']!, data['parcels']!);
      _loadPartners(clients, data['clients']!, 'Cliente');
      _loadPartners(suppliers, data['suppliers']!, 'Proveedor');
      _loadUsers(data['users']!);
      _loadRecords(data);
      _loadSales(data['sales']!, data['units']!);
      _loadCycles(
        data['cycles']!,
        data['expenses']!,
        data['sales']!,
        data['harvests']!,
        data['units']!,
        data['varieties']!,
      );
      _loadAudit(data['audit']!);
    } on ApiException catch (error) {
      dataError = error.message;
    } finally {
      isLoadingData = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createResource(
    String path, {
    required Map<String, Object?> body,
  }) async {
    final result = await _backendRepository.create(path, body: body);
    await loadWorkspace();
    return result;
  }

  Future<Map<String, dynamic>> updateResource(
    String path, {
    required Map<String, Object?> body,
  }) async {
    final result = await _backendRepository.update(path, body: body);
    await loadWorkspace();
    return result;
  }

  Future<void> deleteResource(String path) async {
    await _backendRepository.delete(path);
    await loadWorkspace();
  }

  Future<void> cancelSale(Sale sale) async {
    await _backendRepository.patchAction('ventas/${sale.id}/cancelar');
    await loadWorkspace();
  }

  void _clearWorkspace() {
    properties.clear();
    clients.clear();
    suppliers.clear();
    users.clear();
    auditEntries.clear();
    alerts.clear();
    cycles.clear();
    sales.clear();
    records.clear();
    catalogs.clear();
    dataError = null;
  }

  void _loadProperties(
    List<Map<String, dynamic>> propertyRows,
    List<Map<String, dynamic>> parcelRows,
  ) {
    final parcelsByProperty = <String, List<Parcel>>{};
    for (final row in parcelRows) {
      final propertyId = _id(row['predioId']);
      parcelsByProperty
          .putIfAbsent(propertyId, () => [])
          .add(
            Parcel(
              id: _id(row['id']),
              name: _text(row['nombre'], fallback: 'Parcela'),
              area: _decimal(row['superficie']),
              soil: _text(
                row['tipoSueloNombre'],
                fallback: 'Sin tipo de suelo',
              ),
              coordinates: '${row['latitud'] ?? ''}, ${row['longitud'] ?? ''}',
            ),
          );
    }
    properties
      ..clear()
      ..addAll(
        propertyRows.map(
          (row) => FarmProperty(
            id: _id(row['id']),
            name: _text(row['nombre'], fallback: 'Predio'),
            area: _decimal(row['superficieTotal']),
            location: _text(
              row['ubicacion'],
              fallback: [
                row['municipio'],
                row['entidadFederativa'],
              ].whereType<String>().where((part) => part.isNotEmpty).join(', '),
            ),
            parcels: parcelsByProperty[_id(row['id'])] ?? [],
          ),
        ),
      );
  }

  void _loadPartners(
    List<BusinessPartner> destination,
    List<Map<String, dynamic>> rows,
    String defaultKind,
  ) {
    destination
      ..clear()
      ..addAll(
        rows.map(
          (row) => BusinessPartner(
            id: _id(row['id']),
            companyId: _integer(row['empresaId'], fallback: 0),
            name: _text(row['nombre'], fallback: defaultKind),
            kind: _text(row['tipo'], fallback: defaultKind),
            detail: _text(row['correo']),
            rfc: _text(row['rfc']),
            phone: _text(row['telefono']),
            email: _text(row['correo']),
            address: _text(row['direccion']),
            active: row['activo'] != false,
          ),
        ),
      );
  }

  void _loadUsers(List<Map<String, dynamic>> rows) {
    users
      ..clear()
      ..addAll(
        rows.map(
          (row) => AppUser(
            id: _id(row['id']),
            name: [
              _text(row['nombre']),
              _text(row['apellido']),
            ].where((part) => part.isNotEmpty).join(' '),
            email: _text(row['correo']),
            phone: _text(row['telefono']),
            active: row['activo'] != false,
            role: _userRole(row['rol']),
          ),
        ),
      );
    final current = _sessionUser;
    if (current != null && users.every((user) => user.email != current.email)) {
      users.insert(0, current);
    }
  }

  void _loadRecords(Map<String, List<Map<String, dynamic>>> data) {
    records
      ..clear()
      ..addAll(
        [
          for (final row in data['activities']!)
            ActivityRecord(
              id: _id(row['id']),
              title: _text(row['tipoActividadNombre'], fallback: 'Actividad'),
              detail: _text(row['descripcion']),
              kind: 'Actividad',
              date: _date(row['fecha']),
              cycleId: _id(row['cicloId']),
              value: _decimal(row['horasTrabajadas']),
              unit: 'h',
            ),
          for (final row in data['expenses']!)
            ActivityRecord(
              id: _id(row['id']),
              title: 'Gasto registrado',
              detail: _text(row['descripcion']),
              kind: 'Gasto',
              date: _date(row['fecha']),
              cycleId: _id(row['cicloId']),
              value: _decimal(row['total']),
              unit: 'MXN',
            ),
          for (final row in data['harvests']!)
            ActivityRecord(
              id: _id(row['id']),
              title: 'Cosecha registrada',
              detail: _text(row['observaciones']),
              kind: 'Cosecha',
              date: _date(row['fecha']),
              cycleId: _id(row['cicloId']),
              value: _decimal(row['cantidad']),
              unit: 'kg',
            ),
          for (final row in data['losses']!)
            ActivityRecord(
              id: _id(row['id']),
              title: 'Merma registrada',
              detail: _text(row['observaciones']),
              kind: 'Merma',
              date: _date(row['fecha']),
              cycleId: _id(row['cicloId']),
              value: _decimal(row['cantidad']),
              unit: 'kg',
            ),
        ]..sort((left, right) => right.date.compareTo(left.date)),
      );
  }

  void _loadSales(
    List<Map<String, dynamic>> rows,
    List<Map<String, dynamic>> units,
  ) {
    final unitFactors = {
      for (final unit in units) _id(unit['id']): _decimal(unit['factorABase']),
    };
    sales
      ..clear()
      ..addAll(
        rows.map((row) {
          final lineItems = row['renglones'];
          final kg =
              lineItems is List
                  ? lineItems.fold<double>(0, (sum, line) {
                    if (line is! Map) return sum;
                    final factor = unitFactors[_id(line['unidadId'])] ?? 1;
                    return sum + _decimal(line['cantidad']) * factor;
                  })
                  : 0.0;
          return Sale(
            id: _id(row['id']),
            client: _text(row['clienteNombre'], fallback: 'Cliente'),
            cycleId: _id(row['cicloId']),
            kg: kg,
            total: _decimal(row['total']),
            paid: _decimal(row['totalCobrado']),
            dueDate: _date(row['fechaLimitePago']),
            cancelled: row['estado'] == 'CANCELADA',
          );
        }),
      );
  }

  void _loadCycles(
    List<Map<String, dynamic>> cycleRows,
    List<Map<String, dynamic>> expenseRows,
    List<Map<String, dynamic>> saleRows,
    List<Map<String, dynamic>> harvestRows,
    List<Map<String, dynamic>> units,
    List<Map<String, dynamic>> varieties,
  ) {
    final unitFactors = {
      for (final unit in units) _id(unit['id']): _decimal(unit['factorABase']),
    };
    final varietyNames = {
      for (final variety in varieties)
        _id(variety['id']): _text(variety['nombre']),
    };
    final expenses = <String, double>{};
    for (final row in expenseRows) {
      final id = _id(row['cicloId']);
      expenses.update(
        id,
        (total) => total + _decimal(row['total']),
        ifAbsent: () => _decimal(row['total']),
      );
    }
    final incomes = <String, double>{};
    for (final row in saleRows) {
      if (row['estado'] == 'CANCELADA') continue;
      final id = _id(row['cicloId']);
      incomes.update(
        id,
        (total) => total + _decimal(row['total']),
        ifAbsent: () => _decimal(row['total']),
      );
    }
    final harvests = <String, double>{};
    for (final row in harvestRows) {
      final id = _id(row['cicloId']);
      final factor = unitFactors[_id(row['unidadId'])] ?? 1;
      harvests.update(
        id,
        (total) => total + _decimal(row['cantidad']) * factor,
        ifAbsent: () => _decimal(row['cantidad']) * factor,
      );
    }
    final parcelNames = {
      for (final property in properties)
        for (final parcel in property.parcels) parcel.id: parcel.name,
    };
    cycles
      ..clear()
      ..addAll(
        cycleRows.map((row) {
          final id = _id(row['id']);
          final parcelId = _id(row['parcelaId']);
          final varietyId = _id(row['variedadId']);
          final crop = varietyNames[varietyId] ?? '';
          return FarmCycle(
            id: id,
            parcel: _text(
              row['parcelaNombre'],
              fallback: parcelNames[parcelId] ?? 'Parcela $parcelId',
            ),
            crop:
                crop.isNotEmpty
                    ? crop
                    : _text(row['nombre'], fallback: 'Ciclo'),
            status: _cycleStatus(row['estado']),
            area: _decimal(row['superficieSembrada']),
            cost: expenses[id] ?? 0,
            income: incomes[id] ?? 0,
            harvestedKg: harvests[id] ?? 0,
            goalKg: _decimal(row['metaProduccionKg']),
            parcelId: parcelId,
            varietyId: varietyId,
          );
        }),
      );
  }

  void _loadAudit(List<Map<String, dynamic>> rows) {
    auditEntries
      ..clear()
      ..addAll(
        rows.map(
          (row) => AuditEntry(
            title: _text(row['accion'], fallback: 'Actividad auditada'),
            detail: '${_text(row['entidad'])} · ${_text(row['entidadId'])}',
            ip: _text(row['direccionIp']),
            date: _date(row['createdAt']),
            before: row['valoresAnteriores']?.toString(),
            after: row['valoresNuevos']?.toString(),
          ),
        ),
      );
  }

  void addRecord(
    String title,
    String detail,
    String kind, {
    String? cycleId,
    double? value,
    String? unit,
  }) {
    records.insert(
      0,
      ActivityRecord(
        title: title,
        detail: detail,
        kind: kind,
        date: DateTime.now(),
        cycleId: cycleId,
        value: value,
        unit: unit,
      ),
    );
    notifyListeners();
  }

  void editRecord(
    ActivityRecord record,
    String title,
    String detail, {
    String? kind,
    double? value,
  }) {
    final updatedKind = kind ?? record.kind;
    if (record.cycleId != null) {
      final cycle = this.cycle(record.cycleId!);
      if (record.value != null) {
        if (record.kind == 'Gasto') cycle.cost -= record.value!;
        if (record.kind == 'Cosecha') {
          cycle.harvestedKg -= record.value!;
        }
      }
      if (value != null) {
        if (updatedKind == 'Gasto') cycle.cost += value;
        if (updatedKind == 'Cosecha') cycle.harvestedKg += value;
      }
    }
    record.title = title;
    record.detail = detail;
    record.kind = updatedKind;
    record.value =
        updatedKind == 'Gasto' || updatedKind == 'Cosecha' ? value : null;
    record.unit = switch (updatedKind) {
      'Gasto' => 'MXN',
      'Cosecha' => 'kg',
      _ => null,
    };
    notifyListeners();
  }

  int deleteRecord(ActivityRecord record) {
    final index = records.indexOf(record);
    if (index < 0) return -1;
    _applyRecordMetric(record, -1);
    records.removeAt(index);
    notifyListeners();
    return index;
  }

  void restoreRecord(ActivityRecord record, int index) {
    _applyRecordMetric(record, 1);
    records.insert(index.clamp(0, records.length).toInt(), record);
    notifyListeners();
  }

  void _applyRecordMetric(ActivityRecord record, double direction) {
    if (record.cycleId == null || record.value == null) return;
    final linkedCycle = cycle(record.cycleId!);
    if (record.kind == 'Gasto') linkedCycle.cost += record.value! * direction;
    if (record.kind == 'Cosecha') {
      linkedCycle.harvestedKg += record.value! * direction;
    }
  }

  void addExpense(
    FarmCycle cycle,
    double total, {
    String? category,
    String? supplier,
    String? activity,
    String? unit,
  }) {
    cycle.cost += total;
    addRecord(
      'Gasto registrado',
      [
        cycle.parcel,
        if (category != null) category,
        '\$${total.toStringAsFixed(2)}',
        if (supplier != null) supplier,
        if (activity != null && activity != 'Sin actividad') activity,
        if (unit != null) unit,
      ].join(' · '),
      'Gasto',
      cycleId: cycle.id,
      value: total,
      unit: 'MXN',
    );
  }

  void addHarvest(FarmCycle cycle, double kg, {String? quality}) {
    cycle.harvestedKg += kg;
    addRecord(
      'Cosecha registrada',
      '${cycle.parcel} · ${kg.toStringAsFixed(2)} kg'
          '${quality == null ? '' : ' · $quality'}',
      'Cosecha',
      cycleId: cycle.id,
      value: kg,
      unit: 'kg',
    );
  }

  void addCycle(FarmCycle cycle) {
    cycles.add(cycle);
    addRecord('Ciclo creado', '${cycle.crop} · ${cycle.parcel}', 'Ciclo');
  }

  void addSale(
    FarmCycle cycle,
    double kg,
    double total, {
    String client = 'Cliente nuevo',
    String? detail,
  }) {
    sales.insert(
      0,
      Sale(
        id: 'V-${1043 + sales.length}',
        client: client,
        cycleId: cycle.id,
        kg: kg,
        total: total,
        paid: 0,
        dueDate: DateTime.now().add(const Duration(days: 15)),
      ),
    );
    cycle.income += total;
    addRecord(
      'Venta registrada',
      '${cycle.parcel} · ${kg.toStringAsFixed(0)} kg'
          '${detail == null ? '' : ' · $detail'}',
      'Venta',
    );
  }

  void addPayment(Sale sale, double amount, {String method = 'Efectivo'}) {
    sale.paid = (sale.paid + amount).clamp(0, sale.total);
    addRecord(
      'Cobro registrado',
      '${sale.id} · \$${amount.toStringAsFixed(2)} · $method',
      'Cobro',
    );
  }

  void addProperty(FarmProperty property) {
    properties.add(property);
    notifyListeners();
  }

  bool canAddParcel(FarmProperty property, double area) {
    return area > 0 && area <= property.availableArea;
  }

  void addParcel(FarmProperty property, Parcel parcel) {
    if (!canAddParcel(property, parcel.area)) return;
    property.parcels.add(parcel);
    notifyListeners();
  }

  void addUser(AppUser user) {
    if (users.length >= 5) return;
    users.add(user);
    notifyListeners();
  }

  void addClient(BusinessPartner client) {
    clients.add(client);
    notifyListeners();
  }

  void addSupplier(BusinessPartner supplier) {
    suppliers.add(supplier);
    notifyListeners();
  }

  void updateCurrentUser({
    required String name,
    required String email,
    required String phone,
  }) {
    final user = currentUser;
    user.name = name;
    user.email = email;
    user.phone = phone;
    notifyListeners();
  }

  void toggleUser(AppUser user) {
    if (user == currentUser) return;
    user.active = !user.active;
    notifyListeners();
  }

  void togglePartner(BusinessPartner partner) {
    partner.active = !partner.active;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  int deleteAlert(ProfitabilityAlert alert) {
    final index = alerts.indexOf(alert);
    if (index < 0) return -1;
    alerts.removeAt(index);
    notifyListeners();
    return index;
  }

  void restoreAlert(ProfitabilityAlert alert, int index) {
    alerts.insert(index.clamp(0, alerts.length).toInt(), alert);
    notifyListeners();
  }

  bool canAccess(String module) {
    if (role == UserRole.admin) return true;
    if (role == UserRole.capturista) {
      return const {
        'categorias',
        'perfil',
        'ayuda',
      }.contains(module);
    }
    return !const {'usuarios', 'empresa', 'auditoria'}.contains(module);
  }
}

String _id(Object? value) {
  if (value == null) {
    throw const ApiException('La API devolvió un identificador vacío.');
  }
  return value.toString();
}

String _text(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

double _decimal(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _integer(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime _date(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) {
    throw const ApiException('La API devolvió una fecha con formato inválido.');
  }
  return date.toLocal();
}

UserRole _userRole(Object? value) => switch (value) {
  'ADMIN' => UserRole.admin,
  'CAPTURISTA' => UserRole.capturista,
  'CONTADOR' => UserRole.contador,
  _ => throw const ApiException('La API devolvió un rol desconocido.'),
};

CycleStatus _cycleStatus(Object? value) => switch (value) {
  'ACTIVO' => CycleStatus.activo,
  'SUSPENDIDO' => CycleStatus.suspendido,
  'PLANIFICADO' => CycleStatus.planificado,
  'FINALIZADO' => CycleStatus.finalizado,
  'CANCELADO' => CycleStatus.cancelado,
  _ =>
    throw const ApiException('La API devolvió un estado de ciclo desconocido.'),
};
