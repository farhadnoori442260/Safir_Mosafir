import 'dart:async';
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

class _SafirHomeScreenState extends State<SafirHomeScreen> with SingleTickerProviderStateMixin {
  int _activeSelectedIndex = 0; 
  final Color safirBrandColor = const Color(0xFF1B7A57); 
  final Color activeBgColor = const Color(0xFFEAF6F1); 
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  Future<void> _checkUserStatusInBackground() async {
    try {
      final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);

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
        DatabaseReference usersRef = FirebaseDatabase.instance
            .ref()
            .child("users")
            .child(user.uid);

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

    void _navigateToService(String serviceId, String type) async {
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
    } else if (serviceId == 'intercity') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SafirMapScreen(serviceType: 'intercity'),
        ),
      );
    } else if (serviceId == 'cargo') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SafirMapScreen(serviceType: 'cargo'),
        ),
      );
    } else { 
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SafirMapScreen(serviceType: 'taxi'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

   final List<Map<String, dynamic>> services = [
      {
        'title': 'service_car'.tr().isEmpty ? 'سفیر' : 'service_car'.tr(),
        'subtitle': 'taxi_subtitle'.tr().isEmpty ? 'تاکسی آنلاین شهری' : 'taxi_subtitle'.tr(),
        'bannerImage': 'assets/images/taxi_banner.png',
        'bottomIcon': 'assets/images/taxi_car.png',
        'icon': Icons.local_taxi_rounded,
        'type': 'Car',
        'id': 'car'
      }, 
      {
        'title': 'service_cargo'.tr().isEmpty ? 'باربری' : 'service_cargo'.tr(),
        'subtitle': 'cargo_subtitle'.tr().isEmpty ? 'حمل و نقل سریع بار' : 'cargo_subtitle'.tr(),
        'bannerImage': 'assets/images/cargo_banner.png',
        'bottomIcon': 'assets/images/cargo_truck.png',
        'icon': Icons.local_shipping_rounded,
        'type': 'Bike',
        'id': 'cargo'
      },
      {
        'title': 'service_register'.tr().isEmpty ? 'ثبت سرویس' : 'service_register'.tr(),
        'subtitle': 'register_subtitle'.tr().isEmpty ? 'ثبت خودرو و راننده' : 'register_subtitle'.tr(),
        'bannerImage': 'assets/images/register_banner.png',
        'bottomIcon': 'assets/images/driver_card.png',
        'icon': Icons.assignment_rounded,
        'type': 'Register',
        'id': 'register'
      },
      {
        'title': 'service_auto'.tr().isEmpty ? 'بین شهری' : 'service_auto'.tr(),
        'subtitle': 'intercity_subtitle'.tr().isEmpty ? 'سفر ایمن بین شهرها' : 'intercity_subtitle'.tr(),
        'bannerImage': 'assets/images/intercity_banner.png',
        'bottomIcon': 'assets/images/intercity_car.png',
        'icon': Icons.add_road_rounded,
        'type': 'Auto',
        'id': 'intercity'
      },
    ];

    final activeService = services[_activeSelectedIndex];

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
      backgroundColor: const Color(0xFFF8F9FA), 
      drawer: isRTL ? buildDrawer() : null,
      endDrawer: !isRTL ? buildDrawer() : null,
      extendBody: true, 

      body: SafeArea(
        child: Column(
          children: [
            // 🔝 هدر بالایی
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Safir',
                    style: TextStyle(
                      color: safirBrandColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w600, // 👈 ضخیم‌تر شد
                      fontFamily: 'Serif',
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: null, 
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'home_select_service'.tr().isEmpty ? 'سرویس را انتخاب کنید' : 'home_select_service'.tr(),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.search_rounded, color: safirBrandColor, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.menu_rounded, color: safirBrandColor, size: 28),
                    onPressed: () {
                      if (isRTL) {
                        _scaffoldKey.currentState?.openDrawer();
                      } else {
                        _scaffoldKey.currentState?.openEndDrawer();
                      }
                    },
                  ),
                ],
              ),
            ),

            Divider(color: safirBrandColor.withOpacity(0.15), height: 1, thickness: 1),

            // 📜 لیست اصلی
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildHeroBanner(activeService, isRTL), 
                    const SizedBox(height: 16),
                    
                    Column(
                      children: List.generate(services.length, (index) {
                        return _buildServiceCard(services[index], index);
                      }),
                    ),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 🏁 نوار شناور پایینی
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: safirBrandColor.withOpacity(0.06),
              blurRadius: 15,
              spreadRadius: -2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double itemWidth = totalWidth / services.length;

              final double leftPosition = isRTL
                  ? totalWidth - ((_activeSelectedIndex + 1) * itemWidth)
                  : _activeSelectedIndex * itemWidth;

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    left: leftPosition,
                    top: 6,
                    width: itemWidth,
                    height: 56,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: activeBgColor,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),

                  Row(
                    children: List.generate(services.length, (index) {
                      bool isSelected = _activeSelectedIndex == index;
                      String serviceId = services[index]['id'];

                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _activeSelectedIndex = index;
                            });

                            _navigateToService(serviceId, services[index]['type']);
                          },
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 28,
                                height: 28,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: isSelected ? safirBrandColor : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  services[index]['bottomIcon'],
                                  fit: BoxFit.contain,
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      services[index]['icon'] as IconData,
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                      size: 18,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 3),
                              
                              Text(
                                services[index]['title'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? safirBrandColor : Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, // 👈 ضخیم‌تر شد
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // 🌟 بنر اصلی
  Widget _buildHeroBanner(Map<String, dynamic> activeService, bool isRTL) {
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
          )
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
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Image.asset(
                      activeService['bannerImage'],
                      key: ValueKey<String>(activeService['id']),
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
                    activeService['title'],
                    key: ValueKey<String>("title_${activeService['id']}"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600, // 👈 ضخیم‌تر شد
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    activeService['subtitle'],
                    key: ValueKey<String>("sub_${activeService['id']}"),
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
                  onPressed: () => _navigateToService(activeService['id'], activeService['type']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      Text(
                        'request_service'.tr().isEmpty ? 'درخواست سرویس' : 'request_service'.tr(),
                        style: TextStyle(
                          color: safirBrandColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600, // 👈 ضخیم‌تر شد
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

  // 💳 کارت‌های خدمات
  Widget _buildServiceCard(Map<String, dynamic> service, int index) {
    bool isSelected = _activeSelectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? safirBrandColor : Colors.grey.shade200,
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? safirBrandColor.withOpacity(0.12) : Colors.black.withOpacity(0.02),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _activeSelectedIndex = index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600, // 👈 ضخیم‌تر شد
                        color: isSelected ? safirBrandColor : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service['subtitle'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? safirBrandColor.withOpacity(0.1) : const Color(0xFFF4F6F8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? safirBrandColor : Colors.grey.shade300,
                      width: 1.2,
                    ),
                  ),
                  child: Image.asset(
                    service['bannerImage'],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      service['icon'] as IconData,
                      color: safirBrandColor,
                      size: 22,
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
}
