import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart'
    hide TextDirection;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import 'package:safir_passengers/appInfo/auth_provider.dart';
import 'package:safir_passengers/authentication/user_information_screen.dart';
import 'package:safir_passengers/pages/blocked_screen.dart';
import 'package:safir_passengers/pages/safir_home_screen.dart';
import 'package:safir_passengers/theme/app_colors.dart';

/// ارقام فارسی و عربی را به لاتین تبدیل می‌کند.
class _AsciiDigitsFormatter extends TextInputFormatter {
  String _normalize(String value) {
    final buffer = StringBuffer();

    for (final code in value.runes) {
      if (code >= 0x30 && code <= 0x39) {
        buffer.writeCharCode(code);
      } else if (code >= 0x06F0 && code <= 0x06F9) {
        buffer.writeCharCode(0x30 + code - 0x06F0);
      } else if (code >= 0x0660 && code <= 0x0669) {
        buffer.writeCharCode(0x30 + code - 0x0660);
      }
    }

    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = _normalize(newValue.text);

    final originalOffset = newValue.selection.extentOffset;
    final safeOffset = originalOffset
        .clamp(0, newValue.text.length)
        .toInt();

    final offset = _normalize(
      newValue.text.substring(0, safeOffset),
    ).length;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: offset.clamp(0, text.length).toInt(),
      ),
      composing: TextRange.empty,
    );
  }
}

class OTPScreen extends StatefulWidget {
  const OTPScreen({
    super.key,
    required this.verificationId,
    this.phoneNumber = '',
  });

  final String verificationId;
  final String phoneNumber;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen>
    with WidgetsBindingObserver {
  static const int _resendSeconds = 60;

  final TextEditingController _pinController =
      TextEditingController();

  final FocusNode _pinFocusNode = FocusNode();

  Timer? _timer;
  DateTime? _resendAvailableAt;

  late String _verificationId;

  int? _resendToken;
  int _secondsLeft = _resendSeconds;
  int _resendRequest = 0;

  bool _resending = false;
  bool _verifying = false;
  bool _checkingAccount = false;
  bool _authenticated = false;
  bool _navigated = false;

  static const Map<String, List<String>> _fallbacks = {
    'back': [
      'بازگشت',
      'شاته',
      'Back',
    ],
    'otp_title': [
      'کد تأیید را وارد کنید',
      'د تایید کوډ دننه کړئ',
      'Enter verification code',
    ],
    'otp_subtitle': [
      'کد ۶ رقمی ارسال‌شده با پیامک را وارد کنید',
      'د پیغام له لارې استول شوی شپږ عددي کوډ دننه کړئ',
      'Enter the six-digit code sent by SMS',
    ],
    'otp_code_label': [
      'کد تأیید',
      'د تایید کوډ',
      'Verification code',
    ],
    'verify_btn': [
      'تأیید و ادامه',
      'تایید او دوام',
      'Verify and continue',
    ],
    'otp_resend_in': [
      'ارسال مجدد کد تا',
      'د کوډ بیا لېږل په',
      'Resend code in',
    ],
    'otp_resend_btn': [
      'ارسال مجدد کد',
      'کوډ بیا ولېږئ',
      'Resend code',
    ],
    'otp_sent': [
      'کد جدید ارسال شد',
      'نوی کوډ واستول شو',
      'A new code has been sent',
    ],
    'otp_error': [
      'عملیات انجام نشد؛ دوباره تلاش کنید.',
      'عملیات ترسره نه شول؛ بیا هڅه وکړئ.',
      'Something went wrong. Please try again.',
    ],
    'otp_network_error': [
      'ارتباط با سرور برقرار نشد؛ اینترنت را بررسی و دوباره تلاش کنید.',
      'له سرور سره اړیکه ټینګه نه شوه؛ انټرنېټ وګورئ او بیا هڅه وکړئ.',
      'Could not reach the server. Check your connection and try again.',
    ],
    'otp_invalid_code': [
      'کد تأیید نادرست است.',
      'د تایید کوډ ناسم دی.',
      'The verification code is incorrect.',
    ],
    'otp_expired': [
      'کد منقضی شده است؛ کد جدید درخواست کنید.',
      'د کوډ وخت پای ته رسېدلی؛ نوی کوډ وغواړئ.',
      'The code has expired. Request a new code.',
    ],
    'otp_too_many_requests': [
      'درخواست‌ها زیاد است؛ کمی بعد دوباره تلاش کنید.',
      'غوښتنې ډېرې دي؛ لږ وروسته بیا هڅه وکړئ.',
      'Too many requests. Please try again later.',
    ],
    'otp_invalid_phone': [
      'شمارهٔ تلفن معتبر نیست.',
      'د ټیلیفون شمېره سمه نه ده.',
      'The phone number is invalid.',
    ],
    'otp_retry_account': [
      'بررسی دوبارهٔ حساب',
      'حساب بیا وګورئ',
      'Retry account check',
    ],
  };

  @override
  void initState() {
    super.initState();

    _verificationId = widget.verificationId;

    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _timer?.cancel();
    _pinFocusNode.dispose();
    _pinController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateCountdown();
    }
  }

  String _t(String key) {
    final translated = context.tr(key);

    if (translated.trim().isNotEmpty && translated != key) {
      return translated;
    }

    final values = _fallbacks[key];
    if (values == null) return key;

    switch (context.locale.languageCode) {
      case 'ps':
        return values[1];
      case 'en':
        return values[2];
      default:
        return values[0];
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _resendAvailableAt = DateTime.now().add(
      const Duration(seconds: _resendSeconds),
    );

    _secondsLeft = _resendSeconds;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    if (!mounted || _resendAvailableAt == null) return;

    final milliseconds = _resendAvailableAt!
        .difference(DateTime.now())
        .inMilliseconds;

    final remaining = milliseconds <= 0
        ? 0
        : (milliseconds / 1000).ceil();

    if (remaining != _secondsLeft) {
      setState(() => _secondsLeft = remaining);
    }

    if (remaining == 0) {
      _timer?.cancel();
    }
  }

  String get _timerText {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  String _firebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-verification-code':
        return _t('otp_invalid_code');

      case 'session-expired':
      case 'code-expired':
      case 'invalid-verification-id':
        return _t('otp_expired');

      case 'too-many-requests':
      case 'quota-exceeded':
        return _t('otp_too_many_requests');

      case 'invalid-phone-number':
        return _t('otp_invalid_phone');

      case 'network-request-failed':
        return _t('otp_network_error');

      default:
        return _t('otp_error');
    }
  }

  bool get _localBusy =>
      _resending ||
      _verifying ||
      _checkingAccount ||
      _navigated;

  Future<void> _resend() async {
    final auth = context.read<AuthenticationProvider>();

    if (_localBusy ||
        auth.isLoading ||
        _secondsLeft > 0 ||
        _authenticated) {
      return;
    }

    final phone = widget.phoneNumber.trim();

    if (phone.isEmpty) {
      await Navigator.of(context).maybePop();
      return;
    }

    HapticFeedback.selectionClick();

    final request = ++_resendRequest;

    setState(() => _resending = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          if (!mounted ||
              request != _resendRequest ||
              _navigated ||
              _authenticated ||
              _verifying) {
            return;
          }

          setState(() {
            _resending = false;
            _verifying = true;
          });

          try {
            await FirebaseAuth.instance.signInWithCredential(
              credential,
            );

            if (!mounted) return;

            _authenticated = true;
            await _finishSignIn();
          } on FirebaseAuthException catch (error) {
            if (mounted) {
              _showMessage(_firebaseError(error));
            }
          } catch (error) {
            debugPrint('Automatic OTP verification error: $error');

            if (mounted) {
              _showMessage(_t('otp_error'));
            }
          } finally {
            if (mounted) {
              setState(() => _verifying = false);
            }
          }
        },
        verificationFailed: (error) {
          if (!mounted ||
              request != _resendRequest ||
              _navigated ||
              _authenticated) {
            return;
          }

          setState(() => _resending = false);
          _showMessage(_firebaseError(error));
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted ||
              request != _resendRequest ||
              _navigated ||
              _authenticated) {
            return;
          }

          _pinController.clear();

          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _resending = false;
            _startTimer();
          });

          _pinFocusNode.requestFocus();
          _showMessage(_t('otp_sent'));
        },
        codeAutoRetrievalTimeout: (_) {
          if (!mounted ||
              request != _resendRequest ||
              _navigated ||
              _authenticated) {
            return;
          }

          if (_resending) {
            setState(() => _resending = false);
          }
        },
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted || request != _resendRequest) return;

      setState(() => _resending = false);
      _showMessage(_firebaseError(error));
    } catch (error) {
      debugPrint('Resend OTP error: $error');

      if (!mounted || request != _resendRequest) return;

      setState(() => _resending = false);
      _showMessage(_t('otp_error'));
    }
  }

  Future<void> _verify(String code) async {
    final auth = context.read<AuthenticationProvider>();

    if (_localBusy || auth.isLoading || _authenticated) {
      return;
    }

    final normalized = code.trim();

    if (!RegExp(r'^[0-9]{6}$').hasMatch(normalized)) {
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    setState(() => _verifying = true);

    try {
      // حفظ مسیر تأیید فعلی AuthenticationProvider پروژه.
      // Future.sync با خروجی void یا Future<void> سازگار است.
      await Future<void>.sync(() {
        return auth.verifyOTP(
          context: context,
          verificationId: _verificationId,
          smsCode: normalized,
          onSuccess: () async {
            if (!mounted || _navigated || _authenticated) {
              return;
            }

            _authenticated = true;
            await _finishSignIn();
          },
        );
      });
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        _showMessage(_firebaseError(error));
      }
    } catch (error) {
      debugPrint('OTP verification error: $error');

      if (mounted) {
        _showMessage(_t('otp_error'));
      }
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  Future<void> _finishSignIn() async {
    if (!mounted || _checkingAccount || _navigated) {
      return;
    }

    final auth = context.read<AuthenticationProvider>();

    setState(() => _checkingAccount = true);

    try {
      final exists = await auth.checkUserExistById().timeout(
        const Duration(seconds: 15),
      );

      if (!mounted) return;

      if (!exists) {
        _navigate(const UserInformationScreen());
        return;
      }

      // خطای ارتباط نباید به معنی «مسدود نیست» تلقی شود.
      final blocked = await auth.checkIfUserIsBlocked().timeout(
        const Duration(seconds: 15),
      );

      if (!mounted) return;

      if (blocked) {
        _navigate(const BlockedScreen());
        return;
      }

      await auth.getUserDataFromFirebaseDatabase().timeout(
        const Duration(seconds: 15),
      );

      if (!mounted) return;

      final complete = await auth.checkUserFieldsFilled().timeout(
        const Duration(seconds: 15),
      );

      if (!mounted) return;

      if (complete) {
        _navigate(const SafirHomeScreen());
      } else {
        _navigate(const UserInformationScreen());
      }
    } catch (error) {
      debugPrint('OTP account check error: $error');

      if (mounted) {
        _showMessage(_t('otp_network_error'));
      }
    } finally {
      if (mounted) {
        setState(() => _checkingAccount = false);
      }
    }
  }

  void _navigate(Widget page) {
    if (!mounted || _navigated) return;

    _navigated = true;
    _timer?.cancel();

    FocusScope.of(context).unfocus();

    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => page,
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthenticationProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;
    final background = theme.scaffoldBackgroundColor;
    final surface = scheme.surface;
    final text = scheme.onSurface;
    final secondary = text.withOpacity(0.66);
    final border = text.withOpacity(isDark ? 0.18 : 0.15);

    final brand = isDark
        ? Color.lerp(
            AppColors.primaryBrand,
            Colors.white,
            0.25,
          )!
        : AppColors.primaryBrand;

    final busy = _localBusy || auth.isLoading;

    final validCode = RegExp(r'^[0-9]{6}$').hasMatch(
      _pinController.text,
    );

    final canContinue = !busy && (_authenticated || validCode);

    final defaultPinTheme = PinTheme(
      width: 46,
      height: 56,
      textStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: text,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: surface,
        border: Border.all(
          color: border,
          width: 1.3,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: _t('back'),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: text,
          ),
          onPressed: busy
              ? null
              : () async {
                  await Navigator.of(context).maybePop();
                },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: border),
                      ),
                      child: Icon(
                        Icons.sms_rounded,
                        color: brand,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _t('otp_title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: text,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    child: Text(
                      _t('otp_subtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: secondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  if (widget.phoneNumber.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.phoneNumber.trim(),
                      textAlign: TextAlign.center,
                      textDirection: ui.TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: text,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: Text(
                      _t('otp_code_label'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: text,
                      ),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // جلوگیری از خروج شش کادر از عرض صفحه.
                      final pinWidth =
                          ((constraints.maxWidth - 40) / 6)
                              .clamp(1.0, 46.0)
                              .toDouble();

                      final pinTheme = defaultPinTheme.copyWith(
                        width: pinWidth,
                      );

                      return Directionality(
                        textDirection: ui.TextDirection.ltr,
                        child: Pinput(
                          length: 6,
                          controller: _pinController,
                          focusNode: _pinFocusNode,
                          autofocus: true,
                          showCursor: true,
                          enabled: !busy && !_authenticated,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            _AsciiDigitsFormatter(),
                            LengthLimitingTextInputFormatter(6),
                          ],
                          defaultPinTheme: pinTheme,
                          focusedPinTheme: pinTheme.copyWith(
                            decoration:
                                pinTheme.decoration!.copyWith(
                              border: Border.all(
                                color: brand,
                                width: 2,
                              ),
                            ),
                          ),
                          submittedPinTheme: pinTheme.copyWith(
                            decoration:
                                pinTheme.decoration!.copyWith(
                              border: Border.all(
                                color: brand,
                                width: 1.5,
                              ),
                              color: brand.withOpacity(0.07),
                            ),
                          ),
                          onChanged: (_) {
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          onCompleted: (value) {
                            _verify(value);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canContinue
                          ? () {
                              if (_authenticated) {
                                _finishSignIn();
                              } else {
                                _verify(_pinController.text);
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                        foregroundColor: AppColors.buttonText,
                        disabledBackgroundColor: border,
                        disabledForegroundColor: secondary,
                        minimumSize: const Size(0, 54),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: busy
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.buttonText,
                              ),
                            )
                          : Text(
                              _authenticated
                                  ? _t('otp_retry_account')
                                  : _t('verify_btn'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!_authenticated)
                    Center(
                      child: _secondsLeft > 0
                          ? Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment:
                                  WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 18,
                                  color: secondary,
                                ),
                                Text(
                                  _t('otp_resend_in'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: secondary,
                                  ),
                                ),
                                Text(
                                  _timerText,
                                  textDirection:
                                      ui.TextDirection.ltr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: secondary,
                                  ),
                                ),
                              ],
                            )
                          : TextButton.icon(
                              onPressed: busy ? null : _resend,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                              ),
                              label: Text(
                                _t('otp_resend_btn'),
                                textAlign: TextAlign.center,
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: brand,
                              ),
                            ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
