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

import 'map_screen.dart';

class SafirHomeScreen extends StatefulWidget {
  const SafirHomeScreen({super.key});

  @override
  State<SafirHomeScreen> createState() => _SafirHomeScreenState();
}

class _SafirHomeScreenState extends State<SafirHomeScreen> {
  static const String heroImage =
      'assets/images/home_hero.jpg';

  static const String driverCardImage =
      'assets/images/register_banner.png';

  static const Color _green = Color(0xFF07835D);
  static const Color _dark = Color(0xFF043C35);

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  bool _openingService = false;

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
    final String value = key.tr();

    if (value.trim().isNotEmpty && value != key) {
      return value;
    }

    final translations = _fallbacks[key];
    final language = context.locale.languageCode;

    return translations?[language] ??
        translations?['fa'] ??
        key;
  }

  List<_HomeService> _services() {
    return [
      _HomeService(
        id: 'car',
        title: _tr('home_city_taxi'),
        subtitle: _tr('taxi_subtitle'),
        bannerImage: 'assets/images/taxi_banner.png',
        icon: Icons.directions_car_rounded,
      ),
      _HomeService(
        id: 'cargo',
        title: _tr('service_cargo'),
        subtitle: _tr('cargo_subtitle'),
        bannerImage: 'assets/images/cargo_banner.png',
        icon: Icons.local_shipping_rounded,
      ),
      _HomeService(
        id: 'intercity',
        title: _tr('service_auto'),
        subtitle: _tr('intercity_subtitle'),
        bannerImage: 'assets/images/intercity_banner.png',
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
    if (_openingService || !mounted) return;

    setState(() => _openingService = true);

    try {
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
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final services = _services();
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _dark,

      // در هوم، محل منو همیشه سمت چپ است.
      endDrawer: Directionality(
        textDirection: Directionality.of(context),
        child: const SafirDrawer(),
      ),
      endDrawerEnableOpenDragGesture: false,

      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double heroHeight =
                (constraints.maxHeight * 0.43)
                    .clamp(245.0, 355.0)
                    .toDouble();

            final double headerSpace = topInset + 106;
            final double pictureSpace =
                (heroHeight - headerSpace)
                    .clamp(65.0, 240.0)
                    .toDouble();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF075667),
                              Color(0xFF07524E),
                              Color(0xFF04392F),
                              Color(0xFF022D24),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: heroHeight + 55,
                      child: _buildHeroBackground(),
                    ),

                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: topInset + 135,
                      child: const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x66002430),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: topInset + 10),
                        _buildHeader(),
                        const SizedBox(height: 9),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          child: Text(
                            _tr('home_slogan'),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: pictureSpace),

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
                                if (i > 0)
                                  const SizedBox(height: 12),

                                _SlideServiceCapsule(
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
                              ],

                              const SizedBox(height: 14),
                              _buildTrustBadge(),
                              const SizedBox(height: 14),
                              _buildDriverCard(),
                            ],
                          ),
                        ),

                        const HomeAdvertisementsSection(),
                        SizedBox(height: bottomInset + 22),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroBackground() {
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
      child: Image.asset(
        heroImage,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF075466),
                  Color(0xFF116F67),
                ],
              ),
            ),
            alignment: const Alignment(0, 0.55),
            child: Image.asset(
              'assets/images/taxi_banner.png',
              width: 250,
              height: 145,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.directions_car_rounded,
                  color: Colors.white24,
                  size: 110,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Material(
              color: Colors.white.withOpacity(0.13),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context)
                    .openAppDrawerTooltip,
                onPressed: _openMenu,
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ),
            const Text(
              'Safir',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: Colors.white,
                fontSize: 35,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.4,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF00533D).withOpacity(0.90),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.09),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF40D98C),
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _tr('home_trust'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard() {
    final bool isRTL =
        Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: Colors.white.withOpacity(0.09),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openingService
            ? null
            : () => _navigateToService('register'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Image.asset(
                  driverCardImage,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.assignment_ind_rounded,
                      color: Color(0xFF70E5B2),
                      size: 26,
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
                      _tr('home_become_driver'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _tr('register_subtitle'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
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
    );
  }
}

class _HomeService {
  const _HomeService({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.bannerImage,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final String bannerImage;
  final IconData icon;
}

/// آیکن از چپ به راست حرکت می‌کند.
/// ورود فقط پس از کشیدن تا حد تعیین‌شده انجام می‌شود.
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
  static const double _handleSize = 58;
  static const double _inset = 11;
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
    if (_busy || !widget.enabled || !mounted) return;

    setState(() {
      _busy = true;
      _dragging = false;
    });

    try {
      await _controller.animateTo(
        1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
      ).orCancel;

      if (!mounted) return;

      HapticFeedback.lightImpact();
      await widget.onCompleted();
    } on TickerCanceled {
      // ویجت هنگام انیمیشن از صفحه خارج شده است.
    } catch (error, stackTrace) {
      debugPrint('خطا در باز کردن خدمت: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _controller.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled && !_busy,
      label:
          '${widget.openLabel}: ${widget.service.title}',
      hint: widget.hint,

      // راه جایگزین برای ابزارهای دسترس‌پذیری.
      onTap: widget.enabled && !_busy
          ? () {
              _complete();
            }
          : null,

      child: Material(
        color: const Color(0xFFF6FAFC),
        borderRadius: BorderRadius.circular(29),
        elevation: 5,
        shadowColor: Colors.black26,
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double travel =
                (constraints.maxWidth -
                        (_inset * 2) -
                        _handleSize)
                    .clamp(1.0, double.infinity)
                    .toDouble();

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double progress = _controller.value;
                final double handleLeft =
                    _inset + (travel * progress);

                return SizedBox(
                  height: 104,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: 0.54,
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
                                opacity: 0.22,
                                child: Image.asset(
                                  widget.service.bannerImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // خط ظریف مسیر.
                      Positioned(
                        left: _inset + (_handleSize / 2),
                        right: _inset + (_handleSize / 2),
                        top: 81,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8E8E2),
                            borderRadius:
                                BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // خط پیشرفت.
                      Positioned(
                        left: _inset + (_handleSize / 2),
                        top: 81,
                        width: travel * progress,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A9D70),
                            borderRadius:
                                BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 81,
                        right: 35,
                        top: 12,
                        bottom: 32,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: (1 - progress * 1.6)
                                .clamp(0.0, 1.0)
                                .toDouble(),
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
                                  style: const TextStyle(
                                    color: Color(0xFF1B2B34),
                                    fontSize: 19,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.service.subtitle,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF50616B),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        right: 13,
                        top: 27,
                        child: Opacity(
                          opacity: 1 - progress,
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            textDirection: TextDirection.ltr,
                            color: Color(0xFF07835D),
                            size: 29,
                          ),
                        ),
                      ),

                      Positioned(
                        left: 75,
                        right: 22,
                        bottom: 5,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: (1 - progress * 2)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                            child: Text(
                              widget.hint,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF678278),
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: handleLeft,
                        top: 12,
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
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 150),
                              width: _handleSize,
                              height: _handleSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF12B982),
                                    Color(0xFF007450),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007450)
                                        .withOpacity(
                                      _dragging ? 0.38 : 0.20,
                                    ),
                                    blurRadius:
                                        _dragging ? 15 : 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color:
                                      Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: Icon(
                                _busy
                                    ? Icons.check_rounded
                                    : widget.service.icon,
                                size: 29,
                                color: Colors.white,
                              ),
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
    );
  }
}

/// وقتی تبلیغی ندارد، چیزی نمایش داده نمی‌شود.
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
