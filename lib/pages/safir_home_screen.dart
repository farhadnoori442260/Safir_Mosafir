import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/appInfo/auth_provider.dart';
import 'package:safir_passengers/pages/blocked_screen.dart';
import 'package:safir_passengers/authentication/register_screen.dart';

import 'map_screen.dart';

/// صفحهٔ اصلی اپ.
/// حالا صفحهٔ هوم همان صفحهٔ نقشه است؛ با «startAtHome» باتم‌شیت اول
/// (انتخاب سرویس) نشان داده می‌شود و با انتخاب هر سرویس، فقط باتم‌شیت
/// عوض می‌شود و نقشه دوباره ساخته نمی‌شود.
class SafirHomeScreen extends StatefulWidget {
  const SafirHomeScreen({super.key});

  @override
  State<SafirHomeScreen> createState() => _SafirHomeScreenState();
}

class _SafirHomeScreenState extends State<SafirHomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
    _checkUserStatusInBackground();
  }

  Future<void> _checkUserStatusInBackground() async {
    try {
      final authProvider = Provider.of<AuthenticationProvider>(
        context,
        listen: false,
      );

      final bool isBlocked =
          await authProvider.checkIfUserIsBlocked().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );

      if (!mounted) return;

      if (isBlocked) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BlockedScreen(),
          ),
        );
        return;
      }

      final bool isFilled =
          await authProvider.checkUserFieldsFilled().timeout(
        const Duration(seconds: 3),
        onTimeout: () => true,
      );

      if (!mounted) return;

      if (!isFilled) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RegisterScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('خطا در بررسی پس‌زمینه کاربر: $e');
    }
  }

  Future<void> _loadCurrentUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final DatabaseReference usersRef =
          FirebaseDatabase.instance.ref().child('users').child(user.uid);

      final DatabaseEvent event = await usersRef.once();

      if (!mounted) return;

      final Object? value = event.snapshot.value;

      if (value is Map) {
        setState(() {
          userName = value['name'] ?? userName;
          userPhone = value['phone'] ?? userPhone;
        });
      }
    } catch (e) {
      debugPrint('خطا در دریافت اطلاعات از فایربیس: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SafirMapScreen(
      serviceType: 'taxi',
      startAtHome: true,
    );
  }
}

/// بخش مستقل تبلیغات؛ وقتی خالی است هیچ چیزی نشان نمی‌دهد.
/// (برای سازگاری با جاهای دیگر پروژه نگه داشته شده است.)
class HomeAdvertisementsSection extends StatelessWidget {
  const HomeAdvertisementsSection({
    super.key,
    this.advertisements = const <Widget>[],
  });

  final List<Widget> advertisements;

  @override
  Widget build(BuildContext context) {
    if (advertisements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int index = 0; index < advertisements.length; index++) ...[
            if (index > 0) const SizedBox(height: 14),
            advertisements[index],
          ],
        ],
      ),
    );
  }
}
