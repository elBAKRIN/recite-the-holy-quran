import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recite_the_holy_quran/main.dart';
import 'package:recite_the_holy_quran/models/colors_app_models/colors_app_style_model.dart';
import 'package:recite_the_holy_quran/models/colors_app_models/colors_mode_light_model.dart';
import 'package:recite_the_holy_quran/models/colors_app_models/colors_mode_night_model.dart';

import '../controllers/sittings_app_controllers/settings_controller.dart';
import '../controllers/start_app_loading_controller.dart';
import '../services/islamic_calendar_content.dart';
import '../utils/hijri_date.dart';

ColorsAppStyleModel _activeStyle() {
  if (Get.isRegistered<SettingsController>()) {
    return Get.find<SettingsController>().styleApp;
  }
  return modeAppNight ? nightModeStyle : lightModeStyle;
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StartAppLoadingController>(
      init: StartAppLoadingController(),
      builder: (loadingCtl) {
        return GetBuilder<SettingsController>(
          builder: (_) {
            return Scaffold(
              backgroundColor: _activeStyle().colorBackground,
              body: SafeArea(
                child: _StartScreenContent(isExiting: loadingCtl.isExiting),
              ),
            );
          },
        );
      },
    );
  }
}

class _StartScreenContent extends StatefulWidget {
  const _StartScreenContent({required this.isExiting});

  final bool isExiting;

  @override
  State<_StartScreenContent> createState() => _StartScreenContentState();
}

class _StartScreenContentState extends State<_StartScreenContent>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtl;
  late final AnimationController _ambientCtl;
  late final AnimationController _morphCtl;
  late final AnimationController _exitCtl;

  int _currentOrnament = 0;
  int _nextOrnament = 1;
  static const int _ornamentCount = 4;
  Timer? _morphTimer;

  /// Flipped at the midpoint of the splash sequence so accent colors smoothly
  /// transition from the seed tone to the active theme's title accent.
  bool _themeRevealed = false;
  Timer? _themeTimer;
  static const Duration _themeRevealAt = Duration(milliseconds: 2275);
  static const Duration _colorTransition = Duration(milliseconds: 900);

  /// Content for today's Hijri date. Resolved once at mount so the splash
  /// shows a single consistent occasion text across its lifetime.
  late final OccasionContent _content;

  /// Subtitle fades in shortly after the main Rubik's reveal finishes.
  bool _subtitleVisible = false;
  Timer? _subtitleTimer;
  static const Duration _subtitleAt = Duration(milliseconds: 1900);

  @override
  void initState() {
    super.initState();

    _content = contentFor(toHijri(DateTime.now()));

    _entryCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();

    _ambientCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _morphCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _exitCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _themeTimer = Timer(_themeRevealAt, () {
      if (mounted) setState(() => _themeRevealed = true);
    });

    _subtitleTimer = Timer(_subtitleAt, () {
      if (mounted) setState(() => _subtitleVisible = true);
    });

    _morphTimer = Timer.periodic(const Duration(milliseconds: 950), (_) {
      if (!mounted || _morphCtl.isAnimating) return;
      _nextOrnament = (_currentOrnament + 1) % _ornamentCount;
      _morphCtl.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        setState(() => _currentOrnament = _nextOrnament);
        _morphCtl.value = 0;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _StartScreenContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExiting &&
        !oldWidget.isExiting &&
        _exitCtl.status == AnimationStatus.dismissed) {
      _exitCtl.forward();
      // Stop ambient breathing so the bloom-away reads as a single deliberate gesture.
      _ambientCtl.stop();
      _morphTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _morphTimer?.cancel();
    _themeTimer?.cancel();
    _subtitleTimer?.cancel();
    _entryCtl.dispose();
    _ambientCtl.dispose();
    _morphCtl.dispose();
    _exitCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _activeStyle();
    // Seed tones — soft / desaturated. They blend toward the full theme accent
    // at midpoint, so the splash feels like it's "warming up" into its palette.
    final seedAccent = style.colorTafser;
    final seedSoft = style.shadowColor;
    final finalAccent = style.fontColorTitle;
    final finalSoft = style.colorFontAudio;

    final accent = _themeRevealed ? finalAccent : seedAccent;
    final softAccent = _themeRevealed ? finalSoft : seedSoft;

    return Center(
      child: AnimatedBuilder(
        animation: _exitCtl,
        builder: (context, child) {
          final t = Curves.easeInCubic.transform(_exitCtl.value);
          return Opacity(
            opacity: 1 - t,
            child: Transform.translate(
              offset: Offset(0, -14 * t),
              child: Transform.scale(scale: 1 + 0.06 * t, child: child),
            ),
          );
        },
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: accent),
          duration: _colorTransition,
          curve: Curves.easeInOutCubic,
          builder: (context, animAccent, _) {
            return TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: softAccent),
              duration: _colorTransition,
              curve: Curves.easeInOutCubic,
              builder: (context, animSoft, _) {
                final a = animAccent ?? accent;
                final s = animSoft ?? softAccent;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildOrnament(a, s),
                    const SizedBox(height: 44),
                    _buildAnimatedText(a),
                    const SizedBox(height: 14),
                    _buildSubtitle(style.fontColor),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrnament(Color accent, Color softAccent) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entryCtl, _ambientCtl, _morphCtl]),
      builder: (context, _) {
        final entry = Curves.easeOutCubic.transform(_entryCtl.value);
        final breath = 1 + 0.035 * math.sin(_ambientCtl.value * 2 * math.pi);
        final spin = _ambientCtl.value * 2 * math.pi * 0.18;
        final morph = Curves.easeInOutCubic.transform(_morphCtl.value);

        return Opacity(
          opacity: entry,
          child: Transform.scale(
            scale: (0.82 + 0.18 * entry) * breath,
            child: SizedBox(
              width: 130,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: spin * 0.6,
                    child: Opacity(
                      opacity: 0.35,
                      child: CustomPaint(
                        size: const Size(130, 130),
                        painter: _HaloPainter(color: softAccent),
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: spin,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: 1 - morph,
                          child: Transform.scale(
                            scale: 1 - 0.18 * morph,
                            child: Transform.rotate(
                              angle: -morph * math.pi / 6,
                              child: CustomPaint(
                                size: const Size(110, 110),
                                painter: _OrnamentPainter(
                                  index: _currentOrnament,
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: morph,
                          child: Transform.scale(
                            scale: 0.82 + 0.18 * morph,
                            child: Transform.rotate(
                              angle: (1 - morph) * math.pi / 6,
                              child: CustomPaint(
                                size: const Size(110, 110),
                                painter: _OrnamentPainter(
                                  index: _nextOrnament,
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedText(Color accent) {
    // Leave a side margin so wrapped/auto-fitted text never touches the edges.
    final maxTextWidth = MediaQuery.of(context).size.width - 48;
    return AnimatedBuilder(
      animation: _entryCtl,
      builder: (context, _) {
        final entry = Curves.easeOutCubic.transform(_entryCtl.value);
        return Opacity(
          opacity: entry,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - entry)),
            // Style is fixed (neutral white) so the baked picture never has to
            // be re-rendered when the accent changes; tint flows through a
            // ColorFiltered layer instead.
            child: _RubiksText(
              text: _content.mainText.tr,
              maxWidth: maxTextWidth,
              style: const TextStyle(
                fontFamily: 'hafs',
                fontSize: 32,
                height: 1.6,
                color: Colors.white,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Color(0x2EFFFFFF),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              tint: accent,
              startDelay: const Duration(milliseconds: 380),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle(Color color) {
    final subtitleText = _content.subtitle.tr;
    if (subtitleText.isEmpty) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: _subtitleVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _subtitleVisible ? Offset.zero : const Offset(0, 0.3),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 48,
          ),
          child: Text(
            subtitleText,
            textDirection: _detectDirection(subtitleText),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'hafs',
              fontSize: 17,
              height: 1.4,
              color: color.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft outer glow ring drawn behind the ornament.
class _HaloPainter extends CustomPainter {
  final Color color;
  _HaloPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.48;
    final ring = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // dashed circle
    const dashCount = 36;
    const sweep = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final start = i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start,
        sweep * 0.45,
        false,
        ring,
      );
    }
    // inner subtle circle
    canvas.drawCircle(
      center,
      r * 0.78,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_HaloPainter old) => old.color != color;
}

/// Four hand-drawn Islamic geometric ornaments, selectable by [index].
class _OrnamentPainter extends CustomPainter {
  final int index;
  final Color color;
  _OrnamentPainter({required this.index, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.46;

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color.withValues(alpha: 0.10);
    final accentStroke = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (index % _StartScreenContentState._ornamentCount) {
      case 0:
        _drawRubElHizb(canvas, cx, cy, r, stroke, fill, accentStroke);
        break;
      case 1:
        _drawRosette(canvas, cx, cy, r, stroke, fill, accentStroke);
        break;
      case 2:
        _drawCompassStar(canvas, cx, cy, r, stroke, fill, accentStroke);
        break;
      case 3:
        _drawInterlacedOctagon(canvas, cx, cy, r, stroke, fill, accentStroke);
        break;
    }
  }

  // ۞  classic Quranic 8-point star = two overlapping squares.
  void _drawRubElHizb(
    Canvas c,
    double cx,
    double cy,
    double r,
    Paint s,
    Paint f,
    Paint a,
  ) {
    Path square(double rot) {
      final p = Path();
      for (int i = 0; i < 4; i++) {
        final ang = rot + i * math.pi / 2;
        final x = cx + r * math.cos(ang);
        final y = cy + r * math.sin(ang);
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      p.close();
      return p;
    }

    final p1 = square(-math.pi / 2);
    final p2 = square(-math.pi / 2 + math.pi / 4);
    c.drawPath(p1, f);
    c.drawPath(p2, f);
    c.drawPath(p1, s);
    c.drawPath(p2, s);

    // inner ring + center dot
    c.drawCircle(Offset(cx, cy), r * 0.30, a);
    c.drawCircle(
      Offset(cx, cy),
      r * 0.08,
      Paint()
        ..color = s.color
        ..style = PaintingStyle.fill,
    );
  }

  // 8-petal arabesque rosette
  void _drawRosette(
    Canvas c,
    double cx,
    double cy,
    double r,
    Paint s,
    Paint f,
    Paint a,
  ) {
    const petals = 8;
    final petalLen = r;
    final petalWidth = r * 0.34;
    for (int i = 0; i < petals; i++) {
      final ang = i * 2 * math.pi / petals;
      final tipX = cx + petalLen * math.cos(ang);
      final tipY = cy + petalLen * math.sin(ang);
      final perp = ang + math.pi / 2;
      final bx1 = cx + petalWidth * 0.55 * math.cos(perp);
      final by1 = cy + petalWidth * 0.55 * math.sin(perp);
      final bx2 = cx - petalWidth * 0.55 * math.cos(perp);
      final by2 = cy - petalWidth * 0.55 * math.sin(perp);
      final midX = cx + petalLen * 0.55 * math.cos(ang);
      final midY = cy + petalLen * 0.55 * math.sin(ang);

      final path = Path()
        ..moveTo(bx1, by1)
        ..quadraticBezierTo(
          midX + petalWidth * 0.9 * math.cos(perp),
          midY + petalWidth * 0.9 * math.sin(perp),
          tipX,
          tipY,
        )
        ..quadraticBezierTo(
          midX - petalWidth * 0.9 * math.cos(perp),
          midY - petalWidth * 0.9 * math.sin(perp),
          bx2,
          by2,
        )
        ..close();
      c.drawPath(path, f);
      c.drawPath(path, s);
    }
    // central medallion
    c.drawCircle(Offset(cx, cy), r * 0.28, f);
    c.drawCircle(Offset(cx, cy), r * 0.28, s);
    c.drawCircle(Offset(cx, cy), r * 0.14, a);
  }

  // 16-ray compass / sunburst star
  void _drawCompassStar(
    Canvas c,
    double cx,
    double cy,
    double r,
    Paint s,
    Paint f,
    Paint a,
  ) {
    const points = 16;
    final outer = r;
    final inner = r * 0.52;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outer : inner;
      final ang = -math.pi / 2 + i * math.pi / points;
      final x = cx + radius * math.cos(ang);
      final y = cy + radius * math.sin(ang);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    c.drawPath(path, f);
    c.drawPath(path, s);
    // inner hex highlight
    final inner2 = Path();
    for (int i = 0; i < 8; i++) {
      final ang = -math.pi / 2 + i * 2 * math.pi / 8;
      final x = cx + r * 0.30 * math.cos(ang);
      final y = cy + r * 0.30 * math.sin(ang);
      if (i == 0) {
        inner2.moveTo(x, y);
      } else {
        inner2.lineTo(x, y);
      }
    }
    inner2.close();
    c.drawPath(inner2, a);
    c.drawCircle(
      Offset(cx, cy),
      r * 0.06,
      Paint()
        ..color = s.color
        ..style = PaintingStyle.fill,
    );
  }

  // Interlaced octagon woven with diagonal strands — geometric Islamic pattern
  void _drawInterlacedOctagon(
    Canvas c,
    double cx,
    double cy,
    double r,
    Paint s,
    Paint f,
    Paint a,
  ) {
    // outer octagon
    final oct = Path();
    for (int i = 0; i < 8; i++) {
      final ang = -math.pi / 2 + math.pi / 8 + i * math.pi / 4;
      final x = cx + r * math.cos(ang);
      final y = cy + r * math.sin(ang);
      if (i == 0) {
        oct.moveTo(x, y);
      } else {
        oct.lineTo(x, y);
      }
    }
    oct.close();
    c.drawPath(oct, f);
    c.drawPath(oct, s);

    // 4 interlaced chords forming an 8-point star inside
    final innerR = r * 0.92;
    for (int i = 0; i < 8; i++) {
      final a1 = -math.pi / 2 + math.pi / 8 + i * math.pi / 4;
      final a2 = a1 + 3 * math.pi / 4; // skip 3 vertices
      final x1 = cx + innerR * math.cos(a1);
      final y1 = cy + innerR * math.sin(a1);
      final x2 = cx + innerR * math.cos(a2);
      final y2 = cy + innerR * math.sin(a2);
      c.drawLine(Offset(x1, y1), Offset(x2, y2), s);
    }

    // soft inner circle + dot
    c.drawCircle(Offset(cx, cy), r * 0.20, a);
    c.drawCircle(
      Offset(cx, cy),
      r * 0.07,
      Paint()
        ..color = s.color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_OrnamentPainter old) =>
      old.index != index || old.color != color;
}

/// Reveals an Arabic string one grapheme at a time using random 3D rotations,
/// like Rubik's-cube cells settling into place. Ligatures stay intact because
/// the full string is shaped once and only its per-glyph slices are animated.
class _RubiksText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color tint;
  final Duration startDelay;
  final double maxWidth;
  const _RubiksText({
    required this.text,
    required this.style,
    required this.tint,
    required this.maxWidth,
    this.startDelay = Duration.zero,
  });

  @override
  State<_RubiksText> createState() => _RubiksTextState();
}

/// Returns RTL if the string contains any Arabic-script character, else LTR.
/// Lets the splash widget animate Arabic dhikr and Latin translations with
/// the right reading order without forcing a global locale check.
TextDirection _detectDirection(String s) {
  for (final code in s.runes) {
    if ((code >= 0x0600 && code <= 0x06FF) || // Arabic
        (code >= 0x0750 && code <= 0x077F) || // Arabic Supplement
        (code >= 0x08A0 && code <= 0x08FF) || // Arabic Extended-A
        (code >= 0xFB50 && code <= 0xFDFF) || // Arabic Presentation Forms-A
        (code >= 0xFE70 && code <= 0xFEFF)) {
      // Arabic Presentation Forms-B
      return TextDirection.rtl;
    }
  }
  return TextDirection.ltr;
}

class _RubiksTextState extends State<_RubiksText>
    with SingleTickerProviderStateMixin {
  late TextPainter _painter;
  late final ui.Picture _picture;
  late final List<_CharSlice> _slices;
  late final AnimationController _ctl;
  Timer? _startTimer;

  // Auto-fit bounds for long translations: wrap to at most [_maxLines], and
  // never shrink the font below [_minFontSize] (keeps the splash text bold).
  static const double _minFontSize = 22;
  static const int _maxLines = 2;

  TextPainter _layoutAt(double fontSize, TextDirection direction) =>
      TextPainter(
        text: TextSpan(
          text: widget.text,
          style: widget.style.copyWith(fontSize: fontSize),
        ),
        textDirection: direction,
        textAlign: TextAlign.center,
      )..layout(maxWidth: widget.maxWidth);

  @override
  void initState() {
    super.initState();

    final direction = _detectDirection(widget.text);

    // Auto-fit: short Arabic dhikr fits one line, but longer translations
    // (en/fr/de/…) used to run off-screen because the painter was laid out
    // unbounded. Wrap at maxWidth and shrink the font (down to a floor) until
    // the text fits within maxLines, so every language stays on screen.
    final baseSize = widget.style.fontSize ?? 32;
    var fontSize = baseSize;
    _painter = _layoutAt(fontSize, direction);
    while (_painter.computeLineMetrics().length > _maxLines &&
        fontSize > _minFontSize) {
      fontSize = math.max(_minFontSize, fontSize - 1);
      _painter.dispose();
      _painter = _layoutAt(fontSize, direction);
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _painter.paint(canvas, Offset.zero);
    _picture = recorder.endRecording();

    final rand = math.Random();
    final visible = <_CharSlice>[];
    var offset = 0;
    for (final ch in widget.text.characters) {
      final start = offset;
      final end = offset + ch.length;
      offset = end;
      if (ch.trim().isEmpty) continue;
      final boxes = _painter.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );
      if (boxes.isEmpty) continue;
      final rect = boxes.first.toRect();
      if (rect.width <= 0 || rect.height <= 0) continue;
      visible.add(
        _CharSlice(
          rect: rect,
          axis: rand.nextInt(6),
          magnitude: rand.nextBool() ? math.pi / 2 : math.pi,
          direction: rand.nextBool() ? 1.0 : -1.0,
        ),
      );
    }
    // Stagger by reading order: the first character a reader sees lands first.
    // RTL → sort by .right descending. LTR → by .left ascending.
    if (direction == TextDirection.rtl) {
      visible.sort((a, b) => b.rect.right.compareTo(a.rect.right));
    } else {
      visible.sort((a, b) => a.rect.left.compareTo(b.rect.left));
    }

    const stagger = 0.07;
    const charDur = 0.42;
    for (var i = 0; i < visible.length; i++) {
      final s = visible[i];
      final t0 = i * stagger;
      visible[i] = s.withTiming(t0, t0 + charDur);
    }

    // The controller value runs 0→1. Without normalization, late-staggered
    // slices have endT > 1 and never reach raw=1, leaving them with a tiny
    // residual angle (~2–4°). Scale all timings into [0, 1] and grow the
    // controller duration by the same factor so real-time pacing is unchanged.
    final maxEnd = visible.isEmpty
        ? 1.0
        : visible.map((s) => s.endT).reduce(math.max);
    if (maxEnd > 1.0) {
      for (var i = 0; i < visible.length; i++) {
        final s = visible[i];
        visible[i] = s.withTiming(s.startT / maxEnd, s.endT / maxEnd);
      }
    }
    _slices = visible;

    final totalMs = (maxEnd * 1000).clamp(600, 4000).toInt();
    _ctl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    if (widget.startDelay > Duration.zero) {
      _startTimer = Timer(widget.startDelay, () {
        if (mounted) _ctl.forward();
      });
    } else {
      _ctl.forward();
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _ctl.dispose();
    _painter.dispose();
    _picture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ColorFiltered with srcIn recolors the entire baked picture (text +
    // shadow) to the live tint without re-rasterizing per frame — the GPU
    // applies the filter at composite time, so smooth color interpolation is
    // essentially free.
    return SizedBox(
      width: _painter.width,
      height: _painter.height,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(widget.tint, BlendMode.srcIn),
        child: AnimatedBuilder(
          animation: _ctl,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [for (final s in _slices) _buildSlice(s)],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSlice(_CharSlice s) {
    final span = (s.endT - s.startT).clamp(0.0001, 1.0);
    final raw = ((_ctl.value - s.startT) / span).clamp(0.0, 1.0);
    if (raw == 0) return const SizedBox.shrink();

    final eased = Curves.easeOutCubic.transform(raw);
    final opacity = Curves.easeOutQuart.transform(raw);
    final angle = (1 - eased) * s.magnitude * s.direction;

    final m = Matrix4.identity()..setEntry(3, 2, 0.0018);
    switch (s.axis) {
      case 0:
        m.rotateX(angle);
        break;
      case 1:
        m.rotateY(angle);
        break;
      case 2:
        m.rotateZ(angle);
        break;
      case 3:
        m.rotateX(angle * 0.7);
        m.rotateY(angle * 0.7);
        break;
      case 4:
        m.rotateX(angle * 0.7);
        m.rotateZ(angle * 0.5);
        break;
      case 5:
        m.rotateY(angle * 0.7);
        m.rotateZ(angle * 0.5);
        break;
    }

    return Positioned(
      left: s.rect.left,
      top: s.rect.top,
      width: s.rect.width,
      height: s.rect.height,
      child: Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: m,
          child: RepaintBoundary(
            child: ClipRect(
              child: CustomPaint(
                size: s.rect.size,
                painter: _TextSlicePainter(
                  picture: _picture,
                  offset: -s.rect.topLeft,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CharSlice {
  final Rect rect;
  final int axis;
  final double magnitude;
  final double direction;
  final double startT;
  final double endT;
  const _CharSlice({
    required this.rect,
    required this.axis,
    required this.magnitude,
    required this.direction,
    this.startT = 0,
    this.endT = 1,
  });

  _CharSlice withTiming(double s, double e) => _CharSlice(
    rect: rect,
    axis: axis,
    magnitude: magnitude,
    direction: direction,
    startT: s,
    endT: e,
  );
}

class _TextSlicePainter extends CustomPainter {
  final ui.Picture picture;
  final Offset offset;
  _TextSlicePainter({required this.picture, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(offset.dx, offset.dy);
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(_TextSlicePainter old) =>
      old.picture != picture || old.offset != offset;
}
