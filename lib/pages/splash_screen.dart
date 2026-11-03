import 'dart:math' as math;

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

/// لوگوی متحرک:
/// ابتدا مسیر S، سپس پین و در آخر نوشته از چپ به راست.
class SafirLogoAnimation extends StatefulWidget {
  const SafirLogoAnimation({
    super.key,
    this.onCompleted,
    this.backgroundColor = const Color(0xFF0E7A5F),
    this.title = 'Safir',
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

    _playAnimation();
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double logoSize = math.min(screenWidth * 0.52, 260.0);

    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final double textProgress =
              _text.value.clamp(0.0, 1.0).toDouble();

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SafirLogoPainter(
                    roadProgress: _road.value,
                    pinProgress: _pin.value,
                    bgColor: widget.backgroundColor,
                  ),
                ),
              ),

              // متن داخل فضای خالی زیر نشان قرار می‌گیرد،
              // نه زیر کل بوم مربعی.
              Positioned(
                top: logoSize * 0.805,
                left: logoSize * 0.232,
                width: logoSize * 0.562,
                height: logoSize * 0.185,
                child: Semantics(
                  label: widget.title,
                  child: ExcludeSemantics(
                    child: ClipRect(
                      clipper: _SafirTextRevealClipper(
                        progress: textProgress,
                      ),
                      child: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: Text(
                            widget.title,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            textScaler: TextScaler.noScaling,
                            style: const TextStyle(
                              inherit: false,
                              color: Colors.white,
                              fontFamily: 'sans-serif',
                              fontSize: 100,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              height: 1,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ماسک از چپ به راست؛ ابعاد و جای متن ثابت می‌ماند.
class _SafirTextRevealClipper extends CustomClipper<Rect> {
  const _SafirTextRevealClipper({
    required this.progress,
  });

  final double progress;

  @override
  Rect getClip(Size size) {
    final double t = progress.clamp(0.0, 1.0).toDouble();

    return Rect.fromLTWH(
      0,
      0,
      size.width * t,
      size.height,
    );
  }

  @override
  bool shouldReclip(covariant _SafirTextRevealClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

/// صفحهٔ اسپلش مستقل.
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

/// رسم نشان اصلی روی بوم ۱۰۲۴×۱۰۲۴.
/// شکل و مختصات نشان اصلی حفظ شده است.
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
  static const double _k = 0.88;
  static const double _pinCx = 735;
  static const double _pinCy = 300;

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

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / 1024;

    canvas.save();
    canvas.scale(scale);
    canvas.translate(-1.2, -1.3);

    final Paint white = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;

    // رسم مسیر S.
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
      final metrics = road.computeMetrics().toList();

      final double total = metrics.fold<double>(
        0,
        (sum, metric) => sum + metric.length,
      );

      double remaining =
          total * roadProgress.clamp(0.0, 1.0).toDouble();

      final Path drawn = Path();

      for (final metric in metrics) {
        if (remaining <= 0) break;

        final double take = math.min(
          remaining,
          metric.length,
        );

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

    // ظاهرشدن پین از نوک آن.
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

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SafirLogoPainter oldDelegate) {
    return oldDelegate.roadProgress != roadProgress ||
        oldDelegate.pinProgress != pinProgress ||
        oldDelegate.bgColor != bgColor;
  }
}
