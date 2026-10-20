import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, -3),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔹 ۱. خط کشویی بالای کارت
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // 🔹 ۲. مدل و رنگ خودرو (اصلاح‌شده بدون تکرار)
          Text(
            carTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 14),

          // 🔹 ۳. ردیف راننده و پلاک
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // سمت راست: عکس و نام راننده
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF145A41), width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? const Icon(Icons.person, size: 28, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        driverName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // سمت چپ: پلاک افغانستان (با جلوگیری از OverFlow)
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

          const SizedBox(height: 16),

          // 🔹 ۴. دکمه‌های ارتباطی
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onMessagePressed,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_rounded,
                            color: Color(0xFF2C6B56), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "driver_send_message_hint".tr(),
                          style: const TextStyle(
                            color: Color(0xFF2C6B56),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              InkWell(
                onTap: onCallPressed,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F4F7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Color(0xFF2C6B56), size: 20),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.8),
          ),

          // 🔹 ۵. هزینه سفر و پرداخت
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: onPaymentPressed ?? () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF145A41),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "driver_pay_button".tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),

              Row(
                children: [
                  Text(
                    "driver_trip_cost_label".tr(args: [fareAmount.toStringAsFixed(0), currency]),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.account_balance_wallet_outlined, color: Colors.black54, size: 20),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
