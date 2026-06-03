import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/sittings_app_controllers/settings_controller.dart';
import '../../locale/localization_helpers.dart';
import '../../main.dart';
import '../../models/colors_app_models/colors_app_style_model.dart';

const String _kTutorialSeenPrefKey = 'reading_features_tutorial_seen_v1';

bool shouldShowReadingFeaturesTutorial() {
  return prefs?.getBool(_kTutorialSeenPrefKey) != true;
}

Future<void> markReadingFeaturesTutorialSeen() async {
  await prefs?.setBool(_kTutorialSeenPrefKey, true);
}

enum _ArrowSide { top, bottom, none }

class _TutorialStep {
  const _TutorialStep({
    required this.titleKey,
    required this.bodyKey,
    required this.icons,
    required this.arrow,
    required this.alignment,
  });

  final String titleKey;
  final String bodyKey;
  final List<IconData> icons;
  final _ArrowSide arrow;
  final Alignment alignment;
}

class ReadingFeaturesTutorial extends StatefulWidget {
  const ReadingFeaturesTutorial({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<ReadingFeaturesTutorial> createState() =>
      _ReadingFeaturesTutorialState();
}

class _ReadingFeaturesTutorialState extends State<ReadingFeaturesTutorial>
    with SingleTickerProviderStateMixin {
  static const List<_TutorialStep> _steps = [
    _TutorialStep(
      titleKey: 'tutorial_top_bar_title',
      bodyKey: 'tutorial_top_bar_body',
      icons: [
        Icons.fullscreen_rounded,
        Icons.tune_rounded,
        Icons.bookmark_rounded,
        Icons.linear_scale_rounded,
      ],
      arrow: _ArrowSide.top,
      alignment: Alignment(0, -0.55),
    ),
    _TutorialStep(
      titleKey: 'tutorial_bottom_bar_title',
      bodyKey: 'tutorial_bottom_bar_body',
      icons: [Icons.volume_up_rounded, Icons.mic_rounded, Icons.repeat_rounded],
      arrow: _ArrowSide.bottom,
      alignment: Alignment(0, 0.55),
    ),
    _TutorialStep(
      titleKey: 'tutorial_gestures_title',
      bodyKey: 'tutorial_gestures_body',
      icons: [Icons.touch_app_rounded, Icons.swipe_rounded],
      arrow: _ArrowSide.none,
      alignment: Alignment(0, 0),
    ),
  ];

  late final AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markReadingFeaturesTutorialSeen();
    if (!mounted) return;
    await _animController.reverse();
    if (!mounted) return;
    widget.onDismiss();
  }

  Future<void> _nextStep() async {
    if (_index >= _steps.length - 1) {
      await _finish();
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final settingsControl = Get.find<SettingsController>();
    final style = settingsControl.styleApp;
    final step = _steps[_index];
    final isLast = _index == _steps.length - 1;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _nextStep,
                child: Container(color: Colors.black.withValues(alpha: 0.55)),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: step.alignment,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _TutorialCard(
                    step: step,
                    index: _index,
                    total: _steps.length,
                    isLast: isLast,
                    style: style,
                    onSkip: _finish,
                    onNext: _nextStep,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.style,
    required this.onSkip,
    required this.onNext,
  });

  final _TutorialStep step;
  final int index;
  final int total;
  final bool isLast;
  final ColorsAppStyleModel style;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final accent = style.buttonColorBackground;
    final cardColor = style.colorBackground;
    final fontColor = style.fontColor;
    final titleColor = style.fontColorTitle;

    final card = Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: accent.withValues(alpha: 0.30), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: appTextDirection(),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                ),
                child: Text(
                  'tutorial_step_indicator'.trParams({
                    'current': '${index + 1}',
                    'total': '$total',
                  }),
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'tutorial_title'.tr,
                  textDirection: appTextDirection(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fontColor.withValues(alpha: 0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            step.titleKey.tr,
            textDirection: appTextDirection(),
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: [
              for (final icon in step.icons)
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.bodyKey.tr,
            textDirection: appTextDirection(),
            style: TextStyle(color: fontColor, fontSize: 14, height: 1.55),
          ),
          const SizedBox(height: 14),
          Row(
            textDirection: appTextDirection(),
            children: [
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  foregroundColor: fontColor.withValues(alpha: 0.7),
                ),
                child: Text(
                  'tutorial_skip'.tr,
                  textDirection: appTextDirection(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                textDirection: appTextDirection(),
                children: [
                  for (int i = 0; i < total; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: i == index ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == index
                              ? accent
                              : accent.withValues(alpha: 0.30),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(999),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isLast ? 'tutorial_got_it'.tr : 'tutorial_next'.tr,
                  textDirection: appTextDirection(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (step.arrow == _ArrowSide.none) {
      return card;
    }

    final arrow = CustomPaint(
      size: const Size(22, 12),
      painter: _ArrowPainter(
        color: cardColor,
        borderColor: accent.withValues(alpha: 0.30),
        pointsUp: step.arrow == _ArrowSide.top,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (step.arrow == _ArrowSide.top) arrow,
        card,
        if (step.arrow == _ArrowSide.bottom) arrow,
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({
    required this.color,
    required this.borderColor,
    required this.pointsUp,
  });

  final Color color;
  final Color borderColor;
  final bool pointsUp;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) =>
      old.color != color ||
      old.borderColor != borderColor ||
      old.pointsUp != pointsUp;
}
