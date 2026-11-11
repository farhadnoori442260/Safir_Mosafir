import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ایمپورت ثوابت و پالت رنگی اختصاصی سفیر
import 'package:safir_passengers/theme/app_colors.dart'; // آدرس فایل رنگ‌ها را در صورت نیاز اصلاح کنید

/// پرداخت نقدی پایان سفر. با تأیید، مقدار "paid" به صفحهٔ نقشه برمی‌گردد.
class PaymentDialog extends StatefulWidget {
  final String fareAmount;

  const PaymentDialog({
    super.key,
    required this.fareAmount,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  /// ترجمه با متن جایگزین (اگر کلید نبود، خود کلید نشان داده نشود)
  String _t(String key, String fallback, {List<String>? args}) {
    final String v = args == null ? key.tr() : key.tr(args: args);
    return (v.trim().isEmpty || v == key) ? fallback : v;
  }

  @override
  Widget build(BuildContext context) {
    final String currency = _t('currency_afghani', 'افغانی');

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
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // نشانهٔ پایان سفر
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payments_rounded,
                color: AppColors.successDark,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              _t('trip_finished_title', 'سفر شما به پایان رسید'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _t('cash_payment_to_driver', 'پرداخت نقدی به راننده'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),

            // کارت مبلغ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.fareAmount,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currency,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // راهنما برای مسافر
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t(
                      'cash_payment_instruction',
                      'لطفاً مبلغ ${widget.fareAmount} $currency را به‌صورت نقد به راننده بپردازید.',
                      args: [widget.fareAmount],
                    ),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // تأیید پرداخت و پایان سفر
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, 'paid'); // ارسال سیگنال پرداخت به نقشه اصلی
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  foregroundColor: AppColors.buttonText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _t('confirm_and_end_trip', 'تأیید و پایان سفر'),
                  style: TextStyle(
                    color: AppColors.buttonText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
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
