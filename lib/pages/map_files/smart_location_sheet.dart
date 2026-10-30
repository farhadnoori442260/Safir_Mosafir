import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart'
    hide TextDirection;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:safir_passengers/models/address_models.dart';
import 'package:safir_passengers/pages/saved_addresses_screen.dart';
import 'package:safir_passengers/theme/app_colors.dart';

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

class SmartLocationSheet extends StatefulWidget {
  final int currentStep;
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
  final ValueChanged<AddressModel>? onSavedAddressSelected;

  /// صفحه‌ی نقشه (حالت فقط‌انتخاب) را باز می‌کند و آدرس تأییدشده را برمی‌گرداند.
  final Future<AddressModel?> Function()? onPickFavoriteOnMap;

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
    this.onSavedAddressSelected,
    this.onPickFavoriteOnMap,
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

  // ───────── آدرس‌های ذخیره‌شده ─────────
  // اشتراک (subscription) یک‌بار در initState ساخته می‌شود و آخرین نتیجه در
  // state نگه داشته می‌شود. قبلاً StreamBuilder با هر rebuild (باز و بسته
  // شدن کشو، حرکت نقشه) استریم جدید می‌ساخت و لحظه‌ای اسپینر نشان می‌داد؛
  // همین باعث لرزش کشو می‌شد.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _savedSubscription;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _savedDocs =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  bool _savedLoaded = false;
  bool _savedError = false;

  bool get _expanded => widget.isExpanded;

  CollectionReference<Map<String, dynamic>>?
  get _savedAddressesCollection {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved_addresses');
  }

  @override
  void initState() {
    super.initState();
    _showGpsWarningText = widget.hasGpsDisruption;
    _listenToSavedAddresses();
  }

  void _listenToSavedAddresses() {
    final CollectionReference<Map<String, dynamic>>? collection =
        _savedAddressesCollection;

    if (collection == null) {
      return;
    }

    _savedSubscription = collection
        .orderBy('updatedAt', descending: true)
        .limit(12)
        .snapshots()
        .listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        if (!mounted) return;

        setState(() {
          _savedDocs = snapshot.docs;
          _savedLoaded = true;
          _savedError = false;
        });
      },
      onError: (Object e) {
        debugPrint('Saved addresses shortcut stream error: $e');

        if (!mounted) return;

        setState(() {
          _savedError = true;
          _savedLoaded = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _savedSubscription?.cancel();
    super.dispose();
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

  Future<void> _startAddingFavoritePlace() async {
    HapticFeedback.lightImpact();

    // مرحله ۱: انتخاب روی نقشه + دکمه‌ی تأیید
    final AddressModel? selectedAddress =
        await widget.onPickFavoriteOnMap?.call();

    if (!mounted || selectedAddress == null) {
      return;
    }

    final String addressText =
        selectedAddress.humanReadableAddress?.trim().isNotEmpty == true
            ? selectedAddress.humanReadableAddress!.trim()
            : (selectedAddress.placeName ?? '').trim();

    // مرحله ۲: انتخاب خانه / دفتر یا نام دلخواه
    final Map<String, dynamic>? details =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _FavoriteDetailsPage(
          address: addressText,
        ),
      ),
    );

    if (!mounted || details == null) {
      return;
    }

    final bool saved = await _saveFavoritePlace(
      address: selectedAddress,
      addressText: addressText,
      title: details['title'] as String,
      type: details['type'] as String,
      showAsShortcut: details['showAsShortcut'] as bool,
    );

    if (!mounted || !saved) {
      return;
    }

    // ✅ در مرحلهٔ انتخاب مبدأ، آدرسِ تازه افزوده‌شده همان لحظه «مبدأ» سفر
    // می‌شود (نقشه آن را تایید می‌کند و به مرحلهٔ مقصد می‌رود).
    if (widget.currentStep == 0) {
      _selectSavedAddress(selectedAddress);
    }
  }

  /// true یعنی آدرس با موفقیت ذخیره شد.
  Future<bool> _saveFavoritePlace({
    required AddressModel address,
    required String addressText,
    required String title,
    required String type,
    required bool showAsShortcut,
  }) async {
    final CollectionReference<Map<String, dynamic>>? collection =
        _savedAddressesCollection;

    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);

    if (collection == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _translatedOrFallback(
              'login_required_to_save',
              'برای ذخیره آدرس ابتدا وارد حساب شوید',
            ),
          ),
        ),
      );
      return false;
    }

    try {
      await collection.add(<String, dynamic>{
        'title': title,
        'type': type,
        'address': addressText,
        'placeName': address.placeName ?? addressText,
        'latitude': address.latitudePosition,
        'longitude': address.longitudePosition,
        'showAsShortcut': showAsShortcut,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      HapticFeedback.mediumImpact();

      // آدرس جدید از طریق stream به‌صورت چیپ افقی ظاهر می‌شود.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _translatedOrFallback(
              'favorite_saved_success',
              'آدرس منتخب با موفقیت ذخیره شد.',
            ),
          ),
        ),
      );

      return true;
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _translatedOrFallback(
              'favorite_save_failed',
              'ذخیره آدرس انجام نشد، دوباره تلاش کنید.',
            ),
          ),
        ),
      );

      return false;
    }
  }

  Future<void> _openSavedAddressesManager() async {
    HapticFeedback.selectionClick();

    // کلیک روی هر آدرس همان رفتار چیپ‌ها را دارد: در مرحلهٔ اول مبدأ و
    // در مرحلهٔ دوم مقصد انتخاب می‌شود
    final AddressModel? selected = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (_) => SavedAddressesScreen(
          selectMode: true,
          onPickLocation: widget.onPickFavoriteOnMap,
        ),
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    _selectSavedAddress(selected);
  }

  void _selectSavedAddress(AddressModel address) {
    if (address.latitudePosition == null ||
        address.longitudePosition == null) {
      return;
    }

    HapticFeedback.mediumImpact();
    widget.onSavedAddressSelected?.call(address);
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  Map<String, String> _splitAddress(
    String fullAddress,
  ) {
    final String originFallback = _translatedOrFallback(
      'origin',
      'انتخاب مبدأ',
    );

    final String destinationFallback = _translatedOrFallback(
      'where_to_go',
      'مقصد شما کجاست؟',
    );

    final String fetchingAddress = _translatedOrFallback(
      'fetching_address',
      'در حال دریافت آدرس...',
    );

    final String exactLocation = _translatedOrFallback(
      'exact_location_on_map',
      'موقعیت دقیق روی نقشه',
    );

    final String locationOnMap = _translatedOrFallback(
      'location_on_map',
      'موقعیت روی نقشه',
    );

    final String cleanAddress = fullAddress.trim();

    if (cleanAddress.isEmpty ||
        cleanAddress == originFallback ||
        cleanAddress == destinationFallback) {
      return <String, String>{
        'title': cleanAddress.isEmpty
            ? fetchingAddress
            : cleanAddress,
        'subtitle': exactLocation,
      };
    }

    final List<String> parts =
        cleanAddress.split(RegExp(r'[،,-]'));

    if (parts.length > 1) {
      return <String, String>{
        'title': parts.first.trim(),
        'subtitle': parts.skip(1).join('، ').trim(),
      };
    }

    return <String, String>{
      'title': cleanAddress,
      'subtitle': locationOnMap,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bool isOriginStep = widget.currentStep == 0;

    final String activeAddress = isOriginStep
        ? widget.currentAddress
        : widget.currentDestination;

    final Map<String, String> activeAddressData =
        _splitAddress(activeAddress);

    final String originPlaceholder = _translatedOrFallback(
      'origin',
      'انتخاب مبدأ',
    );

    final String destinationPlaceholder = _translatedOrFallback(
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
                            key: ValueKey<String>(
                              'gps-warning-icon',
                            ),
                            size: 21,
                            color: gpsWarningColor,
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            key: ValueKey<String>(
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
                            mainAxisSize: MainAxisSize.min,
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
                                Icons.keyboard_arrow_up_rounded,
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
      // کانتینر بیرونی ثابت است (قبلاً AnimatedContainer بود که هیچ چیزی
      // را انیمیت نمی‌کرد و فقط با اندازه‌ی فرزند درگیر می‌شد).
      child: Container(
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
            // ✅ فقط یک AnimatedSize؛ محتوای باز و دکمهٔ حالت بسته داخل
            // همین یک انیمیشن جابه‌جا می‌شوند. قبلاً دو AnimatedSize مستقل
            // هم‌زمان کوچک/بزرگ می‌شدند و ارتفاع کشو می‌لرزید.
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? KeyedSubtree(
                      key: const ValueKey<String>('drawer-expanded'),
                      child: _buildExpandedContent(
                        context: context,
                        isOriginStep: isOriginStep,
                        activeAddressData: activeAddressData,
                        currentMarkerColor: currentMarkerColor,
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey<String>('drawer-collapsed'),
                      child: _buildConfirmButton(
                        context,
                        isOriginStep,
                      ),
                    ),
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
        _buildSavedAddressesSection(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSavedAddressesSection() {
    final CollectionReference<Map<String, dynamic>>?
        collection = _savedAddressesCollection;

    if (collection == null || _savedError) {
      return SizedBox(
        height: 58,
        child: _AddFavoriteChip(
          title: _translatedOrFallback(
            'add_favorite_place',
            'افزودن مکان منتخب',
          ),
          onTap: _startAddingFavoritePlace,
        ),
      );
    }

    if (!_savedLoaded) {
      return const SizedBox(
        height: 58,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.primaryBrand,
            ),
          ),
        ),
      );
    }

    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        documents = _savedDocs.where(
      (QueryDocumentSnapshot<Map<String, dynamic>> item) {
        return item.data()['showAsShortcut'] != false;
      },
    ).toList();

    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        homeAndWork = documents.where(
      (QueryDocumentSnapshot<Map<String, dynamic>> item) {
        final String type =
            item.data()['type']?.toString() ?? '';

        return type == 'home' || type == 'work';
      },
    ).toList();

    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        otherAddresses = documents.where(
      (QueryDocumentSnapshot<Map<String, dynamic>> item) {
        final String type =
            item.data()['type']?.toString() ?? '';

        return type != 'home' && type != 'work';
      },
    ).toList();

    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        favoriteAddresses = <QueryDocumentSnapshot<
            Map<String, dynamic>>>[
      ...homeAndWork,
      ...otherAddresses,
    ];

    return SizedBox(
      height: 58,
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: favoriteAddresses.length + 1,
          separatorBuilder: (
            BuildContext context,
            int index,
          ) {
            return const SizedBox(width: 8);
          },
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            // اولین آیتم در سمت راست: افزودن مکان منتخب
            // وقتی آدرس ذخیره‌شده وجود دارد، متن کوتاه می‌شود
            // تا چیپ‌های بیشتری در دید باشند.
            if (index == 0) {
              return _AddFavoriteChip(
                title: favoriteAddresses.isEmpty
                    ? _translatedOrFallback(
                        'add_favorite_place',
                        'افزودن مکان منتخب',
                      )
                    : _translatedOrFallback(
                        'add_favorite_place_short',
                        'افزودن',
                      ),
                onTap: _startAddingFavoritePlace,
              );
            }

            final Map<String, dynamic> data =
                favoriteAddresses[index - 1].data();

            final String type =
                data['type']?.toString() ?? 'other';

            final String title =
                data['title']?.toString().trim().isNotEmpty ==
                        true
                    ? data['title'].toString()
                    : _savedAddressTypeTitle(type);

            final String address =
                data['address']?.toString() ??
                    data['placeName']?.toString() ??
                    '';

            final double? latitude =
                _toDouble(data['latitude']);

            final double? longitude =
                _toDouble(data['longitude']);

            return _FavoriteAddressChip(
              title: title,
              type: type,
              onTap: () {
                _selectSavedAddress(
                  AddressModel(
                    placeName:
                        data['placeName']?.toString() ??
                            address,
                    humanReadableAddress: address,
                    latitudePosition: latitude,
                    longitudePosition: longitude,
                  ),
                );
              },
              onManageTap: type == 'home'
                  ? _openSavedAddressesManager
                  : null,
            );
          },
        ),
      ),
    );
  }

  String _savedAddressTypeTitle(String type) {
    switch (type) {
      case 'home':
        return _translatedOrFallback(
          'saved_address_home',
          'خانه',
        );
      case 'work':
        return _translatedOrFallback(
          'saved_address_work',
          'محل کار',
        );
      default:
        return _translatedOrFallback(
          'saved_address_default_title',
          'مکان منتخب',
        );
    }
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

class _AddFavoriteChip extends StatelessWidget {
  const _AddFavoriteChip({
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryBrand.withOpacity(0.09),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryBrand.withOpacity(0.20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_rounded,
                color: AppColors.primaryBrand,
                size: 21,
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryBrand,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteAddressChip extends StatelessWidget {
  const _FavoriteAddressChip({
    required this.title,
    required this.type,
    required this.onTap,
    this.onManageTap,
  });

  final String title;
  final String type;
  final VoidCallback onTap;
  final VoidCallback? onManageTap;

  IconData get _icon {
    switch (type) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.business_outlined;
      default:
        return Icons.star_outline_rounded;
    }
  }

  Color get _color {
    switch (type) {
      case 'home':
        return const Color(0xFF2563EB);
      case 'work':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.primaryBrand;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
          ),
          decoration: BoxDecoration(
            color: _color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _color.withOpacity(0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icon,
                color: _color,
                size: 20,
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  color: _color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (onManageTap != null) ...[
                const SizedBox(width: 7),
                Container(
                  width: 1,
                  height: 22,
                  color: _color.withOpacity(0.20),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onManageTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_location_alt_outlined,
                      color: _color,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// صفحه‌ی «جزئیات مکان منتخب»: نام‌گذاری آدرس + سوییچ میان‌بر.
class _FavoriteDetailsPage extends StatefulWidget {
  const _FavoriteDetailsPage({required this.address});

  final String address;

  @override
  State<_FavoriteDetailsPage> createState() =>
      _FavoriteDetailsPageState();
}

class _FavoriteDetailsPageState
    extends State<_FavoriteDetailsPage> {
  static const int _maxNameLength = 30;

  final TextEditingController _nameController =
      TextEditingController();

  bool _showAsShortcut = true;
  String _type = 'other';

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_canSave) {
      return;
    }

    FocusScope.of(context).unfocus();

    Navigator.pop<Map<String, dynamic>>(
      context,
      <String, dynamic>{
        'title': _nameController.text.trim(),
        'type': _type,
        'showAsShortcut': _showAsShortcut,
      },
    );
  }

  Widget _typeChip({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final bool selected = _type == type;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: selected
            ? AppColors.primaryBrand
            : AppColors.iconSecondary,
      ),
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primaryBrand.withOpacity(0.12),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() {
          _type = type;
          _nameController.text = label;
          _nameController.selection = TextSelection.collapsed(
            offset: label.length,
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          _translatedOrFallback(
            'favorite_details_title',
            'جزئیات مکان منتخب',
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      _typeChip(
                        type: 'home',
                        label: _translatedOrFallback(
                          'saved_address_home',
                          'خانه',
                        ),
                        icon: Icons.home_outlined,
                      ),
                      _typeChip(
                        type: 'work',
                        label: _translatedOrFallback(
                          'saved_address_work',
                          'دفتر',
                        ),
                        icon: Icons.business_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    onChanged: (_) {
                      if (_type != 'other') {
                        setState(() => _type = 'other');
                      }
                    },
                    maxLength: _maxNameLength,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        _maxNameLength,
                      ),
                    ],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: _translatedOrFallback(
                        'favorite_name_label',
                        'نام مکان منتخب',
                      ),
                      hintText: _translatedOrFallback(
                        'favorite_name_hint',
                        'مثلاً: خانه من، شرکت و ...',
                      ),
                      helperText: _translatedOrFallback(
                        'favorite_name_helper',
                        'نام انتخابی فقط به خودتان نشان داده می‌شود.',
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBrand,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      helperText: _translatedOrFallback(
                        'favorite_address_helper',
                        'این آدرس فقط به خودتان نشان داده می‌شود.',
                      ),
                    ),
                    child: Text(
                      widget.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _showAsShortcut,
                    activeColor: AppColors.primaryBrand,
                    onChanged: (bool value) {
                      setState(() => _showAsShortcut = value);
                    },
                    title: Text(
                      _translatedOrFallback(
                        'favorite_show_as_shortcut',
                        'نمایش به صورت میان‌بر',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 51,
                child: ElevatedButton(
                  onPressed: _canSave ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    foregroundColor: AppColors.buttonText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _translatedOrFallback(
                      'save',
                      'ذخیره',
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
