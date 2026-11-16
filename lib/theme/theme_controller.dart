import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safir_passengers/theme/app_colors.dart';

/// انتخاب تم: روشن / تاریک / سیستم. انتخاب کاربر ذخیره می‌شود.
///
/// در حالت «خودکار» تم از تنظیم خود گوشی پیروی می‌کند و وقتی کاربر
/// تم گوشی را عوض کند (حتی وقتی اپ باز است) بلافاصله عوض می‌شود.
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const String _key = 'safir_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool _observing = false;

  Brightness get _platformBrightness =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  /// شنونده‌ی تغییر تم گوشی را فقط یک‌بار ثبت می‌کند.
  void _ensureObserving() {
    if (_observing) return;
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  /// مقدار AppColors.isDark را با حالت فعلی و روشنایی گوشی هماهنگ می‌کند.
  /// اگر مقدار عوض شده باشد true برمی‌گرداند.
  bool _syncColors() {
    final bool dark = resolveDark(_platformBrightness);
    if (AppColors.isDark == dark) return false;
    AppColors.isDark = dark;
    return true;
  }

  /// کاربر تم گوشی را عوض کرد (فقط در حالت خودکار اثر دارد).
  @override
  void didChangePlatformBrightness() {
    if (_mode != ThemeMode.system) return;
    if (_syncColors()) notifyListeners();
  }

  /// قبل از runApp صدا زده شود تا اولین فریم با تم درست بیاید.
  Future<void> load() async {
    _ensureObserving();
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString(_key)) {
        case 'light':
          _mode = ThemeMode.light;
          break;
        case 'dark':
          _mode = ThemeMode.dark;
          break;
        default:
          _mode = ThemeMode.system;
      }
    } catch (_) {}
    _syncColors();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _ensureObserving();
    _mode = mode;
    _syncColors();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        mode == ThemeMode.light
            ? 'light'
            : mode == ThemeMode.dark
                ? 'dark'
                : 'system',
      );
    } catch (_) {}
  }

  /// آیا با این حالت و روشنایی سیستم، تاریک است؟
  bool resolveDark(Brightness platform) =>
      _mode == ThemeMode.dark ||
      (_mode == ThemeMode.system && platform == Brightness.dark);
}
