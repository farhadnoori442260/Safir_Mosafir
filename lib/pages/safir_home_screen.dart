import 'dart:async';

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
  int _activeSelectedIndex = 0;

  final Color safirBrandColor = const Color(0xFF1B7A57);
  final Color activeBgColor = const Color(0xFFEAF6F1);

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  late AnimationController _galaxyController;

  @override
  void initState() {
    super.initState();

    _loadCurrentUserInfo();
    _checkUserStatusInBackground();

    _galaxyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _galaxyController.dispose();
    super.dispose();
  }

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
        builder: (_) => SafirMapScreen(
          serviceType: serviceType,
        ),
      ),
    );
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
          fa: 'بین‌شهری',
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: isRTL ? _buildDrawer() : null,
      endDrawer: !isRTL ? _buildDrawer() : null,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isRTL),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  110,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroBanner(activeService, isRTL),
                    const SizedBox(height: 16),
                    _buildDriverRegistrationCard(),

                    // بخش مستقل تبلیغات:
                    // فعلاً خالی است و هیچ کادر اضافی نمایش نمی‌دهد.
                    const HomeAdvertisementsSection(),
                  ],
                ),
              ),
            ),
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
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        20,
        8,
        12,
        4,
      ),
      child: Row(
        children: [
          Text(
            'Safir',
            style: TextStyle(
              color: safirBrandColor,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              fontFamily: 'Serif',
            ),
          ),
          const Spacer(),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: IconButton(
              tooltip: MaterialLocalizations.of(context)
                  .openAppDrawerTooltip,
              icon: Icon(
                Icons.menu_rounded,
                color: safirBrandColor,
                size: 26,
              ),
              onPressed: () {
                if (isRTL) {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  _scaffoldKey.currentState?.openEndDrawer();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRegistrationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7ECE9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            _navigateToService('register', 'Register');
          },
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
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: activeBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset(
                    'assets/images/driver_card.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Icon(
                        Icons.badge_outlined,
                        color: safirBrandColor,
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
                  Icons.chevron_right_rounded,
                  textDirection: Directionality.of(context),
                  color: const Color(0xFF84938C),
                  size: 23,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    List<Map<String, dynamic>> services,
    bool isRTL,
  ) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
              color: safirBrandColor.withOpacity(0.03),
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
                        color: activeBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: safirBrandColor.withOpacity(0.09),
                        ),
                      ),
                    ),
                  ),

                  // خطوط ظریف برای تفکیک سه گزینه.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Row(
                        children: List.generate(
                          services.length,
                          (index) {
                            return Expanded(
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
                            );
                          },
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

                            final Map<String, dynamic> service =
                                services[index];

                            return Expanded(
                              child: InkWell(
                                onTap: () {
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
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 7,
                                  ),
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
                                            const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? safirBrandColor
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.asset(
                                          service['bottomIcon']
                                              as String,
                                          fit: BoxFit.contain,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(
                                                  0xFF6D7B74,
                                                ),
                                          errorBuilder:
                                              (_, __, ___) {
                                            return Icon(
                                              service['icon']
                                                  as IconData,
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
                                          service['title']
                                              as String,
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSelected
                                                ? safirBrandColor
                                                : const Color(
                                                    0xFF6D7B74,
                                                  ),
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
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
    );
  }

  Widget _buildHeroBanner(
    Map<String, dynamic> activeService,
    bool isRTL,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: safirBrandColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: safirBrandColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _galaxyController,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            Colors.greenAccent.withOpacity(0.15),
                            Colors.white.withOpacity(0.75),
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
                    child: Image.asset(
                      activeService['bannerImage'] as String,
                      key: ValueKey<String>(
                        activeService['id'] as String,
                      ),
                      fit: BoxFit.contain,
                      height: 75,
                      errorBuilder: (_, __, ___) => Icon(
                        activeService['icon'] as IconData,
                        color: Colors.white,
                        size: 45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    activeService['title'] as String,
                    key: ValueKey<String>(
                      "title_${activeService['id']}",
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    activeService['subtitle'] as String,
                    key: ValueKey<String>(
                      "sub_${activeService['id']}",
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _navigateToService(
                      activeService['id'] as String,
                      activeService['type'] as String,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRTL
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        size: 14,
                        color: safirBrandColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _text(
                            'request_service',
                            fa: 'درخواست سرویس',
                            en: 'Request service',
                            ps: 'د خدمت غوښتنه',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: safirBrandColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
