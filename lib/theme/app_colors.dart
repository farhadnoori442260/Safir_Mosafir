import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 🟢 رنگ اصلی برند (برگرفته از هویت بصری سفیر - وقار و امنیت)
  static const Color primaryBrand = Color(0xFF1B7A57);

  // 🌲 سبز تیره‌ی برند (گرادیان هدر و بنر)  ← جدید
  static const Color primaryDark = Color(0xFF0E5F44);

  // 🟩 دکمه اصلی (ثبت سفر، درخواست، ادامه - پرانرژی و جذاب)
  static const Color primaryButton = Color(0xFF169365);

  // 👆 دکمه هنگام لمس (Pressed)
  static const Color primaryButtonPressed = Color(0xFF0F4A35);
  static const Color primaryPressed = Color(0xFF0F4A35); // جهت رفع ارور map_bottom_sheets
  static const Color buttonPressed = Color(0xFF0F4A35);  // جهت همخوانی با کدهای قبلی

  // 📦 پس‌زمینه کارت‌ها و شیت‌ها
  static const Color cardBackground = Color(0xFFEAF6F1);
  static const Color cardLightBg = Color(0xFFEAF6F1);
  static const Color cardBgLight = Color(0xFFFFFFFF);     // جهت رفع ارور map_bottom_sheets

  // 🎨 پس‌زمینه‌ها و کادرهای عمومی
  static const Color backgroundLight = Color(0xFFF8F9FA); // جهت رفع ارور smart_location_sheet
  static const Color borderLight = Color(0xFFE0E0E0);     // جهت رفع ارور smart_location_sheet
  static const Color fieldBorder = Color(0xFFE2E8F0);     // 👈 جهت رفع ارور cargo_sheets

  // ✅ وضعیت‌ها (موفقیت، خطا)
  static const Color success = Color(0xFF22C55E);
  static const Color successDark = Color(0xFF16A34A);   // پرداخت‌شده  ← جدید
  static const Color danger = Color(0xFFE53935);        // لغو / خطا  ← جدید
  static const Color dangerSoft = Color(0xFFFFEBEE);    // پس‌زمینه‌ی ملایم خطا  ← جدید

  // 📝 متن‌ها و آیکون‌ها
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color iconSecondary = Color(0xFF757575);   // جهت رفع ارور smart_location_sheet

  // ⚠️ هشدار (GPS و غیره)  ← جدید
  static const Color warningBg = Color(0xFFFFF7ED);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningIcon = Color(0xFFD97706);
  static const Color warningText = Color(0xFF92400E);

  // ▬ دستگیره‌ی کشوهای پایین  ← جدید
  static const Color handle = Color(0xFFD1D5DB);

  // سازگاری با نام‌های کلاس قدیمیِ user_profile_screen (دیگر استفاده نمی‌شوند)
  static const Color appBarDivider = Color(0xFFD6DADF);
  static const Color sectionDivider = Color(0xFFF1F5F9);
  static const Color cardBorder = Color(0xFFE8ECEF);
  static const Color wheelGreen = Color(0xFF39B169);

  // 📍 نقشه و پین‌ها
  static const Color originBlue = Color(0xFF2563EB);
}
