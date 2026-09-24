import 'package:flutter_test/flutter_test.dart';
import 'package:samskar_taskmanager/modules/hourly_log/widgets/hourly_log_prompt_overlay.dart';

void main() {
  group('HourlyLogPromptOverlay.computeCurrentSlot', () {
    test('present time 10:30 to 11:30 returns previous section 09:30-10:30', () {
      final t1 = DateTime(2026, 9, 24, 10, 30);
      expect(HourlyLogPromptOverlay.computeCurrentSlot(t1), equals('09:30-10:30'));

      final t2 = DateTime(2026, 9, 24, 11, 0);
      expect(HourlyLogPromptOverlay.computeCurrentSlot(t2), equals('09:30-10:30'));

      final t3 = DateTime(2026, 9, 24, 11, 29);
      expect(HourlyLogPromptOverlay.computeCurrentSlot(t3), equals('09:30-10:30'));
    });

    test('present time 09:30 to 10:30 returns previous section 08:30-09:30', () {
      final t = DateTime(2026, 9, 24, 9, 45);
      expect(HourlyLogPromptOverlay.computeCurrentSlot(t), equals('08:30-09:30'));
    });

    test('present time 11:30 to 12:30 returns previous section 10:30-11:30', () {
      final t = DateTime(2026, 9, 24, 11, 45);
      expect(HourlyLogPromptOverlay.computeCurrentSlot(t), equals('10:30-11:30'));
    });

    test('present time 08:30 to 09:30 returns first slot 08:30-09:30', () {
      final t = DateTime(2026, 9, 24, 8, 45);
      expect(HourlyLogPromptOverlay.computeCurrentSlot(t), equals('08:30-09:30'));
    });

    test('present time after 18:30 returns last slot 17:30-18:30', () {
      final t = DateTime(2026, 9, 24, 19, 0);
      expect(HourlyLogPromptOverlay.computeCurrentSlot(t), equals('17:30-18:30'));
    });
  });
}
