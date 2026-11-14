import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safir_passengers/theme/app_colors.dart';
import 'package:safir_passengers/services/referral_service.dart';
import 'package:share_plus/share_plus.dart';

// نام‌های قبلی برای سازگاری با فایل‌های دیگر؛ حالا از AppColors (روشن/تاریک) می‌آیند.
Color get safirBrandColor => AppColors.primaryBrand;
Color get safirAccentColor => AppColors.success;

// ----------------------------------------------------
// ابزارهای مشترک ظاهر
// ----------------------------------------------------

/// نوار بالای یک‌دست برای همهٔ صفحه‌های این فایل
PreferredSizeWidget _subAppBar(BuildContext context, String title) {
  return AppBar(
    title: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 17,
        color: AppColors.textPrimary,
      ),
    ),
    backgroundColor: AppColors.backgroundLight,
    surfaceTintColor: AppColors.backgroundLight,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    leading: Navigator.canPop(context)
        ? IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 19,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.maybePop(context),
          )
        : null,
  );
}

/// دایرهٔ نرم با آیکن بزرگ (حالت خالی و سربرگ صفحه‌ها)
Widget _heroIcon(IconData icon, Color color, {double size = 92}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: size * 0.5, color: color),
  );
}

/// کارت یک‌دست
BoxDecoration _cardDecoration({double radius = 18}) {
  return BoxDecoration(
    color: AppColors.cardBgLight,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.fieldBorder),
  );
}

/// دکمهٔ اصلی تمام‌عرض
Widget _primaryButton(String label, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryButton,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.buttonText,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    ),
  );
}

// ----------------------------------------------------
// ۲. صفحه دعوت از دوستان
// ----------------------------------------------------
class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String referralCode = ReferralService.code;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _subAppBar(context, "invite_friends_title".tr()),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // کارت اصلی: هدیه + عنوان + توضیح
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: BoxDecoration(
                  color: AppColors.cardBgLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        size: 44,
                        color: AppColors.accentOrange,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _inviteTr(
                          'invite_friends_main_title', 'دوستانتان را به سفیر دعوت کنید'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _inviteTr('invite_friends_subtext',
                          'کد دعوت خود را با دوستان به اشتراک بگذارید'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.5,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // کد دعوت: لمس = کپی
              Material(
                color: AppColors.cardBgLight,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: referralCode));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            _inviteTr('code_copied', 'کد دعوت کپی شد'),
                            style: TextStyle(color: AppColors.buttonText),
                          ),
                        ),
                      );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _inviteTr('your_invite_code', 'کد دعوت شما'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          referralCode,
                          textDirection: ui.TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: 5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              _inviteTr('tap_to_copy', 'برای کپی لمس کنید'),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // چگونه کار می‌کند
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBgLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _inviteTr('invite_how_title', 'چگونه کار می‌کند؟'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _inviteStep(
                      1,
                      _inviteTr('invite_step_1', 'کد خود را برای دوستانتان بفرستید'),
                    ),
                    _inviteStep(
                      2,
                      _inviteTr('invite_step_2',
                          'دوستتان هنگام ثبت‌نام، کد شما را وارد کند'),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // دکمهٔ اصلی: اشتراک‌گذاری
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Share.share(ReferralService.shareMessage);
                  },
                  icon: Icon(Icons.share_rounded,
                      size: 20, color: AppColors.buttonText),
                  label: Text(
                    _inviteTr('share_invite_btn', 'ارسال دعوت به دوستان'),
                    style: TextStyle(
                      color: AppColors.buttonText,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inviteStep(int n, String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Text(
              '$n',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _inviteTr(String key, String fallback) {
  final String v = key.tr();
  return (v.trim().isEmpty || v == key) ? fallback : v;
}

// ----------------------------------------------------
// ۳. صفحه پیام‌ها (کاملاً متصل به Firestore و پیام‌های ادمین)
// ----------------------------------------------------
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _subAppBar(context, "messages_title".tr()),
      body: currentUserId == null
          ? Center(
              child: Text(
                "messages_desc".tr(),
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBrand,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "error_occurred".tr(),
                      style: TextStyle(color: AppColors.danger),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _heroIcon(Icons.mark_email_read_outlined,
                            AppColors.originBlue),
                        const SizedBox(height: 16),
                        Text(
                          "messages_empty".tr(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var notifications = snapshot.data!.docs;

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    var data =
                        notifications[index].data() as Map<String, dynamic>;
                    String title = data['title'] ?? 'messages_default_title'.tr();
                    String body = data['body'] ?? '';
                    String time = '';

                    if (data['timestamp'] != null &&
                        data['timestamp'] is Timestamp) {
                      DateTime date = (data['timestamp'] as Timestamp).toDate();
                      time =
                          "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                    } else {
                      time = "today".tr();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: _cardDecoration(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.originBlue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.notifications_active_rounded,
                              color: AppColors.originBlue,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    body,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// ----------------------------------------------------
// ۴. صفحه کدهای تخفیف
// ----------------------------------------------------
class DiscountCodeScreen extends StatelessWidget {
  const DiscountCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController codeController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _subAppBar(context, "discounts_title".tr()),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: codeController,
                    cursorColor: AppColors.primaryBrand,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: "enter_discount_code".tr(),
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.cardBgLight,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.fieldBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.fieldBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: AppColors.primaryBrand, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                  child: Text(
                    "apply_btn".tr(),
                    style: TextStyle(
                      color: AppColors.buttonText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _heroIcon(
                        Icons.local_offer_rounded, AppColors.warningIcon),
                    const SizedBox(height: 16),
                    Text(
                      "discounts_empty_msg".tr(),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// ۵. صفحه سفر بین شهری
// ----------------------------------------------------
class BinShahriScreen extends StatelessWidget {
  const BinShahriScreen({super.key});

  Widget _routeRow({
    required Widget dot,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool showChevron = false,
    required BuildContext context,
  }) {
    final bool rtl = Directionality.of(context) == ui.TextDirection.rtl;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Row(
          children: [
            SizedBox(width: 24, child: Center(child: dot)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: AppColors.handle,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _subAppBar(context, "intercity_title".tr()),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _cardDecoration(radius: 20),
              child: Column(
                children: [
                  _routeRow(
                    context: context,
                    dot: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardBgLight,
                        border:
                            Border.all(color: AppColors.originBlue, width: 3.5),
                      ),
                    ),
                    title: "origin".tr(),
                    subtitle: "origin_province_hint".tr(),
                  ),
                  Divider(
                    height: 1,
                    indent: 42,
                    color: AppColors.fieldBorder,
                  ),
                  _routeRow(
                    context: context,
                    dot: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.primaryButton,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: "destination".tr(),
                    subtitle: "select_destination".tr(),
                    showChevron: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const Spacer(),
            _primaryButton("request_intercity_ride".tr(), () {}),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// ۶. صفحه باربری سفیر
// ----------------------------------------------------
class BarbariScreen extends StatelessWidget {
  const BarbariScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _subAppBar(context, "cargo_services_title".tr()),
      body: GridView.count(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        children: [
          _buildFreightCard(context, Icons.electric_rickshaw_rounded,
              "vehicle_zaranj_title".tr(), "capacity_zaranj".tr(),
              AppColors.warningIcon),
          _buildFreightCard(context, Icons.local_shipping_rounded,
              "vehicle_pickup_title".tr(), "capacity_pickup".tr(),
              AppColors.originBlue),
          _buildFreightCard(context, Icons.fire_truck_rounded,
              "vehicle_truck_title".tr(), "capacity_truck".tr(),
              AppColors.primaryBrand),
          _buildFreightCard(context, Icons.inventory_2_rounded,
              "extra_cargo_services_section".tr(), "packing_help_label".tr(),
              AppColors.danger),
        ],
      ),
    );
  }

  Widget _buildFreightCard(BuildContext context, IconData icon, String title,
      String subtitle, Color color) {
    return Material(
      color: AppColors.cardBgLight,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Ink(
          decoration: _cardDecoration(radius: 20),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 34, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// ۷. صفحه ثبت‌نام رانندگان
// ----------------------------------------------------
class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _subAppBar(context, "driver_registration_title".tr()),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _heroIcon(Icons.time_to_leave_rounded, AppColors.primaryBrand,
                size: 128),
            const SizedBox(height: 24),
            Text(
              "register_subtitle".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "driver_registration_coming_soon".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.6,
              ),
            ),
            const Spacer(),
            _primaryButton("continue_btn".tr(), () {}),
          ],
        ),
      ),
    );
  }
}
