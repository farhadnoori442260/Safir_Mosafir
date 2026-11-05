import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
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
  static const Color brand = Color(0xFF1B7A57);
  static const Color brandDark = Color(0xFF0E5F44);
  static const Color pageBg = Color(0xFFF6F8F7);
  static const Color darkText = Color(0xFF17202A);
  static const Color softText = Color(0xFF718096);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // متن‌های پیش‌فرض برای کلیدهایی که هنوز در فایل ترجمه نیستند
  static const Map<String, Map<String, String>> _fallbacks = {
    'home_where_to': {
      'fa': 'کجا می‌روید؟',
      'en': 'Where to?',
      'ps': 'چیرته ځې؟',
    },
    'home_hello': {'fa': 'سلام', 'en': 'Hello', 'ps': 'سلام'},
    'home_services': {'fa': 'خدمات', 'en': 'Services', 'ps': 'خدمات'},
    'home_become_driver': {
      'fa': 'راننده سفیر شوید',
      'en': 'Become a Safir driver',
      'ps': 'د سفیر ډرایور شئ',
    },
    'service_car': {'fa': 'سفیر', 'en': 'Safir', 'ps': 'سفیر'},
    'taxi_subtitle': {
      'fa': 'تاکسی آنلاین شهری',
      'en': 'City taxi',
      'ps': 'ښاري ټکسي',
    },
    'service_cargo': {'fa': 'باربری', 'en': 'Cargo', 'ps': 'بار وړنه'},
    'service_auto': {'fa': 'بین شهری', 'en': 'Intercity', 'ps': 'بین ښاري'},
    'register_subtitle': {
      'fa': 'ثبت خودرو و راننده',
      'en': 'Register your vehicle',
      'ps': 'موټر او ډرایور ثبت کړئ',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
    _checkUserStatusInBackground();
  }

  /// ترجمه با پشتیبان: اگر کلید ترجمه نداشت، متن پیش‌فرض همان زبان نمایش داده می‌شود
  String _tr(String key) {
    final String v = key.tr();
    if (v.trim().isNotEmpty && v != key) return v;

    final Map<String, String>? t = _fallbacks[key];
    if (t == null) return key;

    final String lang = context.locale.languageCode;
    return t[lang] ?? t['fa'] ?? key;
  }

  Future<void> _checkUserStatusInBackground() async {
    try {
      final authProvider =
          Provider.of<AuthenticationProvider>(context, listen: false);

      bool isBlocked = await authProvider.checkIfUserIsBlocked().timeout(
            const Duration(seconds: 3),
            onTimeout: () => false,
          );

      if (isBlocked && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BlockedScreen()),
        );
        return;
      }

      bool isFilled = await authProvider.checkUserFieldsFilled().timeout(
            const Duration(seconds: 3),
            onTimeout: () => true,
          );

      if (!isFilled && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
      }
    } catch (e) {
      debugPrint("خطا در بررسی پس‌زمینه کاربر: $e");
    }
  }

  Future<void> _loadCurrentUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DatabaseReference usersRef =
            FirebaseDatabase.instance.ref().child("users").child(user.uid);

        DatabaseEvent event = await usersRef.once();

        if (event.snapshot.value != null && mounted) {
          final userData = event.snapshot.value as Map;
          setState(() {
            userName = userData["name"] ?? userName;
            userPhone = userData["phone"] ?? userPhone;
          });
        }
      } catch (e) {
        debugPrint("خطا در دریافت اطلاعات از فایربیس: $e");
      }
    }
  }

  void _navigateToService(String serviceId) async {
    if (serviceId == 'register') {
      final Uri appUri = Uri.parse("safirdriver://open");
      final Uri storeUri = Uri.parse("https://safirapp.com/download-driver");

      try {
        bool isInstalled = await canLaunchUrl(appUri);

        if (isInstalled) {
          await launchUrl(
            appUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } else {
          await launchUrl(
            storeUri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        debugPrint("خطا در باز کردن اپ راننده: $e");
        await launchUrl(
          storeUri,
          mode: LaunchMode.externalApplication,
        );
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
        builder: (context) => SafirMapScreen(serviceType: type),
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

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    Widget buildDrawer() {
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: pageBg,
      drawer: isRTL ? buildDrawer() : null,
      endDrawer: !isRTL ? buildDrawer() : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isRTL),
            const SizedBox(height: 22),
            _buildServicesSection(),
            const SizedBox(height: 18),
            _buildDriverCard(isRTL),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom + 24,
            ),
          ],
        ),
      ),
    );
  }

  // 🔝 هدر سبز: لوگو، منو، خوش‌آمد و جعبه‌ی «کجا می‌روید؟»
  Widget _buildHeader(bool isRTL) {
    final String name = userName.toString().trim();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [brand, brandDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Safir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'menu',
                    child: Material(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openMenu(isRTL),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                name.isEmpty ? _tr('home_hello') : '${_tr('home_hello')} $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _buildSearchBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Semantics(
      button: true,
      label: _tr('home_where_to'),
      child: Material(
        color: Colors.white,
        elevation: 6,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _navigateToService('car'),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: brand, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _tr('home_where_to'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF6F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_taxi_rounded,
                    color: brand,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🧩 ردیف خدمات
  Widget _buildServicesSection() {
    final List<_ServiceItem> items = [
      _ServiceItem(
        id: 'car',
        title: _tr('service_car'),
        image: 'assets/images/taxi_banner.png',
        icon: Icons.local_taxi_rounded,
      ),
      _ServiceItem(
        id: 'cargo',
        title: _tr('service_cargo'),
        image: 'assets/images/cargo_banner.png',
        icon: Icons.local_shipping_rounded,
      ),
      _ServiceItem(
        id: 'intercity',
        title: _tr('service_auto'),
        image: 'assets/images/intercity_banner.png',
        icon: Icons.add_road_rounded,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('home_services'),
            style: const TextStyle(
              color: darkText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: _buildServiceTile(items[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(_ServiceItem item) {
    return Semantics(
      button: true,
      label: item.title,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToService(item.id),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE6EBE8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF6F1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    item.image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(item.icon, color: brand, size: 28),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🚖 کارت «راننده سفیر شوید»
  Widget _buildDriverCard(bool isRTL) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Semantics(
        button: true,
        label: _tr('home_become_driver'),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _navigateToService('register'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE6EBE8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF6F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_ind_rounded,
                      color: brand,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('home_become_driver'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _tr('register_subtitle'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: softText,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isRTL
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: softText,
                    size: 26,
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

class _ServiceItem {
  const _ServiceItem({
    required this.id,
    required this.title,
    required this.image,
    required this.icon,
  });

  final String id;
  final String title;
  final String image;
  final IconData icon;
}
