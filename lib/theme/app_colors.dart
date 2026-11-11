import 'package:flutter/material.dart';

/// رنگ‌های سفیر — روشن و تاریک.
///
/// پس‌زمینه حالت تاریک: مشکی خنثی.
/// سطح کارت‌ها در حالت تاریک: خاکستری خنثی.
///
/// رنگ برند، دکمه‌ها، آیکن‌ها و حالت روشن حفظ شده‌اند.
///
/// چون مقدارها پویا هستند، عبارت‌هایی که از AppColors
/// استفاده می‌کنند نباید const باشند.
class AppColors {
  AppColors._();

  /// توسط main.dart و ThemeController تنظیم می‌شود.
  static bool isDark = false;

  static Color _p(int light, int dark) =>
      Color(isDark ? dark : light);

  /// رنگ اصلی برند
  static Color get primaryBrand =>
      _p(0xFF1B7A57, 0xFF34B27F);

  /// سبز تیره برند برای گرادیان هدر و بنر
  static Color get primaryDark =>
      _p(0xFF0E5F44, 0xFF0B4A36);

  /// دکمه اصلی
  static Color get primaryButton =>
      _p(0xFF169365, 0xFF169365);

  /// دکمه هنگام لمس
  static Color get primaryButtonPressed =>
      _p(0xFF0F4A35, 0xFF0F6B4A);

  /// زمینه ثانویه:
  /// روشن بدون تغییر؛ تاریک خاکستری خنثی.
  static Color get cardBackground =>
      _p(0xFFEAF6F1, 0xFF282828);

  /// هم‌معنی cardBackground
  static Color get cardLightBg =>
      _p(0xFFEAF6F1, 0xFF282828);

  /// سطح کارت‌ها، منوها و شیت‌ها
  static Color get cardBgLight =>
      _p(0xFFFFFFFF, 0xFF282828);

  /// پس‌زمینه اصلی صفحه
  static Color get backgroundLight =>
      _p(0xFFF8F9FA, 0xFF121212);

  /// کادر عمومی
  static Color get borderLight =>
      _p(0xFFE0E0E0, 0xFF3A3A3A);

  /// کادر فیلدها و کارت‌ها
  static Color get fieldBorder =>
      _p(0xFFE2E8F0, 0xFF383838);

  /// موفقیت
  static Color get success =>
      _p(0xFF22C55E, 0xFF2FCB6C);

  /// پرداخت‌شده
  static Color get successDark =>
      _p(0xFF16A34A, 0xFF22A858);

  /// لغو / خطا
  static Color get danger =>
      _p(0xFFE53935, 0xFFFF5A55);

  /// پس‌زمینه ملایم خطا
  static Color get dangerSoft =>
      _p(0xFFFFEBEE, 0xFF3A1B1D);

  /// متن روی دکمه
  static Color get buttonText =>
      _p(0xFFFFFFFF, 0xFFFFFFFF);

  /// متن اصلی
  static Color get textPrimary =>
      _p(0xFF212121, 0xFFECF1EF);

  /// متن ثانویه
  static Color get textSecondary =>
      _p(0xFF757575, 0xFF9AA8A1);

  /// آیکن ثانویه
  static Color get iconSecondary =>
      _p(0xFF757575, 0xFF9AA8A1);

  /// پس‌زمینه هشدار
  static Color get warningBg =>
      _p(0xFFFFF7ED, 0xFF33260F);

  /// هشدار
  static Color get warning =>
      _p(0xFFF59E0B, 0xFFF5B33C);

  /// آیکن هشدار
  static Color get warningIcon =>
      _p(0xFFD97706, 0xFFFBBF24);

  /// متن هشدار
  static Color get warningText =>
      _p(0xFF92400E, 0xFFFCD38A);

  /// دستگیره کشوها؛ خاکستری خنثی در حالت تاریک
  static Color get handle =>
      _p(0xFFD1D5DB, 0xFF808080);

  /// جداکننده نوار بالا
  static Color get appBarDivider =>
      _p(0xFFD6DADF, 0xFF333333);

  /// جداکننده بخش‌ها
  static Color get sectionDivider =>
      _p(0xFFF1F5F9, 0xFF242424);

  /// کادر کارت‌ها
  static Color get cardBorder =>
      _p(0xFFE8ECEF, 0xFF383838);

  /// سازگاری با کدهای قبلی
  static Color get wheelGreen =>
      _p(0xFF39B169, 0xFF39B169);

  /// پین مبدأ
  static Color get originBlue =>
      _p(0xFF2563EB, 0xFF5B8DEF);

  // رنگ‌های موضوعی آیکن‌ها — بدون تغییر

  static Color get accentPurple =>
      _p(0xFF8158CF, 0xFFB49AFF);

  static Color get accentOrange =>
      _p(0xFFC97A14, 0xFFF5B65B);

  static Color get accentTeal =>
      _p(0xFF0E8F9C, 0xFF4FD1DC);

  // هم‌نام‌های قدیمی

  static Color get primaryPressed =>
      primaryButtonPressed;

  static Color get buttonPressed =>
      primaryButtonPressed;

  /// رنگ خط مسیر روی نقشه
  static String get routeLineHex =>
      isDark ? '#5B8DEF' : '#0066FF';

  static String get routeTraveledHex =>
      isDark ? '#5A6660' : '#B0B7C3';

  /// استایل نقشه
  static String get mapStyleAsset => isDark
      ? 'assets/map/style_dark.json'
      : 'assets/map/style.json';
}
