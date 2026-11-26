import 'package:cultiva_plus/core/validation.dart';
import 'package:cultiva_plus/core/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validación de teléfono', () {
    test('acepta exactamente diez dígitos y permite dejarlo vacío', () {
      expect(validatePhoneNumber('9515550142'), isNull);
      expect(validatePhoneNumber(''), isNull);
    });

    test('rechaza teléfonos cortos o con caracteres no numéricos', () {
      expect(validatePhoneNumber('951555014'), isNotNull);
      expect(validatePhoneNumber('951 555 0142'), isNotNull);
    });
  });

  test('interpreta decimales que comienzan con punto o coma', () {
    expect(parseDecimal('.5'), .5);
    expect(parseDecimal(',5'), .5);
    expect(parseDecimal('1,25'), 1.25);
    expect(parseDecimal('.'), isNull);
  });

  testWidgets('el botón Entendido descarta el estado vacío', (tester) async {
    var acknowledged = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            title: 'Sin registros',
            message: 'Aún no hay información.',
            actionLabel: 'Entendido',
            onAction: () => acknowledged = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    expect(acknowledged, isTrue);
    expect(find.text('Sin registros'), findsNothing);
  });

  testWidgets('el campo de fecha solo permite usar el selector', (
    tester,
  ) async {
    final controller = TextEditingController(text: '01/02/2025');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DatePickerField(controller: controller, label: 'la fecha'),
        ),
      ),
    );

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isTrue,
    );
  });
}
