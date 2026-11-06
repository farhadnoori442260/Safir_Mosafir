import 'package:flutter/material.dart';
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

class _SafirHomeScreenState extends State<SafirHomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color brand = Color(0xFF1B7A57);
  static const Color brandDark = Color(0xFF0E5F44);
  static const Color pageBg = Color(0xFFF6F8F7);
  static const Color darkText = Color(0xFF17202A);
  static const Color softText = Color(0xFF718096);
  static const Color activeBg = Color(0xFFEAF6F1);

  // عکس اختصاصی کارت ثبت‌نام راننده.
  static const String driverCardImage =
      'assets/images/register_banner.png';

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  int _activeSelectedIndex = 0;
  late final AnimationController _galaxyController;

  static const Map<String, Map<String, String>> _fallbacks = {
    'home_where_to': {
      'fa': 'کجا می‌روید؟',
      'en': 'Where to?',
      'ps': 'چیرته ځئ؟',
    },
    'home_become_driver': {
      'fa': 'راننده سفیر شوید',
      'en': 'Become a Safir driver',
      'ps': 'د سفیر ډرایور شئ',
    },
    'service_car': {
      'fa': 'سفیر',
      'en': 'Safir',
      'ps': 'سفیر',
    },
    'taxi_subtitle': {
      'fa': 'تکسی آنلاین شهری',
      'en': 'City taxi service',
      'ps': 'ښاري آنلاین ټکسي',
    },
    'service_cargo': {
      'fa': 'باربری',
      'en': 'Cargo',
      'ps': 'بار وړنه',
    },
    'cargo_subtitle': {
      'fa': 'حمل‌ونقل سریع بار',
      'en': 'Fast cargo transport',
      'ps': 'د بار چټک لېږد',
    },
    'service_auto': {
      'fa': 'بین‌شهری',
      'en': 'Intercity',
      'ps': 'بین ښاري',
    },
    'intercity_subtitle': {
      'fa': 'سفر ایمن بین شهرها',
      'en': 'Safe travel between cities',
      'ps': 'د ښارونو ترمنځ خوندي سفر',
    },
    'register_subtitle': {
      'fa': 'ثبت‌نام موتر و راننده',
      'en': 'Register yourself and your vehicle',
      'ps': 'د موټر او چلوونکي نوم‌لیکنه',
    },
  };

  @override
  void initState() {
    super.initState();

    _galaxyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _loadCurrentUserInfo();
    _checkUserStatusInBackground();
  }

  @override
  void dispose() {
    _galaxyController.dispose();
    super.dispose();
  }

  String _tr(String key) {
    final String value = key.tr();

    if (value.trim().isNotEmpty && value != key) {
      return value;
    }

    final Map<String, String>? translations = _fallbacks[key];
    if (translations == null) return key;

    final String language = context.locale.languageCode;

    return translations[language] ??
        translations['fa'] ??
        key;
  }

  List<_HomeService> _services() {
    return [
      _HomeService(
        id: 'car',
        title: _tr('service_car'),
        subtitle: _tr('taxi_subtitle'),
        bannerImage: 'assets/images/taxi_banner.png',
        bottomIcon: 'assets/images/taxi_car.png',
        icon: Icons.local_taxi_rounded,
      ),
      _HomeService(
        id: 'cargo',
        title: _tr('service_cargo'),
        subtitle: _tr('cargo_subtitle'),
        bannerImage: 'assets/images/cargo_banner.png',
        bottomIcon: 'assets/images/cargo_truck.png',
        icon: Icons.local_shipping_rounded,
      ),
      _HomeService(
        id: 'intercity',
        title: _tr('service_auto'),
        subtitle: _tr('intercity_subtitle'),
        bannerImage: 'assets/images/intercity_banner.png',
        bottomIcon: 'assets/images/intercity_car.png',
        icon: Icons.add_road_rounded,
      ),
    ];
  }

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
          MaterialPageRoute(
            builder: (_) => const BlockedScreen(),
          ),
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
          MaterialPageRoute(
            builder: (_) => const RegisterScreen(),
          ),
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
      final DatabaseReference usersRef =
          FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(user.uid);

      final DatabaseEvent event = await usersRef.once();

      if (!mounted) return;

      final Object? value = event.snapshot.value;

      if (value is Map) {
        setState(() {
          userName = value['name'] ?? userName;
          userPhone = value['phone'] ?? userPhone;
        });
      }
    } catch (e) {
      debugPrint('خطا در دریافت اطلاعات از فایربیس: $e');
    }
  }

  Future<void> _navigateToService(String serviceId) async {
    if (serviceId == 'register') {
      final Uri appUri = Uri.parse('safirdriver://open');
      final Uri storeUri =
          Uri.parse('https://safirapp.com/download-driver');

      try {
        if (await canLaunchUrl(appUri)) {
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

    final String type = serviceId == 'intercity'
        ? 'intercity'
        : serviceId == 'cargo'
            ? 'cargo'
            : 'taxi';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SafirMapScreen(serviceType: type),
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

    final List<_HomeService> services = _services();
    final _HomeService activeService =
        services[_activeSelectedIndex];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: pageBg,
      extendBody: true,
      drawer: isRTL ? _buildDrawer() : null,
      endDrawer: !isRTL ? _buildDrawer() : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isRTL),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildHeroBanner(activeService),
            ),
            const SizedBox(height: 16),
            _buildDriverCard(isRTL),
            const HomeAdvertisementsSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(
        services,
        isRTL,
      ),
    );
  }

  Widget _buildHeader(bool isRTL) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [brand, brandDark],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            16,
            8,
            16,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Safir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(14),
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .openAppDrawerTooltip,
                      onPressed: () => _openMenu(isRTL),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSearchBox(),
            ],
          ),
        ),
      ),
    );
  }

  // این ورودی همیشه تکسی شهری را باز می‌کند.
  Widget _buildSearchBox() {
    return Semantics(
      button: true,
      label: '${_tr('home_where_to')} ${_tr('taxi_subtitle')}',
      child: Material(
        color: Colors.white,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _navigateToService('car'),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: brand,
                  size: 25,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _tr('home_where_to'),
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: activeBg,
                    shape: BoxShape.circle,
                  ),
                  child: const AnimatedSwitcher(
                    duration: Duration(milliseconds: 250),
                    child: Icon(
                      Icons.local_taxi_rounded,
                      key: ValueKey<String>('search_car'),
                      color: brand,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(_HomeService activeService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE4EBE7),
        ),
        boxShadow: [
          BoxShadow(
            color: brandDark.withOpacity(0.09),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 108,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _galaxyController,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            brand.withOpacity(0.05),
                            brand.withOpacity(0.20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: SizedBox(
                      key: ValueKey<String>(activeService.id),
                      width: 96,
                      height: 76,
                      child: Image.asset(
                        activeService.bannerImage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return Icon(
                            activeService.icon,
                            color: brand,
                            size: 46,
                          );
                        },
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    activeService.title,
                    key: ValueKey<String>(
                      'title_${activeService.id}',
                    ),
                    style: const TextStyle(
                      color: brandDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    activeService.subtitle,
                    key: ValueKey<String>(
                      'sub_${activeService.id}',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: softText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(bool isRTL) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        button: true,
        label: _tr('home_become_driver'),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE4EBE7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _navigateToService('register'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: activeBg,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          driverCardImage,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.assignment_ind_rounded,
                              color: brand,
                              size: 27,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tr('home_become_driver'),
                            style: const TextStyle(
                              color: darkText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tr('register_subtitle'),
                            style: const TextStyle(
                              color: softText,
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
                      color: softText,
                      size: 23,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    List<_HomeService> services,
    bool isRTL,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE2EAE6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 22,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: brand.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = constraints.maxWidth;
                final double itemWidth =
                    totalWidth / services.length;

                final double leftPosition = isRTL
                    ? totalWidth -
                        ((_activeSelectedIndex + 1) * itemWidth)
                    : _activeSelectedIndex * itemWidth;

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      left: leftPosition,
                      top: 6,
                      width: itemWidth,
                      height: 52,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: activeBg,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: brand.withOpacity(0.09),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Row(
                          children: List.generate(
                            services.length,
                            (index) => Expanded(
                              child: Align(
                                alignment:
                                    AlignmentDirectional.centerEnd,
                                child: index < services.length - 1
                                    ? Container(
                                        width: 1,
                                        height: 20,
                                        color: const Color(
                                          0xFFE5ECE8,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: Row(
                          children: List.generate(
                            services.length,
                            (index) {
                              final bool isSelected =
                                  _activeSelectedIndex == index;
                              final _HomeService service =
                                  services[index];

                              return Expanded(
                                child: Semantics(
                                  selected: isSelected,
                                  button: true,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _activeSelectedIndex =
                                            index;
                                      });

                                      _navigateToService(service.id);
                                    },
                                    splashColor:
                                        Colors.transparent,
                                    highlightColor:
                                        Colors.transparent,
                                    child: Padding(
                                      padding: const EdgeInsets
                                          .symmetric(horizontal: 7),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            width: 28,
                                            height: 28,
                                            padding:
                                                const EdgeInsets.all(
                                              4,
                                            ),
                                            decoration:
                                                BoxDecoration(
                                              color: isSelected
                                                  ? brand
                                                  : Colors
                                                      .transparent,
                                              shape:
                                                  BoxShape.circle,
                                            ),
                                            child: Image.asset(
                                              service.bottomIcon,
                                              fit: BoxFit.contain,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(
                                                      0xFF6D7B74,
                                                    ),
                                              errorBuilder:
                                                  (_, __, ___) {
                                                return Icon(
                                                  service.icon,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF6D7B74,
                                                        ),
                                                  size: 19,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              service.title,
                                              maxLines: 1,
                                              overflow: TextOverflow
                                                  .ellipsis,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? brand
                                                    : const Color(
                                                        0xFF6D7B74,
                                                      ),
                                                fontSize: 12,
                                                fontWeight:
                                                    isSelected
                                                        ? FontWeight
                                                            .w600
                                                        : FontWeight
                                                            .w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeService {
  const _HomeService({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.bannerImage,
    required this.bottomIcon,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final String bannerImage;
  final String bottomIcon;
  final IconData icon;
}

/// بخش مستقل تبلیغات؛ وقتی خالی است هیچ چیزی نشان نمی‌دهد.
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int index = 0;
              index < advertisements.length;
              index++) ...[
            if (index > 0) const SizedBox(height: 14),
            advertisements[index],
          ],
        ],
      ),
    );
  }
}
