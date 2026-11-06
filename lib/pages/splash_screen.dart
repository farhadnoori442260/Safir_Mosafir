import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// نشان ثابت سفیر، بدون نوشته و انیمیشن.
class SafirLogoMark extends StatelessWidget {
  const SafirLogoMark({
    super.key,
    this.size = 160,
    this.backgroundColor = const Color(0xFF0E7A5F),
  });

  final double size;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SafirLogoPainter(
          roadProgress: 1,
          pinProgress: 1,
          bgColor: backgroundColor,
        ),
      ),
    );
  }
}

/// ابتدا مسیر S، سپس پین و در آخر نوشته آشکار می‌شود.
/// نوشته با نسبت طبیعی حروف، وسط زیر S قرار می‌گیرد.
class SafirLogoAnimation extends StatefulWidget {
  const SafirLogoAnimation({
    super.key,
    this.onCompleted,
    this.backgroundColor = const Color(0xFF0E7A5F),
    this.title = 'SAFIR',
    this.holdAfterFinish = const Duration(milliseconds: 450),
  });

  final VoidCallback? onCompleted;
  final Color backgroundColor;
  final String title;
  final Duration holdAfterFinish;

  @override
  State<SafirLogoAnimation> createState() =>
      _SafirLogoAnimationState();
}

class _SafirLogoAnimationState extends State<SafirLogoAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _road;
  late final Animation<double> _pin;
  late final Animation<double> _text;

  _TextInk? _ink;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _road = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.00,
        0.55,
        curve: Curves.easeInOutCubic,
      ),
    );

    _pin = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.55,
        0.76,
        curve: Curves.easeOutBack,
      ),
    );

    _text = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.72,
        1.00,
        curve: Curves.easeInOutCubic,
      ),
    );

    _measureText();
    _playAnimation();
  }

  @override
  void didUpdateWidget(covariant SafirLogoAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.title != widget.title) {
      _ink = null;
      _measureText();
    }
  }

  Future<void> _measureText() async {
    final String measuredTitle = widget.title;

    try {
      final _TextInk? ink =
          await _TextInk.measure(measuredTitle);

      if (!mounted || measuredTitle != widget.title) {
        return;
      }

      setState(() => _ink = ink);
    } catch (e) {
      debugPrint('Safir splash text measure error: $e');
    }
  }

  Future<void> _playAnimation() async {
    try {
      await _controller.forward().orCancel;

      if (!mounted) return;

      await Future<void>.delayed(widget.holdAfterFinish);

      if (!mounted) return;

      widget.onCompleted?.call();
    } on TickerCanceled {
      // صفحه قبل از پایان انیمیشن بسته شده است.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth =
        MediaQuery.of(context).size.width;

    final double logoSize =
        math.min(screenWidth * 0.52, 260.0);

    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Semantics(
            label: widget.title,
            child: CustomPaint(
              painter: _SafirLogoPainter(
                roadProgress: _road.value,
                pinProgress: _pin.value,
                bgColor: widget.backgroundColor,
                title: widget.title,
                ink: _ink,
                textProgress:
                    _text.value.clamp(0.0, 1.0).toDouble(),
                showText: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// صفحهٔ اسپلش مسافر.
class SafirSplashScreen extends StatelessWidget {
  const SafirSplashScreen({
    super.key,
    required this.onFinished,
    this.backgroundColor = const Color(0xFF0E7A5F),
  });

  final VoidCallback onFinished;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SafirLogoAnimation(
          title: 'SAFIR',
          backgroundColor: backgroundColor,
          onCompleted: onFinished,
        ),
      ),
    );
  }
}

/// همان فونت و وزن عنوان در نسخهٔ راننده.
const TextStyle _wordmarkStyle = TextStyle(
  inherit: false,
  color: Colors.white,
  fontFamily: 'Oswald',
  fontFamilyFallback: <String>['sans-serif'],
  fontWeight: FontWeight.w700,
  fontVariations: <ui.FontVariation>[
    ui.FontVariation('wght', 700),
  ],
  letterSpacing: 0,
  height: 1,
  decoration: TextDecoration.none,
);

/// ابعاد واقعی بخش قابل‌دیدن نوشته، بدون فضای خالی اطراف.
class _TextInk {
  const _TextInk({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.fontSize,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double fontSize;

  static Future<_TextInk?> measure(String text) async {
    if (text.isEmpty) return null;

    const double fontSize = 200;
    const double pad = 24;

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: _wordmarkStyle.copyWith(
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();

    ui.Picture? picture;
    ui.Image? image;

    try {
      final int w = (tp.width + pad * 2).ceil();
      final int h = (tp.height + pad * 2).ceil();

      final ui.PictureRecorder recorder =
          ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      tp.paint(canvas, const Offset(pad, pad));

      picture = recorder.endRecording();
      image = await picture.toImage(w, h);

      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (data == null) return null;

      int minX = w;
      int maxX = -1;
      int minY = h;
      int maxY = -1;

      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final int alpha =
              data.getUint8((y * w + x) * 4 + 3);

          if (alpha > 40) {
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }

      if (maxX < 0 || maxY < 0) return null;

      return _TextInk(
        left: minX - pad,
        top: minY - pad,
        width: (maxX - minX + 1).toDouble(),
        height: (maxY - minY + 1).toDouble(),
        fontSize: fontSize,
      );
    } finally {
      image?.dispose();
      picture?.dispose();
      tp.dispose();
    }
  }
}

/// رسم نشان اصلی روی بوم ۱۰۲۴×۱۰۲۴.
class _SafirLogoPainter extends CustomPainter {
  _SafirLogoPainter({
    required this.roadProgress,
    required this.pinProgress,
    required this.bgColor,
    this.title = '',
    this.ink,
    this.textProgress = 0,
    this.showText = false,
  });

  final double roadProgress;
  final double pinProgress;
  final Color bgColor;
  final String title;
  final _TextInk? ink;
  final double textProgress;
  final bool showText;

  static const double _stroke = 112;
  static const double _k = 0.88;
  static const double _pinCx = 735;
  static const double _pinCy = 300;

  static const double _sLeft = 238;
  static const double _sRight = 786;

  // فاصلهٔ نوشته از نشان، همان مقدار نسخهٔ قبلی است.
  static const double _textTop = 852;

  // ارتفاع هدف نوشته در بوم ۱۰۲۴.
  static const double _textHeight = 118;

  double get _groupShiftY =>
      512 - (222.6 + _textTop + _textHeight) / 2;

  Path _roadPath() {
    return Path()
      ..moveTo(330, 724)
      ..lineTo(624, 724)
      ..arcToPoint(
        const Offset(624, 512),
        radius: const Radius.circular(106),
        clockwise: false,
      )
      ..lineTo(400, 512)
      ..arcToPoint(
        const Offset(400, 300),
        radius: const Radius.circular(106),
        clockwise: true,
      )
      ..lineTo(690, 300);
  }

  Path _pinPath() {
    const double r = 88 * _k;
    const double cx = _pinCx;
    const double cy = _pinCy;

    return Path()
      ..moveTo(cx, cy - r)
      ..arcToPoint(
        const Offset(cx + r, cy),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..cubicTo(
        cx + r,
        cy + 52 * _k,
        cx + r - 56 * _k,
        cy + 104 * _k,
        cx,
        cy + 148 * _k,
      )
      ..cubicTo(
        cx - 32 * _k,
        cy + 104 * _k,
        cx - 88 * _k,
        cy + 52 * _k,
        cx - r,
        cy,
      )
      ..arcToPoint(
        const Offset(cx, cy - r),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..close();
  }

  void _paintWordmark(Canvas canvas) {
    final _TextInk? m = ink;

    if (m == null ||
        m.width <= 0 ||
        m.height <= 0 ||
        textProgress <= 0 ||
        title.isEmpty) {
      return;
    }

    const double targetW = _sRight - _sLeft;

    // حفظ نسبت طبیعی حروف، بدون اجبار به هم‌عرض شدن با S.
    final double scale = math.min(
      _textHeight / m.height,
      targetW / m.width,
    );

    final double fontSize = m.fontSize * scale;
    final double visibleWidth = m.width * scale;
    final double visibleHeight = m.height * scale;

    final double textLeft =
        _sLeft + (targetW - visibleWidth) / 2;

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: title,
        style: _wordmarkStyle.copyWith(
          fontSize: fontSize,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();

    final Offset origin = Offset(
      textLeft - m.left * scale,
      _textTop - m.top * scale,
    );

    canvas.save();

    canvas.clipRect(
      Rect.fromLTWH(
        textLeft - 6,
        _textTop - 20,
        (visibleWidth + 12) *
            textProgress.clamp(0.0, 1.0).toDouble(),
        visibleHeight + 40,
      ),
    );

    tp.paint(canvas, origin);

    canvas.restore();
    tp.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / 1024;

    canvas.save();
    canvas.scale(scale);
    canvas.translate(
      -1.2,
      -1.3 + (showText ? _groupShiftY : 0),
    );

    final Paint white = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;

    if (roadProgress > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(
            330,
            724 - _stroke / 2,
            90,
            _stroke,
          ),
          const Radius.circular(14),
        ),
        white,
      );

      final Path road = _roadPath();
      final List<ui.PathMetric> metrics =
          road.computeMetrics().toList();

      final double total = metrics.fold<double>(
        0,
        (sum, metric) => sum + metric.length,
      );

      double remaining =
          total * roadProgress.clamp(0.0, 1.0).toDouble();

      final Path drawn = Path();

      for (final ui.PathMetric metric in metrics) {
        if (remaining <= 0) break;

        final double take =
            math.min(remaining, metric.length);

        drawn.addPath(
          metric.extractPath(0, take),
          Offset.zero,
        );

        remaining -= take;
      }

      canvas.drawPath(
        drawn,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.butt
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      );
    }

    if (pinProgress > 0) {
      canvas.save();

      const double tipY = _pinCy + 148 * _k;

      canvas.translate(_pinCx, tipY);
      canvas.scale(
        pinProgress.clamp(0.0, 1.25).toDouble(),
      );
      canvas.translate(-_pinCx, -tipY);

      canvas.drawPath(_pinPath(), white);

      canvas.drawCircle(
        const Offset(_pinCx, _pinCy),
        30 * _k,
        Paint()
          ..color = bgColor
          ..isAntiAlias = true,
      );

      canvas.restore();
    }

    if (showText) {
      _paintWordmark(canvas);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _SafirLogoPainter oldDelegate,
  ) {
    return oldDelegate.roadProgress != roadProgress ||
        oldDelegate.pinProgress != pinProgress ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.textProgress != textProgress ||
        oldDelegate.ink != ink ||
        oldDelegate.title != title ||
        oldDelegate.showText != showText;
  }
}
