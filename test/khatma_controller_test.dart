import 'package:flutter_test/flutter_test.dart';
import 'package:recite_the_holy_quran/controllers/khatma_controller.dart';
import 'package:recite_the_holy_quran/models/khatma_model.dart';

void main() {
  test('calculates today pages with integer ceiling only', () {
    final controller = KhatmaController();
    final khatma = KhatmaModel(
      id: '1',
      name: 'اختبار',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 28)),
      remainingPages: 604,
    );

    controller.recalculatePlan(khatma);

    expect(khatma.todayRequiredPages, 21);
  });

  test('caps read pages at 604', () {
    final controller = KhatmaController();
    final khatma = KhatmaModel(
      id: '1',
      name: 'اختبار',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 1)),
      readPages: 700,
    );

    controller.recalculatePlan(khatma);

    expect(khatma.readPages, KhatmaController.quranTotalPages);
    expect(khatma.status, KhatmaStatus.completed);
  });
}
