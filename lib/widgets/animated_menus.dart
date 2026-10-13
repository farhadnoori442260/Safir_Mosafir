import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/pages/settings_screen.dart';
import 'package:safir_passengers/pages/sub_screens.dart';
import 'package:safir_passengers/pages/user_profile_screen.dart';

const Color primaryAccent = Color(0xFF1B7A57);
const Color darkTextColor = Color(0xFF0F172A);
const Color menuIconBackground = Color(0xFFF1F5F9);

Future<void> _makeSupportCall(BuildContext context) async {
  String phone = '+93700000000';

  try {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('admin_settings')
            .doc('support')
            .get();

    final Map<String, dynamic>? data = snapshot.data();
    final String? firestorePhone = data?['support_phone']?.toString();

    if (firestorePhone != null && firestorePhone.trim().isNotEmpty) {
      phone = firestorePhone.trim();
    }
  } catch (e) {
    debugPrint('خطا در دریافت شماره پشتیبانی از Firestore: $e');
  }

  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phone,
  );

  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'can_not_make_call'.tr(args: [phone]),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

void _shareInviteCode(BuildContext context) {
  final User? user = FirebaseAuth.instance.currentUser;

  final String referralCode = user != null && user.uid.length >= 6
      ? user.uid.substring(0, 6).toUpperCase()
      : 'SAFIR2026';

  final String shareMessage = 'invite_message'.tr(args: [referralCode]);

  Share.share(shareMessage);
}

void _showDiscountModal(BuildContext context) {
  final TextEditingController discountController = TextEditingController();
  bool isLoading = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_offer_rounded,
                      color: primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'discount_code'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: darkTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: discountController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: darkTextColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'enter_discount_code'.tr(),
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9CA3AF),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryAccent,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            final String code =
                                discountController.text.trim().toUpperCase();

                            if (code.isEmpty) return;

                            setModalState(() {
                              isLoading = true;
                            });

                            try {
                              final DocumentSnapshot<Map<String, dynamic>>
                                  snapshot = await FirebaseFirestore.instance
                                      .collection('coupons')
                                      .doc(code)
                                      .get();

                              if (!context.mounted) return;

                              setModalState(() {
                                isLoading = false;
                              });

                              final Map<String, dynamic>? couponData =
                                  snapshot.data();

                              final bool isActive =
                                  couponData?['isActive'] != false;

                              if (snapshot.exists && isActive) {
                                Navigator.pop(sheetContext);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'discount_applied_success'.tr(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF22C55E),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'discount_invalid'.tr(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;

                              setModalState(() {
                                isLoading = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'error_occurred'.tr(
                                      args: [e.toString()],
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'apply_code'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
  );
}

void _showAboutAppDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: primaryAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'about_app'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: darkTextColor,
                ),
              ),
            ],
          ),
          content: Text(
            'about_app_desc'.tr(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'close'.tr(),
                style: const TextStyle(
                  color: primaryAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
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
  State<ProfileAnimatedMenu> createState() => _ProfileAnimatedMenuState();
}

class _ProfileAnimatedMenuState extends State<ProfileAnimatedMenu> {
  String _displayName() {
    if (userName.trim().isNotEmpty) {
      return userName.trim();
    }

    return 'user_default'.tr();
  }

  String _displayPhone() {
    if (userPhone.trim().isNotEmpty) {
      return userPhone.trim();
    }

    return '09907027123';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'back'.tr(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkTextColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildSectionTitle('user_account_section'.tr()),
            _buildMenuItem(
              icon: Icons.history_rounded,
              title: 'trips_history'.tr(),
              subtitle: 'trips_history_sub'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TripsScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.person_add_alt_1_rounded,
              title: 'invite_friends'.tr(),
              subtitle: 'invite_friends_sub'.tr(),
              onTap: () => _shareInviteCode(context),
            ),
            _buildMenuItem(
              icon: Icons.mail_outline_rounded,
              title: 'messages'.tr(),
              subtitle: 'messages_sub'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MessagesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            _buildSectionTitle('services_and_support_section'.tr()),
            _buildMenuItem(
              icon: Icons.local_offer_outlined,
              title: 'discount_code'.tr(),
              subtitle: 'discount_code_sub'.tr(),
              onTap: () => _showDiscountModal(context),
            ),
            _buildMenuItem(
              icon: Icons.headset_mic_outlined,
              title: 'support_contact'.tr(),
              subtitle: 'support_contact_sub'.tr(),
              onTap: () => _makeSupportCall(context),
            ),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: 'settings'.tr(),
              subtitle: 'settings_sub'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      currentLanguage: widget.currentLanguage ?? 'fa',
                      onLanguageChanged: widget.onLanguageChanged ?? (_) {},
                    ),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.info_outline_rounded,
              title: 'about_app'.tr(),
              subtitle: 'about_app_sub'.tr(),
              onTap: () => _showAboutAppDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/default_profile.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _displayName(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _displayPhone(),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF94A3B8),
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
      padding: const EdgeInsets.only(
        right: 4,
        bottom: 9,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: darkTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.black12,
          highlightColor: Colors.black.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: menuIconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: darkTextColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
