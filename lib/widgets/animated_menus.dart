import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart'
    hide TextDirection;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/theme/app_colors.dart';
import 'package:safir_passengers/services/promo_service.dart';
import 'package:safir_passengers/services/referral_service.dart';
import 'package:safir_passengers/pages/settings_screen.dart';
import 'package:safir_passengers/pages/trips_history_page.dart';
import 'package:safir_passengers/pages/saved_addresses_screen.dart';
import 'package:safir_passengers/pages/sub_screens.dart';
import 'package:safir_passengers/pages/user_profile_screen.dart';

// سازگاری با فایل‌هایی که این نام‌ها را import می‌کنند.
Color get primaryAccent => AppColors.primaryBrand;
Color get darkTextColor => AppColors.textPrimary;
Color get secondaryTextColor => AppColors.textSecondary;
Color get pageBackground => AppColors.backgroundLight;
Color get menuIconBackground => AppColors.cardBackground;

/// ترجمه با متن جایگزین
String _mt(
  String key,
  String fallback, {
  List<String>? args,
}) {
  final String value =
      args == null ? key.tr() : key.tr(args: args);

  return value.trim().isEmpty || value == key
      ? fallback
      : value;
}

void _snack(
  BuildContext context,
  String message, {
  Color? color,
  SnackBarAction? action,
}) {
  if (!context.mounted) return;

  _snackOn(
    ScaffoldMessenger.of(context),
    message,
    color: color,
    action: action,
  );
}

void _snackOn(
  ScaffoldMessengerState messenger,
  String message, {
  Color? color,
  SnackBarAction? action,
}) {
  if (!messenger.mounted) return;

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color ?? AppColors.cardBgLight,
      action: action,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      content: Text(
        message,
        style: TextStyle(
          color: color == null
              ? AppColors.textPrimary
              : AppColors.buttonText,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

Future<void> _makeSupportCall(BuildContext context) async {
  String phone = '+93700000000';

  try {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('admin_settings')
            .doc('support')
            .get();

    final String? firestorePhone =
        snapshot.data()?['support_phone']?.toString();

    if (firestorePhone != null &&
        firestorePhone.trim().isNotEmpty) {
      phone = firestorePhone.trim();
    }
  } catch (e) {
    debugPrint(
      'خطا در دریافت شماره پشتیبانی از Firestore: $e',
    );
  }

  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phone,
  );

  try {
    final bool opened = await launchUrl(launchUri);
    if (opened) return;
  } catch (e) {
    debugPrint('خطا در بازکردن شماره تماس: $e');
  }

  if (!context.mounted) return;

  _snack(
    context,
    _mt(
      'can_not_make_call',
      'امکان تماس نبود: $phone',
      args: [phone],
    ),
    color: AppColors.danger,
    action: SnackBarAction(
      label: _mt('copy', 'کپی شماره'),
      textColor: AppColors.buttonText,
      onPressed: () {
        Clipboard.setData(ClipboardData(text: phone));
      },
    ),
  );
}

Future<void> _shareInviteCode(BuildContext context) async {
  final String shareMessage = ReferralService.shareMessage;

  try {
    await Share.share(shareMessage);
  } catch (e) {
    debugPrint('خطا در اشتراک‌گذاری کد دعوت: $e');

    _snack(
      context,
      _mt(
        'share_failed',
        'اشتراک‌گذاری انجام نشد، دوباره تلاش کنید',
      ),
      color: AppColors.danger,
    );
  }
}

void _showDiscountModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DiscountCodeSheet(),
  );
}

class _DiscountCodeSheet extends StatefulWidget {
  const _DiscountCodeSheet();

  @override
  State<_DiscountCodeSheet> createState() =>
      _DiscountCodeSheetState();
}

class _DiscountCodeSheetState
    extends State<_DiscountCodeSheet> {
  final TextEditingController _discountController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _checkCode() async {
    if (_isLoading) return;

    final String code =
        _discountController.text.trim().toUpperCase();

    final ScaffoldMessengerState hostMessenger =
        ScaffoldMessenger.of(context);

    if (code.isEmpty) {
      HapticFeedback.lightImpact();

      _snackOn(
        hostMessenger,
        _mt(
          'enter_discount_code',
          'کد تخفیف را وارد کنید',
        ),
      );
      return;
    }

    final String successMessage = _mt(
      'discount_applied_success',
      'کد تخفیف ثبت شد',
    );

    setState(() => _isLoading = true);

    try {
      final PromoValidation result =
          await PromoService.validate(code);

      if (!mounted) return;

      if (result.isValid) {
        await PromoService.savePending(code);

        if (!mounted) return;

        setState(() => _isLoading = false);
        HapticFeedback.mediumImpact();
        Navigator.pop(context);

        _snackOn(
          hostMessenger,
          '${result.message} — $successMessage',
          color: AppColors.successDark,
        );
      } else {
        setState(() => _isLoading = false);
        HapticFeedback.heavyImpact();

        _snackOn(
          hostMessenger,
          result.message,
          color: AppColors.danger,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      debugPrint('Discount check error: $e');

      _snackOn(
        hostMessenger,
        _mt(
          'discount_check_failed',
          'بررسی کد انجام نشد، دوباره تلاش کنید',
        ),
        color: AppColors.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBgLight,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 18),
            Row(
              children: [
                _buildHeaderIcon(
                  Icons.local_offer_rounded,
                  AppColors.warningIcon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _mt('discount_code', 'کد تخفیف'),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _mt('close', 'بستن'),
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 23,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _discountController,
              autofocus: true,
              enabled: !_isLoading,
              textDirection: TextDirection.ltr,
              textCapitalization:
                  TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _checkCode(),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText: _mt(
                  'enter_discount_code',
                  'کد تخفیف را وارد کنید',
                ),
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
                prefixIcon: Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.warningIcon,
                  size: 23,
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.fieldBorder,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.fieldBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.primaryBrand,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  foregroundColor: AppColors.buttonText,
                  disabledBackgroundColor:
                      AppColors.primaryButton.withOpacity(0.45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: AppColors.buttonText,
                        ),
                      )
                    : Text(
                        _mt('apply_code', 'اعمال کد'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileAnimatedMenu extends StatefulWidget {
  const ProfileAnimatedMenu({
    super.key,
    this.currentLanguage,
    this.onLanguageChanged,
  });

  final String? currentLanguage;
  final ValueChanged<String>? onLanguageChanged;

  @override
  State<ProfileAnimatedMenu> createState() =>
      _ProfileAnimatedMenuState();
}

class _ProfileAnimatedMenuState
    extends State<ProfileAnimatedMenu> {
  late Future<String> _nameFuture;
  late Future<String> _phoneFuture;

  @override
  void initState() {
    super.initState();
    _reloadProfile();
  }

  void _reloadProfile() {
    _nameFuture = _displayName();
    _phoneFuture = _displayPhone();
  }

  Future<String> _displayName() async {
    final String globalName = userName.trim();

    if (globalName.isNotEmpty) return globalName;

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    final String? authName =
        currentUser?.displayName?.trim();

    if (authName != null && authName.isNotEmpty) {
      return authName;
    }

    if (currentUser == null) {
      return _localizedKey('user_default', 'کاربر سفیر');
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      final Map<String, dynamic>? data = snapshot.data();

      final String firestoreName = (data?['name'] ??
              data?['full_name'] ??
              data?['fullName'] ??
              data?['userName'] ??
              '')
          .toString()
          .trim();

      if (firestoreName.isNotEmpty) return firestoreName;
    } catch (e) {
      debugPrint('خطا در دریافت نام مسافر: $e');
    }

    return _localizedKey('user_default', 'کاربر سفیر');
  }

  Future<String> _displayPhone() async {
    final String globalPhone = userPhone.trim();

    if (globalPhone.isNotEmpty) return globalPhone;

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    final String? authPhone =
        currentUser?.phoneNumber?.trim();

    if (authPhone != null && authPhone.isNotEmpty) {
      return authPhone;
    }

    if (currentUser == null) return '---';

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      final Map<String, dynamic>? data = snapshot.data();

      final String firestorePhone = (data?['phone'] ??
              data?['phoneNumber'] ??
              data?['mobile'] ??
              data?['userPhone'] ??
              '')
          .toString()
          .trim();

      if (firestorePhone.isNotEmpty) return firestorePhone;
    } catch (e) {
      debugPrint('خطا در دریافت شماره مسافر: $e');
    }

    return '---';
  }

  String _localizedKey(String key, String fallback) {
    return _mt(key, fallback);
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          currentLanguage:
              widget.currentLanguage ??
              context.locale.languageCode,
          onLanguageChanged:
              widget.onLanguageChanged ?? (_) {},
        ),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UserProfileScreen(),
      ),
    );

    if (!mounted) return;
    setState(_reloadProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: _localizedKey('back', 'بازگشت'),
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
        title: Text(
          _localizedKey('profile', 'پروفایل'),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            28,
          ),
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 26),
            _buildSectionTitle(
              _localizedKey(
                'user_account_section',
                'حساب کاربری',
              ),
            ),
            _buildMenuGroup([
              _buildMenuItem(
                icon: Icons.route_rounded,
                accent: AppColors.primaryBrand,
                title: _localizedKey(
                  'trips_history',
                  'سفرها',
                ),
                subtitle: _localizedKey(
                  'trips_history_sub',
                  'مشاهده سفرهای قبلی',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const TripsHistoryPage(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.bookmarks_rounded,
                accent: AppColors.danger,
                title: _localizedKey(
                  'saved_addresses_title',
                  'آدرس‌های ذخیره‌شده',
                ),
                subtitle: _localizedKey(
                  'saved_addresses_sub',
                  'خانه، محل کار و مکان‌های پرکاربرد',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const SavedAddressesScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.group_add_rounded,
                accent: AppColors.originBlue,
                title: _localizedKey(
                  'invite_friends',
                  'دعوت از دوستان',
                ),
                subtitle: _localizedKey(
                  'invite_friends_sub',
                  'دوستان خود را به سفیر دعوت کنید',
                ),
                onTap: () => _shareInviteCode(context),
              ),
              _buildMenuItem(
                icon: Icons.forum_rounded,
                accent: AppColors.warning,
                title: _localizedKey(
                  'messages',
                  'پیام‌ها',
                ),
                subtitle: _localizedKey(
                  'messages_sub',
                  'پیام‌ها و اطلاعیه‌ها',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MessagesScreen(),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle(
              _localizedKey(
                'services_and_support_section',
                'خدمات و پشتیبانی',
              ),
            ),
            _buildMenuGroup([
              _buildMenuItem(
                icon: Icons.settings_rounded,
                accent: AppColors.iconSecondary,
                title: _localizedKey(
                  'settings',
                  'تنظیمات',
                ),
                subtitle: _localizedKey(
                  'settings_sub',
                  'زبان و تنظیمات برنامه',
                ),
                onTap: _openSettings,
              ),
              _buildMenuItem(
                icon: Icons.local_offer_rounded,
                accent: AppColors.warningIcon,
                title: _localizedKey(
                  'discount_code',
                  'کد تخفیف',
                ),
                subtitle: _localizedKey(
                  'discount_code_sub',
                  'ثبت و استفاده از کد تخفیف',
                ),
                onTap: () => _showDiscountModal(context),
              ),
              _buildMenuItem(
                icon: Icons.support_agent_rounded,
                accent: AppColors.success,
                title: _localizedKey(
                  'support_contact',
                  'پشتیبانی و ارتباط با ما',
                ),
                subtitle: _localizedKey(
                  'support_contact_sub',
                  'ما همیشه آماده کمک هستیم',
                ),
                onTap: () => _makeSupportCall(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final bool isRTL =
        Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: AppColors.cardBgLight,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openProfile,
        splashColor: AppColors.textPrimary.withOpacity(0.06),
        highlightColor:
            AppColors.textPrimary.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
          child: Row(
            children: [
              // آواتار بدون حلقه سبز
              Container(
                width: 66,
                height: 66,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.fieldBorder,
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  'assets/images/default_profile.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF757575),
                      size: 42,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _nameFuture,
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ??
                              _localizedKey(
                                'user_default',
                                'کاربر سفیر',
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    FutureBuilder<String>(
                      future: _phoneFuture,
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? '---',
                          textDirection: TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _localizedKey(
                              'edit_profile_hint',
                              'مشاهده و ویرایش پروفایل',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isRTL
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: AppColors.iconSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 8,
        end: 8,
        bottom: 11,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<Widget> children) {
    final bool isRTL =
        Directionality.of(context) == TextDirection.rtl;

    final List<Widget> rows = [];

    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(
            height: 1,
            thickness: 0.5,
            // فاصله از سمت آیکن، متناسب با جهت زبان
            indent: isRTL ? 16 : 68,
            endIndent: isRTL ? 68 : 16,
            color: AppColors.fieldBorder.withOpacity(0.65),
          ),
        );
      }

      rows.add(children[i]);
    }

    return Material(
      color: AppColors.cardBgLight,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final bool isRTL =
        Directionality.of(context) == TextDirection.rtl;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      splashColor: accent.withOpacity(0.10),
      highlightColor: accent.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        child: Row(
          children: [
            // فقط آیکن؛ بدون مربع، قاب یا زمینه رنگی
            SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Icon(
                  icon,
                  color: accent,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isRTL
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: AppColors.iconSecondary.withOpacity(0.65),
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSheetHandle() {
  return Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.handle.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

Widget _buildHeaderIcon(
  IconData icon,
  Color color,
) {
  return SizedBox(
    width: 36,
    height: 36,
    child: Center(
      child: Icon(
        icon,
        color: color,
        size: 28,
      ),
    ),
  );
}
