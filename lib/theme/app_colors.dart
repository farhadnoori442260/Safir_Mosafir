import 'package:flutter/material.dart';

/// رنگ‌های سفیر — روشن و تاریک.
/// نام‌ها همان نام‌های قبلی‌اند؛ فقط حالا `static const` نیستند و بر اساس
/// [isDark] مقدار می‌دهند. [isDark] را main.dart (با ThemeController) تنظیم می‌کند.
///
/// نکته: چون مقدارها پویا هستند، جلوی عبارت‌هایی که AppColors دارند
/// نباید `const` بنویسید (tools/fix_const.py این کار را خودکار می‌کند).
class AppColors {
  AppColors._();

  /// true وقتی برنامه در حالت تاریک است.
  static bool isDark = false;

  static Color _p(int light, int dark) => Color(isDark ? dark : light);

  /// رنگ اصلی برند
  static Color get primaryBrand => _p(0xFF1B7A57, 0xFF34B27F);

  /// سبز تیره‌ی برند (گرادیان هدر و بنر)
  static Color get primaryDark => _p(0xFF0E5F44, 0xFF0B4A36);

  /// دکمه اصلی
  static Color get primaryButton => _p(0xFF169365, 0xFF169365);

  /// دکمه هنگام لمس
  static Color get primaryButtonPressed => _p(0xFF0F4A35, 0xFF0F6B4A);

  /// پس‌زمینه‌ی ملایم سبز (کارت‌ها، انتخاب‌شده)
  static Color get cardBackground => _p(0xFFEAF6F1, 0xFF16352A);

  /// هم‌معنی cardBackground
  static Color get cardLightBg => _p(0xFFEAF6F1, 0xFF16352A);

  /// سطح کارت‌ها و شیت‌ها
  static Color get cardBgLight => _p(0xFFFFFFFF, 0xFF1A211E);

  /// پس‌زمینه‌ی صفحه
  static Color get backgroundLight => _p(0xFFF8F9FA, 0xFF0F1412);

  /// کادر عمومی
  static Color get borderLight => _p(0xFFE0E0E0, 0xFF2A332F);

  /// کادر فیلدها و کارت‌ها
  static Color get fieldBorder => _p(0xFFE2E8F0, 0xFF2B3631);

  /// موفقیت
  static Color get success => _p(0xFF22C55E, 0xFF2FCB6C);

  /// پرداخت‌شده
  static Color get successDark => _p(0xFF16A34A, 0xFF22A858);

  /// لغو / خطا
  static Color get danger => _p(0xFFE53935, 0xFFFF5A55);

  /// پس‌زمینه‌ی ملایم خطا
  static Color get dangerSoft => _p(0xFFFFEBEE, 0xFF3A1B1D);

  /// متن روی دکمه
  static Color get buttonText => _p(0xFFFFFFFF, 0xFFFFFFFF);

  /// متن اصلی
  static Color get textPrimary => _p(0xFF212121, 0xFFECF1EF);

  /// متن ثانویه
  static Color get textSecondary => _p(0xFF757575, 0xFF9AA8A1);

  /// آیکون ثانویه
  static Color get iconSecondary => _p(0xFF757575, 0xFF9AA8A1);

  /// هشدار: پس‌زمینه
  static Color get warningBg => _p(0xFFFFF7ED, 0xFF33260F);

  /// هشدار
  static Color get warning => _p(0xFFF59E0B, 0xFFF5B33C);

  /// هشدار: آیکون
  static Color get warningIcon => _p(0xFFD97706, 0xFFFBBF24);

  /// هشدار: متن
  static Color get warningText => _p(0xFF92400E, 0xFFFCD38A);

  /// دستگیره‌ی کشوها
  static Color get handle => _p(0xFFD1D5DB, 0xFF3B4742);

  /// سازگاری
  static Color get appBarDivider => _p(0xFFD6DADF, 0xFF2A332F);

  /// سازگاری
  static Color get sectionDivider => _p(0xFFF1F5F9, 0xFF161C19);

  /// سازگاری
  static Color get cardBorder => _p(0xFFE8ECEF, 0xFF28322D);

  /// سازگاری
  static Color get wheelGreen => _p(0xFF39B169, 0xFF39B169);

  /// پین مبدا
  static Color get originBlue => _p(0xFF2563EB, 0xFF5B8DEF);

  // هم‌نام‌های قدیمی
  static Color get primaryPressed => primaryButtonPressed;
  static Color get buttonPressed => primaryButtonPressed;

  /// رنگ خط مسیر روی نقشه (hex، چون MapLibre رشته می‌خواهد)
  static String get routeLineHex => isDark ? '#5B8DEF' : '#0066FF';
  static String get routeTraveledHex => isDark ? '#5A6660' : '#B0B7C3';

  /// استایل نقشه‌ی فعلی
  static String get mapStyleAsset =>
      isDark ? 'assets/map/style_dark.json' : 'assets/map/style.json';
}
