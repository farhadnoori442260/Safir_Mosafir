import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:safir_passengers/theme/app_colors.dart';
import 'package:safir_passengers/widgets/afghanistan_license_plate.dart';

class DriverInfoCard extends StatelessWidget {
  final Map<String, dynamic> driverData;
  final VoidCallback? onCallPressed;
  final VoidCallback? onMessagePressed;
  final VoidCallback? onPaymentPressed;

  const DriverInfoCard({
    super.key,
    required this.driverData,
    this.onCallPressed,
    this.onMessagePressed,
    this.onPaymentPressed,
  });

  /// متد هوشمند برای جلوگیری از تکرار رنگ خودرو
  String _buildCarTitle(String model, String color) {
    final cleanModel = model.trim();
    final cleanColor = color.trim();

    if (cleanModel.isEmpty) return cleanColor;
    if (cleanColor.isEmpty) return cleanModel;

    // اگر مدل خودش کلمه رنگ را شامل می‌شود، از تکرار مجدد جلوگیری کن
    if (cleanModel.toLowerCase().contains(cleanColor.toLowerCase())) {
      return cleanModel;
    }

    // اگر شامل خط تیره نیست، آن را با فرمت زیبا ترکیب کن
    if (cleanModel.contains('-')) {
      return "$cleanModel $cleanColor";
    }

    return "$cleanModel - $cleanColor";
  }

  @override
  Widget build(BuildContext context) {
    // استخراج اطلاعات راننده
    String driverName = driverData['full_name'] ?? 'driver_default_name'.tr();
    String rawCarModel = driverData['car_model'] ?? 'driver_default_car_model'.tr();
    String rawCarColor = driverData['car_color'] ?? 'driver_default_car_color'.tr();
    
    // عنوان اصلاح‌شده خودرو
    String carTitle = _buildCarTitle(rawCarModel, rawCarColor);

    String? photoUrl = driverData['photo'];
    
    // اطلاعات هزینه سفر
    double fareAmount = (driverData['fare_amount'] ?? 0.0).toDouble();
    String currency = 'currency_afg'.tr();

    // اطلاعات پلاک افغانستان
    String province = driverData['plate_province'] ?? 'plate_default_province'.tr();
    String category = driverData['plate_category'] ?? 'plate_default_category'.tr();
    String farsiNum = (driverData['plate_farsi_num'] != null && driverData['plate_farsi_num'].toString().isNotEmpty)
        ? driverData['plate_farsi_num'].toString()
        : '٤٤٨٩٢';
    String englishNum = (driverData['plate_num'] != null && driverData['plate_num'].toString().isNotEmpty)
        ? driverData['plate_num'].toString()
        : '44892';
    bool isTemp = driverData['is_temp_plate'] ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppColors.isDark ? 0.45 : 0.10),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔹 ۱. دستگیرهٔ بالای کارت
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.handle,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // 🔹 ۲. مدل و رنگ خودرو
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_taxi_rounded,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  carTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 🔹 ۳. کارت راننده و پلاک
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // عکس و نام راننده
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryBrand.withOpacity(0.45),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.cardBackground,
                          backgroundImage:
                              (photoUrl != null && photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 28,
                                  color: AppColors.primaryBrand,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          driverName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // پلاک افغانستان (با جلوگیری از OverFlow)
                Flexible(
                  flex: 4,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AfghanistanLicensePlate(
                      province: province,
                      categoryLetter: category,
                      farsiNumber: farsiNum,
                      englishNumber: englishNum,
                      isTemporary: isTemp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 🔹 ۴. دکمه‌های ارتباطی: پیام (آبی) و تماس (سبز)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onMessagePressed,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.originBlue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_rounded,
                          color: AppColors.originBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "driver_send_message_hint".tr(),
                          style: TextStyle(
                            color: AppColors.originBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onCallPressed,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.phone_rounded,
                    color: AppColors.successDark,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, thickness: 1, color: AppColors.fieldBorder),
          ),

          // 🔹 ۵. هزینهٔ سفر و پرداخت
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: onPaymentPressed ?? () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  elevation: 0,
                  minimumSize: const Size(0, 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "driver_pay_button".tr(),
                  style: TextStyle(
                    color: AppColors.buttonText,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    "driver_trip_cost_label"
                        .tr(args: [fareAmount.toStringAsFixed(0), currency]),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.warningIcon,
                      size: 19,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
