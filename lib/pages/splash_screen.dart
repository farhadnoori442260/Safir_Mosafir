import 'dart:math' as math;

import 'package:flutter/material.dart';

/// لوگوی ثابت (کامل) بدون انیمیشن؛ برای صفحهٔ خطا و جاهای دیگر
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

/// لوگوی متحرک Safir (بدون Scaffold):
///  ۱) جادهٔ S از انتهای پایین شروع می‌شود و تا بالا کشیده می‌شود
///  ۲) پین مقصد در انتهای مسیر ظاهر می‌شود
///  ۳) نوشتهٔ «Safir» زیر لوگو محو و بالا می‌آید
/// بعد از پایان انیمیشن [onCompleted] صدا زده می‌شود.
class SafirLogoAnimation extends StatefulWidget {
  const SafirLogoAnimation({
    super.key,
    this.onCompleted,
    this.backgroundColor = const Color(0xFF0E7A5F), // راننده: 0xFF12304F
    this.title = 'Safir',
    this.holdAfterFinish = const Duration(milliseconds: 450),
  });

  final VoidCallback? onCompleted;
  final Color backgroundColor;
  final String title;
  final Duration holdAfterFinish;

  @override
  State<SafirLogoAnimation> createState() => _SafirLogoAnimationState();
}

class _SafirLogoAnimationState extends State<SafirLogoAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _road;
  late final Animation<double> _pin;
  late final Animation<double> _text;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _road = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.55, curve: Curves.easeInOutCubic),
    );
    _pin = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.76, curve: Curves.easeOutBack),
    );
    _text = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 1.00, curve: Curves.easeOutCubic),
    );

    _controller.forward().whenComplete(() async {
      await Future<void>.delayed(widget.holdAfterFinish);
      if (!mounted) return;
      widget.onCompleted?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double logoSize = math.min(width * 0.52, 260);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double t = _text.value.clamp(0.0, 1.0).toDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: logoSize,
              height: logoSize,
              child: CustomPaint(
                painter: _SafirLogoPainter(
                  roadProgress: _road.value,
                  pinProgress: _pin.value,
                  bgColor: widget.backgroundColor,
                ),
              ),
            ),
            SizedBox(height: logoSize * 0.04),
            Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 14),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: logoSize * 0.17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: logoSize * 0.012,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// صفحهٔ اسپلش مستقل (اگر خواستید جدا استفاده کنید)
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
          backgroundColor: backgroundColor,
          onCompleted: onFinished,
        ),
      ),
    );
  }
}

/// رسم لوگو روی بوم ۱۰۲۴×۱۰۲۴ (همان مختصات فایل SVG آیکن)
class _SafirLogoPainter extends CustomPainter {
  _SafirLogoPainter({
    required this.roadProgress,
    required this.pinProgress,
    required this.bgColor,
  });

  final double roadProgress;
  final double pinProgress;
  final Color bgColor;

  static const double _stroke = 112;
  static const double _k = 0.88; // اندازهٔ پین
  static const double _pinCx = 735;
  static const double _pinCy = 300;

  Path _roadPath() {
    // از انتهای پایین (مبدأ) تا بالا؛ برعکسِ مسیر SVG
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
        cx + r, cy + 52 * _k,
        cx + r - 56 * _k, cy + 104 * _k,
        cx, cy + 148 * _k,
      )
      ..cubicTo(
        cx - 32 * _k, cy + 104 * _k,
        cx - 88 * _k, cy + 52 * _k,
        cx - r, cy,
      )
      ..arcToPoint(
        const Offset(cx, cy - r),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide / 1024;
    canvas.save();
    canvas.scale(s);
    canvas.translate(-1.2, -1.3); // مرکزدهی دقیق مثل آیکن

    final Paint white = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;

    // ───── ۱) جاده ─────
    if (roadProgress > 0) {
      // سرِ صاف و گردِ انتهای پایین
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(330, 724 - _stroke / 2, 90, _stroke),
          const Radius.circular(14),
        ),
        white,
      );

      final Path road = _roadPath();
      final metrics = road.computeMetrics().toList();
      final double total = metrics.fold<double>(0, (a, m) => a + m.length);
      double remaining = total * roadProgress.clamp(0.0, 1.0).toDouble();

      final Path drawn = Path();
      for (final m in metrics) {
        if (remaining <= 0) break;
        final double take = math.min(remaining, m.length);
        drawn.addPath(m.extractPath(0, take), Offset.zero);
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

    // ───── ۲) پین (از نوک بزرگ می‌شود) ─────
    if (pinProgress > 0) {
      canvas.save();
      const double tipY = _pinCy + 148 * _k;
      canvas.translate(_pinCx, tipY);
      canvas.scale(pinProgress.clamp(0.0, 1.25).toDouble());
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

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SafirLogoPainter old) =>
      old.roadProgress != roadProgress ||
      old.pinProgress != pinProgress ||
      old.bgColor != bgColor;
}
