import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:safir_passengers/theme/app_colors.dart';

class SmartLocationSheet extends StatefulWidget {
  final int currentStep; // 0: مبدأ، 1: مقصد
  final String currentAddress;
  final String currentDestination;
  final VoidCallback onConfirmStep;
  final Function(String) onSearchOriginTap;
  final VoidCallback onSearchDestinationTap;
  final VoidCallback onGpsTap;
  final bool isMapIdle;
  final bool isExpanded;
  final ValueChanged<bool>? onExpandChanged;
  final bool hasGpsDisruption;

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
  State<SmartLocationSheet> createState() =>
      _SmartLocationSheetState();
}

class _SmartLocationSheetState
    extends State<SmartLocationSheet> {
  static const Color destinationColor = Color(0xFF169365);
  static const Color gpsWarningColor = Color(0xFFD97706);
  static const Color gpsWarningTextColor = Color(0xFF92400E);

  bool _showGpsWarningText = false;

  bool get _expanded => widget.isExpanded;

  @override
  void initState() {
    super.initState();

    _showGpsWarningText = widget.hasGpsDisruption;
  }

  @override
  void didUpdateWidget(
    covariant SmartLocationSheet oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.hasGpsDisruption !=
        widget.hasGpsDisruption) {
      _showGpsWarningText = widget.hasGpsDisruption;
    }
  }

  void _setExpanded(bool expanded) {
    widget.onExpandChanged?.call(expanded);
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    _setExpanded(!_expanded);
  }

  void _handleGpsTap() {
    HapticFeedback.lightImpact();
    widget.onGpsTap();

    if (!widget.hasGpsDisruption) {
      return;
    }

    setState(() {
      _showGpsWarningText = !_showGpsWarningText;
    });
  }

  String _translatedOrFallback(
    String key,
    String fallback,
  ) {
    final String value = key.tr();

    if (value.trim().isEmpty || value == key) {
      return fallback;
    }

    return value;
  }

  Map<String, String> _splitAddress(
    String fullAddress,
  ) {
    final String originFallback =
        _translatedOrFallback(
      'origin',
      'انتخاب مبدأ',
    );

    final String destinationFallback =
        _translatedOrFallback(
      'where_to_go',
      'مقصد شما کجاست؟',
    );

    final String fetchingAddress =
        _translatedOrFallback(
      'fetching_address',
      'در حال دریافت آدرس...',
    );

    final String exactLocation =
        _translatedOrFallback(
      'exact_location_on_map',
      'موقعیت دقیق روی نقشه',
    );

    final String locationOnMap =
        _translatedOrFallback(
      'location_on_map',
      'موقعیت روی نقشه',
    );

    final String cleanAddress =
        fullAddress.trim();

    if (cleanAddress.isEmpty ||
        cleanAddress == originFallback ||
        cleanAddress == destinationFallback) {
      return {
        'title': cleanAddress.isEmpty
            ? fetchingAddress
            : cleanAddress,
        'subtitle': exactLocation,
      };
    }

    final List<String> parts =
        cleanAddress.split(RegExp(r'[،,-]'));

    if (parts.length > 1) {
      return {
        'title': parts.first.trim(),
        'subtitle': parts
            .skip(1)
            .join('، ')
            .trim(),
      };
    }

    return {
      'title': cleanAddress,
      'subtitle': locationOnMap,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bool isOriginStep =
        widget.currentStep == 0;

    final String activeAddress = isOriginStep
        ? widget.currentAddress
        : widget.currentDestination;

    final Map<String, String> activeAddressData =
        _splitAddress(activeAddress);

    final String originPlaceholder =
        _translatedOrFallback(
      'origin',
      'انتخاب مبدأ',
    );

    final String destinationPlaceholder =
        _translatedOrFallback(
      'where_to_go',
      'مقصد شما کجاست؟',
    );

    final String searchHint = isOriginStep
        ? widget.currentAddress.trim().isNotEmpty
            ? widget.currentAddress
            : originPlaceholder
        : widget.currentDestination.trim().isNotEmpty
            ? widget.currentDestination
            : destinationPlaceholder;

    final bool hasSelectedAddress = isOriginStep
        ? widget.currentAddress.trim().isNotEmpty
        : widget.currentDestination.trim().isNotEmpty;

    final Color currentMarkerColor = isOriginStep
        ? AppColors.originBlue
        : destinationColor;

    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildGpsButton(context),
              _buildLocationDrawer(
                context: context,
                isOriginStep: isOriginStep,
                activeAddressData: activeAddressData,
                searchHint: searchHint,
                hasSelectedAddress: hasSelectedAddress,
                currentMarkerColor: currentMarkerColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGpsButton(BuildContext context) {
    final bool showWarning =
        widget.hasGpsDisruption &&
        _showGpsWarningText;

    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          elevation: 5,
          shadowColor: Colors.black26,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _handleGpsTap,
            splashColor:
                AppColors.primaryBrand.withOpacity(0.15),
            highlightColor: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(26),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              height: 50,
              padding: EdgeInsets.symmetric(
                horizontal: showWarning ? 14 : 13,
              ),
              decoration: BoxDecoration(
                color: showWarning
                    ? const Color(0xFFFFF7ED)
                    : Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: showWarning
                      ? const Color(0xFFF59E0B)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration:
                        const Duration(milliseconds: 220),
                    transitionBuilder:
                        (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: showWarning
                        ? const Icon(
                            Icons.warning_amber_rounded,
                            key: ValueKey(
                              'gps-warning-icon',
                            ),
                            size: 21,
                            color: gpsWarningColor,
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            key: ValueKey(
                              'gps-location-icon',
                            ),
                            size: 22,
                            color: AppColors.textPrimary,
                          ),
                  ),
                  AnimatedSize(
                    duration:
                        const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: showWarning
                        ? Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              Text(
                                _translatedOrFallback(
                                  'gps_disruption',
                                  'اختلال در موقعیت مکانی',
                                ),
                                style: const TextStyle(
                                  color: gpsWarningTextColor,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons
                                    .keyboard_arrow_up_rounded,
                                size: 18,
                                color: gpsWarningColor,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDrawer({
    required BuildContext context,
    required bool isOriginStep,
    required Map<String, String> activeAddressData,
    required String searchHint,
    required bool hasSelectedAddress,
    required Color currentMarkerColor,
  }) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        final double velocity =
            details.primaryVelocity ?? 0;

        if (velocity < -180) {
          HapticFeedback.selectionClick();
          _setExpanded(true);
        } else if (velocity > 180) {
          HapticFeedback.selectionClick();
          _setExpanded(false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 4,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(26),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDrawerHandle(),
            const SizedBox(height: 4),
            _buildSearchBox(
              context: context,
              isOriginStep: isOriginStep,
              searchHint: searchHint,
              hasSelectedAddress: hasSelectedAddress,
              currentMarkerColor: currentMarkerColor,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: _expanded
                  ? _buildExpandedContent(
                      context: context,
                      isOriginStep: isOriginStep,
                      activeAddressData:
                          activeAddressData,
                      currentMarkerColor:
                          currentMarkerColor,
                    )
                  : const SizedBox.shrink(),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: !_expanded
                  ? _buildConfirmButton(
                      context,
                      isOriginStep,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHandle() {
    return GestureDetector(
      onTap: _toggleExpanded,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        height: 34,
        child: Center(
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Icon(
              _expanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              size: 27,
              color: const Color(0xFFD1D5DB),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox({
    required BuildContext context,
    required bool isOriginStep,
    required String searchHint,
    required bool hasSelectedAddress,
    required Color currentMarkerColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();

        if (isOriginStep) {
          widget.onSearchOriginTap(
            widget.currentAddress,
          );
        } else {
          widget.onSearchDestinationTap();
        }
      },
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            _buildLocationMarker(
              currentMarkerColor,
              isOriginStep,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                searchHint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasSelectedAddress
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: hasSelectedAddress
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.search_rounded,
              color: AppColors.iconSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMarker(
    Color color,
    bool isOrigin,
  ) {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: color,
        shape: isOrigin
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: isOrigin
            ? null
            : BorderRadius.circular(5),
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
    );
  }

  Widget _buildExpandedContent({
    required BuildContext context,
    required bool isOriginStep,
    required Map<String, String> activeAddressData,
    required Color currentMarkerColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 13),
        _buildDividerBar(),
        const SizedBox(height: 13),
        _SearchResultTile(
          title: activeAddressData['title'] ?? '',
          subtitle:
              activeAddressData['subtitle'] ?? '',
          markerColor: currentMarkerColor,
          onTap: () {
            HapticFeedback.lightImpact();

            if (isOriginStep) {
              widget.onSearchOriginTap(
                activeAddressData['title'] ?? '',
              );
            } else {
              widget.onSearchDestinationTap();
            }
          },
        ),
        const SizedBox(height: 12),
        _buildDividerBar(),
        const SizedBox(height: 12),
        _AddFavoriteTile(
          title: _translatedOrFallback(
            'add_favorite_place',
            'افزودن مکان منتخب',
          ),
          onTap: () {
            HapticFeedback.lightImpact();

            ScaffoldMessenger.of(context)
                .showSnackBar(
              SnackBar(
                content: Text(
                  _translatedOrFallback(
                    'add_favorite_place',
                    'افزودن مکان منتخب',
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildDividerBar() {
    return Container(
      height: 5,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildConfirmButton(
    BuildContext context,
    bool isOriginStep,
  ) {
    final String buttonText = isOriginStep
        ? _translatedOrFallback(
            'confirm_origin_btn',
            'تایید مبدأ',
          )
        : _translatedOrFallback(
            'confirm_destination_btn',
            'تایید مقصد',
          );

    return Padding(
      padding: const EdgeInsets.only(top: 13),
      child: SizedBox(
        width: double.infinity,
        height: 51,
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
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            buttonText,
            style: const TextStyle(
              color: AppColors.buttonText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: 4,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: markerColor,
                    size: 27,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 14,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: markerColor.withOpacity(0.8),
                      borderRadius:
                          BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.iconSecondary,
                size: 21,
              ),
            ],
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: 4,
          ),
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
                  Icons.add_rounded,
                  color: AppColors.primaryBrand,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.iconSecondary,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
