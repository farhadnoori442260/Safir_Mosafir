import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/authentication/register_screen.dart';

class AppColors {
  static const Color primaryBrand = Color(0xFF0066FF);
  static const Color primaryButton = Color(0xFF0066FF);
  static const Color primaryButtonPressed = Color(0xFF4348D6);
  static const Color buttonText = Colors.white;
  static const Color textPrimary = Color(0xFF26293D);
  static const Color textSecondary = Color(0xFF9AA0A6);
  static const Color appBarDivider = Color(0xFFD6DADF);
  static const Color sectionDivider = Color(0xFFF1F5F9);
  static const Color fieldBorder = Color(0xFFE2E8F0);
  static const Color wheelGreen = Color(0xFF39B169);
  static const Color cardBorder = Color(0xFFE8ECEF);
}

String toEnglishDigits(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const farsi = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  for (int i = 0; i < 10; i++) {
    input = input.replaceAll(farsi[i], english[i]).replaceAll(arabic[i], english[i]);
  }
  return input;
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
    HapticFeedback.selectionClick();
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
    HapticFeedback.lightImpact();

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

  void _showBadgeDetails(String title, String description, IconData icon, Color color) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
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
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w400),
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
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
    HapticFeedback.mediumImpact();

    String title = isSwitchAccount
        ? ("switch_account_title".tr().isEmpty ? "تغییر حساب کاربری" : "switch_account_title".tr())
        : ("sign_out".tr().isEmpty ? "خروج از حساب" : "sign_out".tr());

    String content = isSwitchAccount
        ? ("switch_account_confirm_msg".tr().isEmpty ? "برای ورود با حساب دیگر، باید از حساب فعلی خارج شوید. ادامه می‌دهید؟" : "switch_account_confirm_msg".tr())
        : ("sign_out_confirm_msg".tr().isEmpty ? "آیا مایل به خروج از حساب کاربری هستید؟" : "sign_out_confirm_msg".tr());

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text(content, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text("cancel".tr().isEmpty ? "انصراف" : "cancel".tr(), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSwitchAccount ? AppColors.primaryBrand : Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text("confirm".tr().isEmpty ? "تأیید" : "confirm".tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        try {
          final GoogleSignIn googleSignIn = GoogleSignIn();
          if (await googleSignIn.isSignedIn()) {
            await googleSignIn.signOut();
          }
        } catch (e) {
          debugPrint("Google sign out error: $e");
        }

        await FirebaseAuth.instance.signOut();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "user_account_title".tr().isEmpty ? "حساب کاربری" : "user_account_title".tr(),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBrand))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE5E5E5),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/default_profile.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: Icon(Icons.person, size: 52, color: Colors.grey.shade400),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 19),
                            const SizedBox(width: 4),
                            Text(
                              formatNumberByLocale(context, _userRating),
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14.5),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder, width: 1.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.012),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "main_account_info_title".tr().isEmpty ? "اطلاعات حساب" : "main_account_info_title".tr(),
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              GestureDetector(
                                onTap: _openEditProfileDrawer,
                                child: Text(
                                  "edit".tr().isEmpty ? "ویرایش" : "edit".tr(),
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.primaryBrand),
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
                                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                formatNumberByLocale(context, _userPhone),
                                style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
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
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
                              const Color(0xFF10B981),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsetsDirectional.only(end: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.sentiment_very_satisfied_rounded,
                                      size: 26,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "badge_polite_label".tr().isEmpty ? "خوش‌رفتار" : "badge_polite_label".tr(),
                                    style: const TextStyle(
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
                              AppColors.primaryBrand,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsetsDirectional.only(start: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBrand.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.access_time_filled_rounded,
                                      size: 26,
                                      color: AppColors.primaryBrand,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "badge_punctual_label".tr().isEmpty ? "وقت‌شناس" : "badge_punctual_label".tr(),
                                    style: const TextStyle(
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
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4, fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder, width: 1.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.012),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "wheelchair_option_label".tr().isEmpty ? "از ویلچر استفاده می‌کنم" : "wheelchair_option_label".tr(),
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder, width: 1.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.012),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            leading: const Icon(Icons.switch_account_outlined, color: AppColors.primaryBrand, size: 21),
                            title: Text(
                              "switch_account_title".tr().isEmpty ? "تغییر حساب کاربری" : "switch_account_title".tr(),
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.textSecondary),
                            onTap: () => _handleLogout(isSwitchAccount: true),
                          ),
                          const Divider(height: 1, color: AppColors.cardBorder, indent: 16, endIndent: 16),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 21),
                            title: Text(
                              "exit".tr().isEmpty ? "خروج" : "exit".tr(),
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.redAccent),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
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
          backgroundColor: Colors.red,
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
      backgroundColor: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
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
                  const Divider(
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
                        style: const TextStyle(
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
              style: const TextStyle(
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
      backgroundColor: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
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
                    child: Row(
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
                        style: const TextStyle(
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

  void _showChangePhoneBottomSheet() {
    HapticFeedback.lightImpact();

    final TextEditingController newPhoneController =
        TextEditingController(text: '+93');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            right: 20,
            left: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _tr('change_phone_title', 'تغییر شماره تماس'),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _tr(
                  'change_phone_subtitle',
                  'شمارهٔ جدید خود را برای دریافت کد تأیید وارد کنید.',
                ),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: newPhoneController,
                label: _tr('phone_number_label', 'شمارهٔ موبایل'),
                hintText: '+93 7XX XXX XXX',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
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
                    final String cleaned =
                        toEnglishDigits(newPhoneController.text.trim());

                    if (cleaned.isNotEmpty && cleaned != '+93') {
                      HapticFeedback.mediumImpact();
                      _phoneController.text = cleaned;
                      _checkChanges();
                      Navigator.pop(sheetContext);
                    }
                  },
                  child: Text(
                    _tr('continue_btn', 'ادامه'),
                    style: const TextStyle(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          _tr('user_info_section_title', 'اطلاعات کاربری'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.appBarDivider,
          ),
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
    height: 48,
    width: double.infinity,
    decoration: const BoxDecoration(
      color: Colors.white,
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isChanged
            ? AppColors.primaryButton
            : Colors.grey.shade300,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: _isChanged && !_isSaving ? _updateUserData : null,
      child: _isSaving
          ? const SizedBox(
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
                color: _isChanged ? AppColors.buttonText : Colors.grey.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  ),
),

            body: _isLoading
          ? const Center(
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
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE5E5E5),
                          width: 0.8,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/default_profile.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF3F4F6),
                              child: Icon(
                                Icons.person,
                                size: 52,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
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
                          style: const TextStyle(
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
                    color: AppColors.sectionDivider,
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
                          style: const TextStyle(
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
                            'gender_hint',
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
      borderSide: const BorderSide(
        color: Color(0xFF9E9E9E),
        width: 1.0,
      ),
    );

    final OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
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
        style: const TextStyle(
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
          labelStyle: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            backgroundColor: Colors.white,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFFBDBDBD),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 22,
          ),
          filled: true,
          fillColor: Colors.white,
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
      borderSide: const BorderSide(
        color: Color(0xFF9E9E9E),
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
            labelStyle: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
            floatingLabelStyle: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              backgroundColor: Colors.white,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 22,
            ),
            filled: true,
            fillColor: Colors.white,
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
                        : const Color(0xFFBDBDBD),
                    fontSize: hasValue ? 13.5 : 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF9E9E9E),
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
 
