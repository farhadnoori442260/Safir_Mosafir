import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/theme/app_colors.dart';

/// اگر حساب شمارهٔ تأییدشده ندارد (مثلاً ورود با گوگل)، کاربر را مجبور می‌کند
/// شماره را با کد پیامکی به همان حساب وصل کند.
///
/// true  → حساب شماره دارد (از قبل یا همین حالا وصل شد)
/// false → کاربر انصراف داد؛ از حساب خارج شده است.
Future<bool> ensurePhoneLinked(BuildContext context) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  try {
    await user.reload();
  } catch (_) {}

  user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  if ((user.phoneNumber ?? '').isNotEmpty) return true;

  if (!context.mounted) return false;

  final bool? ok = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => const LinkPhoneScreen(),
    ),
  );

  return ok == true;
}

String _t(String key, String fallback) {
  final String v = key.tr();
  return v.trim().isEmpty || v == key ? fallback : v;
}

/// ارقام فارسی/عربی را به لاتین تبدیل می‌کند و فقط عدد می‌پذیرد.
class _DigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final StringBuffer b = StringBuffer();

    for (final int c in newValue.text.runes) {
      if (c >= 0x30 && c <= 0x39) {
        b.writeCharCode(c);
      } else if (c >= 0x06F0 && c <= 0x06F9) {
        b.writeCharCode(0x30 + (c - 0x06F0));
      } else if (c >= 0x0660 && c <= 0x0669) {
        b.writeCharCode(0x30 + (c - 0x0660));
      }
    }

    final String text = b.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class LinkPhoneScreen extends StatefulWidget {
  const LinkPhoneScreen({super.key});

  @override
  State<LinkPhoneScreen> createState() => _LinkPhoneScreenState();
}

class _LinkPhoneScreenState extends State<LinkPhoneScreen> {
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();

  bool _codeStep = false;
  bool _busy = false;
  String? _error;

  String _fullPhone = '';
  String _verificationId = '';
  int? _resendToken;

  Timer? _timer;
  int _left = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  bool get _phoneValid => RegExp(r'^07[0-9]{8}$').hasMatch(_phoneCtrl.text);

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

  String _message(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return _t('change_phone_err_phone_invalid',
            'شماره معتبر نیست. مثال: 0770123456');
      case 'invalid-verification-code':
        return _t('change_phone_err_code_invalid', 'کد وارد شده درست نیست');
      case 'session-expired':
      case 'code-expired':
      case 'invalid-verification-id':
        return _t('change_phone_err_code_expired',
            'کد منقضی شده؛ دوباره ارسال کنید');
      case 'too-many-requests':
      case 'quota-exceeded':
        return _t('change_phone_err_too_many',
            'تعداد تلاش‌ها زیاد است؛ کمی بعد دوباره امتحان کنید');
      case 'network-request-failed':
        return _t('change_phone_err_network', 'اتصال اینترنت را بررسی کنید');
      case 'requires-recent-login':
        return _t('link_phone_relogin',
            'لطفاً از حساب خارج شوید و دوباره با گوگل وارد شوید، سپس شماره را تأیید کنید.');
      default:
        return _t('change_phone_err_generic',
            'خطایی رخ داد؛ دوباره تلاش کنید');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (_busy) return;

    if (!resend) {
      if (!_phoneValid) {
        setState(() => _error = _t('invalid_phone_warning',
            'شماره باید با 07 شروع شود و ۱۰ رقم باشد'));
        return;
      }

      _fullPhone = '+93${_phoneCtrl.text.substring(1)}';
      _resendToken = null;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _fullPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resend ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential credential) {
          // خواندن خودکار پیامک: فقط کد را پر می‌کنیم
          final String? sms = credential.smsCode;
          if (mounted && sms != null && sms.isNotEmpty) {
            _codeCtrl.text = sms;
          }
        },
        verificationFailed: (FirebaseAuthException e) => _fail(_message(e.code)),
        codeSent: (String id, int? token) {
          if (!mounted) return;
          setState(() {
            _verificationId = id;
            _resendToken = token;
            _busy = false;
            _codeStep = true;
            _codeCtrl.clear();
          });
          _startTimer();
        },
        codeAutoRetrievalTimeout: (String id) {
          _verificationId = id;
        },
      );
    } on FirebaseAuthException catch (e) {
      _fail(_message(e.code));
    } catch (e) {
      debugPrint('link phone send error: $e');
      _fail(_message('unknown'));
    }
  }

  Future<void> _confirm() async {
    if (_busy) return;

    final String code = _codeCtrl.text.trim();
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pop(context, false);
      return;
    }

    if (code.length < 6 || _verificationId.isEmpty) {
      setState(() => _error =
          _t('change_phone_err_code_invalid', 'کد وارد شده درست نیست'));
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
      await user.linkWithCredential(credential);
      await _saveAndFinish(user.uid);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'account-exists-with-different-credential') {
        await _mergeIntoExisting(user, e.credential ?? credential);
      } else if (e.code == 'provider-already-linked') {
        await _saveAndFinish(user.uid);
      } else {
        _fail(_message(e.code));
      }
    } catch (e) {
      debugPrint('link phone confirm error: $e');
      _fail(_message('unknown'));
    }
  }

  /// این شماره قبلاً حساب دارد (مثلاً با شماره ثبت‌نام کرده بود).
  /// حساب گوگلِ تازه و خالی حذف می‌شود، با شماره وارد حساب قبلی می‌شویم
  /// و گوگل به همان حساب وصل می‌شود؛ پس همهٔ اطلاعات قبلی سر جایش می‌ماند.
  Future<void> _mergeIntoExisting(User current, AuthCredential phoneCred) async {
    try {
      // اگر همین حساب گوگل اطلاعات دارد، چیزی حذف نمی‌شود
      bool hasData = false;
      try {
        final DocumentSnapshot<Map<String, dynamic>> snap =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(current.uid)
                .get();
        hasData = snap.exists;
      } catch (_) {}

      if (hasData) {
        _fail(_t('link_phone_conflict',
            'این شماره با حساب دیگری ثبت شده است. با همان شماره وارد شوید یا شمارهٔ دیگری بزنید.'));
        return;
      }

      AuthCredential? googleCred;
      try {
        final GoogleSignIn g = GoogleSignIn();
        final GoogleSignInAccount? acc =
            g.currentUser ?? await g.signInSilently();
        final GoogleSignInAuthentication? auth = await acc?.authentication;

        if (auth != null) {
          googleCred = GoogleAuthProvider.credential(
            accessToken: auth.accessToken,
            idToken: auth.idToken,
          );
        }
      } catch (e) {
        debugPrint('google credential error: $e');
      }

      await current.delete();

      final UserCredential res =
          await FirebaseAuth.instance.signInWithCredential(phoneCred);

      final User? existing = res.user;

      if (existing != null && googleCred != null) {
        try {
          await existing.linkWithCredential(googleCred);
        } on FirebaseAuthException catch (e) {
          debugPrint('link google after merge: ${e.code}');
        }
      }

      if (existing != null) {
        userPhone = existing.phoneNumber ?? _fullPhone;
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      _fail(_message(e.code));
    } catch (e) {
      debugPrint('merge error: $e');
      _fail(_message('unknown'));
    }
  }

  Future<void> _saveAndFinish(String uid) async {
    try {
      final DocumentReference<Map<String, dynamic>> ref =
          FirebaseFirestore.instance.collection('users').doc(uid);

      final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();

      if (snap.exists) {
        await ref.set({'phone': _fullPhone}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('save linked phone error: $e');
    }

    userPhone = _fullPhone;

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _cancel() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final GoogleSignIn g = GoogleSignIn();
      await g.signOut();
      try {
        await g.disconnect();
      } catch (_) {}
    } catch (_) {}

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    userName = '';
    userPhone = '';

    if (!mounted) return;
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final bool showError = _error != null;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.cardBgLight,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Icon(
                      Icons.phone_android_rounded,
                      size: 34,
                      color: AppColors.primaryBrand,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _t('link_phone_title', 'شمارهٔ همراه را تأیید کنید'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _codeStep
                      ? _t('change_phone_code_sent_new',
                              'کد تأیید به {} ارسال شد.')
                          .replaceAll('{}', _fullPhone)
                      : _t('link_phone_subtitle',
                          'برای امنیت حساب و تماس راننده، شمارهٔ همراه شما باید به حساب وصل شود.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                if (!_codeStep)
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _phoneValid
                              ? AppColors.primaryBrand
                              : AppColors.fieldBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 16),
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
                            child: TextField(
                              controller: _phoneCtrl,
                              enabled: !_busy,
                              maxLength: 10,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              inputFormatters: [_DigitsFormatter()],
                              cursorColor: AppColors.primaryBrand,
                              textAlign: TextAlign.left,
                              onChanged: (_) => setState(() => _error = null),
                              onSubmitted: (_) => _sendCode(),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: AppColors.textPrimary,
                              ),
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
                                    horizontal: 14, vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                    inputFormatters: [_DigitsFormatter()],
                    textDirection: ui.TextDirection.ltr,
                    textAlign: TextAlign.center,
                    cursorColor: AppColors.primaryBrand,
                    onSubmitted: (_) => _confirm(),
                    style: TextStyle(
                      fontSize: 22,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '------',
                      hintStyle: TextStyle(color: AppColors.handle),
                      filled: true,
                      fillColor: AppColors.cardBgLight,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: AppColors.fieldBorder, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: AppColors.primaryBrand, width: 1.2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: AppColors.fieldBorder, width: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton(
                        onPressed:
                            _busy || _left > 0 ? null : () => _sendCode(resend: true),
                        child: Text(
                          _left > 0
                              ? _t('change_phone_resend_in',
                                      'ارسال دوباره تا {} ثانیه')
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
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _codeStep = false;
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
                if (showError) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _busy
                        ? null
                        : (_codeStep
                            ? _confirm
                            : (_phoneValid ? _sendCode : null)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      disabledBackgroundColor: AppColors.fieldBorder,
                      foregroundColor: AppColors.buttonText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _busy
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.buttonText,
                            ),
                          )
                        : Text(
                            _codeStep
                                ? _t('link_phone_continue', 'تأیید و ادامه')
                                : _t('get_otp_btn', 'دریافت کد تأیید'),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.buttonText,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _busy ? null : _cancel,
                  child: Text(
                    _t('link_phone_logout', 'انصراف و خروج از حساب'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
}
