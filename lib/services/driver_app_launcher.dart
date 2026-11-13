import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// باز کردن اپ راننده سفیر (یا صفحهٔ دانلود آن).
/// از منوی کناری (Drawer) صدا زده می‌شود:
///   await DriverAppLauncher.open();
class DriverAppLauncher {
  DriverAppLauncher._();

  static final Uri _appUri = Uri.parse('safirdriver://open');
  static final Uri _storeUri =
      Uri.parse('https://safirapp.com/download-driver');

  static Future<void> open() async {
    try {
      if (await canLaunchUrl(_appUri)) {
        final bool opened = await launchUrl(
          _appUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );

        if (opened) return;
      }

      await launchUrl(
        _storeUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('خطا در باز کردن اپ راننده: $e');

      try {
        await launchUrl(
          _storeUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (fallbackError) {
        debugPrint(
          'خطا در باز کردن لینک دانلود راننده: $fallbackError',
        );
      }
    }
  }
}
