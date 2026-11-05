import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
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
  final taxController = TextEditingController(text: '0');
  final totalController = TextEditingController();
  final priceController = TextEditingController();
  final cycleNameController = TextEditingController();
  final cycleDateController = TextEditingController();
  final cycleAreaController = TextEditingController();
  final cycleGoalController = TextEditingController();
  String? cycleId;
  String? selectedParcel;
  String selectedVariety = 'Brócoli Imperial';
  String unit = 'kg';
  String activityType = 'Aplicación foliar';
  String responsible = 'Luis Pérez';
  String expenseCategory = 'Insumos · Fertilizante';
  String supplierId = 's1';
  String linkedActivity = 'Sin actividad';
  String expenseUnit = 'pieza';
  String stage = 'POSCOSECHA';
  String lossOrigin = 'Sin cosecha específica';
  String lossReason = 'Daño mecánico';
  String quality = 'Primera';
  String saleClient = 'Central de Abastos';
  String saleOrigin = 'Sin origen específico';
  String saleUnit = 'kg';
  String paymentMethod = 'Efectivo';
  String closeReason = 'Fin de temporada';
  bool totalMatches = true;

  @override
  void initState() {
    super.initState();
    cycleId = widget.cycleId;
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
    cycleNameController.dispose();
    cycleDateController.dispose();
    cycleAreaController.dispose();
    cycleGoalController.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
  }

  double get expectedTotal {
    return _number(quantityController) * _number(unitCostController) + _number(taxController);
  }

  double get convertedKg {
    final amount = _number(quantityController);
    return switch (unit) {
      'ton' => amount * 1000,
      'caja' => amount * 18,
      _ => amount,
    };
  }

  double get saleConvertedKg {
    final amount = _number(quantityController);
    return switch (saleUnit) {
      'ton' => amount * 1000,
      'caja' => amount * 18,
      _ => amount,
    };
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
    cycleId ??= store.cycles
        .firstWhere((cycle) => cycle.status == CycleStatus.activo)
        .id;
    if (widget.type == 'cycle' && selectedParcel == null) {
      final occupied = store.cycles
          .where((cycle) => cycle.status == CycleStatus.activo)
          .map((cycle) => cycle.parcel)
          .toSet();
      selectedParcel = ['Parcela 1', 'Parcela 2', 'Parcela 3', 'Parcela 4', 'Parcela 5']
          .firstWhere((parcel) => !occupied.contains(parcel));
    }
    final locked = cycleId != null &&
        widget.type != 'payment' &&
        (store.cycle(cycleId!).status == CycleStatus.finalizado ||
            store.cycle(cycleId!).status == CycleStatus.cerrado);
    final valid = _canSave(store) && !locked;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: valid ? () => _save(store) : null,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Guardar'),
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
                text: 'La captura está bloqueada. Solo se permiten cobros pendientes.',
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
      final cycle = store.cycle(cycleId!);
      return _number(quantityController) > 0 &&
          saleConvertedKg <= store.availableKg(cycle) &&
          _number(priceController) > 0;
    }
    if (widget.type == 'harvest' || widget.type == 'loss') return convertedKg > 0;
    if (widget.type == 'cycle') {
      const parcelAreas = {
        'Parcela 1': 1.8,
        'Parcela 2': 4.2,
        'Parcela 3': 2.5,
        'Parcela 4': 3.0,
        'Parcela 5': 2.2,
      };
      final plantedArea = double.tryParse(cycleAreaController.text) ?? 0;
      return selectedParcel != null &&
          cycleDateController.text.isNotEmpty &&
          plantedArea > 0 &&
          plantedArea <= parcelAreas[selectedParcel]!;
    }
    if (widget.type == 'payment') {
      final sale = store.sales.firstWhere((item) => item.id == widget.saleId);
      final amount = _number(totalController);
      return amount > 0 && amount <= sale.total - sale.paid;
    }
    return true;
  }

  List<Widget> _fields(AppStore store) {
    return switch (widget.type) {
      'expense' => _expenseFields(store),
      'harvest' => _harvestFields(store),
      'loss' => _lossFields(store),
      'sale' => _saleFields(store),
      'payment' => _paymentFields(store),
      'cycle' => _cycleFields(store),
      'close' => _closeFields(store),
      _ => _activityFields(store),
    };
  }

  Widget _cycleSelector(AppStore store) {
    return FieldBlock(
      label: 'Ciclo',
      help: 'El registro quedará ligado a este ciclo.',
      child: DropdownButtonFormField<String>(
        initialValue: cycleId,
        items: [
          for (final cycle in store.cycles.where(
            (item) => item.status == CycleStatus.activo || item.status == CycleStatus.suspendido,
          ))
            DropdownMenuItem(
              value: cycle.id,
              child: Text('${cycle.crop} · ${cycle.parcel}'),
            ),
        ],
        onChanged: (value) => setState(() => cycleId = value),
      ),
    );
  }

  List<Widget> _activityFields(AppStore store) {
    return [
      _cycleSelector(store),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Actividad',
        help: 'Selecciona la labor realizada.',
        child: DropdownButtonFormField<String>(
          initialValue: activityType,
          items: const [
            DropdownMenuItem(value: 'Aplicación foliar', child: Text('Aplicación foliar')),
            DropdownMenuItem(value: 'Riego', child: Text('Riego')),
            DropdownMenuItem(value: 'Deshierbe', child: Text('Deshierbe')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => activityType = value);
          },
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Responsable',
        help: 'Usuario asignado, opcional.',
        child: DropdownButtonFormField<String>(
          initialValue: responsible,
          items: const [
            DropdownMenuItem(value: 'Luis Pérez', child: Text('Luis Pérez')),
            DropdownMenuItem(value: 'Ramón Ortega', child: Text('Ramón Ortega')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => responsible = value);
          },
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Fecha',
        help: 'Fecha de ejecución de la labor.',
        child: TextFormField(
          decoration: const InputDecoration(
            hintText: 'dd/mm/aaaa',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Horas trabajadas',
        help: 'Opcional, debe ser mayor o igual a cero.',
        child: TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'h', hintText: '0'),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Descripción',
        help: 'Opcional. Agrega dosis, clima u observaciones.',
        child: TextFormField(
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Escribe una observación'),
        ),
      ),
    ];
  }

  List<Widget> _expenseFields(AppStore store) {
    return [
      _cycleSelector(store),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Categoría',
        help: 'Se usa para el desglose de costos.',
        child: DropdownButtonFormField<String>(
          initialValue: expenseCategory,
          items: const [
            DropdownMenuItem(
              value: 'Insumos · Fertilizante',
              child: Text('Insumos · Fertilizante'),
            ),
            DropdownMenuItem(value: 'Mano de obra', child: Text('Mano de obra')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => expenseCategory = value);
          },
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Proveedor',
        help: 'CAPTURISTA puede seleccionar proveedores activos sin abrir el catálogo.',
        child: DropdownButtonFormField<String>(
          initialValue: supplierId,
          items: [
            for (final supplier in store.suppliers.where((item) => item.active))
              DropdownMenuItem(
                value: supplier.id,
                child: Text(supplier.name),
              ),
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
          initialValue: linkedActivity,
          items: const [
            DropdownMenuItem(value: 'Sin actividad', child: Text('Sin actividad')),
            DropdownMenuItem(value: 'Aplicación foliar', child: Text('Aplicación foliar')),
            DropdownMenuItem(value: 'Cosecha', child: Text('Cosecha')),
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
          initialValue: expenseUnit,
          items: const [
            DropdownMenuItem(value: 'pieza', child: Text('pieza')),
            DropdownMenuItem(value: 'kg', child: Text('kg')),
            DropdownMenuItem(value: 'litro', child: Text('litro')),
            DropdownMenuItem(value: 'hora', child: Text('hora')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => expenseUnit = value);
          },
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Fecha',
        help: 'Fecha del egreso.',
        child: TextFormField(
          decoration: const InputDecoration(
            hintText: 'dd/mm/aaaa',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Descripción / concepto',
        help: 'Opcional, máximo 500 caracteres.',
        child: TextFormField(
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Concepto del gasto'),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FieldBlock(
              label: 'Cantidad',
              help: 'Unidades',
              child: TextFormField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '10'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FieldBlock(
              label: 'Costo unitario',
              help: 'Antes de impuesto',
              child: TextFormField(
                controller: unitCostController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(prefixText: '\$ ', hintText: '800'),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Impuesto',
        help: 'Importe total de impuestos.',
        child: TextFormField(
          controller: taxController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ '),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Total del comprobante',
        help: totalMatches
            ? 'Coincide con cantidad × costo unitario + impuesto.'
            : 'No coincide. Esperado: ${moneyExact.format(expectedTotal)}',
        child: TextFormField(
          controller: totalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '\$ ',
            errorText: totalMatches ? null : 'Revisa el total',
          ),
        ),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => const Padding(
            padding: EdgeInsets.all(24),
            child: InfoBanner(
              title: 'Foto de ticket',
              text: 'Placeholder: la cámara y carga de archivos no se implementan en este wireframe.',
              tone: AppColors.blue,
              icon: Icons.camera_alt_outlined,
            ),
          ),
        ),
        icon: const Icon(Icons.attach_file_rounded),
        label: const Text('Adjuntar foto del ticket'),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Número de comprobante',
        help: 'Opcional, máximo 60 caracteres.',
        child: TextFormField(
          decoration: const InputDecoration(hintText: 'F-204'),
        ),
      ),
    ];
  }

  List<Widget> _harvestFields(AppStore store) {
    return [
      _cycleSelector(store),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Fecha',
        help: 'Fecha del evento de recolección.',
        child: TextFormField(
          decoration: const InputDecoration(
            hintText: 'dd/mm/aaaa',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '0'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: unit,
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'ton', child: Text('ton')),
                  DropdownMenuItem(value: 'caja', child: Text('caja')),
                ],
                onChanged: (value) => setState(() => unit = value!),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      InfoBanner(
        title: 'Conversión automática',
        text: '${quantity.format(convertedKg)} kg se sumarán a la producción cosechada.',
        tone: AppColors.green,
        icon: Icons.sync_alt_rounded,
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Calidad',
        help: 'Se usará para disponibilidad y ventas.',
        child: DropdownButtonFormField<String>(
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
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Notas de calidad'),
        ),
      ),
    ];
  }

  List<Widget> _lossFields(AppStore store) {
    return [
      _cycleSelector(store),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Etapa de la merma',
        help: 'Define si la merma reduce o no el inventario cosechado.',
        child: DropdownButtonFormField<String>(
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
        title: stage == 'CAMPO' ? 'No resta de lo cosechado' : 'Sí resta del disponible',
        text: stage == 'CAMPO'
            ? 'La merma en campo registra producción potencial perdida; nunca entró al inventario.'
            : 'La merma poscosecha salió de producto ya cosechado y reduce los kg disponibles.',
        tone: stage == 'CAMPO' ? AppColors.blue : AppColors.earth,
        icon: stage == 'CAMPO' ? Icons.info_rounded : Icons.remove_circle_rounded,
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Cosecha de origen',
        help: 'Opcional, debe pertenecer al mismo ciclo.',
        child: DropdownButtonFormField<String>(
          initialValue: lossOrigin,
          items: const [
            DropdownMenuItem(
              value: 'Sin cosecha específica',
              child: Text('Sin cosecha específica'),
            ),
            DropdownMenuItem(
              value: 'Cosecha 12 jun',
              child: Text('Cosecha 12 jun · 1,250 kg'),
            ),
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
          initialValue: unit,
          items: const [
            DropdownMenuItem(value: 'kg', child: Text('kg')),
            DropdownMenuItem(value: 'ton', child: Text('ton')),
            DropdownMenuItem(value: 'caja', child: Text('caja 18 kg')),
          ],
          onChanged: (value) => setState(() => unit = value!),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Fecha',
        help: 'Fecha de la merma.',
        child: TextFormField(
          decoration: const InputDecoration(
            hintText: 'dd/mm/aaaa',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Cantidad',
        help: 'Expresada en kilogramos.',
        child: TextFormField(
          controller: quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kg', hintText: '0'),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Observaciones',
        help: 'Opcional, máximo 500 caracteres.',
        child: TextFormField(
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Notas de la merma'),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Causa',
        help: 'Ayuda a detectar patrones de pérdida.',
        child: DropdownButtonFormField<String>(
          initialValue: lossReason,
          items: const [
            DropdownMenuItem(value: 'Daño mecánico', child: Text('Daño mecánico')),
            DropdownMenuItem(value: 'Plaga', child: Text('Plaga')),
            DropdownMenuItem(value: 'Calidad', child: Text('Fuera de calidad')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => lossReason = value);
          },
        ),
      ),
    ];
  }

  List<Widget> _saleFields(AppStore store) {
    final cycle = store.cycle(cycleId!);
    final available = store.availableKg(cycle);
    final requested = saleConvertedKg;
    final exceeded = requested > available;
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
            Expanded(child: _SaleAvailability(available: available, requested: requested)),
          ],
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Cliente',
        help: 'Selecciona quién recibe la venta.',
        child: DropdownButtonFormField<String>(
          initialValue: saleClient,
          items: const [
            DropdownMenuItem(value: 'Central de Abastos', child: Text('Central de Abastos')),
            DropdownMenuItem(
              value: 'Restaurantes del Valle',
              child: Text('Restaurantes del Valle'),
            ),
            DropdownMenuItem(
              value: 'Mercado Orgánico',
              child: Text('Mercado Orgánico'),
            ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => saleClient = value);
          },
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Fecha',
        help: 'Fecha de la operación comercial.',
        child: TextFormField(
          decoration: const InputDecoration(
            hintText: 'dd/mm/aaaa',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: FieldBlock(
              label: 'Número de factura',
              help: 'Opcional.',
              child: TextFormField(
                decoration: const InputDecoration(hintText: 'FAC-1043'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FieldBlock(
              label: 'Fecha límite',
              help: 'Opcional.',
              child: TextFormField(
                decoration: const InputDecoration(hintText: 'dd/mm/aaaa'),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: FieldBlock(
              label: 'Descuento',
              help: 'Por defecto 0.',
              child: TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FieldBlock(
              label: 'Impuesto',
              help: 'Por defecto 0.',
              child: TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00'),
              ),
            ),
          ),
        ],
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
                initialValue: saleOrigin,
                decoration: const InputDecoration(labelText: 'Cosecha de origen'),
                items: const [
                  DropdownMenuItem(
                    value: 'Sin origen específico',
                    child: Text('Sin origen específico'),
                  ),
                  DropdownMenuItem(
                    value: 'Cosecha 12 jun',
                    child: Text('Cosecha 12 jun · 1,250 kg'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => saleOrigin = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: saleUnit,
                decoration: const InputDecoration(labelText: 'Unidad'),
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'ton', child: Text('ton')),
                  DropdownMenuItem(value: 'caja', child: Text('caja 18 kg')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => saleUnit = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: quality,
                decoration: const InputDecoration(labelText: 'Calidad'),
                items: const [
                  DropdownMenuItem(value: 'Extra', child: Text('Extra')),
                  DropdownMenuItem(value: 'Primera', child: Text('Primera')),
                  DropdownMenuItem(value: 'Segunda', child: Text('Segunda')),
                  DropdownMenuItem(value: 'Tercera', child: Text('Tercera')),
                  DropdownMenuItem(value: 'Industria', child: Text('Industrial')),
                ],
                onChanged: (value) => setState(() => quality = value!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        suffixText: saleUnit == 'caja' ? 'caja 18 kg' : saleUnit,
                        errorText: exceeded ? 'Supera el disponible' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: priceController,
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Precio / $saleUnit',
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Text('Subtotal')),
                  Text(
                    moneyExact.format(
                      _number(quantityController) * _number(priceController),
                    ),
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
        text: 'No se edita: se deriva del total cobrado y de la fecha de vencimiento.',
        tone: AppColors.blue,
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Notas',
        help: 'Opcional, máximo 500 caracteres.',
        child: TextFormField(
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Condiciones de la venta'),
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
            Text('${sale.id} · Saldo ${moneyExact.format(sale.total - sale.paid)}'),
          ],
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Fecha',
        help: 'Fecha de recepción del pago.',
        child: TextFormField(
          decoration: const InputDecoration(
            hintText: 'dd/mm/aaaa',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Importe del cobro',
        help:
            'No puede superar ${moneyExact.format(sale.total - sale.paid)} de saldo.',
        child: TextFormField(
          controller: totalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00'),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Método',
        help: 'Dato informativo para conciliación.',
        child: DropdownButtonFormField<String>(
          initialValue: paymentMethod,
          items: const [
            DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
            DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
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
        help: 'Opcional, por ejemplo autorización o SPEI.',
        child: TextFormField(
          decoration: const InputDecoration(hintText: 'Referencia'),
        ),
      ),
    ];
  }

  List<Widget> _cycleFields(AppStore store) {
    const parcels = ['Parcela 1', 'Parcela 2', 'Parcela 3', 'Parcela 4', 'Parcela 5'];
    const parcelAreas = {
      'Parcela 1': 1.8,
      'Parcela 2': 4.2,
      'Parcela 3': 2.5,
      'Parcela 4': 3.0,
      'Parcela 5': 2.2,
    };
    final occupied = store.cycles
        .where((cycle) => cycle.status == CycleStatus.activo)
        .map((cycle) => cycle.parcel)
        .toSet();
    final available = parcels.where((parcel) => !occupied.contains(parcel)).toList();
    return [
      const InfoBanner(
        text: 'Las parcelas con otro ciclo activo se excluyen automáticamente.',
        tone: AppColors.green,
        icon: Icons.filter_alt_rounded,
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Parcela disponible',
        help: '${occupied.length} parcelas se ocultaron por tener un ciclo activo.',
        child: DropdownButtonFormField<String>(
          initialValue: selectedParcel,
          items: [
            for (final parcel in available)
              DropdownMenuItem(value: parcel, child: Text(parcel)),
          ],
          onChanged: (value) => setState(() => selectedParcel = value),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Variedad',
        help: 'Selecciona la variedad activa del catálogo.',
        child: DropdownButtonFormField<String>(
          initialValue: selectedVariety,
          items: const [
            DropdownMenuItem(value: 'Brócoli Imperial', child: Text('Brócoli Imperial')),
            DropdownMenuItem(value: 'Maíz H-48', child: Text('Maíz H-48')),
            DropdownMenuItem(value: 'Tomate Saladette', child: Text('Tomate Saladette')),
          ],
          onChanged: (value) => setState(() => selectedVariety = value!),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Nombre del ciclo',
        help: 'Opcional, por ejemplo Primavera 2027.',
        child: TextFormField(
          controller: cycleNameController,
          decoration: const InputDecoration(hintText: 'Primavera 2027'),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Fecha de inicio',
        help: 'Primera labor, incluida preparación del suelo.',
        child: TextFormField(
          controller: cycleDateController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'dd/mm/aaaa',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Superficie sembrada',
        help: 'No debe exceder la superficie de la parcela.',
        child: TextFormField(
          controller: cycleAreaController,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: 'ha',
            hintText: '0.00',
            errorText: (double.tryParse(cycleAreaController.text) ?? 0) >
                    parcelAreas[selectedParcel]!
                ? 'Supera ${parcelAreas[selectedParcel]!.toStringAsFixed(2)} ha'
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
          decoration: const InputDecoration(suffixText: 'kg', hintText: '12,000'),
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
        text: 'Cerrar el ciclo bloquea la captura, pero los cobros seguirán permitidos.',
        tone: AppColors.amber,
        icon: Icons.warning_rounded,
      ),
      const SizedBox(height: 20),
      FieldBlock(
        label: 'Motivo de cierre',
        help: 'Quedará registrado en la auditoría.',
        child: DropdownButtonFormField<String>(
          initialValue: closeReason,
          items: const [
            DropdownMenuItem(value: 'Fin de temporada', child: Text('Fin de temporada')),
            DropdownMenuItem(value: 'Cancelación', child: Text('Cancelación')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => closeReason = value);
          },
        ),
      ),
    ];
  }

  void _save(AppStore store) {
    final cycle = cycleId == null ? null : store.cycle(cycleId!);
    switch (widget.type) {
      case 'expense':
        final supplier = store.suppliers.firstWhere(
          (item) => item.id == supplierId,
        );
        store.addExpense(
          cycle!,
          expectedTotal,
          category: expenseCategory,
          supplier: supplier.name,
          activity: linkedActivity,
          unit: expenseUnit,
        );
        break;
      case 'harvest':
        store.addHarvest(cycle!, convertedKg, quality: quality);
        break;
      case 'loss':
        store.addRecord(
          'Merma registrada',
          '${cycle!.parcel} · ${quantity.format(convertedKg)} kg · '
              '$stage · $lossReason · $lossOrigin',
          'Merma',
          cycleId: cycle.id,
        );
        break;
      case 'sale':
        store.addSale(
          cycle!,
          saleConvertedKg,
          _number(quantityController) * _number(priceController),
          client: saleClient,
          detail: '$quality · $saleOrigin',
        );
        break;
      case 'payment':
        final sale = store.sales.firstWhere((item) => item.id == widget.saleId);
        store.addPayment(
          sale,
          _number(totalController),
          method: paymentMethod,
        );
        break;
      case 'cycle':
        store.addCycle(
          FarmCycle(
            id: 'cycle-${store.cycles.length + 1}',
            parcel: selectedParcel!,
            crop: cycleNameController.text.isEmpty
                ? selectedVariety
                : cycleNameController.text,
            status: CycleStatus.planificado,
            area: double.parse(cycleAreaController.text),
            cost: 0,
            income: 0,
            harvestedKg: 0,
            goalKg: double.tryParse(cycleGoalController.text) ?? 0,
          ),
        );
        break;
      case 'close':
        cycle!.status = CycleStatus.cerrado;
        store.addRecord(
          'Ciclo cerrado',
          '${cycle.crop} · ${cycle.parcel} · $closeReason',
          'Ciclo',
        );
        break;
      default:
        store.addRecord(
          widget.type == 'cycle' ? 'Ciclo creado' : 'Actividad registrada',
          cycle == null
              ? 'Nuevo ciclo planificado'
              : '${cycle.crop} · ${cycle.parcel} · $activityType · $responsible',
          widget.type == 'cycle' ? 'Ciclo' : 'Actividad',
          cycleId: cycle?.id,
        );
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro guardado en memoria')),
    );
    context.pop();
  }
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
