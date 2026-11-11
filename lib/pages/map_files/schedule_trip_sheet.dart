import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:shamsi_date/shamsi_date.dart';
import 'package:safir_passengers/theme/app_colors.dart';

const List<String> _afghanMonths = [
  'حمل', 'ثور', 'جوزا', 'سرطان', 'اسد', 'سنبله',
  'میزان', 'عقرب', 'قوس', 'جدی', 'دلو', 'حوت'
];

// شنبه=۱ ... جمعه=۷ (همان قراردادِ getter.weekDay در پکیج shamsi_date)
const List<String> _afghanWeekDayShort = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
const List<String> _afghanWeekDayFull = [
  'شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'
];

/// ترجمه با متن جایگزین (چون .tr() وقتی کلید نیست خودِ کلید را برمی‌گرداند)
String _st(String key, String fallback) {
  final String v = key.tr();
  return (v.trim().isEmpty || v == key) ? fallback : v;
}

/// حداقل فاصله تا زمان سفر زمان‌بندی‌شده
const Duration _minLead = Duration(minutes: 10);

class ScheduleTripSheet extends StatefulWidget {
  final DateTime? initialDateTime;
  final Function(DateTime selectedDateTime) onScheduleConfirmed;

  const ScheduleTripSheet({
    Key? key,
    this.initialDateTime,
    required this.onScheduleConfirmed,
  }) : super(key: key);

  @override
  State<ScheduleTripSheet> createState() => _ScheduleTripSheetState();
}

class _ScheduleTripSheetState extends State<ScheduleTripSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = widget.initialDateTime ??
        DateTime.now().add(const Duration(minutes: 30));
    _selectedDate = now;
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  DateTime get _combined => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  // 🗓️ نام برج‌های خورشیدی افغانستان (حمل، ثور، جوزا...)
  String get _afghanFormattedDate {
    final Jalali j = Jalali.fromDateTime(_selectedDate);
    return '${j.day} ${_afghanMonths[j.month - 1]} ${j.year}';
  }

  String get _weekDayName {
    final Jalali j = Jalali.fromDateTime(_selectedDate);
    return _afghanWeekDayFull[j.weekDay - 1];
  }

  String get _formattedTime {
    final hour = _selectedTime.hour.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// «امروز» / «فردا» / «۳ روز دیگر»
  String get _relativeDay {
    final DateTime today = DateTime.now();
    final int diff = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;

    if (diff <= 0) return _st('day_today', 'امروز');
    if (diff == 1) return _st('day_tomorrow', 'فردا');
    return '$diff ${_st('days_later', 'روز دیگر')}';
  }

  void _applyQuick(DateTime dt) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = dt;
      _selectedTime = TimeOfDay.fromDateTime(dt);
      _error = null;
    });
  }

  List<_QuickOption> _quickOptions() {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = now.add(const Duration(days: 1));
    return [
      _QuickOption(
        _st('sched_in_30', '۳۰ دقیقه بعد'),
        now.add(const Duration(minutes: 30)),
      ),
      _QuickOption(
        _st('sched_in_1h', '۱ ساعت بعد'),
        now.add(const Duration(hours: 1)),
      ),
      _QuickOption(
        _st('sched_tomorrow_morning', 'فردا ۷ صبح'),
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 7, 0),
      ),
      _QuickOption(
        _st('sched_tomorrow_evening', 'فردا ۵ عصر'),
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 17, 0),
      ),
    ];
  }

  bool _isQuickSelected(DateTime dt) =>
      _combined.year == dt.year &&
      _combined.month == dt.month &&
      _combined.day == dt.day &&
      _combined.hour == dt.hour &&
      _combined.minute == dt.minute;

  // 📅 تقویم شمسی سفارشی — به‌جای showDatePicker که فقط میلادی پشتیبانی می‌کند
  Future<void> _pickDate() async {
    HapticFeedback.lightImpact();

    final Jalali initial = Jalali.fromDateTime(_selectedDate);
    final Jalali first = Jalali.fromDateTime(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );
    final Jalali last = Jalali.fromDateTime(
      DateTime.now().add(const Duration(days: 30)),
    );

    final Jalali? picked = await showModalBottomSheet<Jalali>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBgLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _JalaliDatePickerSheet(
        initialDate: initial,
        firstDate: first,
        lastDate: last,
      ),
    );

    if (picked != null) {
      final DateTime g = picked.toDateTime();
      setState(() {
        _selectedDate = DateTime(
          g.year,
          g.month,
          g.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        _error = null;
      });
    }
  }

  Future<void> _pickTime() async {
    HapticFeedback.lightImpact();
    final bool dark = AppColors.isDark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final base = Theme.of(context);
        final scheme = dark
            ? ColorScheme.dark(
                primary: AppColors.primaryBrand,
                onPrimary: Colors.white,
                surface: AppColors.cardBgLight,
                onSurface: AppColors.textPrimary,
              )
            : ColorScheme.light(
                primary: AppColors.primaryBrand,
                onPrimary: Colors.white,
                surface: AppColors.cardBgLight,
                onSurface: AppColors.textPrimary,
              );
        return Theme(
          data: base.copyWith(colorScheme: scheme),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
        _error = null;
      });
    }
  }

  void _confirm() {
    final DateTime target = _combined;
    if (target.isBefore(DateTime.now().add(_minLead))) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = target.isBefore(DateTime.now())
            ? _st('schedule_past_error', 'زمان انتخابی نمی‌تواند در گذشته باشد')
            : _st('schedule_too_soon_error',
                'حداقل ۱۰ دقیقه بعد را انتخاب کنید تا راننده فرصت رسیدن داشته باشد');
      });
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onScheduleConfirmed(target);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final List<_QuickOption> quick = _quickOptions();

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.handle,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.originBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event_available_rounded,
                      color: AppColors.originBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _st('opt_schedule', 'زمان‌بندی سفر'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _st('schedule_subtitle',
                            'راننده قبل از زمان تعیین‌شده برای شما می‌آید'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ⚡ انتخاب سریع
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quick.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final q = quick[i];
                  final bool sel = _isQuickSelected(q.time);
                  return GestureDetector(
                    onTap: () => _applyQuick(q.time),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primaryBrand
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? AppColors.primaryBrand
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Text(
                        q.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: sel
                              ? AppColors.buttonText
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // کارت انتخاب تاریخ
                Expanded(
                  child: _buildPickerCard(
                    title: _st('select_date_title', 'تاریخ'),
                    value: _afghanFormattedDate,
                    icon: Icons.calendar_today_rounded,
                    accent: AppColors.originBlue,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                // کارت انتخاب زمان
                Expanded(
                  child: _buildPickerCard(
                    title: _st('select_time_title', 'ساعت'),
                    value: _formattedTime,
                    icon: Icons.access_time_rounded,
                    accent: AppColors.warning,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 📝 خلاصهٔ زمان انتخاب‌شده
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 20, color: AppColors.primaryBrand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_relativeDay، $_weekDayName  •  $_formattedTime',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ⚠️ خطا
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 18, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // دکمه ثبت و تأیید زمان‌بندی
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _st('confirm_schedule_btn', 'تأیید زمان‌بندی'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.buttonText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBgLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 15, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickOption {
  final String label;
  final DateTime time;
  const _QuickOption(this.label, this.time);
}

/// 🗓️ تقویم هجری شمسی سفارشی با نام برج‌های افغانستان.
/// جایگزین showDatePicker می‌شود چون آن ویجت فقط تقویم میلادی را پشتیبانی می‌کند.
class _JalaliDatePickerSheet extends StatefulWidget {
  final Jalali initialDate;
  final Jalali firstDate;
  final Jalali lastDate;

  const _JalaliDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_JalaliDatePickerSheet> createState() => _JalaliDatePickerSheetState();
}

class _JalaliDatePickerSheetState extends State<_JalaliDatePickerSheet> {
  late Jalali _selected;
  late Jalali _displayedMonth; // روز اول ماهی که نمایش داده می‌شود

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _displayedMonth =
        Jalali(widget.initialDate.year, widget.initialDate.month, 1);
  }

  int _monthIndex(Jalali j) => j.year * 12 + j.month;

  bool get _canGoPrev =>
      _monthIndex(_displayedMonth) > _monthIndex(widget.firstDate);
  bool get _canGoNext =>
      _monthIndex(_displayedMonth) < _monthIndex(widget.lastDate);

  void _goPrevMonth() {
    if (!_canGoPrev) return;
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = _displayedMonth.month == 1
          ? Jalali(_displayedMonth.year - 1, 12, 1)
          : Jalali(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _goNextMonth() {
    if (!_canGoNext) return;
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = _displayedMonth.month == 12
          ? Jalali(_displayedMonth.year + 1, 1, 1)
          : Jalali(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  bool _isSameDay(Jalali a, Jalali b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isWithinAllowedRange(Jalali day) {
    final DateTime d = day.toDateTime();
    final DateTime f = widget.firstDate.toDateTime();
    final DateTime l = widget.lastDate.toDateTime();
    return !d.isBefore(DateTime(f.year, f.month, f.day)) &&
        !d.isAfter(DateTime(l.year, l.month, l.day));
  }

  @override
  Widget build(BuildContext context) {
    final int leadingBlanks = _displayedMonth.weekDay - 1; // شنبه=۱
    final int daysInMonth = _displayedMonth.monthLength;
    final Jalali today = Jalali.now();

    final List<Jalali?> cells = <Jalali?>[
      ...List<Jalali?>.filled(leadingBlanks, null),
      ...List<Jalali?>.generate(
        daysInMonth,
        (i) => Jalali(_displayedMonth.year, _displayedMonth.month, i + 1),
      ),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.handle,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // هدر: ماه/سال + فلش‌های جابه‌جایی
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _canGoPrev ? _goPrevMonth : null,
                  color: AppColors.primaryBrand,
                  disabledColor: AppColors.handle,
                ),
                Text(
                  '${_afghanMonths[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _canGoNext ? _goNextMonth : null,
                  color: AppColors.primaryBrand,
                  disabledColor: AppColors.handle,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // سرستون روزهای هفته (جمعه قرمز)
            Row(
              children: List.generate(7, (i) {
                return Expanded(
                  child: Center(
                    child: Text(
                      _afghanWeekDayShort[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: i == 6
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),

            // شبکهٔ روزها
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: cells.map((day) {
                if (day == null) return const SizedBox.shrink();

                final bool enabled = _isWithinAllowedRange(day);
                final bool isSelected = _isSameDay(day, _selected);
                final bool isToday = _isSameDay(day, today);
                final bool isFriday = day.weekDay == 7;

                Color textColor;
                if (!enabled) {
                  textColor = AppColors.handle;
                } else if (isSelected) {
                  textColor = AppColors.buttonText;
                } else if (isFriday) {
                  textColor = AppColors.danger;
                } else {
                  textColor = AppColors.textPrimary;
                }

                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: GestureDetector(
                    onTap: enabled
                        ? () {
                            HapticFeedback.selectionClick();
                            setState(() => _selected = day);
                          }
                        : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryBrand
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: (isToday && !isSelected)
                            ? Border.all(
                                color: AppColors.primaryBrand, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: (isSelected || isToday)
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _st('confirm_date_btn', 'تأیید تاریخ'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.buttonText,
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
