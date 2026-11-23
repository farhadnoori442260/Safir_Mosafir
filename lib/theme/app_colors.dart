import 'package:flutter/material.dart';

/// رنگ‌های سفیر مسافر — هماهنگ با رنگ‌های سفیر راننده.
///
/// روشن:
/// پس‌زمینه صفحه: #F6F7F9
/// کارت‌ها و کشوها: #FFFFFF
///
/// تاریک:
/// پس‌زمینه صفحه: #0E0F11
/// کارت‌ها و کشوها: #1A1C1F
///
/// نام‌های اختصاصی مسافر حفظ شده‌اند.
/// مقدار isDark مانند قبل توسط main.dart و ThemeController تنظیم می‌شود.
class AppColors {
  AppColors._();

  /// وضعیت تم فعلی برنامه.
  static bool isDark = false;

  static Color _p(int light, int dark) =>
      Color(isDark ? dark : light);

  // رنگ برند

  static Color get primaryBrand =>
      _p(0xFF1B7A57, 0xFF34B27F);

  static Color get primaryDark =>
      _p(0xFF0E5F44, 0xFF0B4A36);

  // پس‌زمینه صفحه — مطابق راننده

  static Color get background =>
      _p(0xFFF6F7F9, 0xFF0E0F11);

  static Color get backgroundLight =>
      _p(0xFFF6F7F9, 0xFF0E0F11);

  // کارت‌ها، منوها و کشوها — مطابق راننده

  static Color get cardBackground =>
      _p(0xFFFFFFFF, 0xFF1A1C1F);

  static Color get cardLightBg =>
      _p(0xFFFFFFFF, 0xFF1A1C1F);

  static Color get cardBgLight =>
      _p(0xFFFFFFFF, 0xFF1A1C1F);

  // کادرها و خطوط جداکننده — مطابق راننده

  static Color get borderLight =>
      _p(0xFFE5E7EB, 0xFF2C2F34);

  static Color get fieldBorder =>
      _p(0xFFE2E8F0, 0xFF2C2F34);

  static Color get handle =>
      _p(0xFFD1D5DB, 0xFF3D4147);

  static Color get appBarDivider =>
      _p(0xFFD6DADF, 0xFF2C2F34);

  static Color get sectionDivider =>
      _p(0xFFF1F5F9, 0xFF16181B);

  static Color get cardBorder =>
      _p(0xFFE8ECEF, 0xFF2A2D32);

  // دکمه اصلی و حالت لمس

  static Color get primaryButton =>
      _p(0xFF169365, 0xFF169365);

  static Color get primaryButtonPressed =>
      _p(0xFF0F4A35, 0xFF0F6B4A);

  static Color get primaryPressed =>
      primaryButtonPressed;

  static Color get buttonPressed =>
      primaryButtonPressed;

  static Color get buttonText =>
      _p(0xFFFFFFFF, 0xFFFFFFFF);

  // موفقیت

  static Color get success =>
      _p(0xFF22C55E, 0xFF2FCB6C);

  static Color get successDark =>
      _p(0xFF16A34A, 0xFF22A858);

  static Color get successSoft =>
      _p(0xFFDCFCE7, 0xFF11301E);

  // خطا و لغو

  static Color get error =>
      _p(0xFFEF4444, 0xFFFF5A55);

  static Color get danger =>
      _p(0xFFE53935, 0xFFFF5A55);

  static Color get dangerSoft =>
      _p(0xFFFFEBEE, 0xFF3A1B1D);

  // هشدار

  static Color get warningBg =>
      _p(0xFFFFF7ED, 0xFF33260F);

  static Color get warning =>
      _p(0xFFF59E0B, 0xFFF5B33C);

  static Color get warningIcon =>
      _p(0xFFD97706, 0xFFFBBF24);

  static Color get warningText =>
      _p(0xFF92400E, 0xFFFCD38A);

  // متن‌ها — مطابق راننده

  static Color get textPrimary =>
      _p(0xFF1A1D29, 0xFFECEEF1);

  static Color get textSecondary =>
      _p(0xFF6B7280, 0xFF9BA1AA);

  // آیکن‌ها — مطابق راننده

  static Color get iconPrimary =>
      _p(0xFF1A1D29, 0xFFECEEF1);

  static Color get iconSecondary =>
      _p(0xFF6B7280, 0xFF9BA1AA);

  // سطح‌های خنثی و اطلاع‌رسانی

  static Color get neutralSoft =>
      _p(0xFFF1F5F9, 0xFF121417);

  static Color get infoSoft =>
      _p(0xFFEFF6FF, 0xFF16243A);

  static Color get infoBorder =>
      _p(0xFFBFDBFE, 0xFF254468);

  static Color get infoText =>
      _p(0xFF1E3A8A, 0xFF9DC2FF);

  // پایان سفر

  static Color get endTrip =>
      _p(0xFFC2570C, 0xFFE0701F);

  // رنگ‌های موضوعی آیکن‌ها

  static Color get accentPurple =>
      _p(0xFF8158CF, 0xFFB49AFF);

  static Color get accentOrange =>
      _p(0xFFC97A14, 0xFFF5B65B);

  static Color get accentTeal =>
      _p(0xFF0E8F9C, 0xFF4FD1DC);

  // کلید انتخاب تم — مطابق راننده

  static Color get toggleTrack =>
      _p(0xFFECEEF2, 0xFF08090B);

  static Color get toggleTrackBorder =>
      _p(0xFFD4D7E2, 0xFF33363C);

  static Color get toggleThumbBorder =>
      _p(0xFFB5BAC8, 0xFF4A4E55);

  // رنگ اختصاصی مسافر — بدون تغییر

  static Color get wheelGreen =>
      _p(0xFF39B169, 0xFF39B169);

  // رنگ شبکه‌های اجتماعی — بدون تغییر

  static Color get brandFacebook =>
      _p(0xFF1877F2, 0xFF1877F2);

  static Color get brandInstagram =>
      _p(0xFFE1306C, 0xFFE1306C);

  // نقشه و پین‌ها

  static Color get originBlue =>
      _p(0xFF2563EB, 0xFF5B8DEF);

  /// رنگ خط مسیر روی نقشه.
  static String get routeLineHex =>
      isDark ? '#5B8DEF' : '#0066FF';

  static String get routeTraveledHex =>
      isDark ? '#5A6660' : '#B0B7C3';

  /// استایل نقشه — مسیرهای فعلی مسافر حفظ شده‌اند.
  static String get mapStyleAsset => isDark
      ? 'assets/map/style_dark.json'
      : 'assets/map/style.json';
}
