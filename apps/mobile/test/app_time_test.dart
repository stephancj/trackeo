import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/app_time.dart';

void main() {
  group('Heure Madagascar (UTC+3)', () {
    test('toMgTime applique +3 sur un instant UTC', () {
      final mg = toMgTime(DateTime.utc(2026, 6, 18, 10, 0)); // 10:00Z
      expect(mg.hour, 13); // 13:00 à Antananarivo
      expect(mg.minute, 0);
    });

    test('fmtMgHm formate en heure malgache', () {
      expect(fmtMgHm(DateTime.utc(2026, 6, 18, 7, 5)), '10:05');
    });

    test('passage de minuit géré (23:30Z → 02:30)', () {
      expect(fmtMgHm(DateTime.utc(2026, 6, 18, 23, 30)), '02:30');
    });
  });
}
