import 'package:flutter/foundation.dart';

import 'models.dart';

class AppStore extends ChangeNotifier {
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

  AppUser? userForLogin(String email, UserRole userRole) {
    for (final user in users) {
      if (user.email.toLowerCase() == email.trim().toLowerCase() &&
          user.role == userRole) {
        return user;
      }
    }
    return null;
  }

  void signIn(AppUser user) {
    _sessionUser = user;
    role = user.role;
    notifyListeners();
  }

  void signOut() {
    _sessionUser = null;
    role = UserRole.admin;
    notifyListeners();
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
    record.value = updatedKind == 'Gasto' || updatedKind == 'Cosecha'
        ? value
        : null;
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

  void cancelSale(Sale sale) {
    sale.cancelled = true;
    auditEntries.insert(
      0,
      AuditEntry(
        title: 'Venta ${sale.id} cancelada',
        detail: 'Cancelar venta',
        ip: '192.168.1.12',
        date: DateTime.now(),
        before: 'Activa',
        after: 'Cancelada',
      ),
    );
    notifyListeners();
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
        'predios',
        'categorias',
        'perfil',
        'ayuda',
      }.contains(module);
    }
    return !const {'usuarios', 'empresa', 'auditoria'}.contains(module);
  }
}
