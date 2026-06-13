import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuletadigitalen/app.dart';
import 'package:kuletadigitalen/screens/qr_settings_screen.dart';

void main() {
  testWidgets('QR settings keeps the saved value visible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: QrSettingsContent(
          qrCodeId: 'QR-RUAJTUR',
          onSave: (_) async {},
          onScan: () async {},
        ),
      ),
    );

    expect(find.widgetWithText(TextFormField, 'QR-RUAJTUR'), findsOneWidget);
    expect(find.text('Skano QR Code'), findsOneWidget);
  });
}
