import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/sittings_app_controllers/settings_controller.dart';
import '../../controllers/view_surah_controllers/functions/change_number_to_ar_func.dart';
import '../../locale/localization_helpers.dart';

/// زخرفة فاصلة تُعرض في أسفل صفحة المصحف (في القراءة العادية وقراءة الختمة)،
/// وفي وسطها رقم الصفحة بنفس خط الآيات وحجمها.
class PageNumberSeparator extends StatelessWidget {
  const PageNumberSeparator({
    super.key,
    required this.pageNumber,
    required this.fontSize,
    required this.settingsControl,
  });

  /// رقم صفحة المصحف.
  final int pageNumber;

  /// حجم خط الآيات الحالي ليُطابقه رقم الصفحة.
  final double fontSize;

  final SettingsController settingsControl;

  @override
  Widget build(BuildContext context) {
    final accent = settingsControl.styleApp.buttonColorBackground;
    final numberColor = settingsControl.styleApp.fontColorTitle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _OrnamentSide(color: accent, pointLeft: false)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${'page'.tr} ${changeNumbersToAr(pageNumber.toString())}',
              textAlign: TextAlign.center,
              textDirection: appTextDirection(),
              style: TextStyle(
                fontSize: fontSize,
                color: numberColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                height: 1.2,
              ),
            ),
          ),
          Expanded(child: _OrnamentSide(color: accent, pointLeft: true)),
        ],
      ),
    );
  }
}

/// نصف الزخرفة: خطّ متدرّج يخفت باتجاه الحافة الخارجية ومُعيّن صغير (♦) ملاصق
/// لرقم الصفحة من الداخل. [pointLeft] تحدّد الجهة التي يلتفت إليها المعيّن نحو
/// الرقم (يسار/يمين) لإبقاء الزخرفة متناظرة حول الرقم.
class _OrnamentSide extends StatelessWidget {
  const _OrnamentSide({required this.color, required this.pointLeft});

  final Color color;
  final bool pointLeft;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1.4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: pointLeft ? Alignment.centerRight : Alignment.centerLeft,
            end: pointLeft ? Alignment.centerLeft : Alignment.centerRight,
            colors: [
              color.withValues(alpha: 0.0),
              color.withValues(alpha: 0.5),
            ],
          ),
        ),
      ),
    );

    final diamond = Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 6,
      height: 6,
      transform: Matrix4.rotationZ(0.7853981633974483),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.55),
        borderRadius: const BorderRadius.all(Radius.circular(1)),
      ),
    );

    return Row(children: pointLeft ? [diamond, line] : [line, diamond]);
  }
}
