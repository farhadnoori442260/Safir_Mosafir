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
  }) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final String currency = 'currency_afg'.tr();
          final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

          return DraggableScrollableSheet(
            initialChildSize: 0.33,
            minChildSize: 0.33,
            maxChildSize: 0.58,
            snap: true,
            snapSizes: const [0.33, 0.58],
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
                      child: PageView(
                        key: ValueKey(selectedCategory),
                        controller: PageController(
                          initialPage: selectedCategory,
                        ),
                        onPageChanged: (index) {
                          HapticFeedback.selectionClick();
                          onCategoryChanged(index);
                        },
                        children: [
                          ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            children: [
                              _buildVehicleCard(
                                title: 'vehicle_eco_title'.tr(),
                                subtitle: 'vehicle_eco_sub'.tr(),
                                price:
                                    '${actualFareAmount.toStringAsFixed(0)} $currency',
                                imagePath: 'assets/images/safir_normal.png',
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
                                    '${(actualFareAmount * 1.35).toStringAsFixed(0)} $currency',
                                imagePath: 'assets/images/uberexec.png',
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
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            children: [
                              _buildVehicleCard(
                                title: 'vehicle_bike_title'.tr(),
                                subtitle: 'vehicle_bike_sub'.tr(),
                                price:
                                    '${(actualFareAmount * 0.55).toStringAsFixed(0)} $currency',
                                imagePath: 'assets/images/safir_bike.png',
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
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 8,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildOptionButton(
                                  title: 'opt_ride_options'.tr(),
                                  isActive: hasActiveTripOptions,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onTripOptionsTap();
                                  },
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 18,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: _buildOptionButton(
                                  title: 'opt_schedule'.tr(),
                                  isActive: isScheduled,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onScheduleTap();
                                  },
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 18,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: _buildOptionButton(
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
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: onRequestTrip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBrand,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'btn_request_safir'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
    return DraggableScrollableSheet(
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
                margin: const EdgeInsets.only(right: 5, top: 2, bottom: 2),
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
    );
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
            return Padding(
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
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: selectedReasonKey == null
                              ? null
                              : () async {
                                  HapticFeedback.mediumImpact();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                  onConfirmCancel();

                                  if (currentRideId != null &&
                                      currentRideId.isNotEmpty) {
                                    try {
                                      WriteBatch batch =
                                          FirebaseFirestore.instance.batch();
                                      DocumentReference rideRef =
                                          FirebaseFirestore.instance
                                              .collection('rides')
                                              .doc(currentRideId);

                                      batch.update(rideRef, {
                                        'status': 'cancelled_by_passenger',
                                        'cancelReason': selectedReasonKey,
                                        'cancelledAfterDriverAssigned':
                                            isDriverAssigned,
                                        'cancelledAt':
                                            FieldValue.serverTimestamp(),
                                      });

                                      DocumentReference adminReportRef =
                                          FirebaseFirestore.instance
                                              .collection('reports')
                                              .doc();
                                      batch.set(adminReportRef, {
                                        'tripId': currentRideId,
                                        'type': 'cancellation',
                                        'reason': selectedReasonKey,
                                        'afterDriverAssigned': isDriverAssigned,
                                        'timestamp':
                                            FieldValue.serverTimestamp(),
                                      });

                                      await batch.commit();
                                    } catch (e) {
                                      debugPrint("Error cancelling trip: $e");
                                    }
                                  }
                                },
                          child: Text(
                            'confirm_cancel_btn'.tr(),
                            style: const TextStyle(
                              color: Colors.red,
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
            );
          },
        );
      },
    );
  }

  // 💳 شیت تسویه حساب
  static void _showPaymentSheet(BuildContext context, String tripId, dynamic amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
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
                    const Icon(Icons.info_outline, color: Colors.amber, size: 20),
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
                    if (tripId.isNotEmpty) {
                      WriteBatch batch = FirebaseFirestore.instance.batch();
                      DocumentReference rideRef = FirebaseFirestore.instance.collection('rides').doc(tripId);
                      
                      batch.update(rideRef, {
                        'paymentStatus': 'paid',
                        'status': 'completed',
                        'paidAmount': amount,
                        'paidAt': FieldValue.serverTimestamp(),
                      });

                      DocumentReference transRef = FirebaseFirestore.instance.collection('transactions').doc();
                      batch.set(transRef, {
                        'tripId': tripId,
                        'amount': amount,
                        'status': 'success',
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      await batch.commit();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('payment_success_msg'.tr())),
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
        );
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
    required bool isSelected,
    required Color safirColor,
    required Color cardBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? cardBgColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                final bool isBike = title.contains('موترسایکل') || title.contains('Motorbike');
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline,
                        size: 15,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
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
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildOptionButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.primaryBrand : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
