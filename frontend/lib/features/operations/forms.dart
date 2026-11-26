import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validation.dart';
import '../../core/widgets.dart';
import '../../data/api_client.dart';
import '../../data/backend_repository.dart';
import '../../data/models.dart';
import '../../data/store.dart';

class DataFormScreen extends StatefulWidget {
  const DataFormScreen({
    required this.type,
    this.cycleId,
    this.saleId,
    super.key,
  });

  final String type;
  final String? cycleId;
  final String? saleId;

  @override
  State<DataFormScreen> createState() => _DataFormScreenState();
}

class _DataFormScreenState extends State<DataFormScreen> {
  final formKey = GlobalKey<FormState>();
  final quantityController = TextEditingController();
  final unitCostController = TextEditingController();
  final taxController = TextEditingController();
  final totalController = TextEditingController();
  final priceController = TextEditingController();
  final discountController = TextEditingController();
  final saleTaxController = TextEditingController();
  final cycleNameController = TextEditingController();
  final cycleDateController = TextEditingController();
  final cycleAreaController = TextEditingController();
  final cycleGoalController = TextEditingController();
  final dateController = TextEditingController();
  final dueDateController = TextEditingController();
  final detailController = TextEditingController();
  final referenceController = TextEditingController();
  final invoiceController = TextEditingController();
  String? cycleId;
  String? selectedParcel;
  String selectedVariety = '';
  String unit = 'kg';
  String activityType = 'Aplicación foliar';
  String responsible = '';
  String expenseCategory = '';
  String supplierId = '';
  String linkedActivity = 'Sin actividad';
  String expenseUnit = 'pieza';
  String stage = 'POSCOSECHA';
  String lossOrigin = 'Sin cosecha específica';
  String lossReason = 'Daño mecánico';
  String quality = 'Primera';
  String saleClient = '';
  String saleOrigin = 'Sin origen específico';
  String saleUnit = 'kg';
  String paymentMethod = 'Efectivo';
  String closeReason = 'Fin de temporada';
  final BackendRepository _filesRepository = BackendRepository();
  String? attachmentName;
  Uint8List? attachmentBytes;
  bool totalMatches = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    cycleId = widget.cycleId;
    final today = DateTime.now();
    dateController.text = formatDateInput(today);
    cycleDateController.text = formatDateInput(today);
    dueDateController.text = formatDateInput(
      today.add(const Duration(days: 15)),
    );
    quantityController.addListener(_recalculate);
    unitCostController.addListener(_recalculate);
    taxController.addListener(_recalculate);
    totalController.addListener(_recalculate);
  }

  @override
  void dispose() {
    quantityController.dispose();
    unitCostController.dispose();
    taxController.dispose();
    totalController.dispose();
    priceController.dispose();
    discountController.dispose();
    saleTaxController.dispose();
    cycleNameController.dispose();
    cycleDateController.dispose();
    cycleAreaController.dispose();
    cycleGoalController.dispose();
    dateController.dispose();
    dueDateController.dispose();
    detailController.dispose();
    referenceController.dispose();
    invoiceController.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller) {
    return parseDecimal(controller.text) ?? 0;
  }

  double get expectedTotal {
    return _number(quantityController) * _number(unitCostController) +
        _number(taxController);
  }

  double get convertedKg {
    final amount = _number(quantityController);
    return switch (unit) {
      'ton' => amount * 1000,
      'caja' => amount * 20,
      _ => amount,
    };
  }

  double get saleConvertedKg {
    final amount = _number(quantityController);
    return switch (saleUnit) {
      'ton' => amount * 1000,
      'caja' => amount * 20,
      _ => amount,
    };
  }

  double get saleSubtotal =>
      _number(quantityController) * _number(priceController);

  double get saleTotal =>
      saleSubtotal - _number(discountController) + _number(saleTaxController);

  String _dateValue(TextEditingController controller, {DateTime? fallback}) {
    final value = controller.text.trim();
    if (value.isEmpty) return _dateOnly(fallback ?? DateTime.now());
    final isoDate = DateTime.tryParse(value);
    if (isoDate != null) return _dateOnly(isoDate);
    final parts = value.split('/');
    if (parts.length == 3) {
      final date = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
      if (date != null) return _dateOnly(date);
    }
    throw const ApiException('La fecha debe tener formato dd/mm/aaaa.');
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  int _numericId(String? value, String label) {
    final id = int.tryParse(value ?? '');
    if (id == null) throw ApiException('Selecciona $label válido.');
    return id;
  }

  Map<String, dynamic> _rowByName(
    List<Map<String, dynamic>> rows,
    String name,
    String label,
  ) {
    for (final row in rows) {
      if ('${row['nombre']}'.toLowerCase() == name.toLowerCase()) return row;
    }
    throw ApiException('Selecciona $label del catálogo vigente.');
  }

  List<Map<String, dynamic>> _expenseCategoryRows(AppStore store) {
    final rows = <Map<String, dynamic>>[];
    for (final category in store.catalogs['expenseCategories'] ?? []) {
      rows.add(category);
      final children = category['subcategorias'];
      if (children is List) {
        rows.addAll(children.whereType<Map>().map(Map<String, dynamic>.from));
      }
    }
    return rows;
  }

  int _unitId(AppStore store, String label) {
    final key = label.toLowerCase();
    final units = store.catalogs['units'] ?? [];
    for (final row in units) {
      final code = '${row['codigo']}'.toLowerCase();
      final name = '${row['nombre']}'.toLowerCase();
      final matches = switch (key) {
        'kg' => code == 'kg' || name.contains('kilogram'),
        'ton' => code.contains('ton') || name.contains('tonelada'),
        'caja' => code.contains('caja') || name.contains('caja'),
        'pieza' => code.contains('pieza') || name.contains('pieza'),
        'litro' => code.contains('litro') || name.contains('litro'),
        'hora' => code.contains('hora') || name.contains('hora'),
        _ => code == key || name == key,
      };
      if (matches) return _numericId('${row['id']}', 'unidad');
    }
    throw ApiException('La unidad "$label" no está en el catálogo vigente.');
  }

  String _qualityCode(String value) => switch (value.toLowerCase()) {
    'extra' => 'EXTRA',
    'primera' => 'PRIMERA',
    'segunda' => 'SEGUNDA',
    'tercera' => 'TERCERA',
    'industria' || 'industrial' => 'INDUSTRIAL',
    _ => throw const ApiException('Selecciona una calidad válida.'),
  };

  String? _positiveNumberError(String? value, String label) {
    final number = parseDecimal(value ?? '');
    if (number == null) return '$label es obligatorio y debe ser numérico.';
    if (number <= 0) return '$label debe ser mayor que cero.';
    return null;
  }

  String? _optionalNonNegativeNumberError(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return null;
    final number = parseDecimal(value!);
    if (number == null) return '$label debe ser un número válido.';
    if (number < 0) return '$label no puede ser negativo.';
    return null;
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required String help,
    required String validationLabel,
  }) {
    return FieldBlock(
      label: label,
      help: help,
      child: DatePickerField(controller: controller, label: validationLabel),
    );
  }

  Widget _fieldPair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 16), second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  void _recalculate() {
    if (!mounted) return;
    final supplied = _number(totalController);
    setState(() {
      totalMatches = supplied == 0 || (supplied - expectedTotal).abs() < .01;
    });
  }

  String get title => switch (widget.type) {
    'cycle' => 'Nuevo ciclo · F-07',
    'close' => 'Cerrar ciclo · F-14',
    'activity' => 'Registrar actividad · F-08',
    'expense' => 'Registrar gasto · F-09',
    'harvest' => 'Registrar cosecha · F-10',
    'loss' => 'Registrar merma · F-11',
    'sale' => 'Nueva venta · F-12',
    'payment' => 'Registrar cobro · F-13',
    _ => 'Nuevo registro',
  };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    if (cycleId == null && widget.type != 'cycle' && store.cycles.isNotEmpty) {
      final eligible = store.cycles.where(
        (cycle) =>
            cycle.status == CycleStatus.activo ||
            cycle.status == CycleStatus.suspendido,
      );
      if (eligible.isNotEmpty) cycleId = eligible.first.id;
    }
    final parcels = store.properties.expand((property) => property.parcels);
    final occupiedParcelIds =
        store.cycles
            .where((cycle) => cycle.status == CycleStatus.activo)
            .map((cycle) => cycle.parcelId)
            .whereType<String>()
            .toSet();
    final availableParcels =
        parcels
            .where((parcel) => !occupiedParcelIds.contains(parcel.id))
            .toList();
    if (widget.type == 'cycle' &&
        selectedParcel == null &&
        availableParcels.isNotEmpty) {
      selectedParcel = availableParcels.first.id;
    }
    final varieties = store.catalogs['varieties'] ?? [];
    final varietyNames = varieties.map((row) => '${row['nombre']}').toList();
    if (widget.type == 'cycle' &&
        varietyNames.isNotEmpty &&
        !varietyNames.contains(selectedVariety)) {
      selectedVariety = varietyNames.first;
    }
    final hasEligibleCycle = store.cycles.any(
      (cycle) =>
          cycle.status == CycleStatus.activo ||
          cycle.status == CycleStatus.suspendido,
    );
    if (widget.type == 'cycle' &&
        (availableParcels.isEmpty || varieties.isEmpty)) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyState(
          title:
              availableParcels.isEmpty
                  ? 'Necesitas una parcela disponible'
                  : 'No hay variedades disponibles',
          message:
              availableParcels.isEmpty
                  ? store.properties.isEmpty
                      ? 'Primero crea un predio y agrega una parcela. Después podrás volver aquí para crear el ciclo.'
                      : 'Agrega una parcela disponible en Predios y parcelas, o finaliza un ciclo existente.'
                  : store.dataError ??
                      'No se pudo cargar el catálogo de variedades. Vuelve a intentar la sincronización.',
          actionLabel:
              availableParcels.isEmpty ? 'Configurar predios' : 'Reintentar',
          onAction:
              availableParcels.isEmpty
                  ? () => context.push('/module/predios')
                  : () async => store.loadWorkspace(),
        ),
      );
    }
    if (widget.type != 'cycle' &&
        widget.type != 'payment' &&
        !hasEligibleCycle) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyState(
          title: 'No hay ciclos disponibles',
          message:
              'Primero debe existir un ciclo activo para registrar movimientos.',
          actionLabel: 'Volver',
          onAction: () => context.pop(),
        ),
      );
    }
    if (widget.type == 'sale' &&
        store.clients.every((client) => !client.active)) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyState(
          title: 'No hay clientes activos',
          message: 'Agrega un cliente antes de registrar una venta.',
          actionLabel: 'Volver',
          onAction: () => context.pop(),
        ),
      );
    }
    final locked =
        cycleId != null &&
        widget.type != 'payment' &&
        (store.cycle(cycleId!).status == CycleStatus.finalizado ||
            store.cycle(cycleId!).status == CycleStatus.cerrado);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: locked || isSaving ? null : () => _save(store),
          icon: const Icon(Icons.check_rounded),
          label: Text(isSaving ? 'Guardando…' : 'Guardar'),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (locked) ...[
              const InfoBanner(
                title: 'Ciclo finalizado',
                text:
                    'La captura está bloqueada. Solo se permiten cobros pendientes.',
                tone: AppColors.amber,
                icon: Icons.lock_rounded,
              ),
              const SizedBox(height: 20),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _fields(store),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  bool _canSave(AppStore store) {
    if (widget.type == 'expense') return totalMatches && expectedTotal > 0;
    if (widget.type == 'sale') {
      if (cycleId == null) return false;
      final cycle = store.cycle(cycleId!);
      return _number(quantityController) > 0 &&
          saleConvertedKg <= store.availableKg(cycle) &&
          _number(priceController) > 0 &&
          _number(discountController) >= 0 &&
          _number(discountController) <= saleSubtotal &&
          _number(saleTaxController) >= 0 &&
          saleTotal > 0;
    }
    if (widget.type == 'harvest' || widget.type == 'loss') {
      return cycleId != null && convertedKg > 0;
    }
    if (widget.type == 'cycle') {
      final parcel = _firstOrNull(
        store.properties
            .expand((property) => property.parcels)
            .where((item) => item.id == selectedParcel),
      );
      final plantedArea = parseDecimal(cycleAreaController.text) ?? 0;
      return parcel != null &&
          cycleDateController.text.isNotEmpty &&
          plantedArea > 0 &&
          plantedArea <= parcel.area &&
          _number(cycleGoalController) > 0;
    }
    if (widget.type == 'payment') {
      final matches = store.sales.where((item) => item.id == widget.saleId);
      if (matches.isEmpty) return false;
      final sale = matches.first;
      final amount = _number(totalController);
      return amount > 0 && amount <= sale.total - sale.paid;
    }
    if (widget.type == 'activity') {
      return cycleId != null &&
          (quantityController.text.trim().isEmpty ||
              _number(quantityController) >= .01);
    }
    return cycleId != null;
  }

  String? _validationMessage(AppStore store) {
    if (widget.type != 'cycle' && widget.type != 'payment' && cycleId == null) {
      return 'Selecciona un ciclo para continuar.';
    }
    switch (widget.type) {
      case 'expense':
        if (expenseCategory.isEmpty) {
          return 'Selecciona una categoría de gasto.';
        }
        if (_number(quantityController) <= 0) {
          return 'La cantidad debe ser mayor que cero.';
        }
        if (_number(unitCostController) <= 0) {
          return 'El costo unitario debe ser mayor que cero.';
        }
        if (_number(taxController) < 0) {
          return 'El impuesto no puede ser negativo.';
        }
        if (!totalMatches) {
          return 'El total debe coincidir con cantidad × costo unitario + impuesto.';
        }
        break;
      case 'sale':
        if (saleClient.isEmpty) return 'Selecciona un cliente activo.';
        if (_number(quantityController) <= 0) {
          return 'La cantidad debe ser mayor que cero.';
        }
        if (cycleId != null &&
            saleConvertedKg > store.availableKg(store.cycle(cycleId!))) {
          return 'La cantidad supera el producto disponible.';
        }
        if (_number(priceController) <= 0) {
          return 'El precio debe ser mayor que cero.';
        }
        if (_number(discountController) < 0 ||
            _number(discountController) > saleSubtotal) {
          return 'El descuento debe estar entre cero y el subtotal.';
        }
        if (_number(saleTaxController) < 0) {
          return 'El impuesto no puede ser negativo.';
        }
        if (saleTotal <= 0) {
          return 'El total de la venta debe ser mayor que cero.';
        }
        break;
      case 'harvest':
      case 'loss':
        if (_number(quantityController) <= 0) {
          return 'La cantidad debe ser mayor que cero.';
        }
        break;
      case 'payment':
        final matches = store.sales.where((item) => item.id == widget.saleId);
        if (matches.isEmpty) return 'No se encontró la venta del cobro.';
        final sale = matches.first;
        if (_number(totalController) <= 0) {
          return 'El importe del cobro debe ser mayor que cero.';
        }
        if (_number(totalController) > sale.total - sale.paid) {
          return 'El cobro no puede superar el saldo pendiente.';
        }
        break;
      case 'cycle':
        final parcel = _firstOrNull(
          store.properties
              .expand((property) => property.parcels)
              .where((item) => item.id == selectedParcel),
        );
        if (parcel == null) return 'Selecciona una parcela disponible.';
        final area = parseDecimal(cycleAreaController.text) ?? 0;
        if (area <= 0) return 'La superficie sembrada debe ser mayor que cero.';
        if (area > parcel.area) {
          return 'La superficie sembrada supera la parcela seleccionada.';
        }
        if (_number(cycleGoalController) <= 0) {
          return 'La meta de producción debe ser mayor que cero.';
        }
        break;
      case 'activity':
        if (quantityController.text.trim().isNotEmpty &&
            _number(quantityController) < .01) {
          return 'Las horas trabajadas deben ser mayores que cero.';
        }
        break;
      case 'close':
        if (cycleId == null) return 'Selecciona el ciclo que vas a finalizar.';
        break;
    }
    return null;
  }

  List<Widget> _fields(AppStore store) {
    final fields = switch (widget.type) {
      'expense' => _expenseFields(store),
      'harvest' => _harvestFields(store),
      'loss' => _lossFields(store),
      'sale' => _saleFields(store),
      'payment' => _paymentFields(store),
      'cycle' => _cycleFields(store),
      'close' => _closeFields(store),
      _ => _activityFields(store),
    };
    if (!const {
      'expense',
      'activity',
      'sale',
      'payment',
    }.contains(widget.type)) {
      return fields;
    }
    return [...fields, const SizedBox(height: 20), _attachmentPicker()];
  }

  Widget _attachmentPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: isSaving ? null : _pickAttachment,
          icon: const Icon(Icons.attach_file_rounded),
          label: Text(
            attachmentName == null
                ? 'Adjuntar archivo (opcional)'
                : 'Cambiar archivo',
          ),
        ),
        if (attachmentName != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(attachmentName!)),
              IconButton(
                tooltip: 'Quitar archivo',
                onPressed:
                    isSaving
                        ? null
                        : () => setState(() {
                          attachmentName = null;
                          attachmentBytes = null;
                        }),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
        const Text('PDF, JPG, PNG o WEBP · máximo 10 MB'),
      ],
    );
  }

  Future<void> _pickAttachment() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final size = await file.length();
      if (size == null || size > 10 * 1024 * 1024) {
        throw const ApiException('El archivo debe pesar como máximo 10 MB.');
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        attachmentName = file.name;
        attachmentBytes = bytes;
      });
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message ?? 'No se pudo seleccionar el archivo.',
            ),
          ),
        );
      }
    }
  }

  Widget _cycleSelector(AppStore store) {
    return FieldBlock(
      label: 'Ciclo',
      help: 'El registro quedará ligado a este ciclo.',
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: cycleId,
        items: [
          for (final cycle in store.cycles.where(
            (item) =>
                item.status == CycleStatus.activo ||
                item.status == CycleStatus.suspendido,
          ))
            DropdownMenuItem(
              value: cycle.id,
              child: Text('${cycle.crop} · ${cycle.parcel}'),
            ),
        ],
        onChanged: (value) => setState(() => cycleId = value),
        validator: (value) => value == null ? 'Selecciona un ciclo.' : null,
      ),
    );
  }

  List<Widget> _activityFields(AppStore store) {
    final activityRows = store.catalogs['activityTypes'] ?? [];
    final activityNames =
        activityRows.map((row) => '${row['nombre']}').toList();
    if (activityNames.isNotEmpty && !activityNames.contains(activityType)) {
      activityType = activityNames.first;
    }
    final responsibleUsers = [
      ...store.users,
      if (store.users.every((user) => user.email != store.currentUser.email))
        store.currentUser,
    ];
    final responsibleNames = responsibleUsers.map((user) => user.name).toList();
    if (responsibleNames.isNotEmpty &&
        !responsibleNames.contains(responsible)) {
      responsible = responsibleNames.first;
    }
    return [
      _cycleSelector(store),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Actividad',
        help: 'Selecciona la labor realizada.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue:
              activityNames.contains(activityType) ? activityType : null,
          items: [
            for (final name in activityNames)
              DropdownMenuItem(value: name, child: Text(name)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => activityType = value);
          },
          validator:
              (value) => value == null ? 'Selecciona una actividad.' : null,
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Responsable',
        help: 'Usuario asignado, opcional.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue:
              responsibleNames.contains(responsible) ? responsible : null,
          items: [
            for (final userName in responsibleNames)
              DropdownMenuItem(value: userName, child: Text(userName)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => responsible = value);
          },
        ),
      ),
      const SizedBox(height: 20),
      _dateField(
        controller: dateController,
        label: 'Fecha',
        help: 'Fecha de ejecución de la labor.',
        validationLabel: 'la fecha de ejecución',
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Horas trabajadas',
        help: 'Opcional; si se captura, debe ser mayor que cero.',
        child: TextFormField(
          controller: quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) return null;
            return _positiveNumberError(value, 'Las horas trabajadas');
          },
          decoration: const InputDecoration(suffixText: 'h', hintText: '0'),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Descripción',
        help: 'Opcional. Agrega dosis, clima u observaciones.',
        child: TextFormField(
          controller: detailController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escribe una observación',
          ),
        ),
      ),
    ];
  }

  List<Widget> _expenseFields(AppStore store) {
    final categoryRows = _expenseCategoryRows(store);
    final categories = categoryRows.map((row) => '${row['nombre']}').toList();
    if (expenseCategory.isEmpty && categories.isNotEmpty) {
      expenseCategory = categories.first;
    }
    if (categories.isNotEmpty && !categories.contains(expenseCategory)) {
      expenseCategory = categories.first;
    }
    final activeSuppliers =
        store.suppliers.where((supplier) => supplier.active).toList();
    if (activeSuppliers.isNotEmpty &&
        !activeSuppliers.any((supplier) => supplier.id == supplierId)) {
      supplierId = activeSuppliers.first.id;
    }
    final activityRecords =
        store.records
            .where(
              (record) =>
                  record.kind == 'Actividad' &&
                  (cycleId == null || record.cycleId == cycleId),
            )
            .toList();
    final expenseUnits =
        (store.catalogs['units'] ?? [])
            .where(
              (row) => const {
                'PESO',
                'VOLUMEN',
                'AREA',
                'TIEMPO',
                'CONTEO',
              }.contains(row['tipo']),
            )
            .map((row) => '${row['nombre']}')
            .toList();
    if (expenseUnits.isNotEmpty && !expenseUnits.contains(expenseUnit)) {
      expenseUnit = expenseUnits.first;
    }
    return [
      _cycleSelector(store),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Categoría',
        help: 'Se usa para el desglose de costos.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue:
              categories.contains(expenseCategory) ? expenseCategory : null,
          items: [
            for (final category in categories)
              DropdownMenuItem(value: category, child: Text(category)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => expenseCategory = value);
          },
          validator:
              (value) =>
                  value == null ? 'Selecciona una categoría de gasto.' : null,
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Proveedor',
        help:
            'CAPTURISTA puede seleccionar proveedores activos sin abrir el catálogo.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue:
              activeSuppliers.any((item) => item.id == supplierId)
                  ? supplierId
                  : null,
          items: [
            for (final supplier in activeSuppliers)
              DropdownMenuItem(value: supplier.id, child: Text(supplier.name)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => supplierId = value);
          },
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Actividad vinculada',
        help: 'Opcional; debe pertenecer al mismo ciclo.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: linkedActivity,
          items: [
            const DropdownMenuItem(
              value: 'Sin actividad',
              child: Text('Sin actividad'),
            ),
            for (final record in activityRecords)
              DropdownMenuItem(
                value: record.id ?? record.title,
                child: Text(record.title),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => linkedActivity = value);
          },
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Unidad de medida',
        help: 'Opcional.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: expenseUnits.contains(expenseUnit) ? expenseUnit : null,
          items: [
            for (final item in expenseUnits)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => expenseUnit = value);
          },
          validator:
              (value) =>
                  value == null ? 'Selecciona una unidad de medida.' : null,
        ),
      ),
      const SizedBox(height: 20),
      _dateField(
        controller: dateController,
        label: 'Fecha',
        help: 'Fecha del egreso.',
        validationLabel: 'la fecha del egreso',
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Descripción / concepto',
        help: 'Opcional, máximo 500 caracteres.',
        child: TextFormField(
          controller: detailController,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Concepto del gasto'),
        ),
      ),
      const SizedBox(height: 20),
      _fieldPair(
        FieldBlock(
          label: 'Cantidad',
          help: 'Unidades',
          child: TextFormField(
            controller: quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) => _positiveNumberError(value, 'La cantidad'),
            decoration: const InputDecoration(hintText: '10'),
          ),
        ),
        FieldBlock(
          label: 'Costo unitario',
          help: 'Antes de impuesto',
          child: TextFormField(
            controller: unitCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator:
                (value) => _positiveNumberError(value, 'El costo unitario'),
            decoration: const InputDecoration(
              prefixText: '\$ ',
              hintText: '800',
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Impuesto',
        help: 'Importe total de impuestos.',
        child: TextFormField(
          controller: taxController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator:
              (value) => _optionalNonNegativeNumberError(value, 'El impuesto'),
          decoration: const InputDecoration(prefixText: '\$ '),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Total del comprobante',
        help:
            totalMatches
                ? 'Coincide con cantidad × costo unitario + impuesto.'
                : 'No coincide. Esperado: ${moneyExact.format(expectedTotal)}',
        child: TextFormField(
          controller: totalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final error = _optionalNonNegativeNumberError(value, 'El total');
            if (error != null) return error;
            if (value != null && value.trim().isNotEmpty && !totalMatches) {
              return 'Debe coincidir con el total calculado.';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixText: '\$ ',
            errorText: totalMatches ? null : 'Revisa el total',
          ),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Número de comprobante',
        help: 'Opcional, máximo 60 caracteres.',
        child: TextFormField(controller: referenceController),
      ),
    ];
  }

  List<Widget> _harvestFields(AppStore store) {
    return [
      _cycleSelector(store),
      const SizedBox(height: 20),
      _dateField(
        controller: dateController,
        label: 'Fecha',
        help: 'Fecha del evento de recolección.',
        validationLabel: 'la fecha de cosecha',
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Cantidad cosechada',
        help: 'Captura la cantidad en la unidad usada en campo.',
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator:
                    (value) =>
                        _positiveNumberError(value, 'La cantidad cosechada'),
                decoration: const InputDecoration(hintText: '0'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: unit,
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'ton', child: Text('ton')),
                  DropdownMenuItem(value: 'caja', child: Text('caja')),
                ],
                onChanged: (value) => setState(() => unit = value!),
                validator:
                    (value) => value == null ? 'Selecciona una unidad.' : null,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      InfoBanner(
        title: 'Conversión automática',
        text:
            '${quantity.format(convertedKg)} kg se sumarán a la producción cosechada.',
        tone: AppColors.green,
        icon: Icons.sync_alt_rounded,
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Calidad',
        help: 'Se usará para disponibilidad y ventas.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: quality,
          items: const [
            DropdownMenuItem(value: 'Extra', child: Text('Extra')),
            DropdownMenuItem(value: 'Primera', child: Text('Primera')),
            DropdownMenuItem(value: 'Segunda', child: Text('Segunda')),
            DropdownMenuItem(value: 'Tercera', child: Text('Tercera')),
            DropdownMenuItem(value: 'Industria', child: Text('Industria')),
          ],
          onChanged: (value) => setState(() => quality = value!),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Observaciones',
        help: 'Opcional, máximo 500 caracteres.',
        child: TextFormField(
          controller: detailController,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Notas de calidad'),
        ),
      ),
    ];
  }

  List<Widget> _lossFields(AppStore store) {
    final lossReasons = store.catalogs['lossReasons'] ?? [];
    final lossReasonNames =
        lossReasons.map((row) => '${row['nombre']}').toList();
    if (lossReasonNames.isNotEmpty && !lossReasonNames.contains(lossReason)) {
      lossReason = lossReasonNames.first;
    }
    final harvestRecords =
        store.records
            .where(
              (record) =>
                  record.kind == 'Cosecha' &&
                  (cycleId == null || record.cycleId == cycleId),
            )
            .toList();
    final harvestIds =
        harvestRecords
            .where((record) => record.id != null)
            .map((record) => record.id!)
            .toSet();
    if (lossOrigin != 'Sin cosecha específica' &&
        !harvestIds.contains(lossOrigin)) {
      lossOrigin = 'Sin cosecha específica';
    }
    return [
      _cycleSelector(store),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Etapa de la merma',
        help: 'Define si la merma reduce o no el inventario cosechado.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: stage,
          items: const [
            DropdownMenuItem(value: 'CAMPO', child: Text('Campo')),
            DropdownMenuItem(value: 'POSCOSECHA', child: Text('Poscosecha')),
            DropdownMenuItem(value: 'TRANSPORTE', child: Text('Transporte')),
            DropdownMenuItem(value: 'ALMACEN', child: Text('Almacén')),
          ],
          onChanged: (value) => setState(() => stage = value!),
        ),
      ),
      const SizedBox(height: 12),
      InfoBanner(
        title:
            stage == 'CAMPO'
                ? 'No resta de lo cosechado'
                : 'Sí resta del disponible',
        text:
            stage == 'CAMPO'
                ? 'La merma en campo registra producción potencial perdida; nunca entró al inventario.'
                : 'La merma poscosecha salió de producto ya cosechado y reduce los kg disponibles.',
        tone: stage == 'CAMPO' ? AppColors.blue : AppColors.earth,
        icon:
            stage == 'CAMPO' ? Icons.info_rounded : Icons.remove_circle_rounded,
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Cosecha de origen',
        help: 'Opcional, debe pertenecer al mismo ciclo.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: lossOrigin,
          items: [
            const DropdownMenuItem(
              value: 'Sin cosecha específica',
              child: Text('Sin cosecha específica'),
            ),
            for (final record in harvestRecords)
              if (record.id != null)
                DropdownMenuItem(value: record.id, child: Text(record.title)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => lossOrigin = value);
          },
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Unidad de medida',
        help: 'Obligatoria.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: unit,
          items: const [
            DropdownMenuItem(value: 'kg', child: Text('kg')),
            DropdownMenuItem(value: 'ton', child: Text('ton')),
            DropdownMenuItem(value: 'caja', child: Text('caja 20 kg')),
          ],
          onChanged: (value) => setState(() => unit = value!),
          validator: (value) => value == null ? 'Selecciona una unidad.' : null,
        ),
      ),
      const SizedBox(height: 20),
      _dateField(
        controller: dateController,
        label: 'Fecha',
        help: 'Fecha de la merma.',
        validationLabel: 'la fecha de la merma',
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Cantidad',
        help: 'Expresada en kilogramos.',
        child: TextFormField(
          controller: quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator:
              (value) => _positiveNumberError(value, 'La cantidad de merma'),
          decoration: const InputDecoration(suffixText: 'kg', hintText: '0'),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Observaciones',
        help: 'Opcional, máximo 500 caracteres.',
        child: TextFormField(
          controller: detailController,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Notas de la merma'),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Causa',
        help: 'Ayuda a detectar patrones de pérdida.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue:
              lossReasonNames.contains(lossReason) ? lossReason : null,
          items: [
            for (final reason in lossReasonNames)
              DropdownMenuItem(value: reason, child: Text(reason)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => lossReason = value);
          },
          validator:
              (value) =>
                  value == null ? 'Selecciona una causa de merma.' : null,
        ),
      ),
    ];
  }

  List<Widget> _saleFields(AppStore store) {
    final cycle = store.cycle(cycleId!);
    final available = store.availableKg(cycle);
    final requested = saleConvertedKg;
    final exceeded = requested > available;
    final activeClients =
        store.clients.where((client) => client.active).toList();
    if (activeClients.isNotEmpty &&
        !activeClients.any((client) => client.name == saleClient)) {
      saleClient = activeClients.first.name;
    }
    final harvestRecords =
        store.records
            .where(
              (record) =>
                  record.kind == 'Cosecha' &&
                  record.cycleId == cycleId &&
                  record.id != null,
            )
            .toList();
    if (saleOrigin != 'Sin origen específico' &&
        harvestRecords.every((record) => record.id != saleOrigin)) {
      saleOrigin = 'Sin origen específico';
    }
    return [
      _cycleSelector(store),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.greenSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.strongGreenSurface),
        ),
        child: Row(
          children: [
            const IconBox(Icons.inventory_2_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: _SaleAvailability(
                available: available,
                requested: requested,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Cliente',
        help: 'Selecciona quién recibe la venta.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue:
              activeClients.any((client) => client.name == saleClient)
                  ? saleClient
                  : null,
          items: [
            for (final client in activeClients)
              DropdownMenuItem(value: client.name, child: Text(client.name)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => saleClient = value);
          },
          validator:
              (value) => value == null ? 'Selecciona un cliente activo.' : null,
        ),
      ),
      const SizedBox(height: 20),
      _dateField(
        controller: dateController,
        label: 'Fecha',
        help: 'Fecha de la operación comercial.',
        validationLabel: 'la fecha de la venta',
      ),
      const SizedBox(height: 20),
      _fieldPair(
        FieldBlock(
          label: 'Número de factura',
          help: 'Opcional.',
          child: TextFormField(controller: invoiceController),
        ),
        _dateField(
          controller: dueDateController,
          label: 'Fecha límite',
          help: 'Fecha prevista de pago.',
          validationLabel: 'la fecha límite de pago',
        ),
      ),
      const SizedBox(height: 20),
      _fieldPair(
        FieldBlock(
          label: 'Descuento',
          help: 'No puede superar el subtotal.',
          child: TextFormField(
            controller: discountController,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final error = _optionalNonNegativeNumberError(
                value,
                'El descuento',
              );
              if (error != null) return error;
              if ((parseDecimal(value ?? '') ?? 0) > saleSubtotal) {
                return 'No puede superar el subtotal.';
              }
              return null;
            },
            decoration: const InputDecoration(
              prefixText: '\$ ',
              hintText: '0.00',
            ),
          ),
        ),
        FieldBlock(
          label: 'Impuesto',
          help: 'Impuesto total trasladado.',
          child: TextFormField(
            controller: saleTaxController,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator:
                (value) =>
                    _optionalNonNegativeNumberError(value, 'El impuesto'),
            decoration: const InputDecoration(
              prefixText: '\$ ',
              hintText: '0.00',
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text('RENGLÓN 1', style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: saleOrigin,
                decoration: const InputDecoration(
                  labelText: 'Cosecha de origen',
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'Sin origen específico',
                    child: Text('Sin origen específico'),
                  ),
                  for (final record in harvestRecords)
                    DropdownMenuItem(
                      value: record.id,
                      child: Text(record.title),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => saleOrigin = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: saleUnit,
                decoration: const InputDecoration(labelText: 'Unidad'),
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'ton', child: Text('ton')),
                  DropdownMenuItem(value: 'caja', child: Text('caja 20 kg')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => saleUnit = value);
                },
                validator:
                    (value) => value == null ? 'Selecciona una unidad.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: quality,
                decoration: const InputDecoration(labelText: 'Calidad'),
                items: const [
                  DropdownMenuItem(value: 'Extra', child: Text('Extra')),
                  DropdownMenuItem(value: 'Primera', child: Text('Primera')),
                  DropdownMenuItem(value: 'Segunda', child: Text('Segunda')),
                  DropdownMenuItem(value: 'Tercera', child: Text('Tercera')),
                  DropdownMenuItem(
                    value: 'Industria',
                    child: Text('Industrial'),
                  ),
                ],
                onChanged: (value) => setState(() => quality = value!),
                validator:
                    (value) => value == null ? 'Selecciona una calidad.' : null,
              ),
              const SizedBox(height: 12),
              _fieldPair(
                TextFormField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final error = _positiveNumberError(value, 'La cantidad');
                    if (error != null) return error;
                    if (exceeded) return 'Supera el producto disponible.';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    suffixText: saleUnit == 'caja' ? 'caja 20 kg' : saleUnit,
                  ),
                ),
                TextFormField(
                  controller: priceController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator:
                      (value) => _positiveNumberError(value, 'El precio'),
                  decoration: InputDecoration(
                    labelText: 'Precio / $saleUnit',
                    prefixText: '\$ ',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Text('Total')),
                  Text(
                    moneyExact.format(saleTotal),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      const SizedBox(height: 20),
      const InfoBanner(
        title: 'Estado de cobro automático',
        text:
            'No se edita: se deriva del total cobrado y de la fecha de vencimiento.',
        tone: AppColors.blue,
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Notas',
        help: 'Opcional, máximo 500 caracteres.',
        child: TextFormField(
          controller: detailController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Condiciones de la venta',
          ),
        ),
      ),
    ];
  }

  List<Widget> _paymentFields(AppStore store) {
    final sale = store.sales.firstWhere((item) => item.id == widget.saleId);
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.greenSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.strongGreenSurface),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sale.client, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '${sale.id} · Saldo ${moneyExact.format(sale.total - sale.paid)}',
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _dateField(
        controller: dateController,
        label: 'Fecha',
        help: 'Fecha de recepción del pago.',
        validationLabel: 'la fecha del cobro',
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Importe del cobro',
        help:
            'No puede superar ${moneyExact.format(sale.total - sale.paid)} de saldo.',
        child: TextFormField(
          controller: totalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator:
              (value) => _positiveNumberError(value, 'El importe del cobro'),
          decoration: const InputDecoration(
            prefixText: '\$ ',
            hintText: '0.00',
          ),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Método',
        help: 'Dato informativo para conciliación.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: paymentMethod,
          items: const [
            DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
            DropdownMenuItem(
              value: 'Transferencia',
              child: Text('Transferencia'),
            ),
            DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
            DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
            DropdownMenuItem(value: 'Otro', child: Text('Otro')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => paymentMethod = value);
          },
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Referencia',
        help: 'Opcional. Captura la referencia del movimiento.',
        child: TextFormField(
          controller: referenceController,
          decoration: const InputDecoration(hintText: 'Referencia'),
        ),
      ),
    ];
  }

  List<Widget> _cycleFields(AppStore store) {
    final parcels = store.properties.expand((property) => property.parcels);
    final occupied =
        store.cycles
            .where((cycle) => cycle.status == CycleStatus.activo)
            .map((cycle) => cycle.parcelId)
            .whereType<String>()
            .toSet();
    final available =
        parcels.where((parcel) => !occupied.contains(parcel.id)).toList();
    final varieties = store.catalogs['varieties'] ?? [];
    final selectedParcelArea =
        _firstOrNull(
          available.where((parcel) => parcel.id == selectedParcel),
        )?.area;
    return [
      const InfoBanner(
        text: 'Las parcelas con otro ciclo activo se excluyen automáticamente.',
        tone: AppColors.green,
        icon: Icons.filter_alt_rounded,
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Parcela disponible',
        help:
            '${occupied.length} parcelas se ocultaron por tener un ciclo activo.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: selectedParcel,
          items: [
            for (final parcel in available)
              DropdownMenuItem(value: parcel.id, child: Text(parcel.name)),
          ],
          onChanged: (value) => setState(() => selectedParcel = value),
          validator:
              (value) => value == null ? 'Selecciona una parcela.' : null,
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Variedad',
        help: 'Selecciona la variedad activa del catálogo.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: selectedVariety,
          items: [
            for (final variety in varieties)
              DropdownMenuItem(
                value: '${variety['nombre']}',
                child: Text('${variety['nombre']}'),
              ),
          ],
          onChanged: (value) => setState(() => selectedVariety = value!),
          validator:
              (value) => value == null ? 'Selecciona una variedad.' : null,
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Nombre del ciclo',
        help: 'Opcional.',
        child: TextFormField(controller: cycleNameController),
      ),
      const SizedBox(height: 20),
      _dateField(
        controller: cycleDateController,
        label: 'Fecha de inicio',
        help: 'Primera labor, incluida preparación del suelo.',
        validationLabel: 'la fecha de inicio',
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Superficie sembrada',
        help: 'No debe exceder la superficie de la parcela.',
        child: TextFormField(
          controller: cycleAreaController,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator:
              (value) => _positiveNumberError(value, 'La superficie sembrada'),
          decoration: InputDecoration(
            suffixText: 'ha',
            hintText: '0.00',
            errorText:
                selectedParcelArea != null &&
                        (parseDecimal(cycleAreaController.text) ?? 0) >
                            selectedParcelArea
                    ? 'Supera ${selectedParcelArea.toStringAsFixed(2)} ha'
                    : null,
          ),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Meta de producción',
        help: 'Se usará en el anillo de avance.',
        child: TextFormField(
          controller: cycleGoalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator:
              (value) => _positiveNumberError(value, 'La meta de producción'),
          decoration: const InputDecoration(
            suffixText: 'kg',
            hintText: '12,000',
          ),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Observaciones',
        help: 'Opcional.',
        child: TextFormField(
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Notas del ciclo'),
        ),
      ),
    ];
  }

  List<Widget> _closeFields(AppStore store) {
    final cycle = store.cycle(cycleId!);
    return [
      HeroCard(
        eyebrow: 'Resultado al cierre',
        value: money.format(cycle.profit),
        subtitle:
            'Margen ${(cycle.margin * 100).toStringAsFixed(2)}% · ROI ${(cycle.roi * 100).toStringAsFixed(2)}%',
      ),
      const SizedBox(height: 20),
      const InfoBanner(
        title: 'Hay ventas sin cobrar',
        text:
            'Cerrar el ciclo bloquea la captura, pero los cobros seguirán permitidos.',
        tone: AppColors.amber,
        icon: Icons.warning_rounded,
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Motivo de cierre',
        help: 'Quedará registrado en la auditoría.',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: closeReason,
          items: const [
            DropdownMenuItem(
              value: 'Fin de temporada',
              child: Text('Fin de temporada'),
            ),
            DropdownMenuItem(value: 'Cancelación', child: Text('Cancelación')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => closeReason = value);
          },
        ),
      ),
    ];
  }

  Future<void> _save(AppStore store) async {
    if (isSaving) return;
    if (!formKey.currentState!.validate()) return;
    final validationMessage = _validationMessage(store);
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }
    if (!_canSave(store)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa los campos marcados antes de guardar.'),
        ),
      );
      return;
    }
    setState(() => isSaving = true);
    try {
      final selectedCycleId = cycleId;
      final cycleNumericId =
          selectedCycleId == null ? null : _numericId(selectedCycleId, 'ciclo');
      Map<String, dynamic>? createdResource;
      switch (widget.type) {
        case 'activity':
          final activityTypeRow = _rowByName(
            store.catalogs['activityTypes'] ?? [],
            activityType,
            'un tipo de actividad',
          );
          final user = _firstOrNull(
            store.users.where((item) => item.name == responsible),
          );
          final responsibleId = user?.id ?? store.currentUser.id;
          createdResource = await store.createResource(
            'actividades',
            body: {
              'cicloId': cycleNumericId,
              'tipoActividadId': _numericId(
                '${activityTypeRow['id']}',
                'tipo de actividad',
              ),
              if (responsibleId != null)
                'responsableId': _numericId(responsibleId, 'responsable'),
              'fecha': _dateValue(dateController),
              if (quantityController.text.trim().isNotEmpty)
                'horasTrabajadas': _number(quantityController),
              'descripcion': detailController.text.trim(),
            },
          );
          break;
        case 'expense':
          final category = _rowByName(
            _expenseCategoryRows(store),
            expenseCategory,
            'una categoría de gasto',
          );
          createdResource = await store.createResource(
            'gastos',
            body: {
              'cicloId': cycleNumericId,
              'categoriaId': _numericId('${category['id']}', 'categoría'),
              'cantidad': _number(quantityController).toString(),
              'costoUnitario': _number(unitCostController).toString(),
              'impuesto': _number(taxController).toString(),
              'total': expectedTotal.toStringAsFixed(2),
              'unidadId': _unitId(store, expenseUnit),
              'fecha': _dateValue(dateController),
              'descripcion': detailController.text.trim(),
              if (supplierId.isNotEmpty)
                'proveedorId': _numericId(supplierId, 'proveedor'),
              if (linkedActivity != 'Sin actividad')
                'actividadId': _numericId(linkedActivity, 'actividad'),
              if (referenceController.text.trim().isNotEmpty)
                'numeroComprobante': referenceController.text.trim(),
            },
          );
          break;
        case 'harvest':
          await store.createResource(
            'cosechas',
            body: {
              'cicloId': cycleNumericId,
              'cantidad': _number(quantityController).toString(),
              'unidadId': _unitId(store, unit),
              'calidad': _qualityCode(quality),
              'fecha': _dateValue(dateController),
              if (detailController.text.trim().isNotEmpty)
                'observaciones': detailController.text.trim(),
            },
          );
          break;
        case 'loss':
          final reason = _rowByName(
            store.catalogs['lossReasons'] ?? [],
            lossReason,
            'un motivo de merma',
          );
          await store.createResource(
            'mermas',
            body: {
              'cicloId': cycleNumericId,
              'cantidad': _number(quantityController).toString(),
              'unidadId': _unitId(store, unit),
              'motivoId': _numericId('${reason['id']}', 'motivo'),
              'etapa': stage,
              'fecha': _dateValue(dateController),
              if (lossOrigin != 'Sin cosecha específica')
                'cosechaId': _numericId(lossOrigin, 'cosecha'),
              if (detailController.text.trim().isNotEmpty)
                'observaciones': detailController.text.trim(),
            },
          );
          break;
        case 'sale':
          final client = store.clients.firstWhere(
            (item) => item.name == saleClient && item.active,
            orElse:
                () => throw const ApiException('Selecciona un cliente activo.'),
          );
          createdResource = await store.createResource(
            'ventas',
            body: {
              'cicloId': cycleNumericId,
              'clienteId': _numericId(client.id, 'cliente'),
              'fecha': _dateValue(dateController),
              'fechaLimitePago': _dateValue(
                dueDateController,
                fallback: DateTime.now().add(const Duration(days: 15)),
              ),
              'total': saleTotal.toStringAsFixed(2),
              'descuento': _number(discountController).toStringAsFixed(2),
              'impuesto': _number(saleTaxController).toStringAsFixed(2),
              if (invoiceController.text.trim().isNotEmpty)
                'numeroFactura': invoiceController.text.trim(),
              if (detailController.text.trim().isNotEmpty)
                'notas': detailController.text.trim(),
              'renglones': [
                {
                  'cantidad': _number(quantityController).toString(),
                  'unidadId': _unitId(store, saleUnit),
                  'precioUnitario': _number(priceController).toStringAsFixed(2),
                  'calidad': _qualityCode(quality),
                  if (saleOrigin != 'Sin origen específico')
                    'cosechaId': _numericId(saleOrigin, 'cosecha'),
                },
              ],
            },
          );
          break;
        case 'payment':
          final saleId = widget.saleId;
          if (saleId == null) {
            throw const ApiException('No se encontró la venta del cobro.');
          }
          createdResource = await store.createResource(
            'ventas/$saleId/cobros',
            body: {
              'fecha': _dateValue(dateController),
              'monto': _number(totalController).toStringAsFixed(2),
              'metodo': switch (paymentMethod) {
                'Efectivo' => 'EFECTIVO',
                'Transferencia' => 'TRANSFERENCIA',
                'Cheque' => 'CHEQUE',
                'Tarjeta' => 'TARJETA',
                _ => 'OTRO',
              },
              if (referenceController.text.trim().isNotEmpty)
                'referencia': referenceController.text.trim(),
            },
          );
          break;
        case 'cycle':
          final parcel = _firstOrNull(
            store.properties
                .expand((property) => property.parcels)
                .where((item) => item.id == selectedParcel),
          );
          if (parcel == null) {
            throw const ApiException('Selecciona una parcela disponible.');
          }
          final variety = _rowByName(
            store.catalogs['varieties'] ?? [],
            selectedVariety,
            'una variedad',
          );
          await store.createResource(
            'ciclos',
            body: {
              'parcelaId': _numericId(parcel.id, 'parcela'),
              'variedadId': _numericId('${variety['id']}', 'variedad'),
              'nombre':
                  cycleNameController.text.trim().isEmpty
                      ? selectedVariety
                      : cycleNameController.text.trim(),
              'fechaInicio': _dateValue(cycleDateController),
              'superficieSembrada':
                  (parseDecimal(cycleAreaController.text) ?? 0).toString(),
              'metaProduccionKg': _number(cycleGoalController),
              if (detailController.text.trim().isNotEmpty)
                'observaciones': detailController.text.trim(),
            },
          );
          break;
        case 'close':
          if (selectedCycleId == null) {
            throw const ApiException(
              'Selecciona el ciclo que vas a finalizar.',
            );
          }
          await store.updateResource(
            'ciclos/$selectedCycleId/finalizar',
            body: {'fechaFin': _dateValue(dateController)},
          );
          break;
        default:
          throw const ApiException('Esta operación no está disponible.');
      }

      if (attachmentBytes != null) {
        final attachmentId = createdResource?['id']?.toString();
        if (attachmentId == null || attachmentId.isEmpty) {
          throw const ApiException(
            'El registro se guardó, pero el servidor no devolvió su identificador para adjuntar el archivo.',
          );
        }
        try {
          await _filesRepository.uploadAttachment(
            '${_attachmentEntityPath(widget.type)}/$attachmentId/adjuntos',
            filename: attachmentName!,
            bytes: attachmentBytes!,
          );
        } on ApiException catch (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'El registro se guardó, pero no se pudo cargar el adjunto: ${error.message}',
              ),
            ),
          );
          context.pop();
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            store.dataError == null
                ? 'Registro guardado en el servidor.'
                : 'Se guardó, pero no se pudo actualizar la información: ${store.dataError}',
          ),
        ),
      );
      context.pop();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  String _attachmentEntityPath(String type) => switch (type) {
    'expense' => 'gastos',
    'activity' => 'actividades',
    'sale' => 'ventas',
    'payment' => 'cobros',
    _ => throw const ApiException('Este registro no admite adjuntos.'),
  };
}

class _SaleAvailability extends StatelessWidget {
  const _SaleAvailability({required this.available, required this.requested});

  final double available;
  final double requested;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('KG DISPONIBLES', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          quantity.format(available),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: available == 0 ? 1 : (requested / available).clamp(0, 1),
          color: requested > available ? AppColors.red : AppColors.green,
          backgroundColor: AppColors.strongGreenSurface,
        ),
      ],
    );
  }
}

T? _firstOrNull<T>(Iterable<T> values) {
  final iterator = values.iterator;
  return iterator.moveNext() ? iterator.current : null;
}
