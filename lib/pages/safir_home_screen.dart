import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:easy_localization/easy_localization.dart'
    hide TextDirection;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/widgets/safir_drawer.dart';
import 'package:safir_passengers/appInfo/auth_provider.dart';
import 'package:safir_passengers/pages/blocked_screen.dart';
import 'package:safir_passengers/authentication/register_screen.dart';

import 'map_screen.dart';
import 'package:safir_passengers/theme/app_colors.dart';

class SafirHomeScreen extends StatefulWidget {
  const SafirHomeScreen({super.key});

  @override
  State<SafirHomeScreen> createState() => _SafirHomeScreenState();
}

class _SafirHomeScreenState extends State<SafirHomeScreen> {
  // عکس اختصاصی کارت ثبت‌نام راننده.
  static const String driverCardImage =
      'assets/images/register_banner.png';

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  int _activeSelectedIndex = 0;

  static const Map<String, Map<String, String>> _fallbacks = {
    'home_greeting': {
      'fa': 'سلام',
      'en': 'Hello',
      'ps': 'سلام',
    },
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
    _loadCurrentUserInfo();
    _checkUserStatusInBackground();
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
    // منوی کناری فقط میان‌بُرهای عمومی است؛ بخش حساب در صفحهٔ پروفایل می‌ماند
    return const SafirDrawer();
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
      backgroundColor: AppColors.backgroundLight,
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
            const SizedBox(height: _Space.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _Space.md,
              ),
              child: _buildHeroBanner(activeService),
            ),
            const SizedBox(height: _Space.md),
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

  // ───────────────────────── هدر ─────────────────────────

  Widget _buildHeader(bool isRTL) {
    final String name = '$userName'.trim();
    final bool hasName = name.isNotEmpty && name != 'null';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryBrand, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_Radius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            _Space.md,
            _Space.sm,
            _Space.md,
            _Space.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasName
                              ? '${_tr('home_greeting')}، $name'
                              : 'Safir',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.buttonText,
                            fontSize: _Type.title,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (hasName)
                          Text(
                            _tr('home_where_to'),
                            style: TextStyle(
                              color: AppColors.buttonText.withOpacity(0.75),
                              fontSize: _Type.body,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Material(
                    color: AppColors.buttonText.withOpacity(0.14),
                    borderRadius:
                        BorderRadius.circular(_Radius.sm),
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .openAppDrawerTooltip,
                      onPressed: () => _openMenu(isRTL),
                      icon: Icon(
                        Icons.menu_rounded,
                        color: AppColors.buttonText,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _Space.lg),
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
        color: AppColors.cardBgLight,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(_Radius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(_Radius.md),
          onTap: () => _navigateToService('car'),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _Space.md,
              vertical: 15,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: AppColors.primaryBrand,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _tr('home_where_to'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: _Type.bodyLarge,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_taxi_rounded,
                    color: AppColors.primaryBrand,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── بنر سرویس ─────────────────────────

  Widget _buildHeroBanner(_HomeService active) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_Radius.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 22,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryBrand, AppColors.primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // دایره‌های محو ثابت (بدون انیمیشن بی‌پایان، مصرف باتری کمتر)
        child: Stack(
          children: [
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: -40,
              top: -50,
              child: _softCircle(130),
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              start: -30,
              bottom: -60,
              child: _softCircle(110),
            ),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 110,
                    child: AnimatedSwitcher(
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
                        active.bannerImage,
                        key: ValueKey<String>(active.id),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return Icon(
                            active.icon,
                            color: AppColors.buttonText,
                            size: 52,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _Space.md),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          active.title,
                          key: ValueKey<String>('title_${active.id}'),
                          style: TextStyle(
                            color: AppColors.buttonText,
                            fontSize: _Type.headline,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: _Space.sm),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          active.subtitle,
                          key: ValueKey<String>('sub_${active.id}'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.buttonText.withOpacity(0.8),
                            fontSize: _Type.body,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _softCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.buttonText.withOpacity(0.07),
      ),
    );
  }

  // ───────────────────────── کارت راننده ─────────────────────────

  Widget _buildDriverCard(bool isRTL) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _Space.md),
      child: Semantics(
        button: true,
        label: _tr('home_become_driver'),
        child: Material(
          color: AppColors.cardBgLight,
          borderRadius: BorderRadius.circular(_Radius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(_Radius.md),
            onTap: () => _navigateToService('register'),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(_Radius.md),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius:
                          BorderRadius.circular(_Radius.sm),
                    ),
                    child: Image.asset(
                      driverCardImage,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Icon(
                          Icons.assignment_ind_rounded,
                          color: AppColors.primaryBrand,
                          size: 26,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('home_become_driver'),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: _Type.bodyLarge,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: _Space.xs),
                        Text(
                          _tr('register_subtitle'),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: _Type.caption + 1,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: _Space.sm),
                  Icon(
                    isRTL
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── نوار پایین ─────────────────────────

  Widget _buildBottomNavigation(
    List<_HomeService> services,
    bool isRTL,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _Space.md,
          0,
          _Space.md,
          _Space.lg,
        ),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: AppColors.cardBgLight,
            borderRadius: BorderRadius.circular(_Radius.lg),
            border: Border.all(color: AppColors.fieldBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_Radius.lg - 1),
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
                    // نشانگر انتخاب‌شده (می‌لغزد)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      left: leftPosition,
                      top: 7,
                      width: itemWidth,
                      height: 52,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(
                            _Radius.md,
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
                              final Color tint = isSelected
                                  ? AppColors.primaryBrand
                                  : AppColors.textSecondary;

                              return Expanded(
                                child: Semantics(
                                  selected: isSelected,
                                  button: true,
                                  label: service.title,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _activeSelectedIndex = index;
                                      });

                                      _navigateToService(service.id);
                                    },
                                    splashColor: Colors.transparent,
                                    highlightColor:
                                        Colors.transparent,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 26,
                                            height: 26,
                                            child: Image.asset(
                                              service.bottomIcon,
                                              fit: BoxFit.contain,
                                              color: tint,
                                              errorBuilder:
                                                  (_, __, ___) {
                                                return Icon(
                                                  service.icon,
                                                  color: tint,
                                                  size: 22,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              service.title,
                                              maxLines: 1,
                                              overflow: TextOverflow
                                                  .ellipsis,
                                              style: TextStyle(
                                                color: tint,
                                                fontSize:
                                                    _Type.body,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
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

// اندازه‌ها (فقط همین چند سطح؛ رنگ‌ها همه از AppColors می‌آیند)
class _Radius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
}

class _Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

class _Type {
  static const double caption = 11;
  static const double body = 13;
  static const double bodyLarge = 15;
  static const double title = 18;
  static const double headline = 24;
}
