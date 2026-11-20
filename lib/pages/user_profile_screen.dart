import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/authentication/link_phone_screen.dart';
import 'package:safir_passengers/authentication/register_screen.dart';
import 'package:safir_passengers/theme/app_colors.dart';

// فایل‌هایی که قبلاً AppColors را از همین فایل می‌گرفتند، حالا همان AppColors
// اصلی پروژه را می‌گیرند (دیگر کلاس جداگانه‌ی آبی وجود ندارد).
export 'package:safir_passengers/theme/app_colors.dart';

String toEnglishDigits(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const farsi = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  for (int i = 0; i < 10; i++) {
    input = input.replaceAll(farsi[i], english[i]).replaceAll(arabic[i], english[i]);
  }
  return input;
}

String _t(String key, String fallback) {
  final String v = key.tr();
  return v.trim().isEmpty || v == key ? fallback : v;
}

// -------------------------------------------------------------
// ۱. صفحه اصلی پروفایل (حساب کاربری)
// -------------------------------------------------------------
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _useWheelchair = false;
  bool _isLoading = true;
  String _userName = '';
  String _userPhone = '';
  String _userRating = '4.5';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      _userName = currentUser.displayName ?? '';
      _userPhone = currentUser.phoneNumber ?? '';

      try {
        DocumentSnapshot userDoc = await _firestore
            .collection("users")
            .doc(currentUser.uid)
            .get()
            .timeout(const Duration(seconds: 8));

        if (userDoc.exists && userDoc.data() != null && mounted) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData["name"] ??
                userData["full_name"] ??
                userData["fullName"] ??
                userData["userName"] ??
                currentUser.displayName ??
                '';
            _userPhone = userData["phone"] ??
                userData["phoneNumber"] ??
                userData["phone_number"] ??
                currentUser.phoneNumber ??
                '';
            _userRating = userData["rating"]?.toString() ?? '4.5';
            _useWheelchair = userData["useWheelchair"] ?? false;
          });
        }
      } catch (e) {
        debugPrint("Error loading profile data: $e");
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateWheelchair(bool val) async {
    setState(() => _useWheelchair = val);
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection("users").doc(currentUser.uid).set(
        {"useWheelchair": val},
        SetOptions(merge: true),
      );
    }
  }

  Future<void> _openEditProfileDrawer() async {

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const EditProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    _loadProfileData();
  }

  Future<void> _changePhone() async {
    HapticFeedback.lightImpact();

    final String? newPhone = await showChangePhoneSheet(context);

    if (newPhone == null || !mounted) return;

    setState(() => _userPhone = newPhone);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t('change_phone_success', 'شماره با موفقیت تغییر کرد')),
        backgroundColor: AppColors.primaryBrand,
      ),
    );
  }

  void _showBadgeDetails(String title, String description, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBgLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBrand,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "got_it_btn".tr().isEmpty ? "متوجه شدم" : "got_it_btn".tr(),
                    style: TextStyle(color: AppColors.buttonText, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout({bool isSwitchAccount = false}) async {

    String title = isSwitchAccount
        ? ("switch_account_title".tr().isEmpty ? "تغییر حساب کاربری" : "switch_account_title".tr())
        : ("sign_out".tr().isEmpty ? "خروج از حساب" : "sign_out".tr());

    String content = isSwitchAccount
        ? ("switch_account_confirm_msg".tr().isEmpty ? "برای ورود با حساب دیگر، باید از حساب فعلی خارج شوید. ادامه می‌دهید؟" : "switch_account_confirm_msg".tr())
        : ("sign_out_confirm_msg".tr().isEmpty ? "آیا مایل به خروج از حساب کاربری هستید؟" : "sign_out_confirm_msg".tr());

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBgLight,
        surfaceTintColor: AppColors.cardBgLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text(content, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text("cancel".tr().isEmpty ? "انصراف" : "cancel".tr(), style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSwitchAccount ? AppColors.primaryBrand : AppColors.danger,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text("confirm".tr().isEmpty ? "تأیید" : "confirm".tr(), style: TextStyle(color: AppColors.buttonText, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        try {
          final GoogleSignIn googleSignIn = GoogleSignIn();
          // برای اینکه دفعهٔ بعد انتخاب حساب دوباره نمایش داده شود
          await googleSignIn.signOut();
          try {
            await googleSignIn.disconnect();
          } catch (_) {}
        } catch (e) {
          debugPrint("Google sign out error: $e");
        }

        await FirebaseAuth.instance.signOut();

        userName = '';
        userPhone = '';

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const RegisterScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint("Error signing out: $e");
      }
    }
  }

  /// آیکون داخل کادر رنگی نرم (هم‌شکل با منوی پروفایل)
  Widget _tileIcon(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  /// فلش جهت‌دار (در فارسی به چپ، در انگلیسی به راست)
  Widget _chevron() {
    return Icon(
      Directionality.of(context) == ui.TextDirection.rtl
          ? Icons.chevron_left_rounded
          : Icons.chevron_right_rounded,
      color: AppColors.handle,
      size: 22,
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
        title: Text(
          "user_account_title".tr().isEmpty ? "حساب کاربری" : "user_account_title".tr(),
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBrand))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  Center(
                    child: Column(
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
    width: 62,
    height: 62,
    child: ClipOval(
      child: Image.asset(
        'assets/images/default_profile.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            color: AppColors.backgroundLight,
            child: Icon(
              Icons.person_rounded,
              color: AppColors.textSecondary,
              size: 32,
            ),
          );
        },
      ),
    ),
  ),
),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: AppColors.warning, size: 19),
                            const SizedBox(width: 4),
                            Text(
                              formatNumberByLocale(context, _userRating),
                              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // کارت ۱: اطلاعات کاربری
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.fieldBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "main_account_info_title".tr().isEmpty ? "اطلاعات حساب" : "main_account_info_title".tr(),
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              GestureDetector(
                                onTap: _openEditProfileDrawer,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBackground,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "edit".tr().isEmpty ? "ویرایش" : "edit".tr(),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryBrand),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _userName.isEmpty
                                    ? ("default_user_name".tr().isEmpty ? "کاربر سفیر" : "default_user_name".tr())
                                    : _userName,
                                style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                formatNumberByLocale(context, _userPhone),
                                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // کارت ۲: مدال‌های افتخار
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        "badges_section_title".tr().isEmpty ? "مدال‌های افتخار" : "badges_section_title".tr(),
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        // کارت خوش‌رفتار
                        Expanded(
                          child: InkWell(
                            onTap: () => _showBadgeDetails(
                              "badge_polite_title".tr().isEmpty ? "مسافر بااخلاق" : "badge_polite_title".tr(),
                              "badge_polite_desc".tr().isEmpty ? "رانندگان سفیر رفتار محترمانه و صمیمانه شما در طول سفر را تحسین کرده‌اند." : "badge_polite_desc".tr(),
                              Icons.sentiment_very_satisfied_rounded,
                              AppColors.success,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsetsDirectional.only(end: 6),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.fieldBorder),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.sentiment_very_satisfied_rounded,
                                      size: 26,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "badge_polite_label".tr().isEmpty ? "خوش‌رفتار" : "badge_polite_label".tr(),
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // کارت وقت‌شناس
                        Expanded(
                          child: InkWell(
                            onTap: () => _showBadgeDetails(
                              "badge_punctual_title".tr().isEmpty ? "مسافر وقت‌شناس" : "badge_punctual_title".tr(),
                              "badge_punctual_desc".tr().isEmpty ? "حضور به موقع شما در مبدأ باعث سفری سریع‌تر و روان‌تر می‌شود." : "badge_punctual_desc".tr(),
                              Icons.access_time_filled_rounded,
                              AppColors.originBlue,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsetsDirectional.only(start: 6),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.fieldBorder),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.originBlue.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.access_time_filled_rounded,
                                      size: 26,
                                      color: AppColors.originBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "badge_punctual_label".tr().isEmpty ? "وقت‌شناس" : "badge_punctual_label".tr(),
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // کارت ۳: بخش دسترس‌پذیری
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        "accessibility_section_title".tr().isEmpty ? "دسترس‌پذیری" : "accessibility_section_title".tr(),
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        "accessibility_subtitle".tr().isEmpty ? "با فعال کردن گزینه متناسب، راننده را برای داشتن تجربه بهتری از سفر برای‌تان ایجاد کنیم." : "accessibility_subtitle".tr(),
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4, fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.fieldBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "wheelchair_option_label".tr().isEmpty ? "از ویلچر استفاده می‌کنم" : "wheelchair_option_label".tr(),
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          Switch(
                            value: _useWheelchair,
                            activeColor: AppColors.primaryBrand,
                            onChanged: _updateWheelchair,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // کارت ۴: گزینه‌های خروج و تغییر حساب
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.fieldBorder),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            leading: _tileIcon(Icons.phone_android_rounded, AppColors.primaryBrand),
                            title: Text(
                              _t('change_phone_title', 'تغییر شماره تماس'),
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            subtitle: _userPhone.isEmpty
                                ? null
                                : Text(
                                    formatNumberByLocale(context, _userPhone),
                                    textDirection: ui.TextDirection.ltr,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                            trailing: _chevron(),
                            onTap: _changePhone,
                          ),
                          Divider(height: 1, color: AppColors.fieldBorder, indent: 70, endIndent: 16),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            leading: _tileIcon(Icons.logout_rounded, AppColors.danger),
                            title: Text(
                              "exit".tr().isEmpty ? "خروج" : "exit".tr(),
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.danger),
                            ),
                            trailing: _chevron(),
                            onTap: () => _handleLogout(isSwitchAccount: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// -------------------------------------------------------------
// ۲. صفحه اطلاعات کاربری (ویرایش)
// -------------------------------------------------------------
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _initialName = '';
  String _initialPhone = '';
  String _initialEmail = '';
  String _initialAddress = '';
  String _initialGender = '';
  String _initialDob = '';

  String _selectedGender = '';
  String _selectedDob = '';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isChanged = false;

  bool get _isRtl {
    final String languageCode = context.locale.languageCode;
    return languageCode == 'fa' || languageCode == 'ps';
  }

  List<String> _getMonthsByLocale() {
    if (_isRtl) {
      return [
        _tr('month_hamal', 'حمل'),
        _tr('month_sawr', 'ثور'),
        _tr('month_jawza', 'جوزا'),
        _tr('month_saratan', 'سرطان'),
        _tr('month_asad', 'اسد'),
        _tr('month_sonbola', 'سنبله'),
        _tr('month_mizan', 'میزان'),
        _tr('month_aqrab', 'عقرب'),
        _tr('month_qaws', 'قوس'),
        _tr('month_jady', 'جدی'),
        _tr('month_dalwa', 'دلو'),
        _tr('month_hoot', 'حوت'),
      ];
    } else {
      return [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
    }
  }

  int _getMaxDays(int monthIndex) {
    if (_isRtl) {
      if (monthIndex < 6) return 31;
      if (monthIndex < 11) return 30;
      return 29;
    } else {
      if ([0, 2, 4, 6, 7, 9, 11].contains(monthIndex)) return 31;
      if ([3, 5, 8, 10].contains(monthIndex)) return 30;
      return 28;
    }
  }

  String _tr(String key, String fallback) {
    final String value = key.tr();
    return value.isEmpty || value == key ? fallback : value;
  }

  @override
  void initState() {
    super.initState();

    _nameController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
    _emailController.addListener(_checkChanges);
    _addressController.addListener(_checkChanges);

    _getUserData();
  }

  Future<void> _getUserData() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      _initialPhone = currentUser.phoneNumber ?? '';
      _initialEmail = currentUser.email ?? '';
      _initialName = currentUser.displayName ?? '';

      try {
        final DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get()
            .timeout(const Duration(seconds: 8));

        if (userDoc.exists && userDoc.data() != null && mounted) {
          final Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          _initialName = userData['name'] ??
              userData['full_name'] ??
              userData['fullName'] ??
              userData['userName'] ??
              _initialName;

          _initialPhone = userData['phone'] ??
              userData['phoneNumber'] ??
              userData['phone_number'] ??
              _initialPhone;

          _initialEmail = userData['email'] ?? _initialEmail;
          _initialAddress = userData['address'] ?? '';
          _initialGender = userData['gender'] ?? '';
          _initialDob = userData['dob'] ?? '';
        }
      } catch (e) {
        debugPrint('Error fetching edit data: $e');
      }

      if (mounted) {
        _nameController.text = _initialName;
        _phoneController.text = _initialPhone;
        _emailController.text = _initialEmail;
        _addressController.text = _initialAddress;

        _selectedGender = _initialGender;
        _selectedDob = _initialDob;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isChanged = false;
      });
    }
  }

  void _checkChanges() {
    final String currentPhone = toEnglishDigits(_phoneController.text.trim());
    final String initialPhone = toEnglishDigits(_initialPhone);

    final bool hasChanged =
        _nameController.text.trim() != _initialName ||
        currentPhone != initialPhone ||
        _emailController.text.trim() != _initialEmail ||
        _addressController.text.trim() != _initialAddress ||
        _selectedGender != _initialGender ||
        _selectedDob != _initialDob;

    if (hasChanged != _isChanged && mounted) {
      setState(() => _isChanged = hasChanged);
    }
  }

  Future<void> _updateUserData() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      await _firestore.collection('users').doc(currentUser.uid).set(
        {
          'name': _nameController.text.trim(),
          'phone': toEnglishDigits(_phoneController.text.trim()),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'gender': _selectedGender,
          'dob': _selectedDob,
        },
        SetOptions(merge: true),
      );

      if (_nameController.text.trim().isNotEmpty) {
        await currentUser.updateDisplayName(_nameController.text.trim());
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'profile_update_success',
              'اطلاعات با موفقیت به‌روزرسانی شد',
            ),
          ),
          backgroundColor: AppColors.primaryBrand,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_tr('profile_update_error', 'خطا در به‌روزرسانی اطلاعات')}: $e',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showGenderPicker() {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBgLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        String temporaryGender = _selectedGender;
        final String male = _tr('gender_male', 'مرد');
        final String female = _tr('gender_female', 'زن');

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _tr('gender_sheet_title', 'انتخاب جنسیت'),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _genderOptionTile(
                    label: male,
                    value: male,
                    groupValue: temporaryGender,
                    onTap: () {
                      setModalState(() => temporaryGender = male);
                    },
                  ),
                  Divider(
                    height: 1,
                    color: AppColors.fieldBorder,
                  ),
                  _genderOptionTile(
                    label: female,
                    value: female,
                    groupValue: temporaryGender,
                    onTap: () {
                      setModalState(() => temporaryGender = female);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() => _selectedGender = temporaryGender);
                        _checkChanges();
                        Navigator.pop(sheetContext);
                      },
                      child: Text(
                        _tr('confirm_btn', 'تأیید'),
                        style: TextStyle(
                          color: AppColors.buttonText,
                          fontSize: 15,
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

  Widget _genderOptionTile({
    required String label,
    required String value,
    required String groupValue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: AppColors.primaryBrand,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker() {
    HapticFeedback.lightImpact();

    int selectedDay = 15;
    int selectedMonthIndex = 5;
    int startYear = _isRtl ? 1340 : 1950;
    int selectedYear = _isRtl ? 1375 : 1995;

    final List<String> months = _getMonthsByLocale();

    final FixedExtentScrollController dayController =
        FixedExtentScrollController(initialItem: selectedDay - 1);

    final FixedExtentScrollController monthController =
        FixedExtentScrollController(initialItem: selectedMonthIndex);

    final FixedExtentScrollController yearController =
        FixedExtentScrollController(initialItem: selectedYear - startYear);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBgLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final int maxDays = _getMaxDays(selectedMonthIndex);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _tr('dob_label', 'تاریخ تولد'),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Row(
                      children: [
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: dayController,
                            itemExtent: 42,
                            perspective: 0.005,
                            diameterRatio: 1.3,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setModalState(() => selectedDay = index + 1);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: maxDays,
                              builder: (context, index) {
                                final bool selected = selectedDay == index + 1;

                                return Center(
                                  child: Text(
                                    formatNumberByLocale(
                                      context,
                                      '${index + 1}',
                                    ),
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      color: selected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: monthController,
                            itemExtent: 42,
                            perspective: 0.005,
                            diameterRatio: 1.3,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedMonthIndex = index;

                                final int newMaxDays = _getMaxDays(index);
                                if (selectedDay > newMaxDays) {
                                  selectedDay = newMaxDays;
                                }
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: months.length,
                              builder: (context, index) {
                                final bool selected =
                                    selectedMonthIndex == index;

                                return Center(
                                  child: Text(
                                    months[index],
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      color: selected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: yearController,
                            itemExtent: 42,
                            perspective: 0.005,
                            diameterRatio: 1.3,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setModalState(() => selectedYear = startYear + index);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 80,
                              builder: (context, index) {
                                final int year = startYear + index;
                                final bool selected = selectedYear == year;

                                return Center(
                                  child: Text(
                                    formatNumberByLocale(
                                      context,
                                      '$year',
                                    ),
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      color: selected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedDob =
                              '${formatNumberByLocale(context, '$selectedDay')} '
                              '${months[selectedMonthIndex]} '
                              '${formatNumberByLocale(context, '$selectedYear')}';
                        });

                        _checkChanges();
                        Navigator.pop(sheetContext);
                      },
                      child: Text(
                        _tr('confirm_btn', 'تأیید'),
                        style: TextStyle(
                          color: AppColors.buttonText,
                          fontSize: 15,
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

  Future<void> _showChangePhoneBottomSheet() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    final String? newPhone = await showChangePhoneSheet(context);

    if (newPhone == null || !mounted) return;

    // شماره همین حالا در حساب و دیتابیس ذخیره شده است
    _initialPhone = newPhone;
    _phoneController.text = newPhone;
    _checkChanges();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t('change_phone_success', 'شماره با موفقیت تغییر کرد')),
        backgroundColor: AppColors.primaryBrand,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.cardBgLight,
      appBar: AppBar(
        backgroundColor: AppColors.cardBgLight,
        surfaceTintColor: AppColors.cardBgLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          _tr('user_info_section_title', 'اطلاعات کاربری'),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),

      ),
      bottomNavigationBar: AnimatedPadding(
  duration: const Duration(milliseconds: 150),
  curve: Curves.easeOut,
  padding: EdgeInsets.only(
    left: 24,
    right: 24,
    top: 12,
    bottom: MediaQuery.of(context).viewInsets.bottom > 0
        ? MediaQuery.of(context).viewInsets.bottom + 12
        : MediaQuery.of(context).padding.bottom + 12,
  ),
  child: Container(
    height: 52,
    width: double.infinity,
    decoration: BoxDecoration(
      color: AppColors.cardBgLight,
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isChanged
            ? AppColors.primaryButton
            : AppColors.handle,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: _isChanged && !_isSaving ? _updateUserData : null,
      child: _isSaving
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: AppColors.buttonText,
                strokeWidth: 2,
              ),
            )
          : Text(
              _tr('save_changes_btn', 'ذخیره'),
              style: TextStyle(
                color: _isChanged ? AppColors.buttonText : AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  ),
),

            body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBrand,
              ),
            )
          : SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Center(
  child: Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.fieldBorder,
        width: 1.2,
      ),
    ),
    child: SizedBox(
      width: 62,
      height: 62,
      child: ClipOval(
        child: Image.asset(
          'assets/images/default_profile.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: AppColors.backgroundLight,
              child: Icon(
                Icons.person_rounded,
                color: AppColors.textSecondary,
                size: 32,
              ),
            );
          },
        ),
      ),
    ),
  ),
),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('main_account_info_title', 'اطلاعات اصلی'),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          controller: _nameController,
                          label: _tr(
                            'full_name_label',
                            'نام و نام خانوادگی',
                          ),
                          hintText: _tr(
                            'full_name_hint',
                            'نام و نام خانوادگی را بنویسید',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        GestureDetector(
                          onTap: _showChangePhoneBottomSheet,
                          child: AbsorbPointer(
                            child: _buildInputField(
                              controller: _phoneController,
                              label: _tr(
                                'phone_number_label',
                                'شمارهٔ موبایل',
                              ),
                              hintText: _tr(
                                'phone_hint',
                                'شمارهٔ موبایل را وارد کنید',
                              ),
                              readOnly: true,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ),
                        _buildInputField(
                          controller: _emailController,
                          label: _tr('email_label', 'ایمیل'),
                          hintText: _tr(
                            'email_hint',
                            'ایمیل آدرس',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 8,
                    width: double.infinity,
                    color: AppColors.backgroundLight,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr(
                            'sub_account_info_title',
                            'اطلاعات فرعی',
                          ),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          controller: _addressController,
                          label: _tr('address_label', 'آدرس'),
                          hintText: _tr(
                            'address_hint',
                            'اول آدرس تان را بنویسید',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        _buildSelectionField(
                          label: _tr('gender_label', 'جنسیت'),
                          hintText: _tr(
                            'gender_label',
                            'جنسیت',
                          ),
                          value: _selectedGender,
                          onTap: _showGenderPicker,
                        ),
                        _buildSelectionField(
                          label: _tr('dob_label', 'تاریخ تولد'),
                          hintText: _tr(
                            'dob_hint',
                            'تاریخ تولد را انتخاب کنید',
                          ),
                          value: _selectedDob,
                          onTap: _showDatePicker,
                        ),
                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    ); // 👈 بسته شدن Scaffold
  } // 👈 بسته شدن متد build

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    final OutlineInputBorder normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: AppColors.fieldBorder,
        width: 1.0,
      ),
    );

    final OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: AppColors.primaryBrand,
        width: 1.5,
      ),
    );

    return Padding(
      key: ValueKey('input_field_$label'),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textAlign: _isRtl ? TextAlign.right : TextAlign.left,
        scrollPadding: const EdgeInsets.only(bottom: 220),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          isDense: false,
          labelText: label,
          hintText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          floatingLabelAlignment: FloatingLabelAlignment.start,
          alignLabelWithHint: false,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
          ),
          floatingLabelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            backgroundColor: AppColors.backgroundLight,
          ),
          hintStyle: TextStyle(
            color: AppColors.handle,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 22,
          ),
          filled: true,
          fillColor: AppColors.backgroundLight,
          border: normalBorder,
          enabledBorder: normalBorder,
          disabledBorder: normalBorder,
          focusedBorder: focusedBorder,
        ),
      ),
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String hintText,
    required String value,
    required VoidCallback onTap,
  }) {
    final bool hasValue = value.trim().isNotEmpty;

    final OutlineInputBorder normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: AppColors.fieldBorder,
        width: 1.0,
      ),
      gapPadding: 4,
    );

    return Padding(
      key: ValueKey('selection_field_$label'),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: hasValue
                ? FloatingLabelBehavior.always
                : FloatingLabelBehavior.never,
            labelStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
            floatingLabelStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              backgroundColor: AppColors.backgroundLight,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 22,
            ),
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: normalBorder,
            enabledBorder: normalBorder,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? value : hintText,
                  textAlign: _isRtl ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: hasValue
                        ? AppColors.textPrimary
                        : AppColors.handle,
                    fontSize: hasValue ? 13.5 : 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.iconSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}


// -------------------------------------------------------------
// ۳. تغییر شماره با تأیید کد (بدون خروج از حساب)
// -------------------------------------------------------------

/// شمارهٔ جدید را برمی‌گرداند؛ اگر کاربر منصرف شود null.
Future<String?> showChangePhoneSheet(BuildContext context) async {
  // اگر تأیید پیامکی خاموش باشد، شماره بدون پیامک جایگزین می‌شود
  final bool verify = await phoneVerificationRequired();

  if (!context.mounted) return null;

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBgLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ChangePhoneSheet(verify: verify),
  );
}

/// شماره را به قالب بین‌المللی (+93...) درمی‌آورد؛ نامعتبر → null
String? _normalizePhone(String raw) {
  String d = toEnglishDigits(raw.trim()).replaceAll(RegExp(r'[\s\-()]'), '');

  if (d.startsWith('+')) {
    d = d.substring(1);
  } else if (d.startsWith('00')) {
    d = d.substring(2);
  } else if (d.startsWith('0')) {
    d = '93${d.substring(1)}';
  } else if (d.length == 9) {
    d = '93$d';
  }

  if (!RegExp(r'^\d{8,15}$').hasMatch(d)) return null;
  if (d.startsWith('93') && d.length != 11) return null;

  return '+$d';
}

class _ChangePhoneSheet extends StatefulWidget {
  const _ChangePhoneSheet({required this.verify});

  final bool verify;

  @override
  State<_ChangePhoneSheet> createState() => _ChangePhoneSheetState();
}

class _ChangePhoneSheetState extends State<_ChangePhoneSheet> {
  // 0: وارد کردن شمارهٔ جدید
  // 1: کد ارسال‌شده به شمارهٔ جدید
  // 2: کد ارسال‌شده به شمارهٔ فعلی (تأیید امنیتی)
  int _step = 0;

  final TextEditingController _phoneCtrl = TextEditingController(text: '+93');
  final TextEditingController _codeCtrl = TextEditingController();

  bool _busy = false;
  bool _reauthed = false;
  bool _forceReauth = false;
  String? _error;

  String _newPhone = '';
  String _verificationId = '';
  int? _resendToken;

  Timer? _timer;
  int _left = 0;

  User? get _user => FirebaseAuth.instance.currentUser;

  // اگر ورود قدیمی باشد، فایربیس برای تغییر شماره تأیید دوباره می‌خواهد
  bool get _needsReauth {
    if (_reauthed) return false;
    if (_forceReauth) return true;

    final DateTime? last = _user?.metadata.lastSignInTime;
    if (last == null) return false;

    return DateTime.now().difference(last) > const Duration(minutes: 4);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _left = 60);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (_left <= 1) {
        t.cancel();
        setState(() => _left = 0);
      } else {
        setState(() => _left--);
      }
    });
  }

  String _authMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return _t('change_phone_err_phone_invalid', 'شماره معتبر نیست. مثال: 0770123456');
      case 'invalid-verification-code':
        return _t('change_phone_err_code_invalid', 'کد وارد شده درست نیست');
      case 'session-expired':
      case 'code-expired':
      case 'invalid-verification-id':
        return _t('change_phone_err_code_expired', 'کد منقضی شده؛ دوباره ارسال کنید');
      case 'too-many-requests':
      case 'quota-exceeded':
        return _t('change_phone_err_too_many', 'تعداد تلاش‌ها زیاد است؛ کمی بعد دوباره امتحان کنید');
      case 'network-request-failed':
        return _t('change_phone_err_network', 'اتصال اینترنت را بررسی کنید');
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return _t('change_phone_err_phone_in_use', 'این شماره قبلاً با حساب دیگری ثبت شده است');
      case 'requires-recent-login':
        return _t('change_phone_err_recent_login', 'برای امنیت لازم است دوباره تأیید کنید؛ ارسال کد را بزنید');
      case 'user-mismatch':
        return _t('change_phone_err_account_mismatch', 'حساب انتخاب‌شده با حساب فعلی یکی نیست');
      default:
        return _t('change_phone_err_generic', 'خطایی رخ داد؛ دوباره تلاش کنید');
    }
  }

  // ---------------- مرحله ۰: دکمهٔ «ارسال کد» ----------------
  Future<void> _submitPhone() async {
    if (_busy) return;

    final String? phone = _normalizePhone(_phoneCtrl.text);

    if (phone == null) {
      setState(() => _error = _t('change_phone_err_phone_invalid', 'شماره معتبر نیست. مثال: 0770123456'));
      return;
    }

    final User? user = _user;
    if (user == null) {
      Navigator.pop(context);
      return;
    }

    final String? current =
        _normalizePhone((user.phoneNumber ?? '').isNotEmpty ? user.phoneNumber! : userPhone);
    if (current != null && current == phone) {
      setState(() => _error = _t('change_phone_err_phone_same', 'این شماره همان شمارهٔ فعلی شما است'));
      return;
    }

    // بدون پیامک: فقط ذخیره می‌شود و «تأییدنشده» علامت می‌خورد
    if (!widget.verify) {
      setState(() {
        _busy = true;
        _error = null;
      });

      await _saveEverywhere(user, phone, verified: false);

      if (!mounted) return;
      Navigator.pop(context, phone);
      return;
    }

    _newPhone = phone;
    _resendToken = null;

    if (_needsReauth) {
      await _startReauth(user);
    } else {
      await _sendCode(_newPhone, forNew: true);
    }
  }

  // تأیید هویت قبل از تغییر شماره
  Future<void> _startReauth(User user) async {
    final String oldPhone = user.phoneNumber ?? '';

    if (oldPhone.isNotEmpty) {
      await _sendCode(oldPhone, forNew: false);
      return;
    }

    final bool hasGoogle =
        user.providerData.any((p) => p.providerId == 'google.com');

    if (!hasGoogle) {
      // راهی برای تأیید دوباره نیست؛ مستقیم تلاش می‌کنیم
      _reauthed = true;
      await _sendCode(_newPhone, forNew: true);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final GoogleSignIn google = GoogleSignIn();
      final GoogleSignInAccount? account = await google.signIn();

      if (account == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        ),
      );

      _reauthed = true;
      _forceReauth = false;

      await _sendCode(_newPhone, forNew: true);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _authMessage(e.code);
        });
      }
    } catch (e) {
      debugPrint('Google reauth error: $e');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _t('change_phone_err_generic', 'خطایی رخ داد؛ دوباره تلاش کنید');
        });
      }
    }
  }

  // ---------------- ارسال کد پیامکی ----------------
  Future<void> _sendCode(String phone, {required bool forNew}) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) {
          // خواندن خودکار پیامک در اندروید: فقط کد را پر می‌کنیم
          final String? sms = credential.smsCode;
          if (mounted && sms != null && sms.isNotEmpty) {
            _codeCtrl.text = sms;
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _error = _authMessage(e.code);
          });
        },
        codeSent: (String id, int? token) {
          if (!mounted) return;
          setState(() {
            _verificationId = id;
            _resendToken = token;
            _busy = false;
            _step = forNew ? 1 : 2;
            _codeCtrl.clear();
          });
          _startTimer();
        },
        codeAutoRetrievalTimeout: (String id) {
          _verificationId = id;
        },
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _authMessage(e.code);
        });
      }
    } catch (e) {
      debugPrint('verifyPhoneNumber error: $e');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _t('change_phone_err_generic', 'خطایی رخ داد؛ دوباره تلاش کنید');
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_busy || _left > 0) return;

    if (_step == 2) {
      await _sendCode(_user?.phoneNumber ?? '', forNew: false);
    } else {
      await _sendCode(_newPhone, forNew: true);
    }
  }

  // ---------------- مرحله ۱ و ۲: تأیید کد ----------------
  Future<void> _confirmCode() async {
    if (_busy) return;

    final String code = toEnglishDigits(_codeCtrl.text.trim());

    if (code.length < 6 || _verificationId.isEmpty) {
      setState(() => _error = _t('change_phone_err_code_invalid', 'کد وارد شده درست نیست'));
      return;
    }

    final User? user = _user;
    if (user == null) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: code,
    );

    try {
      if (_step == 2) {
        // تأیید امنیتی با شمارهٔ فعلی؛ بعد کد به شمارهٔ جدید می‌رود
        await user.reauthenticateWithCredential(credential);

        _reauthed = true;
        _forceReauth = false;
        _resendToken = null;

        await _sendCode(_newPhone, forNew: true);
        return;
      }

      // جایگزینی شماره روی همین حساب (بدون خروج)
      await user.updatePhoneNumber(credential);
      await _saveEverywhere(user, _newPhone, verified: true);

      if (!mounted) return;
      Navigator.pop(context, _newPhone);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _busy = false;

        if (e.code == 'requires-recent-login') {
          _forceReauth = true;
          _reauthed = false;
          _step = 0;
        }

        _error = _authMessage(e.code);
      });
    } catch (e) {
      debugPrint('confirm phone error: $e');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _t('change_phone_err_generic', 'خطایی رخ داد؛ دوباره تلاش کنید');
        });
      }
    }
  }

  // شمارهٔ جدید در Firestore و Realtime Database هم جایگزین می‌شود
  Future<void> _saveEverywhere(User user, String phone, {required bool verified}) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'phone': phone, 'phoneVerified': verified}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore phone update error: $e');
    }

    try {
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .update({'phone': phone});
    } catch (e) {
      debugPrint('Realtime DB phone update error: $e');
    }

    userPhone = phone;
  }

  // ---------------- ظاهر ----------------
  InputDecoration _decoration(String label, String hint) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.fieldBorder, width: 1.0),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      counterText: '',
      labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
      hintStyle: TextStyle(color: AppColors.handle, fontSize: 13),
      filled: true,
      fillColor: AppColors.backgroundLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primaryBrand, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool codeStep = _step != 0;

    final String subtitle;
    if (_step == 0) {
      subtitle = _t(
        'change_phone_subtitle',
        'شمارهٔ جدید خود را برای دریافت کد تأیید وارد کنید.',
      );
    } else if (_step == 1) {
      subtitle = _t('change_phone_code_sent_new', 'کد تأیید به {} ارسال شد.')
          .replaceAll('{}', _newPhone);
    } else {
      subtitle = _t(
        'change_phone_code_sent_old',
        'برای امنیت، کد تأیید به شمارهٔ فعلی شما ({}) ارسال شد.',
      ).replaceAll('{}', _user?.phoneNumber ?? '');
    }

    final String buttonText = _step == 0
        ? _t('change_phone_send_code', 'ارسال کد')
        : _step == 1
            ? _t('change_phone_confirm', 'تأیید و تغییر شماره')
            : _t('continue_btn', 'ادامه');

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        right: 20,
        left: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _t('change_phone_title', 'تغییر شماره تماس'),
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 18),
            if (!codeStep)
              TextField(
                controller: _phoneCtrl,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                textDirection: ui.TextDirection.ltr,
                textAlign: TextAlign.left,
                onSubmitted: (_) => _submitPhone(),
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: _decoration(
                  _t('phone_number_label', 'شمارهٔ موبایل'),
                  '+93 7XX XXX XXX',
                ),
              )
            else ...[
              TextField(
                controller: _codeCtrl,
                enabled: !_busy,
                autofocus: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                textDirection: ui.TextDirection.ltr,
                textAlign: TextAlign.center,
                onSubmitted: (_) => _confirmCode(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _decoration(
                  _t('change_phone_code_label', 'کد تأیید'),
                  '------',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: _busy || _left > 0 ? null : _resend,
                    child: Text(
                      _left > 0
                          ? _t('change_phone_resend_in', 'ارسال دوباره تا {} ثانیه')
                              .replaceAll('{}', '$_left')
                          : _t('change_phone_resend', 'ارسال دوباره'),
                      style: TextStyle(
                        color: _left > 0
                            ? AppColors.textSecondary
                            : AppColors.primaryBrand,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_step == 1)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _step = 0;
                                _error = null;
                                _timer?.cancel();
                              }),
                      child: Text(
                        _t('change_phone_back', 'تغییر شماره'),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _busy
                    ? null
                    : (_step == 0 ? _submitPhone : _confirmCode),
                child: _busy
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.buttonText,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        buttonText,
                        style: TextStyle(
                          color: AppColors.buttonText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
