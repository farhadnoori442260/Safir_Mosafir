import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../appInfo/auth_provider.dart';
import '../globle/global_var.dart';
import '../pages/about_page.dart';
import '../pages/profile_page.dart';
import '../widgets/sign_out_dialog.dart';
import '../theme/app_colors.dart'; // آدرس فایل رنگ‌ها
import 'package:safir_passengers/services/support_service.dart';
import 'package:safir_passengers/theme/theme_controller.dart';

/// منوی کناری: میان‌بُرهای عمومی اپ.
/// موارد مربوط به حساب (سفرها، آدرس‌ها، پیام‌ها، تنظیمات، کد تخفیف، دعوت)
/// فقط در صفحهٔ پروفایل هستند و اینجا تکرار نمی‌شوند.
class CustomDrawer extends StatelessWidget {
  final String userName;
  final AuthenticationProvider authProvider;

  const CustomDrawer({
    super.key,
    required this.userName,
    required this.authProvider,
  });

  String _tr(String key, String fallback) {
    final String v = getTranslation(key) ?? '';
    return v.trim().isEmpty || v == key ? fallback : v;
  }

  /// زیرعنوان زیر نام: شماره (ورود با تلفن) یا ایمیل
  String _contactLine() {
    final String phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    if (phone.trim().isNotEmpty) return phone.trim();
    return userEmail.toString().trim();
  }

  Future<void> _rateApp(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);

    String url = '';
    try {
      final DocumentSnapshot<Map<String, dynamic>> snap = await FirebaseFirestore
          .instance
          .collection('settings')
          .doc('app_config')
          .get()
          .timeout(const Duration(seconds: 6));
      url = snap.data()?['store_url']?.toString().trim() ?? '';
    } catch (e) {
      debugPrint('Store url read error: $e');
    }

    bool opened = false;
    if (url.isNotEmpty) {
      try {
        opened = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Open store error: $e');
      }
    }

    if (!opened) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _tr('store_link_unavailable', 'لینک اپ هنوز در دسترس نیست'),
            style: TextStyle(color: AppColors.buttonText),
          ),
        ),
      );
    }
  }

  void _openProfile(BuildContext context) {
    final NavigatorState nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute(builder: (_) => const ProfilePage()));
  }

  void _openAbout(BuildContext context) {
    final NavigatorState nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute(builder: (_) => const AboutPage()));
  }

  void _signOut(BuildContext context) {
    final NavigatorState nav = Navigator.of(context);
    nav.pop();
    showDialog<void>(
      context: nav.context,
      builder: (BuildContext dialogContext) {
        return SignOutDialog(
          title: _tr('sign_out_title', 'خروج'),
          description: _tr(
            'sign_out_confirm',
            'آیا مطمئن هستید که می‌خواهید از حساب خود خارج شوید؟',
          ),
          onSignOut: () async {
            await authProvider.signOut(nav.context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = userName.trim().isNotEmpty
        ? userName.trim()
        : _tr('safir_passenger', 'مسافر سفیر');
    final String contact = _contactLine();

    return Drawer(
      backgroundColor: AppColors.backgroundLight,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            // ۱. سربرگ: لمس = رفتن به پروفایل
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Material(
                color: AppColors.cardBgLight,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _openProfile(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.fieldBorder,
                              width: 2,
                            ),
                          ),
                          child: SizedBox(
                            width: 54,
                            height: 54,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/default_profile.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  size: 30,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (contact.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  contact,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.handle,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ۲. گزینه‌های عمومی
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                children: [
                  _sectionTitle(_tr('drawer_general', 'عمومی')),
                  _card([
                    _DrawerTile(
                      icon: Icons.support_agent_rounded,
                      title: _tr('help_support', 'مرکز کمک و پشتیبانی'),
                      subtitle: _tr('help_support_sub', 'تماس مستقیم با پشتیبانی'),
                      onTap: () {
                        Navigator.pop(context);
                        SupportService.call(context);
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.info_outline_rounded,
                      title: _tr('about_safir', 'درباره سفیر'),
                      onTap: () => _openAbout(context),
                    ),
                    _DrawerTile(
                      icon: Icons.star_outline_rounded,
                      title: _tr('rate_app', 'امتیاز به اپلیکیشن'),
                      onTap: () => _rateApp(context),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  _sectionTitle(_tr('appearance_header', 'ظاهر برنامه')),
                  _card([const _ThemeQuickSwitch()]),
                ],
              ),
            ),

            // ۳. خروج
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Material(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _signOut(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded,
                            color: AppColors.danger, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _tr('sign_out', 'خروج از حساب کاربری'),
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: 56,
          endIndent: 0,
          color: AppColors.fieldBorder,
        ));
      }
      rows.add(children[i]);
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(children: rows),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary.withOpacity(0.78), size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.handle, size: 22),
          ],
        ),
      ),
    );
  }
}

/// تغییر سریع تم (خودکار / روشن / تاریک) بدون رفتن به تنظیمات
class _ThemeQuickSwitch extends StatelessWidget {
  const _ThemeQuickSwitch();

  String _tr(String key, String fallback) {
    final String v = key.tr();
    return v.trim().isEmpty || v == key ? fallback : v;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final ThemeMode mode = ThemeController.instance.mode;

        final List<(ThemeMode, IconData, String)> items = [
          (ThemeMode.system, Icons.brightness_auto_rounded, _tr('theme_system', 'خودکار')),
          (ThemeMode.light, Icons.light_mode_rounded, _tr('theme_light', 'روشن')),
          (ThemeMode.dark, Icons.dark_mode_rounded, _tr('theme_dark', 'تاریک')),
        ];

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              for (final (ThemeMode m, IconData ic, String label) in items)
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await ThemeController.instance.setMode(m);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.all(3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: mode == m
                            ? AppColors.backgroundLight
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: mode == m
                              ? AppColors.primaryBrand
                              : Colors.transparent,
                          width: 1.4,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ic,
                            size: 22,
                            color: mode == m
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: mode == m
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: mode == m
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
