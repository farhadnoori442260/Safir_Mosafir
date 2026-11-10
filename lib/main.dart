import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'pages/splash_screen.dart';
import 'pages/chat_banner_service.dart';

// پرووایدرها
import 'appInfo/app_info.dart';
import 'appInfo/auth_provider.dart';
import 'theme/app_colors.dart';
import 'theme/theme_controller.dart';

late Size mq;

// دریافت پیام در پس‌زمینه
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();

  debugPrint(
    'Passenger background message received: ${message.messageId}',
  );
}

// آماده‌سازی اعلان‌های عمومی مسافران
Future<void> _setupPassengerNotifications() async {
  try {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint(
        'Passenger notifications: permission denied',
      );
      return;
    }

    await messaging.setAutoInitEnabled(true);

    // تنظیم نمایش اعلان در پیش‌زمینه برای پلتفرم‌های Apple
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // دریافت پیام در پیش‌زمینه؛ نمایش سیستمی روی Android
    // به تنظیم جداگانه نیاز دارد.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'Passenger foreground message received: ${message.messageId}',
      );
    });

    // نام این گروه با مقصد سرور Netlify یکسان است.
    await messaging.subscribeToTopic('passengers');

    debugPrint(
      'Passenger notifications: subscribed to passengers',
    );
  } catch (e) {
    // خطای اعلان نباید مانع بازشدن اپ شود.
    debugPrint(
      'Passenger notifications setup error: $e',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // تم ذخیره‌شده قبل از اولین فریم خوانده می‌شود (تا چشمک روشن→تاریک نداشته باشیم)
  await ThemeController.instance.load();
  AppColors.isDark = ThemeController.instance.resolveDark(
    WidgetsBinding.instance.platformDispatcher.platformBrightness,
  );

  Stripe.publishableKey = stripePublishedKey;
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

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

  // راه‌اندازی اعلان پس از نمایش اولین فریم برنامه
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _setupPassengerNotifications();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const String _defaultFont = 'IranYekan';

  final ThemeController _theme = ThemeController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _theme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _theme.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // کاربر در حالت «سیستم» است و روشنایی گوشی عوض شد
  @override
  void didChangePlatformBrightness() {
    if (_theme.mode == ThemeMode.system) _onThemeChanged();
  }

  void _onThemeChanged() {
    final bool dark = _theme.resolveDark(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
    if (dark == AppColors.isDark) return;

    // ۱) پالت جدید فعال می‌شود
    AppColors.isDark = dark;

    // ۲) همهٔ المان‌ها (حتی const ها) دوباره ساخته می‌شوند؛ پشتهٔ صفحه‌ها و
    //    state ها دست‌نخورده می‌مانند. چون MyApp از همه بالاتر است، همین فریم
    //    با رنگ‌های جدید ساخته می‌شود.
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    if (mounted) {
      setState(() {});
      (context as Element).visitChildren(mark);
    }
  }

  ThemeData _buildTheme(bool dark) {
    final Color primary = dark ? const Color(0xFF34B27F) : const Color(0xFF117656);
    final Color bg = dark ? const Color(0xFF0F1412) : Colors.white;
    final Color surface = dark ? const Color(0xFF1A211E) : Colors.white;
    final Color title = dark ? const Color(0xFFECF1EF) : const Color(0xFF212121);
    final Color body = dark ? const Color(0xFFD5DEDA) : const Color(0xFF2D3142);
    final Color muted = dark ? const Color(0xFF9AA8A1) : Colors.grey;
    final Color line = dark ? const Color(0xFF2B3631) : Colors.grey.shade300;

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      fontFamily: _defaultFont,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF117656),
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(primary: primary, surface: surface),
      scaffoldBackgroundColor: bg,
      canvasColor: surface,
      dialogBackgroundColor: surface,
      dividerColor: line,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: title),
        titleTextStyle: TextStyle(
          fontFamily: _defaultFont,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: title,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(
          fontFamily: _defaultFont,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: muted,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: _defaultFont,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        hintStyle: TextStyle(
          fontFamily: _defaultFont,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: dark ? const Color(0xFF6F7C76) : Colors.grey.shade400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontFamily: _defaultFont,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: title,
        ),
        titleMedium: TextStyle(
          fontFamily: _defaultFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: title,
        ),
        bodyLarge: TextStyle(
          fontFamily: _defaultFont,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: body,
        ),
        bodyMedium: TextStyle(
          fontFamily: _defaultFont,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: body,
        ),
        bodySmall: TextStyle(
          fontFamily: _defaultFont,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: muted,
        ),
        labelLarge: const TextStyle(
          fontFamily: _defaultFont,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = AppColors.isDark;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppInfo()),
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
      ],
      child: MaterialApp(
        // کلید ناوبری برای نمایش بنر پیام راننده در کل اپ
        navigatorKey: ChatBannerService.instance.navigatorKey,
        title: 'Safir Passengers',
        debugShowCheckedModeBanner: false,

        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,

        // تم را خودمان با AppColors.isDark تعیین می‌کنیم (روشن/تاریک/سیستم
        // قبلاً در ThemeController حل شده)
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        theme: _buildTheme(false),
        darkTheme: _buildTheme(true),

        // رنگ آیکون‌های نوار وضعیت و نوار پایین متناسب با تم
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  dark ? Brightness.light : Brightness.dark,
              statusBarBrightness: dark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness:
                  dark ? Brightness.light : Brightness.dark,
              systemNavigationBarContrastEnforced: false,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },

        home: const AuthCheck(),
      ),
    );
  }
}

/// 🛡️ چک‌کننده وضعیت کاربر با اسپلش متحرک سفیر
///  • همزمان با پخش انیمیشن، وضعیت لاگین بررسی می‌شود
///  • وقتی هر دو تمام شدند، به صفحهٔ مقصد می‌رود
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  // رنگ لوگو/آیکن، هماهنگ با اسپلش بومی
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
                    const SafirLogoMark(
                      size: 140,
                      backgroundColor: safirGreen,
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        _tr(
                          'splash_error_msg',
                          'مشکلی در برقراری ارتباط پیش آمده است.',
                        ),
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
