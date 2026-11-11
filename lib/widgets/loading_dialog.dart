import 'package:flutter/material.dart';

// ایمپورت ثوابت، ترجمه و پالت رنگی اختصاصی سفیر
import '../globle/global_var.dart';
import '../theme/app_colors.dart'; // آدرس فایل رنگ‌ها را در صورت نیاز اصلاح کنید

class LoadingDialog extends StatelessWidget {
  final String messageText;

  const LoadingDialog({
    super.key,
    required this.messageText,
  });

  @override
  Widget build(BuildContext context) {
    // اگر ترجمه نبود، خودِ متن داده‌شده نشان داده می‌شود (نه کلید خالی)
    final String translated = getTranslation(messageText) ?? '';
    final String text = translated.trim().isEmpty ? messageText : translated;

    return Dialog(
      backgroundColor: AppColors.cardBgLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.fieldBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                color: AppColors.primaryBrand,
                backgroundColor: AppColors.fieldBorder,
              ),
            ),
            const SizedBox(width: 18),
            // جهت متن از زبان اپ می‌آید (راست‌به‌چپ برای فارسی/پشتو، چپ‌به‌راست برای انگلیسی)
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
