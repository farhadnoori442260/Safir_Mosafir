import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:safir_passengers/services/app_config_service.dart';
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
        builder: (_) => _CargoPartyScreen(
          isSender: true,
          nameController: nameController,
          phoneController: phoneController,
          addressController: addressController,
          unitController: unitController,
          floorController: floorController,
          noteController: noteController,
          onConfirm: onConfirm,
          onUseMyInfoPressed: onUseMyInfoPressed,
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
        builder: (_) => _CargoPartyScreen(
          isSender: false,
          nameController: nameController,
          phoneController: phoneController,
          addressController: addressController,
          unitController: unitController,
          floorController: floorController,
          noteController: noteController,
          onConfirm: onConfirm,
          selectedPackageType: selectedPackageType,
          onPackageTypeChanged: onPackageTypeChanged,
          selectedInsurance: selectedInsurance,
          onInsuranceChanged: onInsuranceChanged,
        ),
      ),
    );
  }

  /// 📐 کرایهٔ هر خودروی باربری بر اساس مسافت (کیلومتر)
  ///
  /// ✅ از تنظیمات پنل ادمین حساب می‌شود:
  /// «کرایه هر کیلومتر باربری» × ضریب نوع خودرو × کیلومتر
  static double calculateFareForVehicle(String vehicleId, double distanceInKm) {
    return AppConfigService.instance.config
        .freightFareForVehicle(vehicleId, distanceInKm);
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
    const List<_CargoVehicle> vehicles = <_CargoVehicle>[
      _CargoVehicle('zaranj', 'زرنج', Icons.electric_rickshaw),
      _CargoVehicle('suzuki', 'سوزوکی', Icons.local_shipping_outlined),
      _CargoVehicle('mazda', 'مازدا', Icons.fire_truck_outlined),
    ];

    final String senderText = 'cargo.sender'.tr();
    final String receiverText = 'cargo.receiver'.tr();

    // ✅ همان قیمتی که در سفر ثبت می‌شود نمایش داده می‌شود
    final double currentFare = fareAmount > 0
        ? fareAmount
        : calculateFareForVehicle(selectedVehicleType, distanceInKm);

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
            SizedBox(
              height: 90,
              child: Row(
                children: vehicles.map((_CargoVehicle vehicle) {
                  final bool isSelected = selectedVehicleType == vehicle.id ||
                      selectedVehicleType.toLowerCase().contains(vehicle.id);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => onVehicleSelected(vehicle.id),
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
                                vehicle.icon,
                                size: 30,
                                color: isSelected
                                    ? focusBlue
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                vehicle.title,
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
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text(
                        senderText,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: paymentPayer == senderText,
                      selectedColor: focusBlue.withOpacity(0.15),
                      onSelected: (_) => onPayerChanged(senderText),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(
                        receiverText,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: paymentPayer == receiverText,
                      selectedColor: focusBlue.withOpacity(0.15),
                      onSelected: (_) => onPayerChanged(receiverText),
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
                        color: AppColors.textSecondary,
                      ),
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
                      horizontal: 28,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : onRequestTrip,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
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
}

/// مشخصات یک خودروی باربری
class _CargoVehicle {
  final String id;
  final String title;
  final IconData icon;

  const _CargoVehicle(this.id, this.title, this.icon);
}

/// صفحهٔ مشترک «اطلاعات فرستنده» و «اطلاعات گیرنده»
///
/// ✅ اصلاح‌ها نسبت به نسخهٔ قبل:
///  • پیام خطای زیر فیلدها واقعاً نمایش داده می‌شود (قبلاً با هر rebuild پاک می‌شد)
///  • انتخاب نوع بار و بیمه با باز و بسته شدن کیبورد پاک نمی‌شود
///  • دراپ‌داون اگر مقدارش در لیست نبود (مثلاً بعد از تغییر زبان) کرش نمی‌کند
///  • شمارهٔ تماس اعتبارسنجی می‌شود
///  • بستن صفحه و ادامهٔ کار بیرون از setState انجام می‌شود
class _CargoPartyScreen extends StatefulWidget {
  final bool isSender;

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController unitController;
  final TextEditingController floorController;
  final TextEditingController noteController;

  final VoidCallback onConfirm;
  final VoidCallback? onUseMyInfoPressed;

  // فقط برای گیرنده
  final String? selectedPackageType;
  final ValueChanged<String?>? onPackageTypeChanged;
  final String? selectedInsurance;
  final ValueChanged<String?>? onInsuranceChanged;

  const _CargoPartyScreen({
    required this.isSender,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.unitController,
    required this.floorController,
    required this.noteController,
    required this.onConfirm,
    this.onUseMyInfoPressed,
    this.selectedPackageType,
    this.onPackageTypeChanged,
    this.selectedInsurance,
    this.onInsuranceChanged,
  });

  @override
  State<_CargoPartyScreen> createState() => _CargoPartyScreenState();
}

class _CargoPartyScreenState extends State<_CargoPartyScreen> {
  String? _nameError;
  String? _phoneError;
  String? _floorError;

  late String _package;
  late String _insurance;

  @override
  void initState() {
    super.initState();
    _package = widget.selectedPackageType ?? '';
    _insurance = widget.selectedInsurance ?? '';
  }

  // ───────── اعتبارسنجی ─────────

  String _normalizeDigits(String input) {
    const String en = '0123456789';
    const String fa = '۰۱۲۳۴۵۶۷۸۹';
    const String ar = '٠١٢٣٤٥٦٧٨٩';

    String s = input;
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(fa[i], en[i]).replaceAll(ar[i], en[i]);
    }
    return s;
  }

  bool _isValidPhone(String raw) {
    final String digits =
        _normalizeDigits(raw).replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 9 && digits.length <= 13;
  }

  void _submit() {
    final String name = widget.nameController.text.trim();
    final String phone = widget.phoneController.text.trim();
    final String floor = widget.floorController.text.trim();

    String? nameError;
    String? phoneError;
    String? floorError;

    if (name.isEmpty) {
      nameError = widget.isSender
          ? 'لطفاً نام فرستنده را وارد کنید'
          : 'نام گیرنده الزامی است';
    }

    if (phone.isEmpty) {
      phoneError = widget.isSender
          ? 'لطفاً شماره تماس را وارد کنید'
          : 'شماره گیرنده الزامی است';
    } else if (!_isValidPhone(phone)) {
      phoneError = 'شماره تماس معتبر نیست';
    }

    if (floor.isEmpty) {
      floorError = 'پلاک/طبقه الزامی است';
    }

    final bool isValid =
        nameError == null && phoneError == null && floorError == null;

    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _floorError = floorError;
    });

    if (!isValid) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isSender
                ? 'لطفاً بخش‌های ضروری را تکمیل کنید'
                : 'لطفاً اطلاعات ضروری گیرنده را تکمیل کنید',
          ),
          backgroundColor: CargoSheets.errorRed,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    Navigator.pop(context);
    widget.onConfirm();
  }

  void _useMyInfo() {
    setState(() {
      if (widget.onUseMyInfoPressed != null) {
        widget.onUseMyInfoPressed!();
      } else {
        widget.nameController.text = userName;
        widget.phoneController.text = userPhone;
      }

      _nameError = null;
      _phoneError = null;
    });
  }

  // ───────── رابط کاربری ─────────

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = keyboardHeight > 0;
    final double safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isSender
              ? 'cargo.sender_details_title'.tr()
              : 'cargo.receiver_details_title'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: isKeyboardOpen ? keyboardHeight + 12 : safeBottom + 12,
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
            onPressed: _submit,
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: isKeyboardOpen ? keyboardHeight + 80 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isSender) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _useMyInfo,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                                color: CargoSheets.focusBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: CargoSheets.focusBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _buildField(
                controller: widget.nameController,
                label: widget.isSender
                    ? 'cargo.sender_fullname'.tr()
                    : 'cargo.receiver_fullname'.tr(),
                errorText: _nameError,
                onChanged: (String v) {
                  if (_nameError != null && v.trim().isNotEmpty) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: widget.phoneController,
                label: widget.isSender
                    ? 'cargo.phone'.tr()
                    : 'cargo.receiver_phone'.tr(),
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                errorText: _phoneError,
                onChanged: (String v) {
                  if (_phoneError != null && _isValidPhone(v)) {
                    setState(() => _phoneError = null);
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: widget.addressController,
                label: widget.isSender
                    ? 'cargo.origin_address_label'.tr()
                    : 'cargo.destination_address_label'.tr(),
                readOnly: true,
                suffixIcon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: CargoSheets.labelGrey,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildField(
                      controller: widget.floorController,
                      label: 'cargo.plaque'.tr(),
                      errorText: _floorError,
                      onChanged: (String v) {
                        if (_floorError != null && v.trim().isNotEmpty) {
                          setState(() => _floorError = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: widget.unitController,
                      label: 'cargo.unit'.tr(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: widget.noteController,
                label: widget.isSender
                    ? 'cargo.description_optional'.tr()
                    : 'cargo.delivery_note'.tr(),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              if (!widget.isSender) ...[
                _buildDropdownField(
                  label: 'cargo.cargo_type'.tr(),
                  value: _package,
                  items: <String>[
                    'cargo.type_other'.tr(),
                    'cargo.type_home_furniture'.tr(),
                    'cargo.type_office_furniture'.tr(),
                    'cargo.type_goods_food'.tr(),
                  ],
                  onChanged: (String? val) {
                    if (val == null) return;
                    setState(() => _package = val);
                    widget.onPackageTypeChanged?.call(val);
                  },
                ),
                const SizedBox(height: 20),
                _buildDropdownField(
                  label: 'cargo.insurance_amount'.tr(),
                  value: _insurance,
                  items: <String>[
                    'cargo.insurance_50k'.tr(),
                    'cargo.insurance_100k'.tr(),
                    'cargo.insurance_500k'.tr(),
                    'cargo.no_insurance'.tr(),
                  ],
                  onChanged: (String? val) {
                    if (val == null) return;
                    setState(() => _insurance = val);
                    widget.onInsuranceChanged?.call(val);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 فیلد ورودی متنی
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    TextDirection? textDirection,
    Widget? suffixIcon,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    const OutlineInputBorder normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: CargoSheets.borderGrey, width: 1.0),
    );

    const OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: CargoSheets.focusBlue, width: 1.5),
    );

    const OutlineInputBorder errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: CargoSheets.errorRed, width: 1.5),
    );

    return TextField(
      key: ValueKey<String>('field_$label'),
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textDirection: textDirection,
      onChanged: onChanged,
      scrollPadding: const EdgeInsets.only(bottom: 40),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        isDense: false,
        labelText: label,
        errorText: errorText,
        errorStyle: const TextStyle(color: CargoSheets.errorRed, fontSize: 11),
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        labelStyle: const TextStyle(
          color: CargoSheets.labelGrey,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: TextStyle(
          color: errorText != null ? CargoSheets.errorRed : CargoSheets.focusBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          backgroundColor: Colors.white,
        ),
        hintStyle: const TextStyle(color: CargoSheets.labelGrey, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        filled: true,
        fillColor: Colors.white,
        border: normalBorder,
        enabledBorder: errorText != null ? errorBorder : normalBorder,
        disabledBorder: normalBorder,
        focusedBorder: errorText != null ? errorBorder : focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
      ),
    );
  }

  /// 🔹 فیلد دراپ‌داون انتخابی
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    const OutlineInputBorder normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: CargoSheets.borderGrey, width: 1.0),
    );

    const OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: CargoSheets.focusBlue, width: 1.5),
    );

    // ✅ اگر مقدار فعلی در لیست نبود (مثلاً بعد از تغییر زبان)، کرش نمی‌کند
    final String? safeValue = items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      key: ValueKey<String>('dropdown_$label'),
      value: safeValue,
      isExpanded: true,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: CargoSheets.labelGrey,
      ),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(
          color: CargoSheets.labelGrey,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: CargoSheets.focusBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          backgroundColor: Colors.white,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        border: normalBorder,
        enabledBorder: normalBorder,
        disabledBorder: normalBorder,
        focusedBorder: focusedBorder,
      ),
      items: items
          .map(
            (String e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
