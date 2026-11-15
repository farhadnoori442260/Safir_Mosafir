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
import 'package:safir_passengers/pages/blocked_screen.dart';
import 'package:safir_passengers/authentication/register_screen.dart';
import 'package:safir_passengers/theme/app_colors.dart';

import 'map_screen.dart';

class SafirHomeScreen extends StatefulWidget {
  const SafirHomeScreen({super.key});

  @override
  State<SafirHomeScreen> createState() => _SafirHomeScreenState();
}

class _SafirHomeScreenState extends State<SafirHomeScreen> {
  static const String heroImage = 'assets/images/home_hero.jpg';

  static const String driverCardImage =
      'assets/images/register_banner.png';

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  bool _openingService = false;

  /// ارتفاع دکمه‌ها و نوار جستجوی بالای صفحه
  static const double _barHeight = 46;

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

  /// ✅ فاصلهٔ امن بالا/پایین. اگر ویجت‌های بالاتر padding را مصرف کرده باشند
  /// (علت افتادن هدر روی نوار وضعیت)، از خود پنجرهٔ سیستم خوانده می‌شود.
  double _safeTop(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final MediaQueryData window = MediaQueryData.fromView(View.of(context));
    return max(
      media.padding.top,
      max(media.viewPadding.top, window.padding.top),
    );
  }

  double _safeBottom(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final MediaQueryData window = MediaQueryData.fromView(View.of(context));
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
      ),
      _HomeService(
        id: 'cargo',
        title: _tr('service_cargo'),
        subtitle: _tr('cargo_subtitle'),
        image: 'assets/images/cargo_banner.png',
        icon: Icons.local_shipping_rounded,
      ),
      _HomeService(
        id: 'intercity',
        title: _tr('service_auto'),
        subtitle: _tr('intercity_subtitle'),
        image: 'assets/images/intercity_banner.png',
        icon: Icons.route_rounded,
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
    if (!mounted || _openingService) return;

    setState(() => _openingService = true);

    try {
      if (serviceId == 'register') {
        final appUri = Uri.parse('safirdriver://open');
        final storeUri =
            Uri.parse('https://safirapp.com/download-driver');

        try {
          if (await canLaunchUrl(appUri)) {
            final opened = await launchUrl(
              appUri,
              mode: LaunchMode.externalNonBrowserApplication,
            );

            if (opened) return;
          }

          await launchUrl(
            storeUri,
            mode: LaunchMode.externalApplication,
          );
        } catch (error) {
          debugPrint('خطا در باز کردن اپ راننده: $error');

          try {
            await launchUrl(
              storeUri,
              mode: LaunchMode.externalApplication,
            );
          } catch (fallbackError) {
            debugPrint('خطا در لینک راننده: $fallbackError');
          }
        }

        return;
      }

      if (!mounted) return;

      final type = serviceId == 'intercity'
          ? 'intercity'
          : serviceId == 'cargo'
              ? 'cargo'
              : 'taxi';

      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => SafirMapScreen(serviceType: type),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingService = false);
      }
    }
  }

  void _openMenu() {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // منو همیشه از سمت چپ باز می‌شود.
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
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    final double topInset = _safeTop(context);
    final double bottomInset = _safeBottom(context);

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
            final double heroHeight = (constraints.maxHeight * 0.55)
                .clamp(260.0, 460.0)
                .toDouble();

            // فاصلهٔ آزاد بین اسلوگان و کپسول‌ها (فضای عکس). ارتفاع بخش‌های
            // ثابت از روی اندازه‌ها حساب می‌شود؛ ۲۴ پیکسل حاشیهٔ اطمینان
            // می‌ماند تا خطای تخمین باعث اسکرول نشود.
            final double textScale = MediaQuery.textScalerOf(context)
                .scale(1)
                .clamp(1.0, 1.8)
                .toDouble();
            final double capsuleHeight = 102 + (textScale - 1) * 38;
            final double fixedHeight = topInset +
                8 +
                _barHeight +
                services.length * (capsuleHeight + 12) +
                2 +
                (64 + (textScale - 1) * 28) +
                bottomInset +
                14;
            final double spacerHeight =
                max(0.0, constraints.maxHeight - fixedHeight - 24);

            return Stack(
              children: [
                Positioned.fill(
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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: heroHeight,
                  child: _buildHeroBackground(palette),
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

                // ✅ صفحهٔ ثابت: اگر محتوا جا شود هیچ اسکرولی ندارد (Clamping یعنی
                // بدون کش‌آمدن). فقط در گوشی‌های خیلی کوتاه اسکرول می‌شود تا
                // چیزی بریده نشود.
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: topInset + 8),
                          _buildTopBar(),
                          // فضای عکس: هر چه جا بماند همین‌جا می‌رود
                          SizedBox(height: spacerHeight),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                for (final service in services) ...[
                                  _SlideServiceCapsule(
                                    key: ValueKey(service.id),
                                    service: service,
                                    enabled: !_openingService,
                                    hint: _tr('home_slide_hint'),
                                    openLabel: _tr('home_open_service'),
                                    onCompleted: () =>
                                        _navigateToService(service.id),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                const HomeAdvertisementsSection(),
                                const SizedBox(height: 2),
                                _buildDriverCard(palette),
                              ],
                            ),
                          ),
                          SizedBox(height: bottomInset + 14),
                        ],
                      ),
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

              // عمداً هیچ موتر جداگانه‌ای اضافه نمی‌شود.
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

  /// شیشهٔ مات واقعی (blur + رنگ نیمه‌شفاف)
  Widget _glass({
    required Widget child,
    required double radius,
    double? width,
    double height = _barHeight,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.30)),
          ),
          child: child,
        ),
      ),
    );
  }

  /// ردیف بالا: [منو]  [کجا می‌روید؟]  [SAFIR]
  Widget _buildTopBar() {
    final TextDirection appDirection = Directionality.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            _buildMenuButton(),
            const SizedBox(width: 10),
            Expanded(child: _buildSearchBar(appDirection)),
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
      label: MaterialLocalizations.of(context).openAppDrawerTooltip,
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

  /// نوار «کجا می‌روید؟»؛ لمس آن مستقیم به تاکسی شهری می‌رود
  Widget _buildSearchBar(TextDirection appDirection) {
    return Semantics(
      button: true,
      label: _tr('home_where_to'),
      child: _glass(
        radius: _barHeight / 2,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openingService ? null : () => _navigateToService('car'),
            child: Directionality(
              textDirection: appDirection,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                          color: Colors.white.withOpacity(0.92),
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

  /// برند: فقط نوشتهٔ جمع‌وجور روی شیشه (بدون آیکن)
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
                Shadow(color: Colors.black38, blurRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// کارت ثبت‌نام راننده: عمداً «ثانویه» (شیشه‌ای و کم‌ارتفاع) تا با سه سرویس
  /// اصلی رقابت نکند.
  Widget _buildDriverCard(_HomePalette palette) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.10),
          child: InkWell(
            onTap: _openingService
                ? null
                : () => _navigateToService('register'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      driverCardImage,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.assignment_ind_rounded,
                          color: Colors.white,
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _tr('register_subtitle'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isRTL
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// رنگ برند از AppColors و رنگ سطوح از تم فعال گرفته می‌شود.
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
      secondary: scheme.onSurface.withOpacity(0.65),
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
          color: Colors.black.withOpacity(isDark ? 0.36 : 0.20),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.12 : 0.05),
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
  });

  final String id;
  final String title;
  final String subtitle;
  final String image;
  final IconData icon;
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

class _SlideServiceCapsuleState extends State<_SlideServiceCapsule>
    with SingleTickerProviderStateMixin {
  static const double _handleSize = 60;
  static const double _inset = 10;
  static const double _threshold = 0.85;

  late final AnimationController _controller;

  bool _dragging = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void didUpdateWidget(covariant _SlideServiceCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.enabled && !_busy) {
      _dragging = false;
      _controller.reverse();
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
      // ویجت هنگام اجرای انیمیشن از درخت خارج شده است.
    } catch (error, stackTrace) {
      debugPrint('خطا در باز کردن خدمت: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() => _busy = false);

        _controller.animateTo(
          0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _HomePalette.of(context);

    final textScale =
        MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8);

    final double cardHeight = 102 + ((textScale - 1) * 38);
    final double handleTop = (cardHeight - _handleSize) / 2;
    final double lineTop = cardHeight - 24;

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
                    (constraints.maxWidth - _inset * 2 - _handleSize)
                        .clamp(1.0, double.infinity)
                        .toDouble();

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final progress = _controller.value;
                    final handleLeft = _inset + travel * progress;
                    final textOpacity =
                        (1 - progress * 1.7).clamp(0.0, 1.0).toDouble();

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
                                      opacity:
                                          palette.isDark ? 0.10 : 0.17,
                                      child: Image.asset(
                                        widget.service.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // لمعان ظریف روی سطح کپسول.
                          Positioned(
                            top: 1,
                            left: 22,
                            right: 22,
                            child: Container(
                              height: 1,
                              color: Colors.white.withOpacity(
                                palette.isDark ? 0.14 : 0.85,
                              ),
                            ),
                          ),

                          Positioned(
                            left: _inset + _handleSize / 2,
                            right: _inset + _handleSize / 2,
                            top: lineTop,
                            child: Container(
                              height: 1.5,
                              color: palette.brandText.withOpacity(0.13),
                            ),
                          ),
                          Positioned(
                            left: _inset + _handleSize / 2,
                            top: lineTop,
                            width: travel * progress,
                            child: Container(
                              height: 1.5,
                              color: palette.brandText.withOpacity(0.6),
                            ),
                          ),

                          Positioned(
                            left: 80,
                            right: 35,
                            top: 14,
                            bottom: 31,
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
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: palette.text,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.service.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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

                          Positioned(
                            left: 80,
                            right: 24,
                            bottom: 6,
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
                                    fontSize: 9,
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
                                            setState(
                                              () => _dragging = true,
                                            );
                                          }
                                        : null,
                                onHorizontalDragUpdate:
                                    widget.enabled && !_busy
                                        ? (details) {
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
                                child: _buildJellyHandle(palette),
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

  Widget _buildJellyHandle(_HomePalette palette) {
    final brand = AppColors.primaryBrand;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: _handleSize,
      height: _handleSize,
      transformAlignment: Alignment.center,
      transform: Matrix4.diagonal3Values(
        _dragging ? 1.055 : 1,
        _dragging ? 0.95 : 1,
        1,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_dragging ? 25 : 30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(brand, Colors.white, 0.65)!,
            Color.lerp(brand, Colors.white, 0.24)!,
            brand,
          ],
          stops: const [0, 0.48, 1],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.78),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: brand.withOpacity(_dragging ? 0.38 : 0.25),
            blurRadius: _dragging ? 16 : 10,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(
              palette.isDark ? 0.08 : 0.65,
            ),
            blurRadius: 3,
            offset: const Offset(-1, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_dragging ? 25 : 30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 2,
              left: 4,
              right: 4,
              height: 31,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.55),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 13,
              right: 13,
              bottom: 3,
              height: 13,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white.withOpacity(0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                _busy ? Icons.check_rounded : widget.service.icon,
                color: Colors.white,
                size: 30,
                shadows: const [
                  Shadow(
                    color: Color(0x44004130),
                    blurRadius: 5,
                    offset: Offset(0, 2),
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
