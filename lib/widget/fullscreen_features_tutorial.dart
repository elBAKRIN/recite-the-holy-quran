import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../locale/localization_helpers.dart';
import '../main.dart';
import '../models/colors_app_models/colors_app_style_model.dart';

const String _kFullscreenTutorialSeenKey = 'fullscreen_tutorial_seen_v1';

bool shouldShowFullscreenTutorial() {
  return prefs?.getBool(_kFullscreenTutorialSeenKey) != true;
}

Future<void> markFullscreenTutorialSeen() async {
  await prefs?.setBool(_kFullscreenTutorialSeenKey, true);
}

/// شرح تعريفي يظهر عند أول دخول لوضع ملء الشاشة، يشرح ميزات بطاقة
/// التحكم العائمة (السحب، التشغيل التلقائي، السرعة، الخروج). يُعرض مرة
/// واحدة فقط لكل مستخدم.
class FullscreenFeaturesTutorial extends StatefulWidget {
  const FullscreenFeaturesTutorial({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<FullscreenFeaturesTutorial> createState() =>
      _FullscreenFeaturesTutorialState();
}

class _FullscreenFeaturesTutorialState extends State<FullscreenFeaturesTutorial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

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
    await markFullscreenTutorialSeen();
    if (!mounted) return;
    await _animController.reverse();
    if (!mounted) return;
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final settingsControl = Get.find<SettingsController>();
    final style = settingsControl.styleApp;
    final accent = style.buttonColorBackground;
    final cardBackground = Color.alphaBlend(
      style.colorCard,
      style.colorBackground,
    );

    final sections = <_FullscreenTutorialEntry>[
      _FullscreenTutorialEntry(
        icon: Icons.pan_tool_alt_rounded,
        title: 'fullscreen_tutorial_drag_title'.tr,
        body: 'fullscreen_tutorial_drag_body'.tr,
      ),
      _FullscreenTutorialEntry(
        icon: Icons.play_arrow_rounded,
        title: 'fullscreen_tutorial_autoscroll_title'.tr,
        body: 'fullscreen_tutorial_autoscroll_body'.tr,
      ),
      _FullscreenTutorialEntry(
        icon: Icons.speed_rounded,
        title: 'fullscreen_tutorial_speed_title'.tr,
        body: 'fullscreen_tutorial_speed_body'.tr,
      ),
      _FullscreenTutorialEntry(
        icon: Icons.fullscreen_exit_rounded,
        title: 'fullscreen_tutorial_exit_title'.tr,
        body: 'fullscreen_tutorial_exit_body'.tr,
      ),
    ];

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // طبقة قاتمة تمنع اللمس خلفها أثناء عرض الشرح.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _finish,
                child: Container(color: Colors.black.withValues(alpha: 0.55)),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Directionality(
                      textDirection: appTextDirection(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(20),
                          ),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.30),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.20),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(accent: accent, style: style),
                            const SizedBox(height: 14),
                            for (var i = 0; i < sections.length; i++) ...[
                              _SectionRow(
                                entry: sections[i],
                                accent: accent,
                                style: style,
                              ),
                              if (i < sections.length - 1)
                                const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _finish,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'tutorial_got_it'.tr,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _Header extends StatelessWidget {
  const _Header({required this.accent, required this.style});

  final Color accent;
  final ColorsAppStyleModel style;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: appTextDirection(),
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.fullscreen_rounded, color: accent, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'fullscreen_tutorial_title'.tr,
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: style.fontColorTitle,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'fullscreen_tutorial_subtitle'.tr,
                textDirection: appTextDirection(),
                style: TextStyle(
                  color: style.fontColor.withValues(alpha: 0.65),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FullscreenTutorialEntry {
  const _FullscreenTutorialEntry({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.entry,
    required this.accent,
    required this.style,
  });

  final _FullscreenTutorialEntry entry;
  final Color accent;
  final ColorsAppStyleModel style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        textDirection: appTextDirection(),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(entry.icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.title,
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: style.fontColorTitle,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.body,
                  textDirection: appTextDirection(),
                  style: TextStyle(
                    color: style.fontColor.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
