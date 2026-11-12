import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:safir_passengers/authentication/register_screen.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/services/support_service.dart';
import 'package:safir_passengers/theme/app_colors.dart';
import 'package:safir_passengers/theme/theme_controller.dart';
import 'package:safir_passengers/widgets/animated_menus.dart';

/// 📂 منوی کناری صفحهٔ اصلی.
///
/// فقط میان‌بُرهای عمومی اپ: تغییر سریع زبان و تم، پشتیبانی، دربارهٔ سفیر،
/// امتیاز به اپ و خروج. موارد مربوط به حساب (سفرها، آدرس‌ها، دعوت، پیام‌ها،
/// تنظیمات، کد تخفیف) فقط در صفحهٔ پروفایل هستند و اینجا تکرار نمی‌شوند.
class SafirDrawer extends StatelessWidget {
  const SafirDrawer({super.key});

  String _tr(String key, String fallback) {
    final String v = key.tr();
    return v.trim().isEmpty || v == key ? fallback : v;
  }

  String _displayName() {
    final String n = userName.trim();
    if (n.isNotEmpty) return n;
    final String? a = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (a != null && a.isNotEmpty) return a;
    return _tr('user_default', 'کاربر سفیر');
  }

  String _displayPhone() {
    final String p = userPhone.trim();
    if (p.isNotEmpty) return p;
    return FirebaseAuth.instance.currentUser?.phoneNumber?.trim() ?? '';
  }

  void _openProfile(BuildContext context) {
    final NavigatorState nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute(builder: (_) => const ProfileAnimatedMenu()));
  }

  void _showAbout(BuildContext context) {
    Navigator.pop(context);
    final BuildContext root = Navigator.of(context, rootNavigator: true).context;
    showModalBottomSheet<void>(
      context: root,
      backgroundColor: AppColors.cardBgLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.handle,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 22),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/images/legacy_192.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.local_taxi_rounded,
                    size: 44,
                    color: AppColors.primaryBrand,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _tr('app_name', 'سفیر'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _tr(
                  'about_app_content_short',
                  'سفیر یک اپلیکیشن حمل‌ونقل شهری است که ثبت و مدیریت سفر را برای مسافران و رانندگان ساده‌تر می‌کند.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.7,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _signOut(BuildContext context) async {
    final NavigatorState nav = Navigator.of(context, rootNavigator: true);
    Navigator.pop(context); // بستن منو

    final bool? confirm = await showDialog<bool>(
      context: nav.context,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: AppColors.cardBgLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: AppColors.fieldBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded,
                    color: AppColors.danger, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                _tr('sign_out_title', 'خروج از حساب'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _tr(
                  'sign_out_confirm',
                  'آیا مطمئن هستید که می‌خواهید از حساب کاربری خود خارج شوید؟',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.fieldBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _tr('cancel', 'انصراف'),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _tr('sign_out', 'خروج'),
                          style: TextStyle(
                            color: AppColors.buttonText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    // همان روال خروج صفحهٔ پروفایل: گوگل + فایربیس، سپس صفحهٔ ورود
    try {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (e) {
        debugPrint('Google sign out error: $e');
      }

      await FirebaseAuth.instance.signOut();

      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final String name = _displayName();
    final String phone = _displayPhone();

    return Drawer(
      width: width * 0.86 > 340 ? 340 : width * 0.86,
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
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.fieldBorder,
                              width: 1.2,
                            ),
                          ),
                          child: SizedBox(
                            width: 56,
                            height: 56,
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
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  phone,
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

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                children: [
                  // ۲. زبان و ظاهر (تغییر سریع)
                  _sectionTitle(_tr('quick_settings', 'تنظیمات سریع')),
                  _card([
                    const _LanguageQuickSwitch(),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.fieldBorder,
                    ),
                    const _ThemeQuickSwitch(),
                  ]),
                  const SizedBox(height: 18),

                  // ۳. عمومی
                  _sectionTitle(_tr('drawer_general', 'عمومی')),
                  _card([
                    _DrawerTile(
                      icon: Icons.support_agent_rounded,
                      color: AppColors.originBlue,
                      title: _tr('help_support', 'مرکز کمک و پشتیبانی'),
                      subtitle:
                          _tr('help_support_sub', 'تماس مستقیم با پشتیبانی'),
                      onTap: () {
                        Navigator.pop(context);
                        SupportService.call(context);
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.info_rounded,
                      color: AppColors.textSecondary,
                      title: _tr('about_safir', 'درباره سفیر'),
                      onTap: () => _showAbout(context),
                    ),
                    _DrawerTile(
                      icon: Icons.star_rounded,
                      color: AppColors.warning,
                      title: _tr('rate_app', 'امتیاز به اپلیکیشن'),
                      onTap: () => _rateApp(context),
                    ),
                  ]),
                ],
              ),
            ),

            // ۴. خروج
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
      if (i > 0 && children[i] is _DrawerTile) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: 56,
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
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.color,
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
            Icon(icon, color: color, size: 26),
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
            Icon(Icons.chevron_right_rounded,
                color: AppColors.handle, size: 22),
          ],
        ),
      ),
    );
  }
}

/// چیپ انتخاب (مشترک بین زبان و تم)
Widget _chip({
  required bool selected,
  required VoidCallback onTap,
  required Widget child,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.backgroundLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryBrand : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Center(child: child),
      ),
    ),
  );
}

/// تغییر سریع زبان (دری / پښتو / English)
class _LanguageQuickSwitch extends StatelessWidget {
  const _LanguageQuickSwitch();

  Future<void> _set(BuildContext context, String code) async {
    HapticFeedback.selectionClick();
    await context.setLocale(Locale(code));
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', code);
    } catch (e) {
      debugPrint('Save language error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String current = context.locale.languageCode;
    final List<(String, String)> langs = [
      ('fa', 'دری'),
      ('ps', 'پښتو'),
      ('en', 'English'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          for (final (String code, String label) in langs)
            _chip(
              selected: current == code,
              onTap: () => _set(context, code),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      current == code ? FontWeight.w800 : FontWeight.w500,
                  color: current == code
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// تغییر سریع تم (خودکار / روشن / تاریک)
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
          (ThemeMode.system, Icons.brightness_auto_rounded,
              _tr('theme_system', 'خودکار')),
          (ThemeMode.light, Icons.light_mode_rounded,
              _tr('theme_light', 'روشن')),
          (ThemeMode.dark, Icons.dark_mode_rounded,
              _tr('theme_dark', 'تاریک')),
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(
            children: [
              for (final (ThemeMode m, IconData ic, String label) in items)
                _chip(
                  selected: mode == m,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await ThemeController.instance.setMode(m);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ic,
                        size: 21,
                        color: mode == m
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              mode == m ? FontWeight.w800 : FontWeight.w500,
                          color: mode == m
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
