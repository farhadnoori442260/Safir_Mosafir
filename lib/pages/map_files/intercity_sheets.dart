import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../theme/app_colors.dart';

class IntercitySheets {
  static const Color safirBrandColor = Color(0xFF145A41);
  static const Color originBlueColor = Color(0xFF2563EB);

  // ════════════════════════════════════════════════════════════
  //  ابزارها
  // ════════════════════════════════════════════════════════════

  /// ترجمه با متن جایگزین.
  /// (در easy_localization اگر کلید پیدا نشود خود کلید برمی‌گردد، نه متن خالی؛
  /// پس باید با خود کلید مقایسه کرد تا متن جایگزین واقعاً استفاده شود.)
  static String _tr(String key, String fallback, {List<String>? args}) {
    final String value = args == null ? key.tr() : key.tr(args: args);
    return (value.isEmpty || value == key) ? fallback : value;
  }

  /// یکسان‌سازی متن برای جستجو: «ي» و «ك» عربی، ارقام و حروف بزرگ
  static String _normalize(String input) {
    String s = input.trim().toLowerCase();

    s = s
        .replaceAll('ي', 'ی')
        .replaceAll('ى', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('ۀ', 'ه')
        .replaceAll('\u200c', ' ');

    const String fa = '۰۱۲۳۴۵۶۷۸۹';
    const String ar = '٠١٢٣٤٥٦٧٨٩';
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }

    return s;
  }

  static const List<String> _afghanMonths = <String>[
    'حمل',
    'ثور',
    'جوزا',
    'سرطان',
    'اسد',
    'سنبله',
    'میزان',
    'عقرب',
    'قوس',
    'جدی',
    'دلو',
    'حوت',
  ];

  static String _toFaDigits(Object value) {
    const String en = '0123456789';
    const String fa = '۰۱۲۳۴۵۶۷۸۹';

    String s = value.toString();
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(en[i], fa[i]);
    }
    return s;
  }

  /// تبدیل میلادی به شمسی؛ خروجی: [سال، ماه، روز]
  static List<int> _gregorianToJalali(int gy, int gm, int gd) {
    const List<int> gDaysBefore = <int>[
      0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334,
    ];

    int jy = gy <= 1600 ? 0 : 979;
    final int y = gy <= 1600 ? gy - 621 : gy - 1600;
    final int y2 = gm > 2 ? y + 1 : y;

    int days = (365 * y) +
        ((y2 + 3) ~/ 4) -
        ((y2 + 99) ~/ 100) +
        ((y2 + 399) ~/ 400) -
        80 +
        gd +
        gDaysBefore[gm - 1];

    jy += 33 * (days ~/ 12053);
    days %= 12053;

    jy += 4 * (days ~/ 1461);
    days %= 1461;

    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }

    final int jm = days < 186 ? 1 + days ~/ 31 : 7 + (days - 186) ~/ 30;
    final int jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);

    return <int>[jy, jm, jd];
  }

  /// مثلاً «۲۸ میزان ۱۴۰۵»
  static String _formatJalali(DateTime date) {
    final DateTime local = date.toLocal();
    final List<int> j = _gregorianToJalali(local.year, local.month, local.day);

    return '${_toFaDigits(j[2])} ${_afghanMonths[j[1] - 1]} ${_toFaDigits(j[0])}';
  }

  // ════════════════════════════════════════════════════════════
  //  ۱. شیت انتخاب شهر مقصد
  // ════════════════════════════════════════════════════════════

  /// 🏙️ نمایش شیت انتخاب شهر مقصد با جستجو و کلیک روی نقشه
  static void showCityPicker({
    required BuildContext context,
    required List<Map<String, dynamic>> targetCities,
    required Function(Map<String, dynamic> city) onCitySelected,
    VoidCallback? onPickOnMapPressed,
  }) {
    List<Map<String, dynamic>> filteredCities = List.from(targetCities);
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _tr('intercity.select_destination_city', 'انتخاب شهر مقصد'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // کادر جستجو
                  TextField(
                    onChanged: (query) {
                      final String q = _normalize(query);

                      setSheetState(() {
                        filteredCities = targetCities.where((city) {
                          final String name =
                              _normalize(city['name']?.toString() ?? '');
                          final String province =
                              _normalize(city['province']?.toString() ?? '');

                          return name.contains(q) || province.contains(q);
                        }).toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: _tr(
                        'intercity.search_city_hint',
                        'جستجوی نام شهر یا ولایت...',
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: safirBrandColor,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // دکمهٔ انتخاب روی نقشه
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onPickOnMapPressed?.call();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: safirBrandColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: safirBrandColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_rounded, color: safirBrandColor),
                          const SizedBox(width: 10),
                          Text(
                            _tr(
                              'intercity.select_on_map',
                              'انتخاب مستقیم از روی نقشه',
                            ),
                            style: const TextStyle(
                              color: safirBrandColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            isRTL
                                ? Icons.arrow_back_ios_new_rounded
                                : Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: safirBrandColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _tr('intercity.popular_cities', 'شهرهای پرتردد'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.38,
                    ),
                    child: filteredCities.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                _tr(
                                  'intercity.no_city_found',
                                  'شهری با این مشخصات یافت نشد',
                                ),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredCities.length,
                            separatorBuilder: (c, i) => const Divider(
                              height: 1,
                              color: Color(0xFFEEEEEE),
                            ),
                            itemBuilder: (context, index) {
                              final Map<String, dynamic> city =
                                  filteredCities[index];
                              final String cityName =
                                  city['name']?.toString() ?? '';
                              final String? province =
                                  city['province']?.toString();

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_city_rounded,
                                    color: safirBrandColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  cityName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  province != null && province.isNotEmpty
                                      ? 'ولایت $province'
                                      : _tr(
                                          'intercity.province_label',
                                          '',
                                          args: [cityName],
                                        ),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: Icon(
                                  isRTL
                                      ? Icons.chevron_left_rounded
                                      : Icons.chevron_right_rounded,
                                  color: Colors.grey,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  onCitySelected(city);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  //  ۲. شیت فاکتور و ثبت سفر بین‌شهری
  // ════════════════════════════════════════════════════════════

  /// 💳 شیت فاکتور، تنظیم زمان، تعداد مسافر و ثبت نهایی سفر بین‌شهری
  static Widget buildStep2IntercitySheet({
    required BuildContext context,
    String originAddress = '',
    String destinationAddress = '',
    dynamic travelDate,
    int passengerCount = 1,
    double fareAmount = 0.0,
    double distanceInKm = 0.0,
    bool isLoading = false,
    VoidCallback? onEditOrigin,
    VoidCallback? onEditDestination,
    VoidCallback? onSelectTimingPressed,
    VoidCallback? onSelectPassengersPressed,
    VoidCallback? onRequestTrip,
    VoidCallback? onSubmitTrip,
    Function(dynamic)? onDateSelected,
    Function(int)? onPassengersChanged,
  }) {
    final VoidCallback? submitAction = onRequestTrip ?? onSubmitTrip;
    final double safeBottom = MediaQuery.of(context).padding.bottom;

    // متن تاریخ: شمسی (ماه‌های افغانی)
    final String dateText;
    if (travelDate is DateTime) {
      dateText = _formatJalali(travelDate);
    } else if (travelDate != null && travelDate.toString().isNotEmpty) {
      dateText = travelDate.toString();
    } else {
      dateText = _tr('intercity.today', 'امروز');
    }

    final String personLabel = _tr('person', 'نفر');

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: EdgeInsets.fromLTRB(12, 12, 12, 12 + safeBottom),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // کادر مبدأ و مقصد
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: onEditOrigin,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: originBlueColor,
                          size: 12,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tr('intercity.origin', 'مبدأ'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                originAddress.isEmpty
                                    ? _tr(
                                        'intercity.selected_origin_default',
                                        'موقعیت فعلی',
                                      )
                                    : originAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: safirBrandColor,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  InkWell(
                    onTap: onEditDestination,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tr('intercity.destination', 'مقصد'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                destinationAddress.isEmpty
                                    ? _tr(
                                        'intercity.selected_destination_default',
                                        'انتخاب شهر مقصد',
                                      )
                                    : destinationAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: safirBrandColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // تاریخ و تعداد مسافر
            Row(
              children: [
                // انتخاب تاریخ
                Expanded(
                  child: InkWell(
                    onTap: onSelectTimingPressed ??
                        () async {
                          final DateTime today =
                              DateUtils.dateOnly(DateTime.now());

                          // ✅ اگر تاریخِ قبلاً انتخاب‌شده گذشته باشد، دیالوگ کرش نمی‌کند
                          final DateTime initial = travelDate is DateTime &&
                                  !DateUtils.dateOnly(travelDate)
                                      .isBefore(today)
                              ? DateUtils.dateOnly(travelDate)
                              : today;

                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: today,
                            lastDate: today.add(const Duration(days: 60)),
                          );

                          if (picked != null) {
                            onDateSelected?.call(picked);
                          }
                        },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.indigo.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.indigo,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tr('intercity.travel_time', 'زمان حرکت'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  dateText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // تعداد مسافران با کنترل + / -
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            if (passengerCount > 1) {
                              onPassengersChanged?.call(passengerCount - 1);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.remove,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              _tr('intercity.passengers_count', 'تعداد مسافر'),
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '$passengerCount $personLabel',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            if (passengerCount < 6) {
                              onPassengersChanged?.call(passengerCount + 1);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // کرایه
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('intercity.fare_cost', 'هزینه تخمینی'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (distanceInKm > 0)
                      Text(
                        'مسافت: ${distanceInKm.toStringAsFixed(1)} کیلومتر',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                Text(
                  '${fareAmount.toStringAsFixed(0)} ${_tr('intercity.currency', 'افغانی')}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: safirBrandColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // دکمهٔ ثبت درخواست
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: safirBrandColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: isLoading ? null : submitAction,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _tr(
                          'intercity.request_trip',
                          'ثبت درخواست سفر بین شهری',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
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
