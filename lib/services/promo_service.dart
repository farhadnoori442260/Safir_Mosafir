import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// نتیجهٔ بررسی یک کد تخفیف
class PromoValidation {
  final bool isValid;

  /// پیام برای کاربر (خطا یا توضیح تخفیف، مثلاً «۱۰٪ تخفیف»)
  final String message;

  const PromoValidation(this.isValid, this.message);
}

/// 🎟️ تنها منبع کد تخفیف در کل اپ.
/// هم شیت نقشه و هم منوی پروفایل از همین‌جا استفاده می‌کنند.
///
/// ساختار Firestore:
///   promo_codes/{CODE}  ← شناسهٔ سند = خود کد با حروف بزرگ
///     active: bool, type: 'percent' | 'fixed', value: number,
///     expires_at: Timestamp (اختیاری), max_uses: number (اختیاری),
///     used_count: number (اختیاری)
///   users/{uid}.pending_promo_code ← کدی که کاربر ثبت کرده و هنوز در سفری استفاده نشده
class PromoService {
  PromoService._();

  static String _t(String key, String fallback) {
    final String v = key.tr();
    return (v.trim().isEmpty || v == key) ? fallback : v;
  }

  static DocumentReference<Map<String, dynamic>>? get _userDoc {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  static Future<PromoValidation> validate(String rawCode) async {
    final String code = rawCode.trim().toUpperCase();
    final String failed =
        _t('promo_check_failed', 'بررسی کد انجام نشد، دوباره تلاش کنید');

    if (code.isEmpty) {
      return PromoValidation(false, _t('enter_discount_code', 'کد تخفیف را وارد کنید'));
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance
              .collection('promo_codes')
              .doc(code)
              .get()
              .timeout(const Duration(seconds: 8));

      final Map<String, dynamic>? data = doc.data();

      if (!doc.exists || data == null) {
        return PromoValidation(
            false, _t('promo_invalid', 'کد تخفیف نامعتبر است'));
      }

      final bool active = data['active'] != false;
      final Object? expires = data['expires_at'];
      final bool expired =
          expires is Timestamp && expires.toDate().isBefore(DateTime.now());

      if (!active || expired) {
        return PromoValidation(
            false, _t('promo_expired', 'مهلت این کد تخفیف تمام شده است'));
      }

      final num? maxUses = data['max_uses'] is num ? data['max_uses'] as num : null;
      final num used = data['used_count'] is num ? data['used_count'] as num : 0;

      if (maxUses != null && used >= maxUses) {
        return PromoValidation(
            false, _t('promo_used_up', 'ظرفیت استفادهٔ این کد تکمیل شده است'));
      }

      final String type = data['type']?.toString().toLowerCase() ?? '';
      final num? value = data['value'] is num ? data['value'] as num : null;

      String summary = _t('promo_valid', 'کد تخفیف معتبر است');
      if (value != null && value > 0) {
        final String word = _t('promo_discount_word', 'تخفیف');
        summary = type == 'percent'
            ? '${value.toStringAsFixed(0)}٪ $word'
            : '${value.toStringAsFixed(0)} ${_t('afn', 'افغانی')} $word';
      }
      return PromoValidation(true, summary);
    } catch (e) {
      debugPrint('Promo check error: $e');
      return PromoValidation(false, failed);
    }
  }

  /// کد تأییدشده را برای سفر بعدی نگه می‌دارد
  static Future<void> savePending(String code) async {
    try {
      await _userDoc?.set(
        <String, dynamic>{'pending_promo_code': code.trim().toUpperCase()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Save pending promo error: $e');
    }
  }

  static Future<String?> loadPending() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>>? snap =
          await _userDoc?.get();
      final String code = snap?.data()?['pending_promo_code']?.toString() ?? '';
      if (code.isEmpty) return null;

      // هنوز معتبر است؟ (ممکن است بین دو سفر منقضی شده باشد)
      final PromoValidation v = await validate(code);
      if (!v.isValid) {
        await clearPending();
        return null;
      }
      return code;
    } catch (e) {
      debugPrint('Load pending promo error: $e');
      return null;
    }
  }

  static Future<void> clearPending() async {
    try {
      await _userDoc?.set(
        <String, dynamic>{'pending_promo_code': FieldValue.delete()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Clear pending promo error: $e');
    }
  }
}
