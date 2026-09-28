import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_colors.dart';
import '../../global/global_var.dart';

class CargoSheets {
  /// 🎨 رنگ اختصاصی فوکوس (آبی اسنپی)
  static const Color focusBlue = Color(0xFF0066FF);
  static const Color borderGrey = Color(0xFFD6D6D6);
  static const Color labelGrey = Color(0xFF9E9E9E);
  static const Color errorRed = Color(0xFFE53935);

  /// 📦 ۱. صفحه کامل اطلاعات فرستنده (Sender Screen)
  static void showSenderDialog({
    required BuildContext context,
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required TextEditingController addressController,
    required TextEditingController unitController,
    required TextEditingController floorController,
    required TextEditingController noteController,
    required VoidCallback onConfirm,
    VoidCallback? onUseMyInfoPressed,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            final double keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
            final bool isKeyboardOpen = keyboardHeight > 0;

            // متغیرهای ذخیره وضعیت خطای فیلدها
            String? nameError;
            String? phoneError;
            String? floorError;

            return Scaffold(
              backgroundColor: Colors.white,
              resizeToAvoidBottomInset: false, // 👈 جلوگیری از لرزش و پرش Scaffold
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(ctx),
                ),
                title: Text(
                  'cargo.sender_details_title'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                centerTitle: false,
              ),

              /// 🟢 دکمه شناور که دقیقاً بالای کیبورد قرار می‌گیرد
              bottomNavigationBar: AnimatedPadding(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: isKeyboardOpen
                      ? keyboardHeight + 12
                      : MediaQuery.of(ctx).padding.bottom + 12,
                ),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1BAB58),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      setModalState(() {
                        // 🛑 شرط‌های اعتبارسنجی خانه پری
                        bool isValid = true;

                        if (nameController.text.trim().isEmpty) {
                          nameError = 'لطفاً نام فرستنده را وارد کنید';
                          isValid = false;
                        } else {
                          nameError = null;
                        }

                        if (phoneController.text.trim().isEmpty) {
                          phoneError = 'لطفاً شماره تماس را وارد کنید';
                          isValid = false;
                        } else {
                          phoneError = null;
                        }

                        if (floorController.text.trim().isEmpty) {
                          floorError = 'پلاک/طبقه الزامی است';
                          isValid = false;
                        } else {
                          floorError = null;
                        }

                        if (!isValid) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('لطفاً بخش‌های ضروری را تکمیل کنید'),
                              backgroundColor: errorRed,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        onConfirm();
                      });
                    },
                    child: Text(
                      'cargo.confirm_continue'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              /// 📜 بخش اسکرول فرم (با قابلیت ۲۴ پیکسل اسکرول اضافی نرم روی کیبورد)
              body: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    // 👈 80 پیکسل شامل ارتفاع دکمه (48) + حاشیه‌ها (12) + ۲۴ پیکسل فضای اسکرول آزاد
                    bottom: isKeyboardOpen ? keyboardHeight + 80 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // دکمه پر کردن اطلاعات حساب کاربری
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                if (onUseMyInfoPressed != null) {
                                  onUseMyInfoPressed();
                                } else {
                                  nameController.text = userName;
                                  phoneController.text = userPhone;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'cargo.use_my_info'.tr(),
                                    style: const TextStyle(
                                      color: focusBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: focusBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildField(
                        controller: nameController,
                        label: 'cargo.sender_fullname'.tr(),
                        errorText: nameError,
                      ),
                      const SizedBox(height: 20),

                      _buildField(
                        controller: phoneController,
                        label: 'cargo.phone'.tr(),
                        keyboardType: TextInputType.phone,
                        errorText: phoneError,
                      ),
                      const SizedBox(height: 20),

                      _buildField(
                        controller: addressController,
                        label: 'cargo.origin_address_label'.tr(),
                        readOnly: true,
                        suffixIcon: const Icon(Icons.edit_outlined, size: 20, color: labelGrey),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: floorController,
                              label: 'cargo.plaque'.tr(),
                              errorText: floorError,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: unitController,
                              label: 'cargo.unit'.tr(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildField(
                        controller: noteController,
                        label: 'cargo.description_optional'.tr(),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 📥 ۲. صفحه کامل اطلاعات گیرنده (Receiver Screen)
  static void showReceiverDialog({
    required BuildContext context,
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required TextEditingController addressController,
    required TextEditingController unitController,
    required TextEditingController floorController,
    required TextEditingController noteController,
    required String selectedPackageType,
    required ValueChanged<String?> onPackageTypeChanged,
    required String selectedInsurance,
    required ValueChanged<String?> onInsuranceChanged,
    required VoidCallback onConfirm,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) {
          String currentPackage = selectedPackageType;
          String currentInsurance = selectedInsurance;

          String? nameError;
          String? phoneError;
          String? floorError;

          return StatefulBuilder(
            builder: (context, setModalState) {
              final double keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
              final bool isKeyboardOpen = keyboardHeight > 0;

              return Scaffold(
                backgroundColor: Colors.white,
                resizeToAvoidBottomInset: false,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  title: Text(
                    'cargo.receiver_details_title'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  centerTitle: false,
                ),

                /// 🟢 دکمه شناور نرم
                bottomNavigationBar: AnimatedPadding(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: isKeyboardOpen
                        ? keyboardHeight + 12
                        : MediaQuery.of(ctx).padding.bottom + 12,
                  ),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1BAB58),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setModalState(() {
                          // 🛑 شرط‌های اعتبارسنجی فرم گیرنده
                          bool isValid = true;

                          if (nameController.text.trim().isEmpty) {
                            nameError = 'نام گیرنده الزامی است';
                            isValid = false;
                          } else {
                            nameError = null;
                          }

                          if (phoneController.text.trim().isEmpty) {
                            phoneError = 'شماره گیرنده الزامی است';
                            isValid = false;
                          } else {
                            phoneError = null;
                          }

                          if (floorController.text.trim().isEmpty) {
                            floorError = 'پلاک/طبقه الزامی است';
                            isValid = false;
                          } else {
                            floorError = null;
                          }

                          if (!isValid) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('لطفاً اطلاعات ضروری گیرنده را تکمیل کنید'),
                                backgroundColor: errorRed,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          onConfirm();
                        });
                      },
                      child: Text(
                        'cargo.confirm_continue'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                /// 📜 اسکرول فرم گیرنده
                body: SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: isKeyboardOpen ? keyboardHeight + 80 : 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          controller: nameController,
                          label: 'cargo.receiver_fullname'.tr(),
                          errorText: nameError,
                        ),
                        const SizedBox(height: 20),

                        _buildField(
                          controller: phoneController,
                          label: 'cargo.receiver_phone'.tr(),
                          keyboardType: TextInputType.phone,
                          errorText: phoneError,
                        ),
                        const SizedBox(height: 20),

                        _buildField(
                          controller: addressController,
                          label: 'cargo.destination_address_label'.tr(),
                          readOnly: true,
                          suffixIcon: const Icon(Icons.edit_outlined, size: 20, color: labelGrey),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: floorController,
                                label: 'cargo.plaque'.tr(),
                                errorText: floorError,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                controller: unitController,
                                label: 'cargo.unit'.tr(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildField(
                          controller: noteController,
                          label: 'cargo.delivery_note'.tr(),
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 20),

                        _buildDropdownField(
                          label: 'cargo.cargo_type'.tr(),
                          value: currentPackage,
                          items: [
                            'cargo.type_other'.tr(),
                            'cargo.type_home_furniture'.tr(),
                            'cargo.type_office_furniture'.tr(),
                            'cargo.type_goods_food'.tr(),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                currentPackage = val;
                              });
                              onPackageTypeChanged(val);
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildDropdownField(
                          label: 'cargo.insurance_amount'.tr(),
                          value: currentInsurance,
                          items: [
                            'cargo.insurance_50k'.tr(),
                            'cargo.insurance_100k'.tr(),
                            'cargo.insurance_500k'.tr(),
                            'cargo.no_insurance'.tr(),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                currentInsurance = val;
                              });
                              onInsuranceChanged(val);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 🔹 متد ساخت فیلدهای ورودی متنی (با اصلاح scrollPadding و پشتیبانی از errorText)
  static Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    Widget? suffixIcon,
    String? errorText,
  }) {
    const normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(
        color: borderGrey,
        width: 1.0,
      ),
    );

    const focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(
        color: focusBlue,
        width: 1.5,
      ),
    );

    const errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(
        color: errorRed,
        width: 1.5,
      ),
    );

    return TextField(
      key: ValueKey('field_$label'),
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      scrollPadding: const EdgeInsets.only(bottom: 40), // 👈 اصلاح شده برای جلوگیری از لرزش
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        isDense: false,
        labelText: label,
        errorText: errorText,
        errorStyle: const TextStyle(color: errorRed, fontSize: 11),
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        labelStyle: const TextStyle(
          color: labelGrey,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: TextStyle(
          color: errorText != null ? errorRed : focusBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          backgroundColor: Colors.white,
        ),
        hintStyle: const TextStyle(
          color: labelGrey,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
        filled: true,
        fillColor: Colors.white,
        border: normalBorder,
        enabledBorder: errorText != null ? errorBorder : normalBorder,
        disabledBorder: normalBorder,
        focusedBorder: errorText != null ? errorBorder : focusedBorder,
      ),
    );
  }

  /// 🔹 متد ساخت فیلدهای دراپ‌داون انتخابی
  static Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    const normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(
        color: borderGrey,
        width: 1.0,
      ),
    );

    const focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(
        color: focusBlue,
        width: 1.5,
      ),
    );

    return DropdownButtonFormField<String>(
      key: ValueKey('dropdown_$label'),
      value: value,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: labelGrey,
      ),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(
          color: labelGrey,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: focusBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          backgroundColor: Colors.white,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
        border: normalBorder,
        enabledBorder: normalBorder,
        disabledBorder: normalBorder,
        focusedBorder: focusedBorder,
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

    /// 📐 تابع محاسبه قیمت اختصاصی هر خودرو بر اساس مسافت (کیلومتر)
  static double calculateFareForVehicle(String vehicleId, double distanceInKm) {
    double baseRate = 35.0;
    double perKmRate = 15.0;

    // بررسی بر اساس کلید یا شناسه
    final id = vehicleId.toLowerCase();
    if (id.contains('zaranj') || id.contains('زرنج') || id.contains('سه چرخ')) {
      baseRate = 35.0;
      perKmRate = 15.0;
    } else if (id.contains('suzuki') || id.contains('سوزوکی') || id.contains('پیکاپ')) {
      baseRate = 70.0;
      perKmRate = 30.0;
    } else if (id.contains('mazda') || id.contains('مازدا') || id.contains('کامیون')) {
      baseRate = 150.0;
      perKmRate = 50.0;
    }

    double calculatedFare = baseRate + (distanceInKm * perKmRate);
    return calculatedFare < baseRate ? baseRate : calculatedFare;
  }

  /// 🚚 ۳. شیت مرحله نهایی انتخاب خودرو و تایید سفارش
  static Widget buildCargoSummarySheet({
    required BuildContext context,
    required double fareAmount,
    required double distanceInKm,
    required String selectedVehicleType,
    required ValueChanged<String> onVehicleSelected,
    required String paymentPayer,
    required ValueChanged<String> onPayerChanged,
    required VoidCallback onRequestTrip,
    bool isLoading = false,
  }) {
    // لیست خودروها با نام‌های تک‌کلمه‌ای و کوتاه و آیکون‌های متناسب
    final List<Map<String, dynamic>> vehicles = [
      {'id': 'zaranj', 'title': 'زرنج', 'icon': Icons.electric_rickshaw},
      {'id': 'suzuki', 'title': 'سوزوکی', 'icon': Icons.local_shipping_outlined},
      {'id': 'mazda', 'title': 'مازدا', 'icon': Icons.fire_truck_outlined},
    ];

    final String senderText = 'cargo.sender'.tr();
    final String receiverText = 'cargo.receiver'.tr();

    // محاسبه دقیق کرایه بر اساس نوع خودرو انتخاب شده
    double currentFare = calculateFareForVehicle(selectedVehicleType, distanceInKm);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'cargo.select_vehicle'.tr(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // 🎨 لیست انتخاب وسیله نقلیه (تراز منظم، نام کوتاه تک‌کلمه‌ای در زیر آیکون)
            SizedBox(
              height: 90,
              child: Row(
                children: vehicles.map((vehicle) {
                  final String id = vehicle['id'] as String;
                  final String title = vehicle['title'] as String;
                  final IconData icon = vehicle['icon'] as IconData;

                  bool isSelected = selectedVehicleType == id ||
                      selectedVehicleType.toLowerCase().contains(id);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          onVehicleSelected(id);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? focusBlue.withOpacity(0.08)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? focusBlue : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: 30,
                                color: isSelected
                                    ? focusBlue
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? focusBlue
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'cargo.payer_side'.tr(),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text(senderText,
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w600)),
                      selected: paymentPayer == senderText,
                      selectedColor: focusBlue.withOpacity(0.15),
                      onSelected: (v) => onPayerChanged(senderText),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(receiverText,
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w600)),
                      selected: paymentPayer == receiverText,
                      selectedColor: focusBlue.withOpacity(0.15),
                      onSelected: (v) => onPayerChanged(receiverText),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'cargo.total_fare'.tr(),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Text(
                        '${currentFare.toStringAsFixed(0)} ${'currency.afghani'.tr()}',
                        key: ValueKey<double>(currentFare),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: focusBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1BAB58),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : onRequestTrip,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'cargo.submit_order'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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

