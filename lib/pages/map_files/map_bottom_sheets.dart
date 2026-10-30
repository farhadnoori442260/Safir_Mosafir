import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/global/trip_var.dart';
import 'package:safir_passengers/theme/app_colors.dart';
import '../chat_page.dart';

import 'smart_location_sheet.dart';
import 'package:safir_passengers/widgets/driver_info_card.dart';

import 'trip_options_sheet.dart';
import 'schedule_trip_sheet.dart';
import 'promo_code_sheet.dart';

class MapBottomSheets {
  // 📍 مرحله ۱: انتخاب مبدأ و مقصد روی نقشه
  static Widget buildStep1({
    required BuildContext context,
    required bool isOriginStep,
    required String liveMarkerAddress,
    required String secondaryAddress,
    required VoidCallback onConfirmLocation,
    required VoidCallback onSearchTap,
    VoidCallback? onGpsTap,
    bool isMapIdle = true,
    bool isExpanded = true,
    ValueChanged<bool>? onExpandChanged,
  }) {
    return SmartLocationSheet(
      currentStep: isOriginStep ? 0 : 1,
      currentAddress: liveMarkerAddress,
      currentDestination: secondaryAddress,
      onConfirmStep: () {
        HapticFeedback.mediumImpact();
        onConfirmLocation();
      },
      onSearchOriginTap: (_) {
        HapticFeedback.lightImpact();
        onSearchTap();
      },
      onSearchDestinationTap: () {
        HapticFeedback.lightImpact();
        onSearchTap();
      },
      onGpsTap: () {
        HapticFeedback.selectionClick();
        onGpsTap?.call();
      },
      isMapIdle: isMapIdle,
      isExpanded: isExpanded,
      onExpandChanged: onExpandChanged,
    );
  }

  // 🎯 مرحله ۲: انتخاب نوع خودرو و موتورسایکل
  static Widget buildStep2({
    required int selectedCategory,
    required int selectedVehicleType,
    required double actualFareAmount,
    required Color safirColor,
    required Function(int) onCategoryChanged,
    required Function(int, String) onVehicleSelected,
    required VoidCallback onRequestTrip,
    required VoidCallback onTripOptionsTap,
    required VoidCallback onScheduleTap,
    required VoidCallback onPromoCodeTap,
    bool hasActiveTripOptions = false,
    bool isScheduled = false,
    bool hasPromoCode = false,
    double? distanceInKm,
    // قیمت هر نوع سرویس (از تنظیمات پنل ادمین)؛ اگر داده نشود از ضریب قدیمی حساب می‌شود
    double? ecoFare,
    double? vipFare,
    double? bikeFare,
  }) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final String currency = 'currency_afg'.tr();
          final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

          return DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.42,
            maxChildSize: 0.64,
            snap: true,
            snapSizes: const [0.42, 0.64],
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTabs(
                      selectedCategory: selectedCategory,
                      onCategoryChanged: onCategoryChanged,
                    ),
                    Expanded(
                      // ✅ کنترلر ثابت (نه ساخت دوباره در هر build) تا کشیدنِ
                      // بین دو تب بدون پرش و بدون ساخت دوباره‌ی صفحه انجام شود
                      child: _VehiclePager(
                        selectedCategory: selectedCategory,
                        onCategoryChanged: onCategoryChanged,
                        pages: [
                          ListView(
                            controller:
                                selectedCategory == 0 ? scrollController : null,
                            primary: false,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            children: [
                              _buildVehicleCard(
                                title: 'vehicle_eco_title'.tr(),
                                subtitle: 'vehicle_eco_sub'.tr(),
                                price:
                                    '${(ecoFare ?? actualFareAmount).toStringAsFixed(0)} $currency',
                                imagePath: 'assets/images/safir_normal.png',
                                isBike: false,
                                isSelected: selectedVehicleType == 0,
                                safirColor: safirColor,
                                cardBgColor: AppColors.cardBgLight,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onVehicleSelected(0, 'Car');
                                },
                              ),
                              const SizedBox(height: 10),
                              _buildVehicleCard(
                                title: 'vehicle_vip_title'.tr(),
                                subtitle: 'vehicle_vip_sub'.tr(),
                                price:
                                    '${(vipFare ?? actualFareAmount * 1.35).toStringAsFixed(0)} $currency',
                                imagePath: 'assets/images/uberexec.png',
                                isBike: false,
                                isSelected: selectedVehicleType == 1,
                                safirColor: safirColor,
                                cardBgColor: AppColors.cardBgLight,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onVehicleSelected(1, 'Auto');
                                },
                              ),
                            ],
                          ),
                          ListView(
                            controller:
                                selectedCategory == 1 ? scrollController : null,
                            primary: false,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            children: [
                              _buildVehicleCard(
                                title: 'vehicle_bike_title'.tr(),
                                subtitle: 'vehicle_bike_sub'.tr(),
                                price:
                                    '${(bikeFare ?? actualFareAmount * 0.55).toStringAsFixed(0)} $currency',
                                imagePath: 'assets/images/safir_bike.png',
                                isBike: true,
                                isSelected: selectedVehicleType == 0,
                                safirColor: safirColor,
                                cardBgColor: AppColors.cardBgLight,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onVehicleSelected(0, 'Bike');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        10,
                        16,
                        bottomSafeArea + 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFF0F1F3)),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildOptionButton(
                                  icon: Icons.tune_rounded,
                                  title: 'opt_ride_options'.tr(),
                                  isActive: hasActiveTripOptions,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onTripOptionsTap();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildOptionButton(
                                  icon: Icons.schedule_rounded,
                                  title: 'opt_schedule'.tr(),
                                  isActive: isScheduled,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onScheduleTap();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildOptionButton(
                                  icon: Icons.local_offer_outlined,
                                  title: 'opt_promo_code'.tr(),
                                  isActive: hasPromoCode,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onPromoCodeTap();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: onRequestTrip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBrand,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'btn_request_safir'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🚀 مرحله ۳: حالت در حال جست‌وجوی سفیر
  static Widget buildStep3({
    required Color safirColor,
    required String originAddress,
    required String destinationAddress,
    required double fareAmount,
    required VoidCallback onCancel,
    String? currentRideId,
    VoidCallback? onBidPricePressed,
  }) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.42,
      minChildSize: 0.28,
      maxChildSize: 0.72,
      snap: true,
      builder: (context, scrollController) {
        final String currency = 'currency_afg'.tr();

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                spreadRadius: 2,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    LoadingAnimationWidget.flickr(
                      leftDotColor: AppColors.primaryBrand,
                      rightDotColor: Colors.orangeAccent,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'searching_driver_msg'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // دکمه‌ای که کاری نمی‌کرد فقط وقتی callback واقعی داده شود نمایش داده می‌شود
              if (onBidPricePressed != null) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppColors.primaryBrand,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onBidPricePressed?.call();
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 14,
                  color: AppColors.primaryBrand,
                ),
                label: Text(
                  'new_bid_offer'.tr(),
                  style: const TextStyle(
                    color: AppColors.primaryBrand,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ],
              Text(
                'opt_ride_options'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.circle,
                    size: 12,
                    color: AppColors.originBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      originAddress.isEmpty ? 'origin'.tr() : originAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 5, top: 2, bottom: 2),
                height: 14,
                width: 2,
                color: Colors.grey.shade300,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.square,
                    size: 12,
                    color: AppColors.primaryBrand,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      destinationAddress.isEmpty
                          ? 'destination'.tr()
                          : destinationAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${fareAmount.toStringAsFixed(0)} $currency',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'terms_and_privacy_notice'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showCancelReasonDialog(
                    context,
                    onCancel,
                    currentRideId: currentRideId,
                    isDriverAssigned: false,
                  );
                },
                child: Text(
                  'cancel_request_title'.tr(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ));
  }

  // 🔴 دیالوگ دلایل لغو
  static void _showCancelReasonDialog(
    BuildContext context,
    VoidCallback onConfirmCancel, {
    String? currentRideId,
    bool isDriverAssigned = false,
  }) {
    String? selectedReasonKey;

    final List<Map<String, String>> searchingReasons = [
      {'key': 'cancel_reason_hurry', 'fallback': 'cancel_reason_hurry'.tr()},
      {'key': 'cancel_reason_changed_mind', 'fallback': 'cancel_reason_changed_mind'.tr()},
      {'key': 'cancel_reason_modify_trip', 'fallback': 'cancel_reason_modify_trip'.tr()},
      {'key': 'cancel_reason_other', 'fallback': 'cancel_reason_other'.tr()},
    ];

    final List<Map<String, String>> afterAcceptReasons = [
      {'key': 'cancel_reason_driver_too_far', 'fallback': 'cancel_reason_driver_too_far'.tr()},
      {'key': 'cancel_reason_no_longer_needed', 'fallback': 'cancel_reason_no_longer_needed'.tr()},
      {'key': 'cancel_reason_wrong_address', 'fallback': 'cancel_reason_wrong_address'.tr()},
      {'key': 'cancel_reason_other', 'fallback': 'cancel_reason_other'.tr()},
    ];

    final List<Map<String, String>> reasons =
        isDriverAssigned ? afterAcceptReasons : searchingReasons;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'cancel_request_title'.tr(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  if (isDriverAssigned) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        'cancel_after_accept_warning'.tr(),
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'select_cancel_reason_title'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...reasons.map((item) {
                    String titleText = item['key']!.tr();

                    return RadioListTile<String>(
                      title: Text(
                        titleText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      value: item['key']!,
                      groupValue: selectedReasonKey,
                      activeColor: Colors.red,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setModalState(() {
                          selectedReasonKey = value;
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            disabledBackgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: selectedReasonKey == null
                              ? null
                              : () async {
                                  HapticFeedback.mediumImpact();

                                  // دلیل انتخاب‌شده را قبل از بستن دیالوگ نگه می‌داریم
                                  final String reasonKey = selectedReasonKey!;

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }

                                  // ✅ لغو واقعی سفر (وضعیت، پنل و نقشه) را
                                  // خود صفحهٔ نقشه انجام می‌دهد
                                  onConfirmCancel();

                                  // ✅ اینجا فقط «دلیل لغو» و گزارش ثبت می‌شود.
                                  // وضعیت سفر دوباره نوشته نمی‌شود تا با لغوِ
                                  // اصلی تداخل نکند (قبلاً دوبار نوشته می‌شد).
                                  if (currentRideId != null &&
                                      currentRideId.isNotEmpty) {
                                    try {
                                      final WriteBatch batch =
                                          FirebaseFirestore.instance.batch();

                                      final DocumentReference rideRef =
                                          FirebaseFirestore.instance
                                              .collection('rides')
                                              .doc(currentRideId);

                                      batch.update(rideRef, {
                                        'cancelReason': reasonKey,
                                        'cancelledAfterDriverAssigned':
                                            isDriverAssigned,
                                      });

                                      final DocumentReference adminReportRef =
                                          FirebaseFirestore.instance
                                              .collection('reports')
                                              .doc();

                                      batch.set(adminReportRef, {
                                        'tripId': currentRideId,
                                        'type': 'cancellation',
                                        'reason': reasonKey,
                                        'afterDriverAssigned': isDriverAssigned,
                                        'timestamp':
                                            FieldValue.serverTimestamp(),
                                      });

                                      await batch.commit();
                                    } catch (e) {
                                      debugPrint(
                                        "Error saving cancel reason: $e",
                                      );
                                    }
                                  }
                                },
                          child: Text(
                            'confirm_cancel_btn'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'cancel'.tr(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ));
          },
        );
      },
    );
  }

  // 💳 شیت تسویه حساب
  //
  // ✅ اصلاح مهم: قبلاً با زدن این دکمه مسافر خودش وضعیت سفر را «completed»
  // می‌کرد و در «transactions» (که فقط ادمین اجازهٔ نوشتن دارد) سند می‌ساخت.
  // پایان سفر باید فقط با دکمهٔ «پایان سفر» راننده انجام شود، وگرنه درآمد
  // راننده ثبت نمی‌شود. حالا فقط «تأیید پرداخت نقدی توسط مسافر» ثبت می‌شود.
  static void _showPaymentSheet(BuildContext context, String tripId, dynamic amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.account_balance_wallet_rounded, size: 48, color: AppColors.primaryBrand),
              const SizedBox(height: 12),
              Text(
                'payment_settlement_title'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                '${'payable_amount_label'.tr()}: $amount ${'currency_afg'.tr()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBrand),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'payment_unpaid_warning_msg'.tr(),
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBrand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);

                    if (tripId.isEmpty) return;

                    try {
                      await FirebaseFirestore.instance
                          .collection('rides')
                          .doc(tripId)
                          .update({
                        'payment_method': 'cash',
                        'passenger_confirmed_payment': true,
                        'paid_amount': amount,
                        'passenger_confirmed_payment_at':
                            FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('payment_success_msg'.tr())),
                        );
                      }
                    } catch (e) {
                      debugPrint('Payment confirm error: $e');

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'error_occurred'.tr(args: [e.toString()]),
                            ),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'confirm_cash_payment_btn'.tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ));
      },
    );
  }

  // 🚕 مرحله ۴: پذیرش راننده، زمان رسیدن و اطلاعات کامل سفر
  static Widget buildStep4(
    Color safirColor, {
    String tripId = '',
    String carColorDriver = '',
    dynamic tripFareAmount = 0,
    String plateProvinceDriver = '',
    String plateCategoryDriver = '',
    String plateFarsiNumDriver = '',
    String plateNumDriver = '',
    bool isTempPlateDriver = false,
    String nameDriver = '',
    String carDetailsDriver = '',
    String photoDriver = '',
    String phoneNumberDriver = '',
    String estimatedArrivalTime = '5',
    VoidCallback? onCancelTrip,
  }) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.38,
        minChildSize: 0.22,
        maxChildSize: 0.65,
        snap: true,
        snapSizes: const [0.22, 0.38, 0.65],
        expand: false,
        builder: (context, scrollController) {
          final Map<String, dynamic> driverData = {
            'tripId': tripId,
            'full_name': nameDriver.isNotEmpty ? nameDriver : "driver_default_name".tr(),
            'car_model': carDetailsDriver.isNotEmpty ? carDetailsDriver : "car_default_model".tr(),
            'car_color': carColorDriver.isNotEmpty ? carColorDriver : 'car_default_color'.tr(),
            'photo': photoDriver,
            'fare_amount': tripFareAmount,
            'plate_province': plateProvinceDriver.isNotEmpty ? plateProvinceDriver : 'plate_default_province'.tr(),
            'plate_category': plateCategoryDriver.isNotEmpty ? plateCategoryDriver : 'sh',
            'plate_farsi_num': plateFarsiNumDriver.isNotEmpty ? plateFarsiNumDriver : plateNumDriver,
            'plate_num': plateNumDriver,
            'is_temp_plate': isTempPlateDriver,
            // 🔗 اضافه کردن متون ترجمه‌شده کلیدها برای اتصال قطعی به ویجت کارت راننده
            'message_button_label': 'msg_driver_hint'.tr(),
            'payment_button_label': 'payment_btn_label'.tr(),
          };

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time_filled, color: safirColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'driver_arrival_time_msg'.tr(args: [estimatedArrivalTime]),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 0.8),
                DriverInfoCard(
                  driverData: driverData,
                  onCallPressed: () {
                    HapticFeedback.lightImpact();
                    if (phoneNumberDriver.isNotEmpty) {
                      launchUrl(Uri.parse('tel:$phoneNumberDriver'));
                    }
                  },
                  onMessagePressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          tripId: tripId,
                          driverName: nameDriver.isNotEmpty ? nameDriver : "driver_default_name".tr(),
                          driverPhoto: photoDriver,
                        ),
                      ),
                    );
                  },
                  onPaymentPressed: () {
                    HapticFeedback.mediumImpact();
                    _showPaymentSheet(context, tripId, tripFareAmount);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        side: const BorderSide(color: Colors.redAccent, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        if (onCancelTrip != null) {
                          _showCancelReasonDialog(
                            context,
                            onCancelTrip,
                            currentRideId: tripId,
                            isDriverAssigned: true,
                          );
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                      label: Text(
                        'cancel_current_trip_btn'.tr(),
                        style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void showTripOptions(BuildContext context, TripOptionsSheet sheetContent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => sheetContent,
    );
  }

  static void showScheduleTrip(BuildContext context, ScheduleTripSheet sheetContent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => sheetContent,
    );
  }

  static void showPromoCode(BuildContext context, PromoCodeSheet sheetContent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => sheetContent,
    );
  }

  static Widget _buildTabs({
    required int selectedCategory,
    required Function(int) onCategoryChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTabItem(
              title: 'tab_car'.tr(),
              index: 0,
              selectedCategory: selectedCategory,
              color: AppColors.primaryBrand,
              onTap: () => onCategoryChanged(0),
            ),
            _buildTabItem(
              title: 'tab_motorbike'.tr(),
              index: 1,
              selectedCategory: selectedCategory,
              color: AppColors.primaryBrand,
              onTap: () => onCategoryChanged(1),
            ),
          ],
        ),
        const Divider(height: 1),
      ],
    );
  }

  static Widget _buildTabItem({
    required String title,
    required int index,
    required int selectedCategory,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedCategory == index;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 24,
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.textPrimary : Colors.grey.shade600,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isSelected ? 80 : 0,
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildVehicleCard({
    required String title,
    required String subtitle,
    required String price,
    required String imagePath,
    required bool isBike,
    required bool isSelected,
    required Color safirColor,
    required Color cardBgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? cardBgColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? safirColor : Colors.grey.shade200,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                imagePath,
                width: 75,
                height: 45,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    isBike ? Icons.motorcycle : Icons.directions_car,
                    size: 38,
                    color: isSelected ? safirColor : Colors.grey,
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isSelected ? safirColor : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: isSelected ? 1 : 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: safirColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryBrand.withOpacity(0.10)
                : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primaryBrand : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? AppColors.primaryBrand : Colors.grey.shade700,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isActive ? AppColors.primaryBrand : Colors.grey.shade800,
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

/// دو صفحه‌ی خودرو/موتور با PageController ثابت.
/// تب‌ها با انیمیشن عوض می‌شوند و کشیدنِ انگشت، صفحه را از نو نمی‌سازد.
class _VehiclePager extends StatefulWidget {
  const _VehiclePager({
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.pages,
  });

  final int selectedCategory;
  final ValueChanged<int> onCategoryChanged;
  final List<Widget> pages;

  @override
  State<_VehiclePager> createState() => _VehiclePagerState();
}

class _VehiclePagerState extends State<_VehiclePager> {
  late final PageController _controller =
      PageController(initialPage: widget.selectedCategory);

  @override
  void didUpdateWidget(covariant _VehiclePager oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedCategory != widget.selectedCategory &&
        _controller.hasClients &&
        _controller.page?.round() != widget.selectedCategory) {
      _controller.animateToPage(
        widget.selectedCategory,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      onPageChanged: (int index) {
        // تغییر ناشی از خود انیمیشن تب دوباره اعلام نمی‌شود
        if (index == widget.selectedCategory) return;
        HapticFeedback.selectionClick();
        widget.onCategoryChanged(index);
      },
      children: widget.pages,
    );
  }
}
