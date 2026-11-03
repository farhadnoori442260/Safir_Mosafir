import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide AppInfo;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

// ایمپورت‌های پروژه سفیر مسافر
import 'global/global_var.dart';
import 'authentication/register_screen.dart';
import 'pages/blocked_screen.dart';
import 'pages/safir_home_screen.dart';
import 'pages/safir_splash_screen.dart';

// پرووایدرها
import 'appInfo/app_info.dart';
import 'appInfo/auth_provider.dart';

late Size mq;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  Stripe.publishableKey = stripePublishedKey;
  await Firebase.initializeApp();

  await Permission.locationWhenInUse.isDenied.then((valueOfPermission) {
    if (valueOfPermission) {
      Permission.locationWhenInUse.request();
    }
  });

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fa'), Locale('ps'), Locale('en')],
      path: 'assets/lang',
      startLocale: const Locale('fa'),
      fallbackLocale: const Locale('fa'),
      saveLocale: true,
      useOnlyLangCode: true,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String defaultFont = 'IranYekan';
    const Color primaryColor = Color(0xFF117656);
    const Color textColor = Color(0xFF2D3142);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppInfo()),
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
      ],
      child: MaterialApp(
        title: 'Safir Passengers',
        debugShowCheckedModeBanner: false,

        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,

        theme: ThemeData(
          useMaterial3: true,
          fontFamily: defaultFont,
          colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
          scaffoldBackgroundColor: Colors.white,

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontFamily: defaultFont,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),

          inputDecorationTheme: InputDecorationTheme(
            labelStyle: const TextStyle(
              fontFamily: defaultFont,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
            floatingLabelStyle: const TextStyle(
              fontFamily: defaultFont,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
            hintStyle: TextStyle(
              fontFamily: defaultFont,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
          ),

          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontFamily: defaultFont,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
            titleMedium: TextStyle(
              fontFamily: defaultFont,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
            bodyLarge: TextStyle(
              fontFamily: defaultFont,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
            bodyMedium: TextStyle(
              fontFamily: defaultFont,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
            bodySmall: TextStyle(
              fontFamily: defaultFont,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
            labelLarge: TextStyle(
              fontFamily: defaultFont,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),

        home: const AuthCheck(),
      ),
    );
  }
}

/// 🛡️ چک‌کننده وضعیت کاربر با اسپلش متحرک سفیر
///  • همزمان با پخش انیمیشن، وضعیت لاگین بررسی می‌شود
///  • وقتی هر دو تمام شدند، به صفحهٔ مقصد می‌رود (بدون تأخیر مصنوعی ۳ ثانیه‌ای)
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  // رنگ لوگو/آیکن (با اسپلش بومی یکی است تا پرش دیده نشود)
  static const Color safirGreen = Color(0xFF0E7A5F);

  bool _animationDone = false;
  bool _hasError = false;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  String _tr(String key, String fallback) {
    final String v = key.tr();
    return (v.trim().isEmpty || v == key) ? fallback : v;
  }

  void _checkAuth() {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      setState(() {
        _hasError = false;
        _targetScreen =
            user == null ? const RegisterScreen() : const SafirHomeScreen();
      });
    } catch (e) {
      debugPrint('AuthCheck error: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _targetScreen = null;
      });
    }
  }

  void _retry() {
    HapticFeedback.mediumImpact();
    setState(() => _hasError = false);
    _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: safirGreen,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SafirLogoMark(size: 140, backgroundColor: safirGreen),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        _tr('splash_error_msg',
                            'مشکلی در برقراری ارتباط پیش آمده است.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _retry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _tr('retry_btn', 'تلاش دوباره'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: safirGreen,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // انیمیشن تمام شده و مقصد مشخص است → برو
    if (_animationDone && _targetScreen != null) {
      return _targetScreen!;
    }

    return Scaffold(
      backgroundColor: safirGreen,
      body: Center(
        child: SafirLogoAnimation(
          key: const ValueKey('safir_logo_animation'),
          backgroundColor: safirGreen,
          onCompleted: () {
            if (!mounted) return;
            setState(() => _animationDone = true);
          },
        ),
      ),
    );
  }
}
