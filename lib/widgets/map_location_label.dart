import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:safir_passengers/theme/app_colors.dart';

/// متن لیبل؛ اگر ترجمه نبود، متن جایگزین (نه خودِ کلید)
String _labelText(BuildContext context, String? custom, String key, String fallback) {
  if (custom != null && custom.trim().isNotEmpty) return custom.trim();
  final String v = context.tr(key);
  return (v.trim().isEmpty || v == key) ? fallback : v;
}

/// ساختار مشترک لیبل مبدأ و مقصد: حباب + ساقهٔ باریک + نقطهٔ پایین
class _MapPinLabel extends StatelessWidget {
  final String text;
  final Color accent;
  final bool squareMarker;

  const _MapPinLabel({
    required this.text,
    required this.accent,
    required this.squareMarker,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // حباب؛ با عرض محدود تا آدرس طولانی سرریز نکند
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.cardBgLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.fieldBorder.withOpacity(0.8),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withOpacity(
                    AppColors.isDark ? 0.35 : 0.14,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
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
                    color: accent,
                    shape: squareMarker ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius:
                        squareMarker ? BorderRadius.circular(3.5) : null,
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ساقه و نقطه هم‌رنگ نشانگر؛ در حالت تاریک هم دیده می‌شود
        Container(
          width: 2.5,
          height: 10,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

// لیبل مبدأ
class MapOriginLabel extends StatelessWidget {
  final String? labelText;

  const MapOriginLabel({
    super.key,
    this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return _MapPinLabel(
      text: _labelText(context, labelText, 'origin', 'مبدأ'),
      accent: AppColors.originBlue,
      squareMarker: false,
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
    return _MapPinLabel(
      text: _labelText(context, labelText, 'destination', 'مقصد'),
      accent: AppColors.primaryBrand,
      squareMarker: true,
    );
  }
}
