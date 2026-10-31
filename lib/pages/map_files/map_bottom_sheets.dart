import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;
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

  // 🎯 مرحله ۲: انتخاب نوع خودرو و موتورسایکل (با رفتار جمع‌شدنِ استاندارد فایل اول)
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
    double? ecoFare,
    double? vipFare,
    double? bikeFare,
  }) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: _Step2Sheet(
        selectedCategory: selectedCategory,
        selectedVehicleType: selectedVehicleType,
        actualFareAmount: actualFareAmount,
        safirColor: safirColor,
        onCategoryChanged: onCategoryChanged,
        onVehicleSelected: onVehicleSelected,
        onRequestTrip: onRequestTrip,
        onTripOptionsTap: onTripOptionsTap,
        onScheduleTap: onScheduleTap,
        onPromoCodeTap: onPromoCodeTap,
        hasActiveTripOptions: hasActiveTripOptions,
        isScheduled: isScheduled,
        hasPromoCode: hasPromoCode,
        ecoFare: ecoFare,
        vipFare: vipFare,
        bikeFare: bikeFare,
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
      {'key': 'cancel_reason_hurry'},
      {'key': 'cancel_reason_changed_mind'},
      {'key': 'cancel_reason_modify_trip'},
      {'key': 'cancel_reason_other'},
    ];

    final List<Map<String, String>> afterAcceptReasons = [
      {'key': 'cancel_reason_driver_too_far'},
      {'key': 'cancel_reason_no_longer_needed'},
      {'key': 'cancel_reason_wrong_address'},
      {'key': 'cancel_reason_other'},
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
                    final String titleText = _cancelReasonText(context, item['key']!);

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
                                  final String reasonKey = selectedReasonKey!;

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }

                                  onConfirmCancel();

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

  static const Map<String, List<String>> _cancelReasonFallbacks = {
    'cancel_reason_hurry': ['عجله دارم', 'I am in a hurry'],
    'cancel_reason_changed_mind': ['نظرم عوض شد', 'I changed my mind'],
    'cancel_reason_modify_trip': ['می‌خواهم سفر را ویرایش کنم', 'I want to modify the trip'],
    'cancel_reason_other': ['دلیل دیگر', 'Other reason'],
    'cancel_reason_driver_too_far': ['راننده خیلی دور است', 'The driver is too far'],
    'cancel_reason_no_longer_needed': ['دیگر نیازی ندارم', 'I no longer need the ride'],
    'cancel_reason_wrong_address': ['آدرس را اشتباه زدم', 'I entered the wrong address'],
  };

  static String _cancelReasonText(BuildContext context, String key) {
    final String v = key.tr();
    if (v.trim().isNotEmpty && v != key) return v;
    final List<String>? t = _cancelReasonFallbacks[key];
    if (t == null) return key;
    return context.locale.languageCode == 'en' ? t[1] : t[0];
  }

  // 💳 شیت پرداخت
  static void _showPaymentSheet(BuildContext context, String tripId, dynamic amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PaymentSheet(tripId: tripId, amount: amount),
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
    int? etaMinutes,
    bool isOnTrip = false,
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
                        _etaMessage(
                          context,
                          etaMinutes,
                          isOnTrip,
                          estimatedArrivalTime,
                        ),
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

  /// متن زمان رسیدن: عدد با ارقام همان زبان و واحد از خود ترجمه می‌آید؛
  /// دیگر «۱ دقیقه» فارسی داخل جمله‌ی انگلیسی (minutes) نمی‌نشیند.
  static String _etaMessage(
    BuildContext context,
    int? minutes,
    bool isOnTrip,
    String legacyText,
  ) {
    if (minutes == null) {
      return 'driver_arrival_time_msg'.tr(args: [legacyText]);
    }

    final String lang = context.locale.languageCode;
    final String n = NumberFormat.decimalPattern(lang).format(minutes);

    final String key = isOnTrip ? 'trip_arrival_eta' : 'driver_arrival_eta';
    final String translated = key.tr(args: [n]);

    if (translated != key && translated.trim().isNotEmpty) {
      return translated;
    }

    // اگر کلید در فایل ترجمه نبود
    switch (lang) {
      case 'fa':
        return isOnTrip
            ? 'تا مقصد $n دقیقه دیگر'
            : 'راننده تا $n دقیقه دیگر می‌رسد';
      case 'ps':
        return isOnTrip
            ? 'تر منزل $n دقیقې پاتې دي'
            : 'ډرایور په $n دقیقو کې رسیږي';
      default:
        return isOnTrip ? '$n min to destination' : 'Driver arrives in $n min';
    }
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

class _VehicleEntry {
  const _VehicleEntry({
    required this.index,
    required this.vehicleType,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.imagePath,
    required this.isBike,
  });

  final int index;
  final String vehicleType;
  final String title;
  final String subtitle;
  final String price;
  final String imagePath;
  final bool isBike;
}

class _Step2Sheet extends StatefulWidget {
  const _Step2Sheet({
    required this.selectedCategory,
    required this.selectedVehicleType,
    required this.actualFareAmount,
    required this.safirColor,
    required this.onCategoryChanged,
    required this.onVehicleSelected,
    required this.onRequestTrip,
    required this.onTripOptionsTap,
    required this.onScheduleTap,
    required this.onPromoCodeTap,
    required this.hasActiveTripOptions,
    required this.isScheduled,
    required this.hasPromoCode,
    this.ecoFare,
    this.vipFare,
    this.bikeFare,
  });

  final int selectedCategory;
  final int selectedVehicleType;
  final double actualFareAmount;
  final Color safirColor;
  final Function(int) onCategoryChanged;
  final Function(int, String) onVehicleSelected;
  final VoidCallback onRequestTrip;
  final VoidCallback onTripOptionsTap;
  final VoidCallback onScheduleTap;
  final VoidCallback onPromoCodeTap;
  final bool hasActiveTripOptions;
  final bool isScheduled;
  final bool hasPromoCode;
  final double? ecoFare;
  final double? vipFare;
  final double? bikeFare;

  @override
  State<_Step2Sheet> createState() => _Step2SheetState();
}

class _Step2SheetState extends State<_Step2Sheet> {
  bool _expanded = true;

  void _setExpanded(bool value) {
    if (_expanded == value) return;
    HapticFeedback.selectionClick();
    setState(() => _expanded = value);
  }

  List<_VehicleEntry> _entries(String currency) {
    final _Step2Sheet w = widget;

    if (w.selectedCategory == 1) {
      return <_VehicleEntry>[
        _VehicleEntry(
          index: 0,
          vehicleType: 'Bike',
          title: 'vehicle_bike_title'.tr(),
          subtitle: 'vehicle_bike_sub'.tr(),
          price:
              '${(w.bikeFare ?? w.actualFareAmount * 0.55).toStringAsFixed(0)} $currency',
          imagePath: 'assets/images/safir_bike.png',
          isBike: true,
        ),
      ];
    }

    return <_VehicleEntry>[
      _VehicleEntry(
        index: 0,
        vehicleType: 'Car',
        title: 'vehicle_eco_title'.tr(),
        subtitle: 'vehicle_eco_sub'.tr(),
        price:
            '${(w.ecoFare ?? w.actualFareAmount).toStringAsFixed(0)} $currency',
        imagePath: 'assets/images/safir_normal.png',
        isBike: false,
      ),
      _VehicleEntry(
        index: 1,
        vehicleType: 'Auto',
        title: 'vehicle_vip_title'.tr(),
        subtitle: 'vehicle_vip_sub'.tr(),
        price:
            '${(w.vipFare ?? w.actualFareAmount * 1.35).toStringAsFixed(0)} $currency',
        imagePath: 'assets/images/uberexec.png',
        isBike: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final _Step2Sheet w = widget;
    final String currency = 'currency_afg'.tr();
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

    final List<_VehicleEntry> all = _entries(currency);

    // حالت جمع‌شده: فقط سرویس انتخاب‌شده نمایش داده می‌شود و بخش VIP پنهان می‌گردد
    final List<_VehicleEntry> visible = _expanded || all.length == 1
        ? all
        : <_VehicleEntry>[
            all.firstWhere(
              (e) => e.index == w.selectedVehicleType,
              orElse: () => all.first,
            ),
          ];

    return GestureDetector(
      onVerticalDragEnd: (DragEndDetails d) {
        final double v = d.primaryVelocity ?? 0;
        if (v > 180) {
          _setExpanded(false);
        } else if (v < -180) {
          _setExpanded(true);
        }
      },
      child: Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _setExpanded(!_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            MapBottomSheets._buildTabs(
              selectedCategory: w.selectedCategory,
              onCategoryChanged: w.onCategoryChanged,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < visible.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      MapBottomSheets._buildVehicleCard(
                        title: visible[i].title,
                        subtitle: visible[i].subtitle,
                        price: visible[i].price,
                        imagePath: visible[i].imagePath,
                        isBike: visible[i].isBike,
                        isSelected:
                            w.selectedVehicleType == visible[i].index,
                        safirColor: w.safirColor,
                        cardBgColor: AppColors.cardBgLight,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          w.onVehicleSelected(
                            visible[i].index,
                            visible[i].vehicleType,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottomSafeArea + 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MapBottomSheets._buildOptionButton(
                          icon: Icons.tune_rounded,
                          title: 'opt_ride_options'.tr(),
                          isActive: w.hasActiveTripOptions,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            w.onTripOptionsTap();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MapBottomSheets._buildOptionButton(
                          icon: Icons.schedule_rounded,
                          title: 'opt_schedule'.tr(),
                          isActive: w.isScheduled,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            w.onScheduleTap();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MapBottomSheets._buildOptionButton(
                          icon: Icons.local_offer_outlined,
                          title: 'opt_promo_code'.tr(),
                          isActive: w.hasPromoCode,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            w.onPromoCodeTap();
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
                      onPressed: w.onRequestTrip,
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
      ),
    );
  }
}

const Map<String, Map<String, String>> _payFallbacks = {
  'payment_request_sent': {
    'fa': 'درخواست تایید پرداخت برای راننده ارسال شد.',
    'en': 'Payment confirmation request sent to the driver.',
  },
  'payment_request_failed': {
    'fa': 'ارسال درخواست انجام نشد',
    'en': 'Could not send the request',
  },
  'payment_driver_confirmed': {
    'fa': 'راننده دریافت پرداخت را تایید کرد.',
    'en': 'The driver confirmed receiving your payment.',
  },
  'payment_awaiting_driver': {
    'fa':
        'درخواست شما برای راننده ارسال شد. تا زمانی که راننده تایید نکند، پرداخت انجام‌نشده محسوب می‌شود.',
    'en':
        'Your request was sent to the driver. Until the driver confirms, the trip counts as unpaid.',
  },
  'payment_unpaid_warning_msg': {
    'fa':
        'پرداخت تا تایید راننده ثبت نمی‌شود. بعد از پرداخت نقدی به راننده، درخواست تایید را بفرستید.',
    'en':
        'Payment is not recorded until the driver confirms. After paying the driver in cash, send the confirmation request.',
  },
  'close': {'fa': 'بستن', 'en': 'Close', 'ps': 'بندول'},
  'payment_waiting_btn': {
    'fa': 'در انتظار تایید راننده',
    'en': 'Waiting for driver confirmation',
  },
  'payment_send_request_btn': {
    'fa': 'ارسال درخواست تایید پرداخت',
    'en': 'Send payment confirmation request',
  },
  'payment_settlement_title': {'fa': 'پرداخت کرایه', 'en': 'Pay the fare'},
  'payable_amount_label': {'fa': 'مبلغ قابل پرداخت', 'en': 'Amount due'},
};

/// ترجمه با پشتیبان (fa / en؛ پشتو اگر نبود فارسی)
String _payTr(BuildContext context, String key) {
  final String v = key.tr();
  if (v.trim().isNotEmpty && v != key) return v;

  final Map<String, String>? t = _payFallbacks[key];
  if (t == null) return key;

  final String lang = context.locale.languageCode;
  return t[lang] ?? (lang == 'ps' ? t['fa']! : t['en']!);
}

String _formatAmount(dynamic amount) {
  final num? n = amount is num ? amount : num.tryParse('$amount');
  return n == null ? '$amount' : n.toStringAsFixed(0);
}

/// وضعیت‌های پرداخت روی سند rides
class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.tripId, required this.amount});

  final String tripId;
  final dynamic amount;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  bool _sending = false;

  Future<void> _sendRequest() async {
    if (_sending || widget.tripId.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() => _sending = true);

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    // متن‌ها قبل از await ساخته می‌شوند تا بعد از آن به context وابسته نباشیم
    final String sentMsg = _payTr(context, 'payment_request_sent');
    final String failedMsg = _payTr(context, 'payment_request_failed');
    final num? numericAmount = widget.amount is num
        ? widget.amount as num
        : num.tryParse('${widget.amount}');

    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.tripId)
          .update(<String, dynamic>{
        'payment_method': 'cash',
        'payment_status': 'awaiting_driver_confirmation',
        'payment_requested_amount': numericAmount ?? 0,
        'payment_requested_at': FieldValue.serverTimestamp(),
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(sentMsg),
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint('Payment request error: ${e.code} | ${e.message}');

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            '$failedMsg (${e.code})',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Payment request error: $e');

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(failedMsg),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Stream<DocumentSnapshot<Map<String, dynamic>>>? stream =
        widget.tripId.isEmpty
            ? null
            : FirebaseFirestore.instance
                .collection('rides')
                .doc(widget.tripId)
                .snapshots();

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          final String status =
              snapshot.data?.data()?['payment_status']?.toString() ?? 'unpaid';

          final bool isPaid = status == 'paid' || status == 'settled';
          final bool isAwaiting = status == 'awaiting_driver_confirmation';

          final Color bannerColor = isPaid
              ? const Color(0xFF16A34A)
              : isAwaiting
                  ? const Color(0xFF2563EB)
                  : Colors.amber.shade800;

          final IconData bannerIcon = isPaid
              ? Icons.check_circle_rounded
              : isAwaiting
                  ? Icons.hourglass_top_rounded
                  : Icons.info_outline_rounded;

          final String bannerText = isPaid
              ? _payTr(context, 'payment_driver_confirmed')
              : isAwaiting
                  ? _payTr(context, 'payment_awaiting_driver')
                  : _payTr(context, 'payment_unpaid_warning_msg');

          final String buttonText = isPaid
              ? _payTr(context, 'close')
              : isAwaiting
                  ? _payTr(context, 'payment_waiting_btn')
                  : _payTr(context, 'payment_send_request_btn');

          final VoidCallback? onPressed = isPaid
              ? () => Navigator.pop(context)
              : (isAwaiting || _sending)
                  ? null
                  : _sendRequest;

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
                Icon(
                  isPaid
                      ? Icons.verified_rounded
                      : Icons.account_balance_wallet_rounded,
                  size: 48,
                  color: isPaid ? const Color(0xFF16A34A) : AppColors.primaryBrand,
                ),
                const SizedBox(height: 12),
                Text(
                  _payTr(context, 'payment_settlement_title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_payTr(context, 'payable_amount_label')}: '
                  '${_formatAmount(widget.amount)} ${'currency_afg'.tr()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBrand,
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bannerColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: bannerColor.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(bannerIcon, color: bannerColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bannerText,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPaid
                          ? const Color(0xFF16A34A)
                          : AppColors.primaryBrand,
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey.shade600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onPressed,
                    child: _sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
}
