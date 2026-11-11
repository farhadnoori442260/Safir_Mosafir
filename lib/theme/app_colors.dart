import 'package:flutter/material.dart';

/// رنگ‌های سفیر — روشن و تاریک.
///
/// مقدار اول در _p برای حالت روشن و مقدار دوم برای حالت تاریک است.
/// isDark توسط main.dart و ThemeController تنظیم می‌شود.
///
/// چون رنگ‌ها getter هستند، عبارت‌هایی که از AppColors استفاده می‌کنند
/// نباید const باشند.
class AppColors {
  AppColors._();

  /// true وقتی برنامه در حالت تاریک است.
  static bool isDark = false;

  static Color _p(int light, int dark) {
    return Color(isDark ? dark : light);
  }

  // ─────────────────────────────────────────
  // برند و دکمه‌ها
  // ─────────────────────────────────────────

  /// رنگ اصلی برند
  static Color get primaryBrand =>
      _p(0xFF1B7A57, 0xFF34B27F);

  /// سبز تیره‌ی برند برای هدر و بنر
  static Color get primaryDark =>
      _p(0xFF0E5F44, 0xFF0B4A36);

  /// دکمه اصلی
  static Color get primaryButton =>
      _p(0xFF169365, 0xFF169365);

  /// دکمه هنگام لمس
  static Color get primaryButtonPressed =>
      _p(0xFF0F4A35, 0xFF0F6B4A);

  /// متن روی دکمه
  static Color get buttonText =>
      _p(0xFFFFFFFF, 0xFFFFFFFF);

  // ─────────────────────────────────────────
  // زمینه‌ها و سطح کارت‌ها
  // ─────────────────────────────────────────

  /// روشن: سبز بسیار ملایم
  /// تاریک: خاکستری خنثی، بدون ته‌رنگ سبز
  static Color get cardBackground =>
      _p(0xFFEAF6F1, 0xFF282828);

  /// هم‌معنی cardBackground
  static Color get cardLightBg => cardBackground;

  /// سطح کارت‌ها، منوها و شیت‌ها
  static Color get cardBgLight =>
      _p(0xFFFFFFFF, 0xFF282828);

  /// پس‌زمینه اصلی صفحه
  static Color get backgroundLight =>
      _p(0xFFF8F9FA, 0xFF121212);

  // ─────────────────────────────────────────
  // کادرها و جداکننده‌ها
  // ─────────────────────────────────────────

  /// کادر عمومی
  static Color get borderLight =>
      _p(0xFFE0E0E0, 0xFF3A3A3A);

  /// کادر فیلدها و کارت‌ها
  static Color get fieldBorder =>
      _p(0xFFE2E8F0, 0xFF383838);

  /// خط زیر نوار بالا
  static Color get appBarDivider =>
      _p(0xFFD6DADF, 0xFF333333);

  /// جداکننده بخش‌ها
  static Color get sectionDivider =>
      _p(0xFFF1F5F9, 0xFF242424);

  /// کادر کارت‌ها
  static Color get cardBorder =>
      _p(0xFFE8ECEF, 0xFF383838);

  // ─────────────────────────────────────────
  // متن‌ها و آیکن‌ها
  // ─────────────────────────────────────────

  /// متن اصلی
  static Color get textPrimary =>
      _p(0xFF212121, 0xFFE6E6E6);

  /// توضیحات و متن ثانویه
  static Color get textSecondary =>
      _p(0xFF757575, 0xFFB3B3B3);

  /// آیکن ثانویه
  static Color get iconSecondary =>
      _p(0xFF757575, 0xFFB3B3B3);

  /// دستگیره کشوها و فلش‌های منو
  static Color get handle =>
      _p(0xFFD1D5DB, 0xFF808080);

  // ─────────────────────────────────────────
  // موفقیت
  // ─────────────────────────────────────────

  static Color get success =>
      _p(0xFF22C55E, 0xFF2FCB6C);

  /// پرداخت‌شده یا پیام موفقیت
  static Color get successDark =>
      _p(0xFF16A34A, 0xFF22A858);

  // ─────────────────────────────────────────
  // خطا و لغو
  // ─────────────────────────────────────────

  static Color get danger =>
      _p(0xFFE53935, 0xFFFF5A55);

  /// پس‌زمینه ملایم خطا
  static Color get dangerSoft =>
      _p(0xFFFFEBEE, 0xFF3A1B1D);

  // ─────────────────────────────────────────
  // هشدار
  // ─────────────────────────────────────────

  /// پس‌زمینه هشدار
  static Color get warningBg =>
      _p(0xFFFFF7ED, 0xFF33260F);

  static Color get warning =>
      _p(0xFFF59E0B, 0xFFF5B33C);

  /// آیکن هشدار
  static Color get warningIcon =>
      _p(0xFFD97706, 0xFFFBBF24);

  /// متن هشدار
  static Color get warningText =>
      _p(0xFF92400E, 0xFFFCD38A);

  // ─────────────────────────────────────────
  // نقشه و مسیر
  // ─────────────────────────────────────────

  static Color get wheelGreen =>
      _p(0xFF39B169, 0xFF39B169);

  /// پین مبدأ
  static Color get originBlue =>
      _p(0xFF2563EB, 0xFF5B8DEF);

  /// رنگ خط مسیر؛ MapLibre رشته hex می‌خواهد.
  static String get routeLineHex =>
      isDark ? '#5B8DEF' : '#0066FF';

  static String get routeTraveledHex =>
      isDark ? '#5A6660' : '#B0B7C3';

  /// استایل نقشه
  static String get mapStyleAsset => isDark
      ? 'assets/map/style_dark.json'
      : 'assets/map/style.json';

  // ─────────────────────────────────────────
  // سازگاری با نام‌های قدیمی
  // ─────────────────────────────────────────

  static Color get primaryPressed => primaryButtonPressed;
  static Color get buttonPressed => primaryButtonPressed;
}
