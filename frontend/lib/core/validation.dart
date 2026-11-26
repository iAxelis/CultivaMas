String? validatePhoneNumber(String? value, {bool required = false}) {
  final phone = (value ?? '').trim();
  if (phone.isEmpty) {
    return required ? 'Este campo es obligatorio.' : null;
  }
  if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
    return 'El teléfono debe tener exactamente 10 dígitos.';
  }
  return null;
}

String normalizePhoneNumber(String value) =>
    value.replaceAll(RegExp(r'\D'), '');

String? validateEmailAddress(String? value, {bool required = false}) {
  final email = (value ?? '').trim();
  if (email.isEmpty) {
    return required ? 'Este campo es obligatorio.' : null;
  }
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Escribe un correo electrónico válido.';
  }
  return null;
}

double? parseDecimal(String value) {
  var normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  if (RegExp(r'^-?\.$').hasMatch(normalized)) return null;
  if (normalized.startsWith('-.')) {
    normalized = '-0${normalized.substring(1)}';
  } else if (normalized.startsWith('.')) {
    normalized = '0$normalized';
  }
  return double.tryParse(normalized);
}
