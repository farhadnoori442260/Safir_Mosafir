import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // برای بازخورد لمسی (Haptic)
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/theme/app_colors.dart';

class MapWidgetsHelper {
  /// 📍 فیلد نمایش و انتخاب آدرس (مبدأ / مقصد)
  static Widget buildAddressField(
    String text,
    IconData icon,
    Color iconColor,
    Color safirColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: AppColors.cardBgLight,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: () {
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                // ✅ قبلاً overflow داخل TextStyle بود و متن بلند بریده نمی‌شد
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: safirColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔘 دکمه اصلی پایین صفحه (پشتیبانی از ترجمه و Haptic)
  static Widget buildBottomButton({
    required BuildContext? context,
    required String titleKey,
    required Color buttonColor,
    required Color pressedColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          overlayColor: pressedColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () {
          onTap();
        },
        child: Text(
          context != null ? getTranslation(context, titleKey) : titleKey,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  /// 🏷️ تب‌های دسته‌بندی بالای شیت
  static Widget buildCategoryTab({
    required BuildContext context,
    required int categoryIndex,
    required int selectedCategory,
    required String labelKey,
    required Color safirColor,
    required VoidCallback onTap,
  }) {
    final bool isCategorySelected = selectedCategory == categoryIndex;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isCategorySelected ? safirColor : AppColors.fieldBorder,
                width: isCategorySelected ? 2.5 : 1,
              ),
            ),
          ),
          child: Text(
            getTranslation(context, labelKey),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isCategorySelected ? safirColor : AppColors.textSecondary,
              fontWeight:
                  isCategorySelected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// 🚗 گزینه انتخاب وسیله نقلیه (با انیمیشن نرم انتخاب و Haptic)
  static Widget buildHorizontalVehicleOption({
    required BuildContext context,
    required int index,
    required int selectedVehicleType,
    required IconData icon,
    required String titleKey,
    required String subtitleKey,
    required String price,
    required Color safirColor,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedVehicleType == index;
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? safirColor.withOpacity(0.10)
              : AppColors.cardBgLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? safirColor : AppColors.fieldBorder,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isSelected ? safirColor : AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      getTranslation(context, titleKey),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      getTranslation(context, subtitleKey),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: safirColor.withOpacity(isSelected ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: safirColor, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
