import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fullscreen_features_tutorial.dart';

class AutoScrollFullscreenPanel extends StatefulWidget {
  const AutoScrollFullscreenPanel({
    super.key,
    required this.enabled,
    required this.speedSeconds,
    required this.onToggle,
    required this.onChangeSpeed,
    required this.onExitFullscreen,
    required this.style,
  });

  final bool enabled;
  final int speedSeconds;
  final VoidCallback onToggle;
  final ValueChanged<int> onChangeSpeed;
  final VoidCallback onExitFullscreen;
  final dynamic style;

  @override
  State<AutoScrollFullscreenPanel> createState() =>
      _AutoScrollFullscreenPanelState();
}

class _AutoScrollFullscreenPanelState extends State<AutoScrollFullscreenPanel> {
  Offset? _position;
  final GlobalKey _cardKey = GlobalKey();
  Offset _grabOffset = Offset.zero;
  OverlayEntry? _tutorialEntry;

  @override
  void initState() {
    super.initState();
    // نعرض الشرح مرّة واحدة فقط للمستخدم عند أول دخول لوضع ملء الشاشة
    // (في القراءة العادية أو في الختمة — نفس المفتاح في SharedPreferences).
    // نستخدم OverlayEntry بدل تغيير شجرة الويدجت لأن البطاقة نفسها
    // ترجع Positioned داخل Stack مملوك من الصفحة الأم.
    if (shouldShowFullscreenTutorial()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showTutorialOverlay();
      });
    }
  }

  void _showTutorialOverlay() {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null || _tutorialEntry != null) return;
    final entry = OverlayEntry(
      builder: (_) => FullscreenFeaturesTutorial(onDismiss: _dismissTutorial),
    );
    _tutorialEntry = entry;
    overlay.insert(entry);
  }

  void _dismissTutorial() {
    _tutorialEntry?.remove();
    _tutorialEntry = null;
  }

  @override
  void dispose() {
    _dismissTutorial();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_position == null) {
      final size = MediaQuery.of(context).size;
      final topInset = MediaQuery.of(context).padding.top;
      _position = Offset(size.width - 170, 4 + topInset);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    _grabOffset = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!mounted) return;
    final screen = MediaQuery.of(context).size;
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    final cardSize = box?.size ?? const Size(170, 46);

    final raw = details.globalPosition - _grabOffset;
    final maxX = math.max(0.0, screen.width - cardSize.width);
    final maxY = math.max(0.0, screen.height - cardSize.height);

    setState(() {
      _position = Offset(raw.dx.clamp(0.0, maxX), raw.dy.clamp(0.0, maxY));
    });
  }

  void _openSpeedPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: widget.style.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final options = const [15, 30, 45, 60, 90, 120, 180, 240, 300];
        return SafeArea(
          top: false,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.style.fontColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'سرعة التمرير التلقائي',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.style.fontColorTitle,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'الزمن اللازم لتمرير صفحة كاملة (كلما زاد الرقم كان التمرير أبطأ)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.style.fontColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((sec) {
                      final selected = sec == widget.speedSeconds;
                      return GestureDetector(
                        onTap: () {
                          widget.onChangeSpeed(sec);
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? widget.style.buttonColorBackground
                                : widget.style.buttonColorBackground.withValues(
                                    alpha: 0.12,
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.style.buttonColorBackground
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            '${sec}s',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : widget.style.fontColorTitle,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = _position ?? const Offset(8, 56);
    final bgColor = widget.style.colorBackground.withValues(alpha: 0.78);
    final accent = widget.style.buttonColorBackground;
    final playIconColor = widget.enabled ? Colors.white : accent;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        child: Container(
          key: _cardKey,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: widget.onExitFullscreen,
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.fullscreen_exit_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: widget.onToggle,
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? accent
                        : accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.enabled
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: playIconColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _openSpeedPicker,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed_rounded, color: accent, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.speedSeconds}s',
                        style: TextStyle(
                          color: widget.style.fontColorTitle,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
