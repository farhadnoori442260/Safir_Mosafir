import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ایمپورت ثوابت، ترجمه و پالت رنگی اختصاصی سفیر
import '../globle/global_var.dart';
import '../theme/app_colors.dart'; // آدرس فایل رنگ‌ها را در صورت نیاز اصلاح کنید

class SignOutDialog extends StatelessWidget {
  final String? title;
  final String? description;
  final VoidCallback onSignOut;

  const SignOutDialog({
    super.key,
    this.title,
    this.description,
    required this.onSignOut,
  });

  /// ترجمه با متن جایگزین (اگر کلید نبود یا خالی بود)
  String _tr(String key, String fallback) {
    final String v = getTranslation(key) ?? '';
    return v.trim().isEmpty || v == key ? fallback : v;
  }

  @override
  Widget build(BuildContext context) {
    final String titleText = (title != null && title!.trim().isNotEmpty)
        ? title!
        : _tr('sign_out_title', 'خروج از حساب');

    final String descText =
        (description != null && description!.trim().isNotEmpty)
            ? description!
            : _tr(
                'sign_out_confirm',
                'آیا مطمئن هستید که می‌خواهید از حساب کاربری خود خارج شوید؟',
              );

    return Dialog(
      backgroundColor: AppColors.cardBgLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: AppColors.fieldBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // آیکون هشدار خروج
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),

            // عنوان دیالوگ
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // متن توضیحات
            Text(
              descText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // انصراف (کنار) و خروج (قرمز)؛ دکمهٔ امن‌تر اول است
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context), // بستن پنجره
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.fieldBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _tr('cancel', 'انصراف'),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        onSignOut(); // اجرای فرآیند خروج از فایربیس
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: AppColors.buttonText,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _tr('sign_out', 'خروج'),
                        style: TextStyle(
                          color: AppColors.buttonText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
