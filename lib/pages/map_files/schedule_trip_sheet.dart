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

  @override
  void initState() {
    super.initState();
    final now = widget.initialDateTime ?? DateTime.now().add(const Duration(minutes: 30));
    _selectedDate = now;
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  // 🗓️ تبدیل به نام برج‌های خورشیدی افغانستان (حمل، ثور، جوزا...)
  String get _afghanFormattedDate {
    Jalali j = Jalali.fromDateTime(_selectedDate);
    String monthName = _afghanMonths[j.month - 1];
    return '${j.day} $monthName ${j.year}';
  }

  // ⏰ فرمت نمایش ساعت
  String get _formattedTime {
    final hour = _selectedTime.hour.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _JalaliDatePickerSheet(
        initialDate: initial,
        firstDate: first,
        lastDate: last,
      ),
    );

    if (picked != null) {
      final DateTime pickedGregorian = picked.toDateTime();
      setState(() {
        _selectedDate = DateTime(
          pickedGregorian.year,
          pickedGregorian.month,
          pickedGregorian.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    HapticFeedback.lightImpact();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBrand,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'opt_schedule'.tr().isNotEmpty ? 'opt_schedule'.tr() : 'زمان‌بندی سفر',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // کارت انتخاب تاریخ
              Expanded(
                child: _buildPickerCard(
                  title: 'select_date_title'.tr().isNotEmpty ? 'select_date_title'.tr() : 'انتخاب تاریخ',
                  value: _afghanFormattedDate,
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              // کارت انتخاب زمان
              Expanded(
                child: _buildPickerCard(
                  title: 'select_time_title'.tr().isNotEmpty ? 'select_time_title'.tr() : 'انتخاب زمان',
                  value: _formattedTime,
                  icon: Icons.access_time_outlined,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // دکمه ثبت و تأیید زمان‌بندی
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedDate.isBefore(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('زمان انتخابی نمی‌تواند در گذشته باشد.')),
                  );
                  return;
                }
                HapticFeedback.mediumImpact();
                widget.onScheduleConfirmed(_selectedDate);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrand,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'confirm_schedule_btn'.tr().isNotEmpty ? 'confirm_schedule_btn'.tr() : 'تأیید زمان‌بندی',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primaryBrand),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🗓️ تقویم هجری شمسی سفارشی با نام برج‌های افغانستان.
/// جایگزین showDatePicker می‌شود چون آن ویجت فقط تقویم میلادی را پشتیبانی
/// می‌کند — حتی با locale فارسی، فقط متن‌ها ترجمه می‌شوند نه سیستم تقویم.
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
    _displayedMonth = Jalali(widget.initialDate.year, widget.initialDate.month, 1);
  }

  int _monthIndex(Jalali j) => j.year * 12 + j.month;

  bool get _canGoPrev => _monthIndex(_displayedMonth) > _monthIndex(widget.firstDate);
  bool get _canGoNext => _monthIndex(_displayedMonth) < _monthIndex(widget.lastDate);

  void _goPrevMonth() {
    if (!_canGoPrev) return;
    setState(() {
      _displayedMonth = _displayedMonth.month == 1
          ? Jalali(_displayedMonth.year - 1, 12, 1)
          : Jalali(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _goNextMonth() {
    if (!_canGoNext) return;
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // هدر: ماه/سال + فلش‌های جابه‌جایی
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _canGoPrev ? _goPrevMonth : null,
                  color: _canGoPrev ? AppColors.primaryBrand : Colors.grey.shade300,
                ),
                Text(
                  '${_afghanMonths[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _canGoNext ? _goNextMonth : null,
                  color: _canGoNext ? AppColors.primaryBrand : Colors.grey.shade300,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // سرستون روزهای هفته
            Row(
              children: _afghanWeekDayShort
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
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
                        color: isSelected ? AppColors.primaryBrand : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: !enabled
                              ? Colors.grey.shade300
                              : isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrand,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تأیید تاریخ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
