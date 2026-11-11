import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:safir_passengers/theme/app_colors.dart';

/// 📞 تنها منبع تماس با پشتیبانی؛ منوی کناری و صفحهٔ پروفایل هر دو از همین‌جا استفاده می‌کنند.
/// شماره از admin_settings/support.support_phone خوانده می‌شود.
class SupportService {
  SupportService._();

  static const String _fallbackPhone = '+93700000000';

  static String _t(String key, String fallback, {List<String>? args}) {
    final String v = args == null ? key.tr() : key.tr(args: args);
    return (v.trim().isEmpty || v == key) ? fallback : v;
  }

  static Future<String> _phone() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snap = await FirebaseFirestore
          .instance
          .collection('admin_settings')
          .doc('support')
          .get()
          .timeout(const Duration(seconds: 6));
      final String p = snap.data()?['support_phone']?.toString().trim() ?? '';
      if (p.isNotEmpty) return p;
    } catch (e) {
      debugPrint('Support phone read error: $e');
    }
    return _fallbackPhone;
  }

  static Future<void> call(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String phone = await _phone();

    // مستقیم تلاش می‌کنیم؛ canLaunchUrl روی اندروید ۱۱+ بدون queries در Manifest همیشه false می‌دهد
    try {
      if (await launchUrl(Uri(scheme: 'tel', path: phone))) return;
    } catch (e) {
      debugPrint('Support call error: $e');
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
        content: Text(
          _t('can_not_make_call', 'امکان تماس نبود: $phone', args: [phone]),
          style: TextStyle(
            color: AppColors.buttonText,
            fontWeight: FontWeight.w600,
          ),
        ),
        action: SnackBarAction(
          label: _t('copy', 'کپی شماره'),
          textColor: AppColors.buttonText,
          onPressed: () => Clipboard.setData(ClipboardData(text: phone)),
        ),
      ),
    );
  }
}
