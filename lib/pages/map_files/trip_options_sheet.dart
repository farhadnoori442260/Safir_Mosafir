import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:safir_passengers/theme/app_colors.dart';

/// ترجمه با متن جایگزین (چون .tr() وقتی کلید نیست خودِ کلید را برمی‌گرداند)
String _ot(String key, String fallback) {
  final String v = key.tr();
  return (v.trim().isEmpty || v == key) ? fallback : v;
}

class TripOptionsSheet extends StatefulWidget {
  final String? secondDestination;
  final int stopMinutes;
  final bool isRoundTrip;
  final bool hasLuggage;
  final bool preferSilence;
  final VoidCallback onSelectSecondDestinationOnMap;
  final Function(
    String? secondDest,
    int stopMinutes,
    bool isRoundTrip,
    bool hasLuggage,
    bool preferSilence,
  ) onSave;

  const TripOptionsSheet({
    Key? key,
    this.secondDestination,
    this.stopMinutes = 0,
    this.isRoundTrip = false,
    this.hasLuggage = false,
    this.preferSilence = false,
    required this.onSelectSecondDestinationOnMap,
    required this.onSave,
  }) : super(key: key);

  @override
  State<TripOptionsSheet> createState() => _TripOptionsSheetState();
}

class _TripOptionsSheetState extends State<TripOptionsSheet> {
  late String? _secondDestination;
  late int _stopMinutes;
  late bool _isRoundTrip;
  late bool _hasLuggage;
  late bool _preferSilence;

  bool _stopExpanded = false;

  static const List<int> _stopChoices = [0, 5, 10, 20];

  @override
  void initState() {
    super.initState();
    _secondDestination = widget.secondDestination;
    _stopMinutes = widget.stopMinutes;
    _isRoundTrip = widget.isRoundTrip;
    _hasLuggage = widget.hasLuggage;
    _preferSilence = widget.preferSilence;
    // اگر قبلاً توقفی انتخاب شده، گزینه‌ها باز باشند
    _stopExpanded = _stopMinutes > 0;
  }

  String _stopLabel(int m) {
    switch (m) {
      case 0:
        return _ot('stop_none', 'بدون توقف');
      case 5:
        return _ot('stop_5_min', '۵ دقیقه');
      case 10:
        return _ot('stop_10_min', '۱۰ دقیقه');
      case 20:
        return _ot('stop_20_min', '۲۰ دقیقه');
      default:
        return '$m ${_ot('minutes_suffix', 'دقیقه')}';
    }
  }

  int get _activeCount {
    int c = 0;
    if ((_secondDestination ?? '').isNotEmpty) c++;
    if (_stopMinutes > 0) c++;
    if (_isRoundTrip) c++;
    if (_hasLuggage) c++;
    if (_preferSilence) c++;
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSecond = (_secondDestination ?? '').isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                const SizedBox(height: 10),

                // عنوان و دکمه بازگشت
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        _ot('opt_ride_options', 'گزینه‌های سفر'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),

                // ⚠️ هشدار تغییر گزینه‌ها (به راننده اعلان می‌رود)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notifications_active_rounded,
                          color: AppColors.warningIcon, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _ot(
                            'trip_options_change_warning',
                            'با تغییر این گزینه‌ها، راننده مطلع می‌شود.',
                          ),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.warningText,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ۱. مقصد دوم
                _OptionTile(
                  icon: Icons.add_location_alt_rounded,
                  accent: AppColors.success,
                  title: _ot('opt_second_destination', 'مقصد دوم'),
                  subtitle: hasSecond ? _secondDestination! : '',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelectSecondDestinationOnMap();
                  },
                  trailing: hasSecond
                      ? IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: _ot('remove', 'حذف'),
                          icon: Icon(Icons.close_rounded,
                              size: 20, color: AppColors.textSecondary),
                          onPressed: () {
                            setState(() => _secondDestination = null);
                          },
                        )
                      : null,
                ),

                // ۲. توقف در مسیر
                _OptionTile(
                  icon: Icons.pause_circle_filled_rounded,
                  accent: AppColors.warning,
                  title: _ot('opt_stop_in_path', 'توقف در مسیر'),
                  subtitle: _stopMinutes > 0 ? _stopLabel(_stopMinutes) : '',
                  expandedChild: _stopExpanded
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _stopChoices.map((m) {
                            final bool sel = m == _stopMinutes;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _stopMinutes = m);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
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
                                  _stopLabel(m),
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
                          }).toList(),
                        )
                      : null,
                  chevronTurned: _stopExpanded,
                  onTap: () {
                    setState(() => _stopExpanded = !_stopExpanded);
                  },
                ),

                // ۳. رفت و برگشت
                _SwitchTile(
                  icon: Icons.swap_horiz_rounded,
                  accent: AppColors.originBlue,
                  title: _ot('opt_round_trip', 'رفت و برگشت'),
                  hint: _ot('opt_round_trip_hint',
                      'راننده منتظر می‌ماند و شما را برمی‌گرداند'),
                  value: _isRoundTrip,
                  onChanged: (val) {
                    setState(() => _isRoundTrip = val);
                  },
                ),

                // ۴. بار یا چمدان
                _SwitchTile(
                  icon: Icons.luggage_rounded,
                  accent: AppColors.warningIcon,
                  title: _ot('opt_extra_luggage', 'بار یا چمدان اضافه'),
                  hint: _ot('opt_extra_luggage_hint',
                      'راننده برای جای بار آماده می‌شود'),
                  value: _hasLuggage,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _hasLuggage = val);
                  },
                ),

                // ۵. تمایلی به گفتگو ندارم
                _SwitchTile(
                  icon: Icons.volume_off_rounded,
                  accent: AppColors.textSecondary,
                  title: _ot('opt_prefer_silence', 'تمایلی به گفتگو ندارم'),
                  hint: _ot('opt_prefer_silence_hint',
                      'سفری آرام و بدون صحبت اضافه'),
                  value: _preferSilence,
                  isLast: true,
                  onChanged: (val) {
                    setState(() => _preferSilence = val);
                  },
                ),

                const SizedBox(height: 20),

                // دکمه‌های تایید و انصراف
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          _ot('cancel', 'انصراف'),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButton,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          widget.onSave(
                            _secondDestination,
                            _stopMinutes,
                            _isRoundTrip,
                            _hasLuggage,
                            _preferSilence,
                          );
                          Navigator.pop(context);
                        },
                        child: Text(
                          _activeCount > 0
                              ? '${_ot('confirm_btn', 'تأیید')} ($_activeCount)'
                              : _ot('confirm_btn', 'تأیید'),
                          style: TextStyle(
                            color: AppColors.buttonText,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
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
    );
  }
}

/// ردیف قابل لمس با آیکون رنگی، زیرعنوان و (اختیاری) محتوای بازشونده
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? expandedChild;
  final bool chevronTurned;

  const _OptionTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.onTap,
    this.subtitle = '',
    this.trailing,
    this.expandedChild,
    this.chevronTurned = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _IconBadge(icon: icon, accent: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBrand,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                AnimatedRotation(
                  turns: chevronTurned ? 0.25 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: expandedChild == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: expandedChild!,
                  ),
                ),
        ),
        Divider(height: 1, thickness: 0.6, color: AppColors.borderLight),
      ],
    );
  }
}

/// ردیف کلیددار با آیکون رنگی و توضیح کوتاه
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String hint;
  final bool value;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _IconBadge(icon: icon, accent: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  activeColor: AppColors.buttonText,
                  activeTrackColor: AppColors.primaryBrand,
                  inactiveThumbColor: AppColors.textSecondary,
                  inactiveTrackColor: AppColors.backgroundLight,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 0.6, color: AppColors.borderLight),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color accent;
  const _IconBadge({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: accent),
    );
  }
}
