import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart'
    hide TextDirection;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:safir_passengers/authentication/register_screen.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/services/support_service.dart';
import 'package:safir_passengers/theme/app_colors.dart';
import 'package:safir_passengers/theme/theme_controller.dart';
import 'package:safir_passengers/widgets/animated_menus.dart';

class SafirDrawer extends StatefulWidget {
  const SafirDrawer({super.key});

  @override
  State<SafirDrawer> createState() => _SafirDrawerState();
}

class _SafirDrawerState extends State<SafirDrawer> {
  bool _busy = false;

  String _tr(
    BuildContext context,
    String key,
    String fallback,
  ) {
    final value = context.tr(key);

    if (value.trim().isEmpty || value == key) {
      return fallback;
    }

    return value;
  }

  String _displayName(BuildContext context) {
    final name = userName.trim();
    if (name.isNotEmpty) return name;

    final authName =
        FirebaseAuth.instance.currentUser?.displayName?.trim();

    if (authName != null && authName.isNotEmpty) {
      return authName;
    }

    return _tr(context, 'user_default', 'کاربر سفیر');
  }

  String _displayPhone() {
    final phone = userPhone.trim();
    if (phone.isNotEmpty) return phone;

    return FirebaseAuth.instance.currentUser?.phoneNumber?.trim() ??
        '';
  }

  /// منو را فوری می‌بندد. کار بعدی بدون انتظار شروع می‌شود، پس با
  /// ناوبری/دیالوگ ساخته‌شده از مرجع‌های از‌پیش‌گرفته‌شده انجام می‌شود
  /// (state منو هنگام بسته شدن از بین می‌رود).
  void _closeDrawerNow() {
    final scaffold = Scaffold.maybeOf(context);

    if (scaffold == null) return;

    if (scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    } else if (scaffold.isEndDrawerOpen) {
      scaffold.closeEndDrawer();
    }
  }

  Future<void> _openProfile() async {
    final nav = Navigator.of(context, rootNavigator: true);

    _closeDrawerNow();

    await nav.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileAnimatedMenu(),
      ),
    );
  }

  Future<void> _showAbout() async {
    final nav = Navigator.of(context, rootNavigator: true);
    final colors = _DrawerColors.of(context);

    _closeDrawerNow();

    await showModalBottomSheet<void>(
      context: nav.context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      elevation: 12,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) {
        final sheetColors = _DrawerColors.of(sheetContext);

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetColors.border,
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
                    cacheWidth: 216,
                    cacheHeight: 216,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(
                          Icons.local_taxi_rounded,
                          size: 44,
                          color: sheetColors.brand,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _tr(sheetContext, 'app_name', 'سفیر'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: sheetColors.text,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _tr(
                    sheetContext,
                    'about_app_content_short',
                    'سفیر یک اپلیکیشن حمل‌ونقل شهری است که ثبت و مدیریت سفر را برای مسافران و رانندگان ساده‌تر می‌کند.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.7,
                    color: sheetColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _rateApp() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failText = _tr(
      context,
      'store_link_unavailable',
      'لینک اپ هنوز در دسترس نیست',
    );

    _closeDrawerNow();

    String storeUrl = '';

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('settings')
          .doc('app_config')
          .get()
          .timeout(const Duration(seconds: 6));

      storeUrl =
          snapshot.data()?['store_url']?.toString().trim() ?? '';
    } catch (error) {
      debugPrint('Store URL read error: $error');
    }

    bool opened = false;
    final uri = Uri.tryParse(storeUrl);

    if (uri != null && uri.hasScheme) {
      const allowedSchemes = <String>{
        'http',
        'https',
        'market',
        'itms-apps',
        'itms-appss',
      };

      final scheme = uri.scheme.toLowerCase();
      final isAllowed = allowedSchemes.contains(scheme);
      final hasValidHost =
          scheme != 'http' &&
              scheme != 'https' ||
          uri.host.isNotEmpty;

      if (isAllowed && hasValidHost) {
        try {
          opened = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } catch (error) {
          debugPrint('Open store error: $error');
        }
      }
    }

    if (opened) return;

    _showMessage(messenger, failText);
  }

  Future<void> _signOut() async {
    // تا پایان کار، منو باز می‌ماند؛ پس state هم زنده است.
    final nav = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final errorText = _tr(
      context,
      'drawer_action_error',
      'خروج انجام نشد؛ دوباره تلاش کنید.',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        final colors = _DrawerColors.of(dialogContext);

        return Dialog(
          backgroundColor: colors.surface,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: colors.border),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.dangerSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: colors.danger,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _tr(
                    dialogContext,
                    'sign_out_title',
                    'خروج از حساب',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _tr(
                    dialogContext,
                    'sign_out_confirm',
                    'آیا مطمئن هستید که می‌خواهید از حساب کاربری خود خارج شوید؟',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.secondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.text,
                          minimumSize: const Size(0, 48),
                          side: BorderSide(color: colors.border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _tr(
                            dialogContext,
                            'cancel',
                            'انصراف',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.danger,
                          foregroundColor: Theme.of(dialogContext)
                              .colorScheme
                              .onError,
                          minimumSize: const Size(0, 48),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _tr(
                            dialogContext,
                            'sign_out',
                            'خروج',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    try {
      try {
        final googleSignIn = GoogleSignIn();

        // برای اینکه دفعهٔ بعد انتخاب حساب دوباره نمایش داده شود
        await googleSignIn.signOut();

        try {
          await googleSignIn.disconnect();
        } catch (_) {}
      } catch (error) {
        debugPrint('Google sign out error: $error');
      }

      await FirebaseAuth.instance.signOut();

      userName = '';
      userPhone = '';

      nav.pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => const RegisterScreen(),
        ),
        (_) => false,
      );
    } catch (error) {
      debugPrint('Sign out error: $error');

      _showMessage(messenger, errorText);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showMessage(
    ScaffoldMessengerState? messenger,
    String message,
  ) {
    if (messenger == null || !messenger.mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _DrawerColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final phone = _displayPhone();
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Drawer(
      width: (width * 0.86).clamp(0.0, 340.0).toDouble(),
      backgroundColor: colors.background,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: RepaintBoundary(
        child: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                child: Material(
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: colors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _openProfile,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.border,
                                width: 1.2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/default_profile.png',
                                width: 56,
                                height: 56,
                                cacheWidth: 168,
                                cacheHeight: 168,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return ColoredBox(
                                    color: colors.brand.withOpacity(0.08),
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 30,
                                      color: colors.secondary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _displayName(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.text,
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
                                      color: colors.secondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            isRTL
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            color: colors.secondary,
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
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  children: [
                    _DrawerSectionTitle(
                      title: _tr(
                        context,
                        'quick_settings',
                        'تنظیمات سریع',
                      ),
                    ),
                    _DrawerCard(
                      children: [
                        const _LanguageQuickSwitch(),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: colors.border,
                        ),
                        const _ThemeQuickSwitch(),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _DrawerSectionTitle(
                      title: _tr(
                        context,
                        'drawer_general',
                        'عمومی',
                      ),
                    ),
                    _DrawerCard(
                      children: [
                        _DrawerTile(
                          icon: Icons.support_agent_rounded,
                          color: colors.brand,
                          title: _tr(
                            context,
                            'help_support',
                            'مرکز کمک و پشتیبانی',
                          ),
                          subtitle: _tr(
                            context,
                            'help_support_sub',
                            'تماس مستقیم با پشتیبانی',
                          ),
                          onTap: () {
                            final rootContext = Navigator.of(
                              context,
                              rootNavigator: true,
                            ).context;

                            _closeDrawerNow();

                            SupportService.call(rootContext);
                          },
                        ),
                        const _DrawerTileDivider(),
                        _DrawerTile(
                          icon: Icons.info_outline_rounded,
                          color: colors.secondary,
                          title: _tr(
                            context,
                            'about_safir',
                            'دربارهٔ سفیر',
                          ),
                          onTap: _showAbout,
                        ),
                        const _DrawerTileDivider(),
                        _DrawerTile(
                          icon: Icons.star_rounded,
                          color: AppColors.warning,
                          title: _tr(
                            context,
                            'rate_app',
                            'امتیاز به اپلیکیشن',
                          ),
                          onTap: _rateApp,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Material(
                  color: colors.dangerSoft,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _signOut,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: colors.danger,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _tr(
                                context,
                                'sign_out',
                                'خروج از حساب کاربری',
                              ),
                              style: TextStyle(
                                color: colors.danger,
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
        ),
      ),
    );
  }
}

class _DrawerColors {
  const _DrawerColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.secondary,
    required this.border,
    required this.brand,
    required this.danger,
    required this.dangerSoft,
    required this.selected,
  });

  factory _DrawerColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final brand = isDark
        ? Color.lerp(
            AppColors.primaryBrand,
            Colors.white,
            0.35,
          )!
        : AppColors.primaryBrand;

    return _DrawerColors(
      background: theme.scaffoldBackgroundColor,
      surface: scheme.surface,
      text: scheme.onSurface,
      secondary: scheme.onSurface.withOpacity(0.66),
      border: scheme.onSurface.withOpacity(
        isDark ? 0.14 : 0.10,
      ),
      brand: brand,
      danger: scheme.error,
      dangerSoft: scheme.error.withOpacity(
        isDark ? 0.16 : 0.08,
      ),
      selected: brand.withOpacity(
        isDark ? 0.18 : 0.08,
      ),
    );
  }

  final Color background;
  final Color surface;
  final Color text;
  final Color secondary;
  final Color border;
  final Color brand;
  final Color danger;
  final Color dangerSoft;
  final Color selected;
}

class _DrawerSectionTitle extends StatelessWidget {
  const _DrawerSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = _DrawerColors.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 6,
        bottom: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: colors.secondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DrawerCard extends StatelessWidget {
  const _DrawerCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = _DrawerColors.of(context);

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _DrawerTileDivider extends StatelessWidget {
  const _DrawerTileDivider();

  @override
  Widget build(BuildContext context) {
    final colors = _DrawerColors.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 54),
      child: Divider(
        height: 1,
        thickness: 1,
        color: colors.border,
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _DrawerColors.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
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
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: colors.secondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isRTL
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: colors.secondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.selected,
    required this.onTap,
    required this.child,
    this.enabled = true,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = _DrawerColors.of(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: selected ? colors.selected : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? colors.brand : Colors.transparent,
              width: 1.2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 48,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageQuickSwitch extends StatefulWidget {
  const _LanguageQuickSwitch();

  @override
  State<_LanguageQuickSwitch> createState() =>
      _LanguageQuickSwitchState();
}

class _LanguageQuickSwitchState
    extends State<_LanguageQuickSwitch> {
  bool _saving = false;

  Future<void> _setLanguage(String code) async {
    if (_saving || context.locale.languageCode == code) {
      return;
    }

    final matches = context.supportedLocales.where(
      (locale) => locale.languageCode == code,
    );

    if (matches.isEmpty) {
      debugPrint(
        'Language "$code" is not included in supportedLocales.',
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await context.setLocale(matches.first);

      final preferences =
          await SharedPreferences.getInstance();

      await preferences.setString(
        'selected_language',
        code,
      );
    } catch (error) {
      debugPrint('Language change error: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = context.locale.languageCode;
    final colors = _DrawerColors.of(context);

    const languages = <(String, String)>[
      ('fa', 'دری'),
      ('ps', 'پښتو'),
      ('en', 'English'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          for (final (code, label) in languages)
            _ChoiceChip(
              selected: current == code,
              enabled: !_saving,
              onTap: () => _setLanguage(code),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: current == code
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: current == code
                      ? colors.brand
                      : colors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeQuickSwitch extends StatefulWidget {
  const _ThemeQuickSwitch();

  @override
  State<_ThemeQuickSwitch> createState() =>
      _ThemeQuickSwitchState();
}

class _ThemeQuickSwitchState extends State<_ThemeQuickSwitch> {
  bool _saving = false;

  String _tr(
    BuildContext context,
    String key,
    String fallback,
  ) {
    final value = context.tr(key);

    return value.trim().isEmpty || value == key
        ? fallback
        : value;
  }

  Future<void> _setTheme(ThemeMode mode) async {
    if (_saving || ThemeController.instance.mode == mode) {
      return;
    }

    setState(() => _saving = true);

    try {
      await ThemeController.instance.setMode(mode);
    } catch (error) {
      debugPrint('Theme change error: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _DrawerColors.of(context);

    final items = <(ThemeMode, IconData, String)>[
      (
        ThemeMode.system,
        Icons.brightness_auto_rounded,
        _tr(context, 'theme_system', 'خودکار'),
      ),
      (
        ThemeMode.light,
        Icons.light_mode_rounded,
        _tr(context, 'theme_light', 'روشن'),
      ),
      (
        ThemeMode.dark,
        Icons.dark_mode_rounded,
        _tr(context, 'theme_dark', 'تاریک'),
      ),
    ];

    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final current = ThemeController.instance.mode;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(
            children: [
              for (final (mode, icon, label) in items)
                _ChoiceChip(
                  selected: current == mode,
                  enabled: !_saving,
                  onTap: () => _setTheme(mode),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 21,
                        color: current == mode
                            ? colors.brand
                            : colors.secondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: current == mode
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: current == mode
                              ? colors.brand
                              : colors.secondary,
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
