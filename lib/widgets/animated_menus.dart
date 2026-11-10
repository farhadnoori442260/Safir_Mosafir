import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart'
    hide TextDirection;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/theme/app_colors.dart';
import 'package:safir_passengers/pages/settings_screen.dart';
import 'package:safir_passengers/pages/trips_history_page.dart';
import 'package:safir_passengers/pages/saved_addresses_screen.dart';
import 'package:safir_passengers/pages/sub_screens.dart';
import 'package:safir_passengers/pages/user_profile_screen.dart';

// این پنج نام ممکن است در فایل‌های دیگر import شده باشند؛
// نام‌ها نگه داشته شده‌اند ولی حالا به AppColors وصل‌اند (رنگ جدا ندارند).
const Color primaryAccent = AppColors.primaryBrand;
const Color darkTextColor = AppColors.textPrimary;
const Color secondaryTextColor = AppColors.textSecondary;
const Color pageBackground = AppColors.backgroundLight;
const Color menuIconBackground = AppColors.cardBackground;

Future<void> _makeSupportCall(BuildContext context) async {
  String phone = '+93700000000';

  try {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('admin_settings')
            .doc('support')
            .get();

    final Map<String, dynamic>? data = snapshot.data();
    final String? firestorePhone =
        data?['support_phone']?.toString();

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
    final bool canCall = await canLaunchUrl(launchUri);

    if (canCall) {
      final bool opened = await launchUrl(launchUri);
      if (opened) return;
    }
  } catch (e) {
    debugPrint('خطا در بازکردن شماره تماس: $e');
  }

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'can_not_make_call'.tr(args: [phone]),
      ),
      backgroundColor: AppColors.danger,
    ),
  );
}

Future<void> _shareInviteCode(BuildContext context) async {
  final User? user = FirebaseAuth.instance.currentUser;

  final String referralCode =
      user != null && user.uid.length >= 6
          ? user.uid.substring(0, 6).toUpperCase()
          : 'SAFIR2026';

  final String shareMessage =
      'invite_message'.tr(args: [referralCode]);

  try {
    await Share.share(shareMessage);
  } catch (e) {
    debugPrint('خطا در اشتراک‌گذاری کد دعوت: $e');

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'error_occurred'.tr(args: [e.toString()]),
        ),
      ),
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

    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);

    if (code.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('enter_discount_code'.tr()),
        ),
      );
      return;
    }

    final String successMessage =
        'discount_applied_success'.tr();
    final String invalidMessage = 'discount_invalid'.tr();

    setState(() => _isLoading = true);

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('coupons')
              .doc(code)
              .get();

      if (!mounted) return;

      final Map<String, dynamic>? couponData =
          snapshot.data();

      final bool isActive =
          couponData?['isActive'] != false;

      setState(() => _isLoading = false);

      if (snapshot.exists && isActive) {
        Navigator.pop(context);

        messenger.showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.successDark,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(invalidMessage),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'error_occurred'.tr(
              args: [e.toString()],
            ),
          ),
        ),
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
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cardBgLight,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildHeaderIcon(
                  Icons.local_offer_outlined,
                  AppColors.primaryBrand,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'discount_code'.tr(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _discountController,
              autofocus: true,
              textDirection: TextDirection.ltr,
              textCapitalization:
                  TextCapitalization.characters,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'enter_discount_code'.tr(),
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.fieldBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBrand,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : _checkCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrand,
                  foregroundColor: AppColors.buttonText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: AppColors.buttonText,
                        ),
                      )
                    : Text(
                        'apply_code'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
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
  Future<String> _displayName() async {
    final String globalName = userName.trim();

    if (globalName.isNotEmpty) {
      return globalName;
    }

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    final String? authName =
        currentUser?.displayName?.trim();

    if (authName != null && authName.isNotEmpty) {
      return authName;
    }

    if (currentUser == null) {
      return _localizedKey(
        'user_default',
        'کاربر سفیر',
      );
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      final Map<String, dynamic>? data =
          snapshot.data();

      final String firestoreName = (data?['name'] ??
              data?['full_name'] ??
              data?['fullName'] ??
              data?['userName'] ??
              '')
          .toString()
          .trim();

      if (firestoreName.isNotEmpty) {
        return firestoreName;
      }
    } catch (e) {
      debugPrint('خطا در دریافت نام مسافر: $e');
    }

    return _localizedKey(
      'user_default',
      'کاربر سفیر',
    );
  }

  Future<String> _displayPhone() async {
    final String globalPhone = userPhone.trim();

    if (globalPhone.isNotEmpty) {
      return globalPhone;
    }

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    final String? authPhone =
        currentUser?.phoneNumber?.trim();

    if (authPhone != null && authPhone.isNotEmpty) {
      return authPhone;
    }

    if (currentUser == null) {
      return '---';
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      final Map<String, dynamic>? data =
          snapshot.data();

      final String firestorePhone = (data?['phone'] ??
              data?['phoneNumber'] ??
              data?['mobile'] ??
              data?['userPhone'] ??
              '')
          .toString()
          .trim();

      if (firestorePhone.isNotEmpty) {
        return firestorePhone;
      }
    } catch (e) {
      debugPrint('خطا در دریافت شماره مسافر: $e');
    }

    return '---';
  }

  String _localizedKey(String key, String fallback) {
    final String value = key.tr();

    return value.trim().isEmpty || value == key
        ? fallback
        : value;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: _localizedKey('back', 'بازگشت'),
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 19,
          ),
        ),
        title: Text(
          _localizedKey('profile', 'پروفایل'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            6,
            16,
            28,
          ),
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildSectionTitle(
              _localizedKey(
                'user_account_section',
                'حساب کاربری',
              ),
            ),
            _buildMenuGroup([
              _buildMenuItem(
                icon: Icons.route_rounded,
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
                icon: Icons.bookmark_border_rounded,
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
                icon: Icons.person_add_alt_1_rounded,
                title: _localizedKey(
                  'invite_friends',
                  'دعوت از دوستان',
                ),
                subtitle: _localizedKey(
                  'invite_friends_sub',
                  'دوستان خود را به سفیر دعوت کنید',
                ),
                onTap: () {
                  _shareInviteCode(context);
                },
              ),
              _buildMenuItem(
                icon: Icons.chat_bubble_outline_rounded,
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
            const SizedBox(height: 22),
            _buildSectionTitle(
              _localizedKey(
                'services_and_support_section',
                'خدمات و پشتیبانی',
              ),
            ),
            _buildMenuGroup([
              // تنظیمات دقیقاً جای قبلی کد تخفیف.
              _buildMenuItem(
                icon: Icons.settings_outlined,
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
                icon: Icons.local_offer_outlined,
                title: _localizedKey(
                  'discount_code',
                  'کد تخفیف',
                ),
                subtitle: _localizedKey(
                  'discount_code_sub',
                  'ثبت و استفاده از کد تخفیف',
                ),
                onTap: () {
                  _showDiscountModal(context);
                },
              ),
              _buildMenuItem(
                icon: Icons.support_agent_rounded,
                title: _localizedKey(
                  'support_contact',
                  'پشتیبانی و ارتباط با ما',
                ),
                subtitle: _localizedKey(
                  'support_contact_sub',
                  'ما همیشه آماده کمک هستیم',
                ),
                onTap: () {
                  _makeSupportCall(context);
                },
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
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UserProfileScreen(),
            ),
          );

          if (mounted) {
            setState(() {});
          }
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                AppColors.cardBackground,
                AppColors.cardBgLight,
              ],
            ),
            border: Border.all(color: AppColors.fieldBorder),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              // آواتار با حلقه‌ی سبز ملایم
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBrand.withOpacity(0.35),
                    width: 2,
                  ),
                ),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/default_profile.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.person_rounded,
                          color: AppColors.primaryBrand,
                          size: 32,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _displayName(),
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<String> snapshot,
                      ) {
                        final String name =
                            snapshot.data ??
                                _localizedKey(
                                  'user_default',
                                  'کاربر سفیر',
                                );

                        return Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<String>(
                      future: _displayPhone(),
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<String> snapshot,
                      ) {
                        return Text(
                          snapshot.data ?? '---',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
        start: 6,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<Widget> children) {
    // بین آیتم‌ها خط جداکننده‌ی ظریف
    final List<Widget> rows = <Widget>[];

    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          const Divider(
            height: 1,
            thickness: 1,
            indent: 70,
            color: AppColors.fieldBorder,
          ),
        );
      }
      rows.add(children[i]);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final bool isRTL =
        Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryBrand,
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isRTL
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: AppColors.handle,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildSheetHandle() {
  return Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.handle,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}

Widget _buildHeaderIcon(
  IconData icon,
  Color color,
) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(
      icon,
      color: color,
      size: 21,
    ),
  );
}
