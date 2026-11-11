import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:safir_passengers/appInfo/auth_provider.dart';
import 'package:safir_passengers/authentication/user_information_screen.dart';
import 'package:safir_passengers/methods/common_methods.dart';
import 'package:safir_passengers/pages/blocked_screen.dart';
import 'package:safir_passengers/pages/safir_home_screen.dart';
import 'package:safir_passengers/theme/app_colors.dart';

/// ارقام فارسی/عربی را به لاتین تبدیل می‌کند و فقط عدد می‌پذیرد.
class _AsciiDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final StringBuffer buffer = StringBuffer();

    for (final int code in newValue.text.runes) {
      if (code >= 0x30 && code <= 0x39) {
        buffer.writeCharCode(code);
      } else if (code >= 0x06F0 && code <= 0x06F9) {
        buffer.writeCharCode(0x30 + (code - 0x06F0));
      } else if (code >= 0x0660 && code <= 0x0669) {
        buffer.writeCharCode(0x30 + (code - 0x0660));
      }
    }

    final String text = buffer.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class OTPScreen extends StatefulWidget {
  final String verificationId;

  /// اختیاری: اگر داده شود، شماره زیر عنوان نشان داده می‌شود و «ارسال مجدد»
  /// کد را دوباره می‌فرستد. اگر داده نشود، «ارسال مجدد» به صفحهٔ شماره برمی‌گردد.
  final String phoneNumber;

  const OTPScreen({
    Key? key,
    required this.verificationId,
    this.phoneNumber = '',
  }) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  static const int _resendSeconds = 60;

  String? smsCode;
  CommonMethods commonMethods = CommonMethods();

  final TextEditingController _pinController = TextEditingController();

  Timer? _timer;
  int _secondsLeft = _resendSeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  /// ترجمه با متن جایگزین (اگر کلید نبود، خود کلید نشان داده نشود)
  String _t(String key, String fallback) {
    final String v = key.tr();
    return (v.trim().isEmpty || v == key) ? fallback : v;
  }

  String get _timerText {
    final int m = _secondsLeft ~/ 60;
    final int s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _resend() {
    HapticFeedback.selectionClick();

    if (widget.phoneNumber.trim().isNotEmpty) {
      final AuthenticationProvider auth =
          Provider.of<AuthenticationProvider>(context, listen: false);

      _pinController.clear();
      setState(() => smsCode = null);
      _startTimer();

      auth.signInWithPhone(
        context: context,
        phoneNumber: widget.phoneNumber.trim(),
      );
    } else {
      // شماره در دسترس نیست؛ به صفحهٔ قبل برمی‌گردیم تا دوباره درخواست شود
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<AuthenticationProvider>(context, listen: true);
    final currentLangCode = context.locale.languageCode;

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.cardBgLight,
        border: Border.all(color: AppColors.fieldBorder, width: 1.3),
      ),
    );

    final bool canVerify =
        (smsCode?.length ?? 0) == 6 && !authRepo.isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: _t('back', 'بازگشت'),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // آیکون بالای صفحه
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.cardBgLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Icon(
                    Icons.sms_rounded,
                    color: AppColors.textPrimary.withOpacity(0.8),
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // عناوین تأیید کد
              Center(
                child: Text(
                  _t('otp_title', 'کد تأیید را وارد کنید'),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _t('otp_subtitle',
                        'کد ۶ رقمی که با پیامک برایتان ارسال شد را وارد کنید'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              if (widget.phoneNumber.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    widget.phoneNumber.trim(),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // هدر بخش ورودی Pinput
              _buildSectionHeader(
                currentLangCode == 'en'
                    ? 'Verification Code'
                    : currentLangCode == 'ps'
                        ? 'د تایید کوډ'
                        : 'کد تأیید',
              ),

              // کادرهای کد؛ همیشه چپ‌به‌راست تا ترتیب ارقام به‌هم نریزد
              Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: Pinput(
                    length: 6,
                    controller: _pinController,
                    autofocus: true,
                    showCursor: true,
                    enabled: !authRepo.isLoading,
                    inputFormatters: [_AsciiDigitsFormatter()],
                    androidSmsAutofillMethod:
                        AndroidSmsAutofillMethod.smsUserConsentApi,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(
                            color: AppColors.primaryBrand, width: 2),
                      ),
                    ),
                    submittedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(
                            color: AppColors.primaryBrand, width: 1.5),
                        color: AppColors.primaryBrand.withOpacity(0.07),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => smsCode = value);
                    },
                    onCompleted: (value) {
                      setState(() => smsCode = value);
                      verifyOTP(smsCode: smsCode!);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // دکمهٔ تأیید (علاوه بر تأیید خودکار با کامل شدن کد)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: canVerify
                      ? () {
                          HapticFeedback.mediumImpact();
                          verifyOTP(smsCode: smsCode!);
                        }
                      : null,
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
                  child: authRepo.isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.buttonText,
                          ),
                        )
                      : authRepo.isSuccessful
                          ? Icon(Icons.done_rounded,
                              color: AppColors.buttonText, size: 28)
                          : Text(
                              _t('verify_btn', 'تأیید و ادامه'),
                              style: TextStyle(
                                color: canVerify
                                    ? AppColors.buttonText
                                    : AppColors.textSecondary,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 18),

              // ارسال مجدد کد با شمارندهٔ معکوس
              Center(
                child: _secondsLeft > 0
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '${_t('otp_resend_in', 'ارسال مجدد کد تا')} $_timerText',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : TextButton.icon(
                        onPressed: authRepo.isLoading ? null : _resend,
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: AppColors.primaryBrand,
                        ),
                        label: Text(
                          _t('otp_resend_btn', 'ارسال مجدد کد'),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBrand,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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

  void verifyOTP({required String smsCode}) {
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);

    authProvider.verifyOTP(
      context: context,
      verificationId: widget.verificationId,
      smsCode: smsCode,
      onSuccess: () async {
        try {
          bool userExits = await authProvider.checkUserExistById().timeout(
            const Duration(seconds: 4),
            onTimeout: () => false,
          );

          if (!mounted) return;

          if (userExits) {
            bool isBlocked = false;
            try {
              isBlocked = await authProvider.checkIfUserIsBlocked();
            } catch (e) {
              isBlocked = false;
            }

            if (isBlocked) {
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BlockedScreen()));
              return;
            }

            try {
              await authProvider.getUserDataFromFirebaseDatabase();
            } catch (e) {
              debugPrint("Error fetching passenger data: $e");
            }

            bool isUserComplete = false;
            try {
              isUserComplete = await authProvider.checkUserFieldsFilled();
            } catch (e) {
              isUserComplete = false;
            }

            if (isUserComplete) {
              navigate(isSingedIn: true);
            } else {
              navigate(isSingedIn: false);
            }
          } else {
            navigate(isSingedIn: false);
          }
        } catch (globalError) {
          navigate(isSingedIn: false);
        }
      },
    );
  }

  void navigate({required bool isSingedIn}) {
    if (isSingedIn) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const SafirHomeScreen()), (route) => false);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserInformationScreen()));
    }
  }
}
