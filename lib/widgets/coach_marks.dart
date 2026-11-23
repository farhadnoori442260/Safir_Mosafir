import 'package:easy_localization/easy_localization.dart'
    hide TextDirection;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safir_passengers/theme/app_colors.dart';

String _t(String key, String fallback) {
  final String v = key.tr();
  return (v.trim().isEmpty || v == key) ? fallback : v;
}

/// کلیدهای جاهایی که راهنما روی آن‌ها نور می‌اندازد.
class CoachKeys {
  static final GlobalKey taxi = GlobalKey(debugLabel: 'coach_taxi');
  static final GlobalKey search = GlobalKey(debugLabel: 'coach_search');
  static final GlobalKey menu = GlobalKey(debugLabel: 'coach_menu');
  static final GlobalKey mapPin = GlobalKey(debugLabel: 'coach_map_pin');
  static final GlobalKey mapSheet = GlobalKey(debugLabel: 'coach_map_sheet');
}

class _Step {
  const _Step(this.key, this.title, this.text);
  final GlobalKey key;
  final String title;
  final String text;
}

/// راهنمای اولین ورود مسافر. فقط یک بار نشان داده می‌شود؛
/// از منو می‌توان دوباره دید.
class CoachMarks {
  static const String _kDone = 'coach_done_passenger_v1';
  static const String _kMapDone = 'coach_done_map_v1';

  /// با هر افزایش، صفحهٔ هوم راهنما را دوباره نشان می‌دهد.
  static final ValueNotifier<int> replayTick = ValueNotifier<int>(0);

  static bool _showing = false;

  static Future<void> maybeStart(
    BuildContext context, {
    bool force = false,
  }) async {
    if (_showing) return;

    await _run(
      context,
      _kDone,
      force,
      <_Step>[
      _Step(
        CoachKeys.taxi,
        _t('coach_taxi_title', 'درخواست تاکسی'),
        _t(
          'coach_taxi_text',
          'آیکن سبز را به سمت راست بکشید تا صفحهٔ نقشه باز شود و مبدأ و مقصد را انتخاب کنید.',
        ),
      ),
      _Step(
        CoachKeys.search,
        _t('coach_search_title', 'کجا می‌روید؟'),
        _t(
          'coach_search_text',
          'با لمس این نوار هم می‌توانید مستقیم به نقشه بروید و مقصدتان را بگویید.',
        ),
      ),
      _Step(
        CoachKeys.menu,
        _t('coach_menu_title', 'منو'),
        _t(
          'coach_menu_text',
          'پروفایل، زبان، تم، پشتیبانی و خروج از حساب از اینجا باز می‌شوند.',
        ),
      ),
      ],
    );
  }

  /// راهنمای اولین ورود به صفحهٔ نقشه (انتخاب مبدأ و مقصد).
  static Future<void> maybeStartMap(
    BuildContext context, {
    bool force = false,
  }) async {
    await _run(
      context,
      _kMapDone,
      force,
      <_Step>[
        _Step(
          CoachKeys.mapPin,
          _t('coach_map_pin_title', 'مبدأ را مشخص کنید'),
          _t(
            'coach_map_pin_text',
            'نقشه را بکشید تا پین روی نقطهٔ سوارشدن‌تان قرار بگیرد. بعد از تأیید مبدأ، همین‌طور مقصد را انتخاب می‌کنید.',
          ),
        ),
        _Step(
          CoachKeys.mapSheet,
          _t('coach_map_sheet_title', 'جستجو و تأیید'),
          _t(
            'coach_map_sheet_text',
            'آدرس را جستجو کنید، از آدرس‌های ذخیره‌شده انتخاب کنید یا با دکمهٔ تأیید ادامه دهید.',
          ),
        ),
      ],
    );
  }

  static Future<void> _run(
    BuildContext context,
    String prefKey,
    bool force,
    List<_Step> steps,
  ) async {
    if (_showing) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!force && prefs.getBool(prefKey) == true) return;
    if (!context.mounted) return;

    // فقط وقتی همین صفحه، صفحهٔ بالایی است.
    if (ModalRoute.of(context)?.isCurrent != true) return;

    final List<_Step> all =
        steps.where((_Step s) => s.key.currentContext != null).toList();

    if (all.isEmpty || !context.mounted) return;

    _showing = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'coach',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (BuildContext c, Animation<double> a,
                Animation<double> b) =>
            _CoachOverlay(steps: all),
        transitionBuilder: (BuildContext c, Animation<double> a,
                Animation<double> b, Widget child) =>
            FadeTransition(opacity: a, child: child),
      );
    } finally {
      _showing = false;
      await prefs.setBool(prefKey, true);
    }
  }

  /// از منو: راهنما را دوباره فعال می‌کند.
  static Future<void> requestReplay() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDone, false);
    await prefs.setBool(_kMapDone, false);
    replayTick.value++;
  }
}

class _CoachOverlay extends StatefulWidget {
  const _CoachOverlay({required this.steps});
  final List<_Step> steps;

  @override
  State<_CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<_CoachOverlay> {
  int _index = 0;

  Rect? _rectOf(GlobalKey key) {
    final BuildContext? c = key.currentContext;
    if (c == null) return null;
    final RenderObject? ro = c.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return null;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _Step step = widget.steps[_index];
    final Size size = MediaQuery.of(context).size;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Rect rect = (_rectOf(step.key) ??
            Rect.fromCenter(
              center: size.center(Offset.zero),
              width: 0,
              height: 0,
            ))
        .inflate(8);

    final bool below = rect.center.dy < size.height / 2;
    final bool last = _index == widget.steps.length - 1;

    return PopScope(
      // دکمهٔ برگشت = رد کردن راهنما
      canPop: true,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(painter: _HolePainter(rect)),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: below ? rect.bottom + 14 : null,
            bottom: below ? null : size.height - rect.top + 14,
            child: Material(
              color: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: scheme.onSurface.withOpacity(0.12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.text,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.6,
                        color: scheme.onSurface.withOpacity(0.70),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Text(
                          '${_index + 1} / ${widget.steps.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withOpacity(0.60),
                          ),
                        ),
                        const Spacer(),
                        if (!last)
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              _t('coach_skip', 'رد کردن'),
                              style: TextStyle(
                                color: scheme.onSurface.withOpacity(0.70),
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBrand,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            last
                                ? _t('coach_done', 'شروع')
                                : _t('coach_next', 'بعدی'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  _HolePainter(this.hole);
  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(hole, const Radius.circular(28)),
      );
    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.72));
  }

  @override
  bool shouldRepaint(covariant _HolePainter old) => old.hole != hole;
}
