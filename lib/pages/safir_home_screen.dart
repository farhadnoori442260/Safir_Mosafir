import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:easy_localization/easy_localization.dart'
    hide TextDirection;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/widgets/animated_menus.dart';
import 'package:safir_passengers/appInfo/auth_provider.dart';
import 'package:safir_passengers/pages/blocked_screen.dart';
import 'package:safir_passengers/authentication/register_screen.dart';

import 'map_screen.dart';

class SafirHomeScreen extends StatefulWidget {
  const SafirHomeScreen({super.key});

  @override
  State<SafirHomeScreen> createState() => _SafirHomeScreenState();
}

class _SafirHomeScreenState extends State<SafirHomeScreen> {
  static const String _font = 'IranYekan';

  static const Color _brand = Color(0xFF1B7A57);
  static const Color _brandDark = Color(0xFF0E5F44);
  static const Color _activeBg = Color(0xFFEAF6F1);
  static const Color _pageBg = Color(0xFFF1F4F2);
  static const Color _darkText = Color(0xFF17202A);
  static const Color _softText = Color(0xFF6B7A73);
  static const Color _line = Color(0xFFE4EBE7);

  // فیلتر خاکستری برای آیکن‌های انتخاب‌نشده‌ی نوار پایین
  static const ColorFilter _grayFilter = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  int _activeSelectedIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
    _checkUserStatusInBackground();
  }

  // ───────────────────────── ترجمه ─────────────────────────

  String _text(
    String key, {
    required String fa,
    required String en,
    required String ps,
  }) {
    final String translated = key.tr();

    if (translated.trim().isNotEmpty && translated != key) {
      return translated;
    }

    switch (context.locale.languageCode) {
      case 'en':
        return en;
      case 'ps':
        return ps;
      default:
        return fa;
    }
  }

  // ───────────────────────── منطق ─────────────────────────

  Future<void> _checkUserStatusInBackground() async {
    try {
      final authProvider = Provider.of<AuthenticationProvider>(
        context,
        listen: false,
      );

      final bool isBlocked =
          await authProvider.checkIfUserIsBlocked().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );

      if (!mounted) return;

      if (isBlocked) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BlockedScreen()),
        );
        return;
      }

      final bool isFilled =
          await authProvider.checkUserFieldsFilled().timeout(
        const Duration(seconds: 3),
        onTimeout: () => true,
      );

      if (!mounted) return;

      if (!isFilled) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
      }
    } catch (e) {
      debugPrint('خطا در بررسی پس‌زمینه کاربر: $e');
    }
  }

  Future<void> _loadCurrentUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final DatabaseReference usersRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid);

      final DatabaseEvent event = await usersRef.once();

      if (!mounted || event.snapshot.value == null) return;

      final userData = event.snapshot.value;

      if (userData is Map) {
        setState(() {
          userName = userData['name'] ?? userName;
          userPhone = userData['phone'] ?? userPhone;
        });
      }
    } catch (e) {
      debugPrint('خطا در دریافت اطلاعات از فایربیس: $e');
    }
  }

  Future<void> _navigateToService(
    String serviceId,
    String type,
  ) async {
    if (serviceId == 'register') {
      final Uri appUri = Uri.parse('safirdriver://open');
      final Uri storeUri =
          Uri.parse('https://safirapp.com/download-driver');

      try {
        final bool isInstalled = await canLaunchUrl(appUri);

        if (isInstalled) {
          final bool opened = await launchUrl(
            appUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );

          if (opened) return;
        }

        await launchUrl(
          storeUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('خطا در باز کردن اپ راننده: $e');

        try {
          await launchUrl(
            storeUri,
            mode: LaunchMode.externalApplication,
          );
        } catch (fallbackError) {
          debugPrint(
            'خطا در باز کردن لینک دانلود راننده: $fallbackError',
          );
        }
      }

      return;
    }

    if (!mounted) return;

    final String serviceType;

    switch (serviceId) {
      case 'intercity':
        serviceType = 'intercity';
        break;
      case 'cargo':
        serviceType = 'cargo';
        break;
      default:
        serviceType = 'taxi';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SafirMapScreen(serviceType: serviceType),
      ),
    );
  }

  void _openMenu(bool isRTL) {
    if (isRTL) {
      _scaffoldKey.currentState?.openDrawer();
    } else {
      _scaffoldKey.currentState?.openEndDrawer();
    }
  }

  List<Map<String, dynamic>> _services() {
    return [
      {
        'title': _text(
          'service_car',
          fa: 'سفیر',
          en: 'Safir',
          ps: 'سفیر',
        ),
        'subtitle': _text(
          'taxi_subtitle',
          fa: 'تکسی آنلاین شهری',
          en: 'City taxi service',
          ps: 'ښاري آنلاین ټکسي',
        ),
        'bannerImage': 'assets/images/taxi_banner.png',
        'bottomIcon': 'assets/images/taxi_car.png',
        'icon': Icons.local_taxi_rounded,
        'type': 'Car',
        'id': 'car',
      },
      {
        'title': _text(
          'service_cargo',
          fa: 'باربری',
          en: 'Cargo',
          ps: 'بار وړل',
        ),
        'subtitle': _text(
          'cargo_subtitle',
          fa: 'حمل‌ونقل سریع بار',
          en: 'Fast cargo transport',
          ps: 'د بار چټک لېږد',
        ),
        'bannerImage': 'assets/images/cargo_banner.png',
        'bottomIcon': 'assets/images/cargo_truck.png',
        'icon': Icons.local_shipping_rounded,
        'type': 'Bike',
        'id': 'cargo',
      },
      {
        'title': _text(
          'service_auto',
          fa: 'بین‌ولایتی',
          en: 'Intercity',
          ps: 'بین ښاري',
        ),
        'subtitle': _text(
          'intercity_subtitle',
          fa: 'سفر ایمن بین شهرها',
          en: 'Safe travel between cities',
          ps: 'د ښارونو ترمنځ خوندي سفر',
        ),
        'bannerImage': 'assets/images/intercity_banner.png',
        'bottomIcon': 'assets/images/intercity_car.png',
        'icon': Icons.add_road_rounded,
        'type': 'Auto',
        'id': 'intercity',
      },
    ];
  }

  // ───────────────────────── ساخت صفحه ─────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width,
      child: SafeArea(
        child: ProfileAnimatedMenu(
          currentLanguage: context.locale.languageCode,
          onLanguageChanged: (newLang) {
            context.setLocale(Locale(newLang));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRTL =
        Directionality.of(context) == TextDirection.rtl;

    final List<Map<String, dynamic>> services = _services();
    final Map<String, dynamic> activeService =
        services[_activeSelectedIndex];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // هدر سبز تا بالای صفحه می‌رود؛ آیکن‌های نوار وضعیت سفید باشند
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _pageBg,
        drawer: isRTL ? _buildDrawer() : null,
        endDrawer: !isRTL ? _buildDrawer() : null,
        extendBody: true,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isRTL, activeService),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroBanner(activeService),
                    const SizedBox(height: 16),
                    _buildDriverRegistrationCard(isRTL),

                    // بخش مستقل تبلیغات: تا خالی است چیزی نمایش نمی‌دهد
                    const HomeAdvertisementsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(services, isRTL),
      ),
    );
  }

  // 🔝 هدر سبز: لوگو، منو، خوش‌آمد و «کجا می‌روید؟»
  Widget _buildHeader(bool isRTL, Map<String, dynamic> activeService) {
    final String name = userName.toString().trim();
    final bool hasName = name.isNotEmpty && name.toLowerCase() != 'null';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_brand, _brandDark],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 14, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Safir',
                    style: TextStyle(
                      fontFamily: _font,
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .openAppDrawerTooltip,
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () => _openMenu(isRTL),
                    ),
                  ),
                ],
              ),
              if (hasName) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: Text(
                    '${_text('home_hello', fa: 'سلام', en: 'Hello', ps: 'سلام')} $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ] else
                const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: _buildWhereToBox(activeService),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔎 «کجا می‌روید؟» — با لمس، نقشه‌ی سرویس انتخاب‌شده باز می‌شود
  Widget _buildWhereToBox(Map<String, dynamic> activeService) {
    final String hint = _text(
      'home_where_to',
      fa: 'کجا می‌روید؟',
      en: 'Where to?',
      ps: 'چیرته ځې؟',
    );

    return Semantics(
      button: true,
      label: hint,
      child: Material(
        color: Colors.white,
        elevation: 6,
        shadowColor: Colors.black45,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            _navigateToService(
              activeService['id'] as String,
              activeService['type'] as String,
            );
          },
          child: SizedBox(
            height: 58,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: _brand,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _darkText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: _activeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      activeService['icon'] as IconData,
                      color: _brand,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🌟 بنر سفید با سایه — فقط نام و شعار هر بخش
  Widget _buildHeroBanner(Map<String, dynamic> activeService) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE9EFEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {
            _navigateToService(
              activeService['id'] as String,
              activeService['type'] as String,
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 112,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // هالهٔ ملایم پشت ماشین
                        Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color(0xFFDDF1E8),
                                Color(0x00DDF1E8),
                              ],
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.92,
                                  end: 1,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            activeService['bannerImage'] as String,
                            key: ValueKey<String>(
                              activeService['id'] as String,
                            ),
                            fit: BoxFit.contain,
                            height: 92,
                            errorBuilder: (_, __, ___) => Icon(
                              activeService['icon'] as IconData,
                              color: _brand,
                              size: 52,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          activeService['title'] as String,
                          key: ValueKey<String>(
                            'title_${activeService['id']}',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _brand,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          activeService['subtitle'] as String,
                          key: ValueKey<String>(
                            'sub_${activeService['id']}',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _softText,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🚖 کارت «رانندهٔ سفیر شوید»
  Widget _buildDriverRegistrationCard(bool isRTL) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _navigateToService('register', 'Register'),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _activeBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset(
                    'assets/images/driver_card.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.badge_outlined,
                        color: _brand,
                        size: 25,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _text(
                          'home_become_driver_title',
                          fa: 'رانندهٔ سفیر شوید',
                          en: 'Become a Safir driver',
                          ps: 'د سفیر چلوونکی شئ',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF243B32),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _text(
                          'home_become_driver_subtitle',
                          fa: 'ثبت‌نام موتر و راننده',
                          en: 'Register yourself and your vehicle',
                          ps: 'د موټر او چلوونکي نوم‌لیکنه',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF75827C),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isRTL
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: const Color(0xFF84938C),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🏁 نوار پایین — بالاتر از لبه، با آیکن اصلی (بدون رنگ‌آمیزی)
  Widget _buildBottomNavigation(
    List<Map<String, dynamic>> services,
    bool isRTL,
  ) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 30),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2EAE6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 26,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: _brand.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double itemWidth = totalWidth / services.length;

              final double leftPosition = isRTL
                  ? totalWidth - ((_activeSelectedIndex + 1) * itemWidth)
                  : _activeSelectedIndex * itemWidth;

              return Stack(
                children: [
                  // پس‌زمینه‌ی متحرک گزینه‌ی انتخاب‌شده
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    left: leftPosition,
                    top: 6,
                    width: itemWidth,
                    height: 54,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: _activeBg,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: _brand.withOpacity(0.10),
                        ),
                      ),
                    ),
                  ),

                  // خطوط ظریف جداکننده
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Row(
                        children: List.generate(services.length, (index) {
                          return Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: index < services.length - 1
                                  ? Container(
                                      width: 1,
                                      height: 22,
                                      color: const Color(0xFFE5ECE8),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        children: List.generate(services.length, (index) {
                          final bool isSelected =
                              _activeSelectedIndex == index;
                          final Map<String, dynamic> service =
                              services[index];

                          return Expanded(
                            child: Semantics(
                              button: true,
                              selected: isSelected,
                              label: service['title'] as String,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();

                                  setState(() {
                                    _activeSelectedIndex = index;
                                  });

                                  _navigateToService(
                                    service['id'] as String,
                                    service['type'] as String,
                                  );
                                },
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      _buildNavIcon(service, isSelected),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          service['title'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSelected
                                                ? _brand
                                                : const Color(0xFF6D7B74),
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// آیکن اصلی خودِ پروژه: وقتی انتخاب شده با رنگ اصلی دیده می‌شود،
  /// وقتی انتخاب نشده کمرنگ و خاکستری است.
  Widget _buildNavIcon(Map<String, dynamic> service, bool isSelected) {
    final Widget icon = Image.asset(
      service['bottomIcon'] as String,
      width: 32,
      height: 32,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Icon(
          service['icon'] as IconData,
          color: isSelected ? _brand : const Color(0xFF6D7B74),
          size: 24,
        );
      },
    );

    return AnimatedScale(
      scale: isSelected ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: isSelected
          ? icon
          : Opacity(
              opacity: 0.7,
              child: ColorFiltered(
                colorFilter: _grayFilter,
                child: icon,
              ),
            ),
    );
  }
}

/// بخش مستقل تبلیغات صفحهٔ خانه.
/// تا زمانی که لیست خالی باشد، چیزی نمایش داده نمی‌شود.
class HomeAdvertisementsSection extends StatelessWidget {
  const HomeAdvertisementsSection({
    super.key,
    this.advertisements = const <Widget>[],
  });

  final List<Widget> advertisements;

  @override
  Widget build(BuildContext context) {
    if (advertisements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int index = 0; index < advertisements.length; index++) ...[
            if (index > 0) const SizedBox(height: 14),
            advertisements[index],
          ],
        ],
      ),
    );
  }
}
