import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🎁 تنها منبع کد دعوت؛ هم صفحهٔ «دعوت دوستان» و هم منوی پروفایل از همین‌جا می‌خوانند.
class ReferralService {
  ReferralService._();

  static String get code {
    final User? user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid.length >= 6
        ? user.uid.substring(0, 6).toUpperCase()
        : 'SAFIR2026';
  }

  static String get shareMessage {
    final String c = code;
    final String v = 'invite_message'.tr(args: [c]);
    return (v.trim().isEmpty || v == 'invite_message')
        ? 'با سفیر سفر کنید! کد دعوت من: $c'
        : v;
  }
}
