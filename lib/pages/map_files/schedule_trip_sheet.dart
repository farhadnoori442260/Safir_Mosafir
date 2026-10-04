import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:safir_passengers/theme/app_colors.dart';

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

  // 🗓️ تبدیل تاریخ انتخابی به رشته هجری شمسی (مثلاً ۱۴۰۵/۰۷/۱۳)
  String get _jalaliFormattedDate {
    Jalali j = Jalali.fromDateTime(_selectedDate);
    String month = j.month.toString().padLeft(2, '0');
    String day = j.day.toString().padLeft(2, '0');
    return '${j.year}/$month/$day';
  }

  // ⏰ فرمت نمایش ساعت (مثلاً ۱۷:۴۶)
  String get _formattedTime {
    final hour = _selectedTime.hour.toString().padLeft(2, '0');
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickDate() async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
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
              // کارت انتخاب تاریخ هجری شمسی
              Expanded(
                child: _buildPickerCard(
                  title: 'select_date_title'.tr().isNotEmpty ? 'select_date_title'.tr() : 'انتخاب تاریخ',
                  value: _jalaliFormattedDate,
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
