import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:safir_passengers/theme/app_colors.dart';

// لیبل مبدأ
class MapOriginLabel extends StatelessWidget {
  final String? labelText;

  const MapOriginLabel({
    super.key,
    this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    final String displayText =
        (labelText != null && labelText!.trim().isNotEmpty)
            ? labelText!
            : context.tr('origin');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.originBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                displayText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 2.5,
          height: 10,
          color: Colors.grey.shade800,
        ),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

// لیبل مقصد بدون نمایش ساعت
class MapDestinationLabel extends StatelessWidget {
  final String? labelText;

  // برای سازگاری با فراخوانی‌های قبلی حفظ شده است.
  // این مقدار در لیبل نمایش داده نمی‌شود.
  final String? arrivalTime;

  const MapDestinationLabel({
    super.key,
    this.labelText,
    this.arrivalTime,
  });

  @override
  Widget build(BuildContext context) {
    final String displayText =
        (labelText != null && labelText!.trim().isNotEmpty)
            ? labelText!
            : context.tr('destination');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primaryBrand,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                displayText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 2.5,
          height: 10,
          color: Colors.grey.shade800,
        ),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
