import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/api_client.dart';
import '../../data/models.dart';
import '../../data/store.dart';

Future<void> showRecordEditSheet(
  BuildContext context,
  AppStore store,
  ActivityRecord record,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _RecordEditSheet(store: store, record: record),
  );
}

class _RecordEditSheet extends StatefulWidget {
  const _RecordEditSheet({required this.store, required this.record});

  final AppStore store;
  final ActivityRecord record;

  @override
  State<_RecordEditSheet> createState() => _RecordEditSheetState();
}

class _RecordEditSheetState extends State<_RecordEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitCostController;
  late final TextEditingController _taxController;
  late DateTime _date;
  bool _isSaving = false;

  Map<String, dynamic> get _source => widget.record.sourceData;
  bool get _isExpense => widget.record.kind == 'Gasto';
  bool get _isDirectExpense => _isExpense && _source['unidadId'] == null;
  bool get _isActivity => widget.record.kind == 'Actividad';
  bool get _hasAmount =>
      _isActivity ||
      _isExpense ||
      widget.record.kind == 'Cosecha' ||
      widget.record.kind == 'Merma';

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.record.detail);
    _amountController = TextEditingController(
      text: _valueText(
        _isActivity
            ? _source['horasTrabajadas']
            : _isExpense
            ? _source['total']
            : _source['cantidad'],
      ),
    );
    _quantityController = TextEditingController(
      text: _valueText(_source['cantidad']),
    );
    _unitCostController = TextEditingController(
      text: _valueText(_source['costoUnitario']),
    );
    _taxController = TextEditingController(
      text: _valueText(_source['impuesto'] ?? '0'),
    );
    _date = widget.record.date;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _unitCostController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.record.kind) {
      'Actividad' => 'Editar actividad',
      'Gasto' => 'Editar gasto',
      'Cosecha' => 'Editar cosecha',
      'Merma' => 'Editar merma',
      _ => 'Editar registro',
    };
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  widget.record.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(DateFormat('dd/MM/yyyy', 'es_MX').format(_date)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: _isActivity ? 'Descripción' : 'Observaciones',
                  ),
                ),
                if (_hasAmount) ...[
                  const SizedBox(height: 8),
                  ..._amountFields(),
                ],
                const SizedBox(height: 12),
                const InfoBanner(
                  title: 'Cambios guardados en la cuenta',
                  text:
                      'El servidor valida permisos, antigüedad del registro y estado del ciclo antes de guardar.',
                  tone: AppColors.blue,
                  icon: Icons.sync_rounded,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon:
                          _isSaving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Guardando…' : 'Guardar cambios'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _amountFields() {
    if (_isActivity) {
      return [
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Horas trabajadas',
            suffixText: 'h',
          ),
          validator: (value) => _validateOptionalNumber(value, positive: true),
        ),
      ];
    }
    if (_isExpense && !_isDirectExpense) {
      return [
        TextFormField(
          controller: _quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Cantidad'),
          validator: (value) => _validateNumber(value, positive: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _unitCostController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Costo unitario',
            prefixText: '\$ ',
          ),
          validator: (value) => _validateNumber(value),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _taxController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Impuestos',
            prefixText: '\$ ',
          ),
          validator: (value) => _validateNumber(value),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(
          'Total calculado: ${moneyExact.format(_expenseTotal)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ];
    }
    final label =
        _isExpense
            ? 'Total del gasto'
            : widget.record.kind == 'Cosecha'
            ? 'Cantidad cosechada'
            : 'Cantidad mermada';
    return [
      TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixText: _isExpense ? '\$ ' : null,
          suffixText: _isExpense ? null : _unitLabel,
        ),
        validator: (value) => _validateNumber(value, positive: true),
      ),
    ];
  }

  double get _expenseTotal =>
      (_number(_quantityController) * _number(_unitCostController) +
          _number(_taxController));

  String get _unitLabel {
    final id = _source['unidadId']?.toString();
    for (final unit in widget.store.catalogs['units'] ?? const []) {
      if (unit['id']?.toString() == id) {
        return '${unit['codigo'] ?? unit['nombre'] ?? 'unidades'}';
      }
    }
    return 'unidades';
  }

  Future<void> _selectDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) setState(() => _date = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final path = widget.record.resourcePath;
    final id = widget.record.id;
    if (path == null || id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar el registro.')),
      );
      return;
    }
    final body = <String, Object?>{
      'fecha': DateFormat('yyyy-MM-dd').format(_date),
    };
    final description = _descriptionController.text.trim();
    if (_isActivity) {
      body['descripcion'] = description.isEmpty ? null : description;
      body['horasTrabajadas'] =
          _amountController.text.trim().isEmpty
              ? null
              : _number(_amountController);
    } else if (_isExpense) {
      body['descripcion'] = description.isEmpty ? null : description;
      if (_isDirectExpense) {
        body['total'] = _number(_amountController).toStringAsFixed(2);
      } else {
        final total = _expenseTotal;
        if (total <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El total del gasto debe ser mayor que cero.'),
            ),
          );
          return;
        }
        body
          ..['cantidad'] = _number(_quantityController).toString()
          ..['costoUnitario'] = _number(_unitCostController).toStringAsFixed(2)
          ..['impuesto'] = _number(_taxController).toStringAsFixed(2)
          ..['total'] = total.toStringAsFixed(2);
      }
    } else if (widget.record.kind == 'Cosecha') {
      body
        ..['observaciones'] = description.isEmpty ? null : description
        ..['cantidad'] = _number(_amountController).toString();
    } else if (widget.record.kind == 'Merma') {
      body
        ..['observaciones'] = description.isEmpty ? null : description
        ..['cantidad'] = _number(_amountController).toString();
    } else {
      throw const ApiException(
        'Este tipo de registro no se puede editar aquí.',
      );
    }

    setState(() => _isSaving = true);
    try {
      await widget.store.updateResource('$path/$id', body: body);
      if (!mounted) return;
      final message =
          widget.store.dataError == null
              ? 'Cambios guardados correctamente.'
              : 'Se guardó, pero no se pudo actualizar la información: ${widget.store.dataError}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateNumber(String? value, {bool positive = false}) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite || (positive && parsed <= 0)) {
      return positive
          ? 'Ingresa una cantidad mayor que cero.'
          : 'Ingresa un número válido.';
    }
    if (!positive && parsed < 0) return 'El valor no puede ser negativo.';
    return null;
  }

  String? _validateOptionalNumber(String? value, {bool positive = false}) {
    if (value == null || value.trim().isEmpty) return null;
    return _validateNumber(value, positive: positive);
  }

  double _number(TextEditingController controller) =>
      double.parse(controller.text.replaceAll(',', '.'));

  String _valueText(Object? value) => value?.toString() ?? '';
}

Future<void> showRecordAttachmentsSheet(
  BuildContext context,
  AppStore store,
  ActivityRecord record,
) async {
  final path = record.attachmentEntityPath;
  final id = record.id;
  if (path == null || id == null) return;
  await showAttachmentsSheet(
    context,
    store,
    path: '$path/$id/adjuntos',
    title: record.title,
  );
}

Future<void> showAttachmentsSheet(
  BuildContext context,
  AppStore store, {
  required String path,
  required String title,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AttachmentsSheet(store: store, path: path, title: title),
  );
}

class _AttachmentsSheet extends StatefulWidget {
  const _AttachmentsSheet({
    required this.store,
    required this.path,
    required this.title,
  });

  final AppStore store;
  final String path;
  final String title;

  @override
  State<_AttachmentsSheet> createState() => _AttachmentsSheetState();
}

class _AttachmentsSheetState extends State<_AttachmentsSheet> {
  late Future<List<Map<String, dynamic>>> _attachments;
  String? _busyId;
  bool _isUploading = false;

  String get _path => widget.path;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _attachments = widget.store.listResource(_path);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Archivos adjuntos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(widget.title),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickAndUpload,
              icon:
                  _isUploading
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.attach_file_rounded),
              label: Text(_isUploading ? 'Subiendo…' : 'Agregar archivo'),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _attachments,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _AttachmentError(
                      error: snapshot.error,
                      onRetry: () => setState(_load),
                    );
                  }
                  final files = snapshot.data ?? const [];
                  if (files.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Este registro aún no tiene archivos.'),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final id = file['id']?.toString() ?? '';
                      final filename =
                          file['nombreArchivo']?.toString() ??
                          'Archivo adjunto';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_outlined),
                        title: Text(
                          filename,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_sizeLabel(file['tamanoBytes'])),
                        trailing: Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              tooltip: 'Descargar',
                              onPressed:
                                  id.isEmpty || _busyId != null
                                      ? null
                                      : () => _download(id),
                              icon:
                                  _busyId == id
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.download_rounded),
                            ),
                            if (widget.store.role == UserRole.admin)
                              IconButton(
                                tooltip: 'Eliminar archivo',
                                onPressed:
                                    id.isEmpty || _busyId != null
                                        ? null
                                        : () => _delete(id, filename),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.red,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (result.isEmpty) return;
      final file = result.first;
      final size = await file.length();
      if (size == null || size > 10 * 1024 * 1024) {
        throw const ApiException('El archivo debe pesar como máximo 10 MB.');
      }
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _isUploading = true);
      await widget.store.uploadAttachment(
        _path,
        filename: file.name,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _load();
      });
    } on ApiException catch (error) {
      _showError(error.message);
    } on PlatformException catch (error) {
      _showError(error.message ?? 'No se pudo seleccionar el archivo.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _download(String id) async {
    setState(() => _busyId = id);
    try {
      final file = await widget.store.downloadAttachment(id);
      if (!mounted) return;
      final filename = file.filename.split(RegExp(r'[/\\]')).last;
      final dot = filename.lastIndexOf('.');
      final extension = dot > 0 ? filename.substring(dot + 1) : 'bin';
      final name = dot > 0 ? filename.substring(0, dot) : filename;
      await FileSaver.instance.saveFile(
        name: name,
        bytes: file.bytes,
        fileExtension: extension,
        mimeType: MimeType.other,
      );
    } on ApiException catch (error) {
      _showError(error.message);
    } on PlatformException catch (error) {
      _showError(error.message ?? 'No se pudo guardar el archivo.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _delete(String id, String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('¿Eliminar archivo?'),
            content: Text('Se eliminará "$filename" de forma permanente.'),
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
    if (confirmed != true || !mounted) return;
    setState(() => _busyId = id);
    try {
      await widget.store.deleteAttachment(id);
      if (!mounted) return;
      setState(_load);
    } on ApiException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _sizeLabel(Object? value) {
    final bytes = int.tryParse(value?.toString() ?? '');
    if (bytes == null || bytes <= 0) return 'Tamaño desconocido';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _AttachmentError extends StatelessWidget {
  const _AttachmentError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message =
        error is ApiException
            ? (error as ApiException).message
            : 'No se pudieron cargar los archivos adjuntos.';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
