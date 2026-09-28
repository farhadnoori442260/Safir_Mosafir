import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:safir_passengers/theme/app_colors.dart';

class SmartLocationSheet extends StatefulWidget {
  final int currentStep; // 0: مبدأ, 1: مقصد
  final String currentAddress;
  final String currentDestination;
  final VoidCallback onConfirmStep;
  final Function(String) onSearchOriginTap;
  final VoidCallback onSearchDestinationTap;
  final VoidCallback onGpsTap;
  final bool isMapIdle;
  final bool isExpanded;
  final ValueChanged<bool>? onExpandChanged;
  final bool hasGpsDisruption; // وضعیت اختلال سیگنال

  const SmartLocationSheet({
    super.key,
    required this.currentStep,
    required this.currentAddress,
    required this.currentDestination,
    required this.onConfirmStep,
    required this.onSearchOriginTap,
    required this.onSearchDestinationTap,
    required this.onGpsTap,
    required this.isMapIdle,
    this.isExpanded = true,
    this.onExpandChanged,
    this.hasGpsDisruption = false,
  });

  @override
  State<SmartLocationSheet> createState() => _SmartLocationSheetState();
}

class _SmartLocationSheetState extends State<SmartLocationSheet> {
  bool get _expanded => widget.isExpanded;
  static const Color destinationColor = Color(0xFF169365);
  late bool _showGpsWarningText;

  @override
  void initState() {
    super.initState();
    // متن هشدار فقط زمانی اتوماتیک باز می‌شود که اختلال شدید وجود داشته باشد
    _showGpsWarningText = widget.hasGpsDisruption;
  }

  @override
  void didUpdateWidget(covariant SmartLocationSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // در صورت تغییر وضعیت اختلال GPS از سمت والد، مقدار به‌روزرسانی می‌شود
    if (oldWidget.hasGpsDisruption != widget.hasGpsDisruption) {
      setState(() {
        _showGpsWarningText = widget.hasGpsDisruption;
      });
    }
  }

  void _setExpanded(bool expanded) {
    if (widget.onExpandChanged != null) {
      widget.onExpandChanged!(expanded);
    }
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    _setExpanded(!_expanded);
  }

  Map<String, String> _splitAddress(String fullAddress) {
    String originFallback = "origin".tr().isEmpty ? "انتخاب مبدأ" : "origin".tr();
    String destFallback = "where_to_go".tr().isEmpty ? "مقصد شما کجاست؟" : "where_to_go".tr();

    if (fullAddress.isEmpty || fullAddress == originFallback || fullAddress == destFallback) {
      return {
        'title': fullAddress.isEmpty
            ? ("fetching_address".tr().isEmpty ? "در حال دریافت آدرس..." : "fetching_address".tr())
            : fullAddress,
        'subtitle': "exact_location_on_map".tr().isEmpty ? "موقعیت دقیق روی نقشه" : "exact_location_on_map".tr()
      };
    }
    List<String> parts = fullAddress.split(RegExp(r'[،,-]'));
    if (parts.length > 1) {
      return {
        'title': parts.first.trim(),
        'subtitle': parts.skip(1).join('، ').trim(),
      };
    }
    return {
      'title': fullAddress,
      'subtitle': "location_on_map".tr().isEmpty ? "موقعیت روی نقشه" : "location_on_map".tr()
    };
  }

  @override
  Widget build(BuildContext context) {
    final bool isOriginStep = widget.currentStep == 0;
    final String activeAddress = isOriginStep ? widget.currentAddress : widget.currentDestination;
    final Map<String, String> activeAddressData = _splitAddress(activeAddress);

    final String originPlaceholder = "origin".tr().isEmpty ? "انتخاب مبدأ" : "origin".tr();
    final String destPlaceholder = "where_to_go".tr().isEmpty ? "مقصد شما کجاست؟" : "where_to_go".tr();

    final String searchHint = isOriginStep
        ? (widget.currentAddress.isNotEmpty ? widget.currentAddress : originPlaceholder)
        : (widget.currentDestination.isNotEmpty ? widget.currentDestination : destPlaceholder);

    final Color currentMarkerColor = isOriginStep ? AppColors.originBlue : destinationColor;

    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // برای قرارگیری دکمه GPS در سمت راست (در محیط RTL)
            children: [
              // ویجت شناور GPS
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  elevation: 4,
                  shadowColor: Colors.black26,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onGpsTap();
                      // با لمس کاربر، وضعیت باز/بسته بودن متن هشدار تغییر می‌کند
                      setState(() {
                        _showGpsWarningText = !_showGpsWarningText;
                      });
                    },
                    splashColor: AppColors.primaryBrand.withOpacity(0.15),
                    highlightColor: Colors.black.withOpacity(0.05),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.fastOutSlowIn,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.hasGpsDisruption && _showGpsWarningText) ...[
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "gps_disruption".tr().isEmpty ? "اختلال در موقعیت مکانی" : "gps_disruption".tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ] else
                            const Icon(
                              Icons.my_location,
                              size: 22,
                              color: AppColors.textPrimary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // کشوی تعاملی
              GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! < -180) {
                    HapticFeedback.selectionClick();
                    _setExpanded(true);
                  } else if (details.primaryVelocity! > 180) {
                    HapticFeedback.selectionClick();
                    _setExpanded(false);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // دستگیره کشویی
                      GestureDetector(
                        onTap: _toggleExpanded,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Center(
                            child: Directionality(
                              textDirection: ui.TextDirection.ltr,
                              child: Icon(
                                _expanded
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.keyboard_arrow_up_rounded,
                                size: 28,
                                color: const Color(0xFFD1D5DB),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // کادر جستجو
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (isOriginStep) {
                            widget.onSearchOriginTap(widget.currentAddress);
                          } else {
                            widget.onSearchDestinationTap();
                          }
                        },
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: currentMarkerColor,
                                  shape: isOriginStep ? BoxShape.circle : BoxShape.rectangle,
                                  borderRadius: isOriginStep ? null : BorderRadius.circular(4),
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  searchHint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: (isOriginStep && widget.currentAddress.isNotEmpty) ||
                                            (!isOriginStep && widget.currentDestination.isNotEmpty)
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.search, color: AppColors.iconSecondary),
                            ],
                          ),
                        ),
                      ),

                      // لیست پیشنهادات و آدرس
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.fastOutSlowIn,
                        child: _expanded
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 6,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _SearchResultTile(
                                    title: activeAddressData['title']!,
                                    subtitle: activeAddressData['subtitle']!,
                                    markerColor: currentMarkerColor,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      if (isOriginStep) {
                                        widget.onSearchOriginTap(activeAddressData['title']!);
                                      } else {
                                        widget.onSearchDestinationTap();
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 6,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _AddFavoriteTile(
                                    title: "add_favorite_place".tr().isEmpty ? "افزودن مکان منتخب" : "add_favorite_place".tr(),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("add_favorite_place".tr().isEmpty ? "افزودن مکان منتخب" : "add_favorite_place".tr()),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),

                      // دکمه تایید مرحله
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.fastOutSlowIn,
                        child: !_expanded
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      widget.onConfirmStep();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryButton,
                                      foregroundColor: AppColors.buttonText,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      isOriginStep
                                          ? ("confirm_origin_btn".tr().isEmpty ? "تایید مبدأ" : "confirm_origin_btn".tr())
                                          : ("confirm_destination_btn".tr().isEmpty ? "تایید مقصد" : "confirm_destination_btn".tr()),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.buttonText,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.markerColor,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color markerColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: markerColor,
                  size: 26,
                ),
                const SizedBox(height: 2),
                Container(
                  width: 14,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: markerColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.star_outline_rounded,
              color: AppColors.iconSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFavoriteTile extends StatelessWidget {
  const _AddFavoriteTile({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primaryBrand,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
