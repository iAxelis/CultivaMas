enum UserRole { admin, capturista, contador }

enum CycleStatus { activo, suspendido, planificado, finalizado, cerrado }

enum PaymentStatus { pendiente, parcial, pagada, vencida }

class FarmCycle {
  FarmCycle({
    required this.id,
    required this.parcel,
    required this.crop,
    required this.status,
    required this.area,
    required this.cost,
    required this.income,
    required this.harvestedKg,
    required this.goalKg,
  });

  final String id;
  final String parcel;
  final String crop;
  CycleStatus status;
  final double area;
  double cost;
  double income;
  double harvestedKg;
  final double goalKg;

  double get profit => income - cost;
  double get margin => income == 0 ? 0 : profit / income;
  double get roi => cost == 0 ? 0 : profit / cost;
  double get costPerKg => harvestedKg == 0 ? 0 : cost / harvestedKg;
  double get pricePerKg => harvestedKg == 0 ? 0 : income / harvestedKg;
}

class Sale {
  Sale({
    required this.id,
    required this.client,
    required this.cycleId,
    required this.kg,
    required this.total,
    required this.paid,
    required this.dueDate,
    this.cancelled = false,
  });

  final String id;
  final String client;
  final String cycleId;
  final double kg;
  final double total;
  double paid;
  final DateTime dueDate;
  bool cancelled;

  PaymentStatus get status {
    if (paid >= total) return PaymentStatus.pagada;
    if (paid > 0) return PaymentStatus.parcial;
    if (dueDate.isBefore(DateTime.now())) return PaymentStatus.vencida;
    return PaymentStatus.pendiente;
  }
}

class ActivityRecord {
  ActivityRecord({
    required this.title,
    required this.detail,
    required this.kind,
    required this.date,
    this.cycleId,
    this.value,
    this.unit,
  });

  String title;
  String detail;
  String kind;
  final DateTime date;
  final String? cycleId;
  double? value;
  String? unit;
}

class Parcel {
  Parcel({
    required this.id,
    required this.name,
    required this.area,
    required this.soil,
    this.coordinates = '',
  });

  final String id;
  final String name;
  final double area;
  final String soil;
  final String coordinates;
}

class FarmProperty {
  FarmProperty({
    required this.id,
    required this.name,
    required this.area,
    required this.location,
    required this.parcels,
  });

  final String id;
  final String name;
  final double area;
  final String location;
  final List<Parcel> parcels;

  double get occupiedArea =>
      parcels.fold(0, (sum, parcel) => sum + parcel.area);
  double get availableArea => (area - occupiedArea).clamp(0, double.infinity);
}

class BusinessPartner {
  BusinessPartner({
    required this.id,
    this.companyId = 1,
    required this.name,
    required this.kind,
    required this.detail,
    this.rfc = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.active = true,
  });

  final String id;
  final int companyId;
  final String name;
  final String kind;
  final String detail;
  final String rfc;
  final String phone;
  final String email;
  final String address;
  bool active;
}

class AppUser {
  AppUser({
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.active = true,
  });

  String name;
  String email;
  final UserRole role;
  String phone;
  bool active;
}

class AuditEntry {
  AuditEntry({
    required this.title,
    required this.detail,
    required this.ip,
    required this.date,
    this.before,
    this.after,
  });

  final String title;
  final String detail;
  final String ip;
  final DateTime date;
  final String? before;
  final String? after;
}

class ProfitabilityAlert {
  ProfitabilityAlert({
    required this.severity,
    required this.title,
    required this.detail,
  });

  final String severity;
  final String title;
  final String detail;
}
