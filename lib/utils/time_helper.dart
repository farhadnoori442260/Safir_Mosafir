import 'package:easy_localization/easy_localization.dart';

class TimeHelper {
  /// ۱. تبدیل ثانیه OSRM به متن خوانا با پشتیبانی کامل از ترجمه
  static String formatDuration(double durationInSeconds) {
    if (durationInSeconds <= 0) {
      return _localized('less_than_one_minute', 'کمتر از ۱ دقیقه');
    }

    int minutes = (durationInSeconds / 60).round();

    if (minutes < 1) {
      return _localized('less_than_one_minute', 'کمتر از ۱ دقیقه');
    } else if (minutes < 60) {
      // استفاده از آرگومان برای قرارگیری عدد در متن ترجمه‌شده
      return 'minutes_format'.tr(args: [minutes.toString()]);
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      
      if (remainingMinutes == 0) {
        return 'hours_format'.tr(args: [hours.toString()]);
      }
      return 'hours_and_minutes_format'.tr(args: [hours.toString(), remainingMinutes.toString()]);
    }
  }

  /// ۲. محاسبه ساعت دقیق رسیدن به مقصد (ETA) به فرمت 24 ساعته (مثلاً 14:35)
  static String getArrivalTime(double durationInSeconds) {
    if (durationInSeconds <= 0) {
      DateTime now = DateTime.now();
      return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    }

    int totalMinutes = (durationInSeconds / 60).round();
    if (totalMinutes < 1) totalMinutes = 1;

    DateTime arrivalTime = DateTime.now().add(Duration(minutes: totalMinutes));

    String hour = arrivalTime.hour.toString().padLeft(2, '0');
    String minute = arrivalTime.minute.toString().padLeft(2, '0');

    return "$hour:$minute";
  }

  static String _localized(String key, String fallback) {
    final String value = key.tr();
    return value.isEmpty || value == key ? fallback : value;
  }
}
