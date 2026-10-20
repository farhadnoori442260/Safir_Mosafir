import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// ایمپورت ثوابت و پالت رنگی اختصاصی سفیر
import 'package:safir_passengers/theme/app_colors.dart'; // آدرس فایل رنگ‌ها را در صورت نیاز اصلاح کنید

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
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // راست‌چین کردن دیالوگ برای زبان‌های دری و پشتو
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // لبه‌های گرد مدرن مطابق دیزاین سفیر
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // آیکون رسید یا پول با پس‌زمینه کارت روشن (#EAF6F1)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.cardLightBg, // #EAF6F1
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primaryBrand, // #145A41
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'cash_payment_to_driver'.tr(),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Divider(height: 1, color: Colors.grey.withOpacity(0.25), thickness: 1.0),
              const SizedBox(height: 20),
              
              // نمایش کرایه به افغانی با رنگ برند سفیر (#145A41)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.fareAmount,
                    style: const TextStyle(
                      color: AppColors.primaryBrand, // #145A41
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'currency_afghani'.tr(),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // متن راهنما برای مسافر
              Text(
                'cash_payment_instruction'.tr(args: [widget.fareAmount]),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              
              // دکمه تایید و اتمام سفر با رنگ اصلی دکمه (#1B7A57)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, "paid"); // ارسال سیگنال پرداخت به نقشه اصلی
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton, // #1B7A57
                    foregroundColor: AppColors.buttonPressed, // #0F4A35
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'confirm_and_end_trip'.tr(),
                    style: const TextStyle(
                      color: AppColors.buttonText, // #FFFFFF
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
