import 'dart:math' show max;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:easy_localization/easy_localization.dart'
    hide TextDirection;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/widgets/safir_drawer.dart';
import 'package:safir_passengers/appInfo/auth_provider.dart';
import 'package:safir_passengers/authentication/link_phone_screen.dart';
import 'package:safir_passengers/pages/blocked_screen.dart';
import 'package:safir_passengers/authentication/register_screen.dart';
import 'package:safir_passengers/theme/app_colors.dart';

import 'map_screen.dart';

/// false: آیکن‌های خدمات سفید روی زمینهٔ سبز.
/// true: آیکن‌های رنگی روی زمینهٔ روشن.
const bool _kColoredHomeIcons = false;

class SafirHomeScreen extends StatefulWidget {
  const SafirHomeScreen({super.key});

  @override
  State<SafirHomeScreen> createState() => _SafirHomeScreenState();
}

class _SafirHomeScreenState extends State<SafirHomeScreen> {
  static const String heroImage = 'assets/images/home_hero.jpg';

  static const String driverCardImage =
      'assets/images/register_banner.png';

  static const double _barHeight = 46;

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  bool _openingService = false;
  bool _driverPressed = false;

  static const Map<String, Map<String, String>> _fallbacks = {
    'home_slogan': {
      'fa': 'همیشه در کنارتان...',
      'en': 'Always by your side...',
      'ps': 'تل ستاسو تر څنګ...',
    },
    'home_become_driver': {
      'fa': 'راننده سفیر شوید',
      'en': 'Become a Safir driver',
      'ps': 'د سفیر ډرایور شئ',
    },
    'home_city_taxi': {
      'fa': 'تکسی شهری',
      'en': 'City taxi',
      'ps': 'ښاري ټکسي',
    },
    'taxi_subtitle': {
      'fa': 'درخواست موتر برای شهر',
      'en': 'Request a ride in the city',
      'ps': 'د ښار لپاره موټر وغواړئ',
    },
    'service_cargo': {
      'fa': 'باربری',
      'en': 'Cargo',
      'ps': 'بار وړنه',
    },
    'cargo_subtitle': {
      'fa': 'ارسال بار و بسته‌ها',
      'en': 'Send cargo and packages',
      'ps': 'بار او بستې ولېږئ',
    },
    'service_auto': {
      'fa': 'بین‌شهری',
      'en': 'Intercity',
      'ps': 'بین ښاري',
    },
    'intercity_subtitle': {
      'fa': 'سفر به ولایت‌ها',
      'en': 'Travel between cities',
      'ps': 'ولایتونو ته سفر',
    },
    'register_subtitle': {
      'fa': 'ثبت‌نام موتر و راننده',
      'en': 'Register yourself and your vehicle',
      'ps': 'د موټر او چلوونکي نوم‌لیکنه',
    },
    'home_slide_hint': {
      'fa': 'آیکن را به راست بکشید',
      'en': 'Slide the icon to the right',
      'ps': 'نښه ښي لوري ته کش کړئ',
    },
    'home_trust': {
      'fa': 'سفر امن، سریع و مطمئن با سفیر',
      'en': 'Safe and reliable travel with Safir',
      'ps': 'له سفیر سره خوندي او ډاډمن سفر',
    },
    'home_where_to': {
      'fa': 'کجا می‌روید؟',
      'en': 'Where to?',
      'ps': 'چیرته ځئ؟',
    },
    'home_open_service': {
      'fa': 'باز کردن خدمت',
      'en': 'Open service',
      'ps': 'خدمت پرانیزئ',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
    _checkUserStatusInBackground();
  }

  String _tr(String key) {
    final value = key.tr();

    if (value.trim().isNotEmpty && value != key) {
      return value;
    }

    final translations = _fallbacks[key];

    return translations?[context.locale.languageCode] ??
        translations?['fa'] ??
        key;
  }

  double _safeTop(BuildContext context) {
    final media = MediaQuery.of(context);
    final window = MediaQueryData.fromView(View.of(context));

    return max(
      media.padding.top,
      max(media.viewPadding.top, window.padding.top),
    );
  }

  double _safeBottom(BuildContext context) {
    final media = MediaQuery.of(context);
    final window = MediaQueryData.fromView(View.of(context));

    return max(
      media.padding.bottom,
      max(media.viewPadding.bottom, window.padding.bottom),
    );
  }

  List<_HomeService> _services() {
    return [
      _HomeService(
        id: 'car',
        title: _tr('home_city_taxi'),
        subtitle: _tr('taxi_subtitle'),
        image: 'assets/images/taxi_banner.png',
        icon: Icons.directions_car_rounded,
        iconAsset: 'assets/icons/home_taxi.png',
      ),
      _HomeService(
        id: 'cargo',
        title: _tr('service_cargo'),
        subtitle: _tr('cargo_subtitle'),
        image: 'assets/images/cargo_banner.png',
        icon: Icons.local_shipping_rounded,
        iconAsset: 'assets/icons/home_cargo.png',
      ),
      _HomeService(
        id: 'intercity',
        title: _tr('service_auto'),
        subtitle: _tr('intercity_subtitle'),
        image: 'assets/images/intercity_banner.png',
        icon: Icons.route_rounded,
        iconAsset: 'assets/icons/home_intercity.png',
      ),
    ];
  }

  Future<void> _checkUserStatusInBackground() async {
    try {
      final authProvider = Provider.of<AuthenticationProvider>(
        context,
        listen: false,
      );

      final isBlocked =
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

      // حساب بدون شمارهٔ تأییدشده (مثلاً ورود قدیمی با گوگل)
      final phoneUser = FirebaseAuth.instance.currentUser;

      if (phoneUser != null && (phoneUser.phoneNumber ?? '').isEmpty) {
        final phoneOk = await ensurePhoneLinked(context);

        if (!mounted) return;

        if (!phoneOk) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const RegisterScreen(),
            ),
            (route) => false,
          );
          return;
        }
      }

      final isFilled =
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
    } catch (error) {
      debugPrint('خطا در بررسی پس‌زمینه کاربر: $error');
    }
  }

  Future<void> _loadCurrentUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final ref = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid);

      final event = await ref.once();

      if (!mounted) return;

      final value = event.snapshot.value;

      if (value is Map) {
        setState(() {
          userName = value['name'] ?? userName;
          userPhone = value['phone'] ?? userPhone;
        });
      }
    } catch (error) {
      debugPrint('خطا در دریافت اطلاعات از فایربیس: $error');
    }
  }

    Future<void> _navigateToService(String serviceId) async {
    if (!mounted) return;

    if (serviceId == 'register') {
      final Uri driverAppUri = Uri.parse(
        'safirdriver://open',
      );

      final Uri driverDownloadUri = Uri.parse(
        'https://github.com/farhadrasa78-a11y/'
        'safir-downloads/releases/latest/download/'
        'safir-driver.apk',
      );

      bool opened = false;

      // ابتدا تلاش برای بازکردن اپ راننده.
      try {
        opened = await launchUrl(
          driverAppUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (error) {
        debugPrint('Driver app launch error: $error');
      }

      if (opened || !mounted) return;

      // اگر اپ باز نشد، لینک دانلود آخرین APK باز شود.
      try {
        opened = await launchUrl(
          driverDownloadUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (error) {
        debugPrint('Driver APK link error: $error');
      }

      if (opened || !mounted) return;

      final String language = context.locale.languageCode;
      final String message;

      switch (language) {
        case 'en':
          message =
              'Could not open Safir Driver or its download link. '
              'Please try again.';
          break;

        case 'ps':
          message =
              'د سفیر ډرایور اپ یا د ډاونلوډ لینک خلاص نه شو. '
              'بیا هڅه وکړئ.';
          break;

        default:
          message =
              'اپ راننده یا لینک دانلود باز نشد؛ '
              'دوباره تلاش کنید.';
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(message),
          ),
        );

      return;
    }

    final String type = serviceId == 'intercity'
        ? 'intercity'
        : serviceId == 'cargo'
            ? 'cargo'
            : 'taxi';

    // تا بازگشت از نقشه منتظر می‌ماند؛ آیکن کشیده‌شده تا آن موقع
    // در انتها می‌ماند و بعد نرم به جای اول برمی‌گردد.
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SafirMapScreen(serviceType: type),
      ),
    );
    }

  void _openMenu() {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    if (isRTL) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);
    final services = _services();
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final topInset = _safeTop(context);
    final bottomInset = _safeBottom(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.background,
      drawer: !isRTL ? const SafirDrawer() : null,
      endDrawer: isRTL ? const SafirDrawer() : null,
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroHeight = (constraints.maxHeight * 0.55)
                .clamp(260.0, 460.0)
                .toDouble();

            final textScale = MediaQuery.textScalerOf(context)
                .scale(1)
                .clamp(1.0, 1.8)
                .toDouble();

            final capsuleHeight = 102 + (textScale - 1) * 38;
            final driverHeight = 72 + (textScale - 1) * 28;

            final fixedHeight = topInset +
                8 +
                _barHeight +
                services.length * (capsuleHeight + 12) +
                2 +
                driverHeight +
                bottomInset +
                14;

            final spacerHeight =
                max(0.0, constraints.maxHeight - fixedHeight - 24);

            return Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            palette.backgroundTop,
                            palette.background,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: heroHeight,
                  child: RepaintBoundary(
                    child: _buildHeroBackground(palette),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topInset + 150,
                  child: const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x6600181D),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: topInset + 8),
                        _buildTopBar(),
                        SizedBox(height: spacerHeight),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              for (int i = 0;
                                  i < services.length;
                                  i++) ...[
                                TweenAnimationBuilder<double>(
                                  key: ValueKey(
                                    'enter_${services[i].id}',
                                  ),
                                  tween: Tween<double>(
                                    begin: 0,
                                    end: 1,
                                  ),
                                  duration: Duration(
                                    milliseconds: 520 + i * 140,
                                  ),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, t, child) {
                                    return Opacity(
                                      opacity: t,
                                      child: Transform.translate(
                                        offset: Offset(
                                          0,
                                          28 * (1 - t),
                                        ),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _SlideServiceCapsule(
                                    key: ValueKey(services[i].id),
                                    service: services[i],
                                    enabled: !_openingService,
                                    hint: _tr('home_slide_hint'),
                                    openLabel:
                                        _tr('home_open_service'),
                                    onCompleted: () =>
                                        _navigateToService(
                                      services[i].id,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              const HomeAdvertisementsSection(),
                              const SizedBox(height: 2),
                              _buildDriverCard(
                                palette,
                                driverHeight,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: bottomInset + 14),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroBackground(_HomePalette palette) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, 0.80, 1],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            heroImage,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, error, ___) {
              debugPrint('خطا در بارگذاری عکس هوم: $error');

              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      palette.backgroundTop,
                      palette.background,
                    ],
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              color: Colors.black.withOpacity(
                palette.isDark ? 0.38 : 0.04,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glass({
    required Widget child,
    required double radius,
    double? width,
    double height = _barHeight,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withOpacity(0.30),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final appDirection = Directionality.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            _buildMenuButton(),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSearchBar(appDirection),
            ),
            const SizedBox(width: 10),
            _buildBrandMark(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return Semantics(
      button: true,
      label:
          MaterialLocalizations.of(context).openAppDrawerTooltip,
      child: _glass(
        radius: _barHeight / 2,
        width: _barHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openMenu,
            child: const Center(
              child: Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(TextDirection appDirection) {
    return Semantics(
      button: true,
      label: _tr('home_where_to'),
      child: _glass(
        radius: _barHeight / 2,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openingService
                ? null
                : () => _navigateToService('car'),
            child: Directionality(
              textDirection: appDirection,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _tr('home_where_to'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.94),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildBrandMark() {
    return _glass(
      radius: _barHeight / 2,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Center(
          child: Text(
            'SAFIR',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.6,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard(
    _HomePalette palette,
    double minHeight,
  ) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: palette.shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(
                      palette.isDark ? 0.14 : 0.22,
                    ),
                    Colors.white.withOpacity(
                      palette.isDark ? 0.07 : 0.11,
                    ),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(
                    palette.isDark ? 0.23 : 0.35,
                  ),
                ),
              ),
              child: InkWell(
                onHighlightChanged: (pressed) {
                  if (!mounted || _driverPressed == pressed) {
                    return;
                  }

                  setState(() => _driverPressed = pressed);
                },
                onTap: _openingService
                    ? null
                    : () => _navigateToService('register'),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: minHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        _JellyBadge(
                          size: 46,
                          pressed: _driverPressed,
                          isDark: palette.isDark,
                          child: Image.asset(
                            driverCardImage,
                            width: 29,
                            height: 29,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) {
                              return const Icon(
                                Icons.assignment_ind_rounded,
                                color: Colors.white,
                                size: 27,
                              );
                            },
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
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _tr('register_subtitle'),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.82),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isRTL
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 23,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePalette {
  const _HomePalette({
    required this.isDark,
    required this.surface,
    required this.text,
    required this.secondary,
    required this.border,
    required this.background,
    required this.backgroundTop,
    required this.brandText,
  });

  factory _HomePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return _HomePalette(
      isDark: isDark,
      surface: scheme.surface,
      text: scheme.onSurface,
      secondary: scheme.onSurface.withOpacity(
        isDark ? 0.74 : 0.70,
      ),
      border: isDark
          ? Colors.white.withOpacity(0.13)
          : Colors.white.withOpacity(0.85),
      background: isDark
          ? theme.scaffoldBackgroundColor
          : Color.lerp(
              AppColors.primaryDark,
              AppColors.primaryBrand,
              0.15,
            )!,
      backgroundTop: isDark
          ? Color.lerp(
              theme.scaffoldBackgroundColor,
              AppColors.primaryDark,
              0.30,
            )!
          : AppColors.primaryDark,
      brandText: isDark
          ? Color.lerp(
              AppColors.primaryBrand,
              Colors.white,
              0.48,
            )!
          : AppColors.primaryBrand,
    );
  }

  final bool isDark;
  final Color surface;
  final Color text;
  final Color secondary;
  final Color border;
  final Color background;
  final Color backgroundTop;
  final Color brandText;

  List<BoxShadow> get shadows => [
        BoxShadow(
          color: Colors.black.withOpacity(
            isDark ? 0.32 : 0.17,
          ),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(
            isDark ? 0.12 : 0.04,
          ),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
}

class _HomeService {
  const _HomeService({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.icon,
    required this.iconAsset,
  });

  final String id;
  final String title;
  final String subtitle;
  final String image;
  final IconData icon;
  final String iconAsset;
}

/// ظاهر مشترک دستگیره‌های خدمات و آیکن ثبت‌نام راننده.
class _JellyBadge extends StatelessWidget {
  const _JellyBadge({
    required this.size,
    required this.child,
    required this.isDark,
    this.pressed = false,
    this.coloredIcon = false,
  });

  final double size;
  final Widget child;
  final bool isDark;
  final bool pressed;
  final bool coloredIcon;

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.primaryBrand;

    final base = isDark
        ? Color.lerp(brand, Colors.white, 0.10)!
        : brand;

    final top = Color.lerp(base, Colors.white, 0.27)!;
    final bottom = Color.lerp(base, Colors.black, 0.16)!;
    final radius = size * (pressed ? 0.39 : 0.46);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      transformAlignment: Alignment.center,
      transform: Matrix4.diagonal3Values(
        pressed ? 1.045 : 1,
        pressed ? 0.95 : 1,
        1,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: coloredIcon
              ? [
                  Color.lerp(Colors.white, brand, 0.05)!,
                  Color.lerp(Colors.white, brand, 0.12)!,
                  Color.lerp(Colors.white, brand, 0.23)!,
                ]
              : [
                  top,
                  base,
                  bottom,
                ],
          stops: const [0, 0.48, 1],
        ),
        border: Border.all(
          color: coloredIcon
              ? brand.withOpacity(0.25)
              : Color.lerp(base, Colors.white, 0.57)!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isDark ? 0.24 : 0.14,
            ),
            blurRadius: pressed ? 10 : 7,
            offset: Offset(0, pressed ? 5 : 3),
          ),
          BoxShadow(
            color: brand.withOpacity(
              pressed ? 0.22 : 0.12,
            ),
            blurRadius: pressed ? 12 : 7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // لمعان باریک بالا؛ از مرکز علامت فاصله دارد.
            Positioned(
              left: size * 0.18,
              right: size * 0.18,
              top: size * 0.055,
              height: size * 0.10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(
                        coloredIcon ? 0.65 : 0.40,
                      ),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),

            // نور لبهٔ چپ، بدون لکهٔ سفید روی آیکن.
            Positioned(
              top: size * 0.23,
              bottom: size * 0.25,
              left: size * 0.045,
              width: size * 0.045,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),

            // بازتاب ضعیف لبهٔ پایین.
            Positioned(
              left: size * 0.25,
              right: size * 0.25,
              bottom: size * 0.045,
              height: size * 0.045,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  color: Colors.white.withOpacity(0.13),
                ),
              ),
            ),

            Center(child: child),
          ],
        ),
      ),
    );
  }
}

class _SlideServiceCapsule extends StatefulWidget {
  const _SlideServiceCapsule({
    super.key,
    required this.service,
    required this.enabled,
    required this.hint,
    required this.openLabel,
    required this.onCompleted,
  });

  final _HomeService service;
  final bool enabled;
  final String hint;
  final String openLabel;
  final Future<void> Function() onCompleted;

  @override
  State<_SlideServiceCapsule> createState() =>
      _SlideServiceCapsuleState();
}

class _SlideServiceCapsuleState
    extends State<_SlideServiceCapsule>
    with SingleTickerProviderStateMixin {
  static const double _handleSize = 60;
  static const double _inset = 10;
  static const double _threshold = 0.85;

  late final AnimationController _controller;

  bool _dragging = false;
  bool _busy = false;
  bool _returning = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void didUpdateWidget(
    covariant _SlideServiceCapsule oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (!widget.enabled && !_busy) {
      _dragging = false;

      _controller.animateTo(
        0,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reset() {
    if (!mounted || _busy) return;

    setState(() => _dragging = false);

    _controller.animateTo(
      0,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    if (!mounted || _busy || !widget.enabled) return;

    setState(() {
      _busy = true;
      _dragging = false;
    });

    try {
      await _controller
          .animateTo(
            1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
          )
          .orCancel;

      if (!mounted) return;

      await widget.onCompleted();
    } on TickerCanceled {
      // خروج ویجت از صفحه هنگام انیمیشن.
    } catch (error, stackTrace) {
      debugPrint('خطا در باز کردن خدمت: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        // آیکن اصلی برمی‌گردد و دستگیره نرم به جای اول می‌لغزد
        setState(() => _returning = true);

        try {
          await _controller
              .animateTo(
                0,
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeInOutCubic,
              )
              .orCancel;
        } on TickerCanceled {
          // خروج ویجت از صفحه
        }

        if (mounted) {
          setState(() {
            _busy = false;
            _returning = false;
          });
        }
      }
    }
  }

  Widget _buildHandleIcon() {
    final iconColor = _kColoredHomeIcons
        ? AppColors.primaryBrand
        : Colors.white;

    final showCheck = _busy && !_returning;

    final fallback = Icon(
      showCheck ? Icons.check_rounded : widget.service.icon,
      color: iconColor,
      size: 31,
      shadows: _kColoredHomeIcons
          ? null
          : const [
              Shadow(
                color: Color(0x33002E23),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
    );

    if (showCheck) return fallback;

    return Image.asset(
      widget.service.iconAsset,
      width: 37,
      height: 37,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      color: _kColoredHomeIcons ? null : Colors.white,
      colorBlendMode:
          _kColoredHomeIcons ? null : BlendMode.srcIn,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);

    final textScale = MediaQuery.textScalerOf(context)
        .scale(1)
        .clamp(1.0, 1.8)
        .toDouble();

    final cardHeight = 102 + (textScale - 1) * 38;
    final handleTop = (cardHeight - _handleSize) / 2;

    return Semantics(
      button: true,
      enabled: widget.enabled && !_busy,
      label: '${widget.openLabel}: ${widget.service.title}',
      hint: widget.hint,
      onTap: widget.enabled && !_busy
          ? () {
              _complete();
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: palette.shadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: palette.border,
                width: 1.1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final travel =
                    (constraints.maxWidth -
                            _inset * 2 -
                            _handleSize)
                        .clamp(1.0, double.infinity)
                        .toDouble();

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final progress = _controller.value;
                    final handleLeft =
                        _inset + travel * progress;

                    final textOpacity = (1 - progress * 1.7)
                        .clamp(0.0, 1.0)
                        .toDouble();

                    return SizedBox(
                      height: cardHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FractionallySizedBox(
                                  widthFactor: 0.55,
                                  heightFactor: 1,
                                  child: ShaderMask(
                                    shaderCallback: (bounds) {
                                      return const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.transparent,
                                          Colors.white,
                                        ],
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode.dstIn,
                                    child: Opacity(
                                      opacity: palette.isDark
                                          ? 0.17
                                          : 0.24,
                                      child: Image.asset(
                                        widget.service.image,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) {
                                          return const SizedBox
                                              .shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            top: 1,
                            left: 25,
                            right: 25,
                            child: Container(
                              height: 1,
                              color: Colors.white.withOpacity(
                                palette.isDark ? 0.12 : 0.70,
                              ),
                            ),
                          ),

                          // پیشرفت فقط هنگام کشیدن نمایان است.
                          Positioned(
                            left: _inset + _handleSize / 2,
                            top: cardHeight - 29,
                            width: travel * progress,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: palette.brandText
                                    .withOpacity(0.50),
                                borderRadius:
                                    BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          Positioned(
                            left: 80,
                            right: 35,
                            top: 12,
                            bottom: 32,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: textOpacity,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.service.title,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: palette.text,
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.service.subtitle,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: palette.secondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            right: 12,
                            top: (cardHeight - 29) / 2 - 6,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 1 - progress,
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  textDirection: TextDirection.ltr,
                                  color: palette.brandText,
                                  size: 29,
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            left: 80,
                            right: 24,
                            bottom: 8,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: textOpacity,
                                child: Text(
                                  widget.hint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: palette.secondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            left: handleLeft,
                            top: handleTop,
                            child: ExcludeSemantics(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onHorizontalDragStart:
                                    widget.enabled && !_busy
                                        ? (_) {
                                            _controller.stop();

                                            setState(() {
                                              _dragging = true;
                                            });
                                          }
                                        : null,
                                onHorizontalDragUpdate:
                                    widget.enabled && !_busy
                                        ? (details) {
                                            if (_busy ||
                                                !widget.enabled) {
                                              return;
                                            }

                                            final next =
                                                _controller.value +
                                                    details.delta.dx /
                                                        travel;

                                            _controller.value = next
                                                .clamp(0.0, 1.0)
                                                .toDouble();

                                            if (_controller.value >=
                                                _threshold) {
                                              _complete();
                                            }
                                          }
                                        : null,
                                onHorizontalDragEnd:
                                    widget.enabled && !_busy
                                        ? (_) {
                                            if (_controller.value >=
                                                _threshold) {
                                              _complete();
                                            } else {
                                              _reset();
                                            }
                                          }
                                        : null,
                                onHorizontalDragCancel: _reset,
                                child: _JellyBadge(
                                  size: _handleSize,
                                  isDark: palette.isDark,
                                  pressed: _dragging,
                                  coloredIcon: _kColoredHomeIcons,
                                  child: _buildHandleIcon(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

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

    final palette = _HomePalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < advertisements.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: palette.shadows,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: advertisements[i],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
