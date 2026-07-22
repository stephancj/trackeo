import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/settings/views/delete_account_view.dart';
import 'package:mobile/features/vehicles/views/add_vehicle_view.dart';

Widget _app(Widget home) => ProviderScope(
      child: MaterialApp(theme: AppTheme.light, home: home),
    );

void main() {
  testWidgets('ajout véhicule valide l’IMEI avant tout appel API',
      (tester) async {
    await tester.pumpWidget(_app(const AddVehicleView()));

    await tester.ensureVisible(find.text('Associer le véhicule'));
    await tester.tap(find.text('Associer le véhicule'));
    await tester.pump();

    expect(find.text('Identifiant requis'), findsOneWidget);
    expect(find.text('Ajouter un véhicule'), findsOneWidget);
  });

  testWidgets('suppression exige mot de passe et consentement', (tester) async {
    await tester.pumpWidget(_app(const DeleteAccountView()));

    FilledButton deleteButton() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Supprimer définitivement'),
        );

    expect(deleteButton().onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Mot de passe actuel'),
      'secret12',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(deleteButton().onPressed, isNotNull);
  });
}
