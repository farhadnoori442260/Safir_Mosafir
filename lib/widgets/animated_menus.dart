import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart'
    hide TextDirection;
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
const Color secondaryTextColor = Color(0xFF64748B);
const Color pageBackground = Color(0xFFF7F9F8);
const Color menuIconBackground = Color(0xFFEFF5F1);

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
      await launchUrl(launchUri);
      return;
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
      backgroundColor: Colors.red.shade700,
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
  final TextEditingController discountController =
      TextEditingController();

  bool isLoading = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (
          BuildContext context,
          StateSetter setModalState,
        ) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(sheetContext)
                      .viewInsets
                      .bottom +
                  20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
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
                      primaryAccent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'discount_code'.tr(),
                        style: const TextStyle(
                          color: darkTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: discountController,
                  autofocus: true,
                  textDirection: TextDirection.ltr,
                  textCapitalization:
                      TextCapitalization.characters,
                  style: const TextStyle(
                    color: darkTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'enter_discount_code'.tr(),
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.confirmation_number_outlined,
                      color: secondaryTextColor,
                    ),
                    filled: true,
                    fillColor: pageBackground,
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: primaryAccent,
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
                    onPressed: isLoading
                        ? null
                        : () async {
                            final String code =
                                discountController.text
                                    .trim()
                                    .toUpperCase();

                            if (code.isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'enter_discount_code'.tr(),
                                  ),
                                ),
                              );
                              return;
                            }

                            setModalState(() {
                              isLoading = true;
                            });

                            try {
                              final DocumentSnapshot<
                                  Map<String, dynamic>> snapshot =
                                  await FirebaseFirestore
                                      .instance
                                      .collection('coupons')
                                      .doc(code)
                                      .get();

                              final Map<String, dynamic>?
                                  couponData = snapshot.data();

                              final bool isActive =
                                  couponData?['isActive'] !=
                                      false;

                              if (!context.mounted) {
                                return;
                              }

                              setModalState(() {
                                isLoading = false;
                              });

                              if (snapshot.exists && isActive) {
                                Navigator.pop(sheetContext);

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'discount_applied_success'
                                          .tr(),
                                    ),
                                    backgroundColor:
                                        const Color(0xFF16A34A),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'discount_invalid'.tr(),
                                    ),
                                    backgroundColor:
                                        Colors.red.shade700,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) {
                                return;
                              }

                              setModalState(() {
                                isLoading = false;
                              });

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'error_occurred'.tr(
                                      args: [e.toString()],
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
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
          );
        },
      );
    },
  ).whenComplete(() {
    discountController.dispose();
  });
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
      return 'user_default'.tr();
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await FirebaseFirestore.instance
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

    return 'user_default'.tr();
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
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await FirebaseFirestore.instance
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        surfaceTintColor: pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'back'.tr(),
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkTextColor,
            size: 19,
          ),
        ),
        title: Text(
          'profile'.tr(),
          style: const TextStyle(
            color: darkTextColor,
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
              'user_account_section'.tr(),
            ),
            _buildMenuGroup([
              _buildMenuItem(
                icon: Icons.route_rounded,
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
                onTap: () {
                  _shareInviteCode(context);
                },
              ),
              _buildMenuItem(
                icon: Icons.chat_bubble_outline_rounded,
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
            ]),
            const SizedBox(height: 22),
            _buildSectionTitle(
              'services_and_support_section'.tr(),
            ),
            _buildMenuGroup([
              _buildMenuItem(
                icon: Icons.local_offer_outlined,
                title: 'discount_code'.tr(),
                subtitle: 'discount_code_sub'.tr(),
                onTap: () {
                  _showDiscountModal(context);
                },
              ),
              _buildMenuItem(
                icon: Icons.support_agent_rounded,
                title: 'support_contact'.tr(),
                subtitle: 'support_contact_sub'.tr(),
                onTap: () {
                  _makeSupportCall(context);
                },
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
                        currentLanguage:
                            widget.currentLanguage ?? 'fa',
                        onLanguageChanged:
                            widget.onLanguageChanged ?? (_) {},
                      ),
                    ),
                  );
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Material(
      color: Colors.white,
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
            border: Border.all(
              color: const Color(0xFFE5EBE7),
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/default_profile.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.person_rounded,
                        color: primaryAccent,
                        size: 30,
                      );
                    },
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
                                'user_default'.tr();

                        return Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    FutureBuilder<String>(
                      future: _displayPhone(),
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<String> snapshot,
                      ) {
                        final String phone =
                            snapshot.data ?? '---';

                        return Text(
                          phone,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: secondaryTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF94A3B8),
                size: 23,
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
        start: 5,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: darkTextColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5EBE7),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: menuIconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
                        color: darkTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFFB0BAC5),
                size: 20,
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
        color: const Color(0xFFD1D5DB),
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
