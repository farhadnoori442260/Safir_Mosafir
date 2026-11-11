import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ایمپورت‌های پکیج سفیر مسافر
import 'package:safir_passengers/appInfo/auth_provider.dart';
import 'package:safir_passengers/authentication/user_information_screen.dart';
import 'package:safir_passengers/methods/common_methods.dart';
import 'package:safir_passengers/pages/blocked_screen.dart';
import 'package:safir_passengers/pages/safir_home_screen.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/theme/app_colors.dart';

/// ارقام فارسی/عربی را به لاتین تبدیل می‌کند و فقط عدد می‌پذیرد.
/// (کاربری که با کیبورد فارسی «۰۷۸۱۲۳۴۵۶۷» بنویسد، قبلاً هیچ‌وقت معتبر شناخته نمی‌شد)
class _AsciiDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final StringBuffer buffer = StringBuffer();

    for (final int code in newValue.text.runes) {
      if (code >= 0x30 && code <= 0x39) {
        buffer.writeCharCode(code); // 0-9
      } else if (code >= 0x06F0 && code <= 0x06F9) {
        buffer.writeCharCode(0x30 + (code - 0x06F0)); // ۰-۹ فارسی
      } else if (code >= 0x0660 && code <= 0x0669) {
        buffer.writeCharCode(0x30 + (code - 0x0660)); // ٠-٩ عربی
      }
    }

    final String text = buffer.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final TextEditingController phoneController =
      TextEditingController();

  CommonMethods commonMethods = CommonMethods();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (context.locale.languageCode == 'en') {
        context.setLocale(const Locale('fa'));
      }
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  /// ترجمه با متن جایگزین (اگر کلید نبود، خود کلید نشان داده نشود)
  String _t(String key, String fallback) {
    final String v = key.tr();
    return (v.trim().isEmpty || v == key) ? fallback : v;
  }

  String _getLanguageCodeText(BuildContext context) {
    switch (context.locale.languageCode) {
      case 'ps':
        return 'PS';
      case 'en':
        return 'EN';
      case 'fa':
      default:
        return 'FA';
    }
  }

  void showLanguageBottomSheet(BuildContext context) {
    HapticFeedback.selectionClick();

    String bottomSheetTitle;

    if (context.locale.languageCode == 'ps') {
      bottomSheetTitle = 'ژبه غوره کړئ';
    } else if (context.locale.languageCode == 'en') {
      bottomSheetTitle = 'Select Language';
    } else {
      bottomSheetTitle = 'انتخاب زبان';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBgLight,
      elevation: 0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.handle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  bottomSheetTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                _buildLanguageTile(
                  context: ctx,
                  title: 'دری',
                  code: 'fa',
                ),
                const SizedBox(height: 10),
                _buildLanguageTile(
                  context: ctx,
                  title: 'پښتو',
                  code: 'ps',
                ),
                const SizedBox(height: 10),
                _buildLanguageTile(
                  context: ctx,
                  title: 'English',
                  code: 'en',
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required String title,
    required String code,
  }) {
    final bool isSelected =
        context.locale.languageCode == code;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        context.setLocale(Locale(code));
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBrand
                : AppColors.fieldBorder,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryBrand,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  bool _isPhoneValid(String input) {
    final String clean = input.trim();

    return RegExp(
      r'^0[7][0-9]{8}$',
    ).hasMatch(clean);
  }

  @override
  Widget build(BuildContext context) {
    final AuthenticationProvider authProvider =
        Provider.of<AuthenticationProvider>(context);

    final String phoneText = phoneController.text;
    final bool isValidPhone = _isPhoneValid(phoneText);

    // ۱۰ رقم وارد شده ولی با 07 شروع نمی‌شود
    final bool showPhoneError =
        phoneText.length == 10 && !isValidPhone;

    final bool canSubmit = isValidPhone && !authProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // انتخاب زبان
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Material(
                    color: AppColors.cardBgLight,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => showLanguageBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.fieldBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.language_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getLanguageCodeText(context),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // سربرگ خوش‌آمدگویی
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.cardBgLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.fieldBorder),
                      boxShadow: AppColors.isDark
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.textPrimary.withOpacity(0.07),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: Image.asset(
                        'assets/images/legacy_192.png',
                        fit: BoxFit.cover,
                        // اگر فایل در pubspec معرفی نشده بود، آیکن جایگزین
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.local_taxi_rounded,
                          color: AppColors.primaryBrand,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    _t('welcome_title', 'به سفیر خوش آمدید'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _t(
                      'enter_phone_subtitle',
                      'شمارهٔ همراه خود را وارد کنید تا کد تأیید برایتان ارسال شود',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                _buildSectionHeader(
                  context.locale.languageCode == 'en'
                      ? 'Phone Number'
                      : context.locale.languageCode == 'ps'
                          ? 'د تلیفون شمېره'
                          : 'شماره همراه',
                ),

                // کادر شماره: پیش‌شمارهٔ ثابت +93 و ورودی
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: AppColors.cardBgLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: showPhoneError
                          ? AppColors.danger
                          : isValidPhone
                              ? AppColors.primaryBrand
                              : AppColors.fieldBorder,
                      width: (showPhoneError || isValidPhone) ? 1.6 : 1.2,
                    ),
                  ),
                  child: Directionality(
                    // شماره همیشه چپ‌به‌راست: +93 | 0781234567
                    textDirection: ui.TextDirection.ltr,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: AppColors.fieldBorder),
                            ),
                          ),
                          child: Text(
                            '+93',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: phoneController,
                            autofocus: false,
                            maxLength: 10,
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [_AsciiDigitsFormatter()],
                            cursorColor: AppColors.primaryBrand,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: AppColors.textPrimary,
                            ),
                            onChanged: (_) {
                              setState(() {});
                            },
                            onFieldSubmitted: (_) {
                              if (canSubmit) sendPhoneNumber();
                            },
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '0781234567',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary
                                    .withOpacity(0.55),
                                fontSize: 16,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        if (isValidPhone)
                          Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 22,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.topCenter,
                  child: showPhoneError
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 16, color: AppColors.danger),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _t(
                                    'invalid_phone_warning',
                                    'شماره باید با 07 شروع شود و ۱۰ رقم باشد',
                                  ),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 20),

                // دکمهٔ دریافت کد
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: canSubmit ? sendPhoneNumber : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      disabledBackgroundColor: AppColors.fieldBorder,
                      foregroundColor: AppColors.buttonText,
                      disabledForegroundColor: AppColors.textSecondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.buttonText,
                            ),
                          )
                        : Text(
                            _t('get_otp_btn', 'دریافت کد تأیید'),
                            style: TextStyle(
                              color: isValidPhone
                                  ? AppColors.buttonText
                                  : AppColors.textSecondary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 26),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.fieldBorder,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        _t('or_continue_with', 'یا ادامه با'),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.fieldBorder,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ورود با گوگل
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: authProvider.isGoogleSigInLoading
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            _handleGoogleSignIn(authProvider);
                          },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.cardBgLight,
                      side: BorderSide(
                        color: AppColors.fieldBorder,
                        width: 1.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: authProvider.isGoogleSigInLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryBrand,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _GoogleGMark(),
                              const SizedBox(width: 10),
                              Text(
                                _t('google_sign_in_btn', 'ورود با گوگل'),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                Center(
                  child: Text(
                    _t(
                      'terms_and_privacy_notice',
                      'با ادامه دادن، شرایط استفاده و سیاست حریم خصوصی سفیر را می‌پذیرید.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.6,
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

  void _handleGoogleSignIn(
    AuthenticationProvider authProvider,
  ) {
    authProvider.signInWithGoogle(
      context,
      () async {
        final User? currentUser =
            authProvider.firebaseAuth.currentUser;

        if (currentUser == null) {
          if (!mounted) return;

          commonMethods.displaySnackBar(
            'google_sign_in_incomplete'.tr(),
            context,
          );
          return;
        }

        final bool userExists =
            await authProvider.checkUserExistById();

        if (!mounted) return;

        if (!userExists) {
          navigate(isSingedIn: false);
          return;
        }

        final bool isBlocked =
            await authProvider.checkIfUserIsBlocked();

        if (!mounted) return;

        if (isBlocked) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const BlockedScreen(),
            ),
            (route) => false,
          );
          return;
        }

        await authProvider
            .getUserDataFromFirebaseDatabase();

        if (!mounted) return;

        navigate(isSingedIn: true);
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  void sendPhoneNumber() {
    final AuthenticationProvider authRepo =
        Provider.of<AuthenticationProvider>(
      context,
      listen: false,
    );

    String rawPhoneNumber =
        phoneController.text.trim();

    if (rawPhoneNumber.startsWith('0')) {
      rawPhoneNumber =
          rawPhoneNumber.substring(1);
    }

    if (rawPhoneNumber.isEmpty ||
        rawPhoneNumber.length != 9 ||
        !RegExp(r'^[7][0-9]{8}$')
            .hasMatch(rawPhoneNumber)) {
      commonMethods.displaySnackBar(
        'invalid_phone_warning'.tr(),
        context,
      );
      return;
    }

    final String fullPhoneNumber =
        '+93$rawPhoneNumber';

    authRepo.signInWithPhone(
      context: context,
      phoneNumber: fullPhoneNumber,
    );
  }

  void navigate({
    required bool isSingedIn,
  }) {
    if (isSingedIn) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const SafirHomeScreen(),
        ),
        (route) => false,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const UserInformationScreen(),
        ),
      );
    }
  }
}

/// نشانهٔ «G» گوگل بدون نیاز به اینترنت.
/// (قبلاً از یک SVG اینترنتی با Image.network استفاده می‌شد که SVG را نمایش
/// نمی‌دهد و همیشه آیکن قرمز جایگزین دیده می‌شد.)
class _GoogleGMark extends StatelessWidget {
  const _GoogleGMark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) {
        return const SweepGradient(
          colors: <Color>[
            Color(0xFFEA4335), // قرمز
            Color(0xFFFBBC05), // زرد
            Color(0xFF34A853), // سبز
            Color(0xFF4285F4), // آبی
            Color(0xFFEA4335),
          ],
          stops: <double>[0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(bounds);
      },
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          height: 1.0,
          color: Colors.white,
        ),
      ),
    );
  }
}
