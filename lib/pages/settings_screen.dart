import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safir_passengers/theme/app_colors.dart';
import 'package:safir_passengers/theme/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  final String currentLanguage;
  final ValueChanged<String>? onLanguageChanged;

  const SettingsScreen({
    super.key,
    this.currentLanguage = 'fa',
    this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableNotifications = true;
  bool _enableSoundEffects = true;
  bool _isLoadingCache = false;

  Color get _blue => AppColors.isDark
      ? const Color(0xFF78A7FF)
      : const Color(0xFF3478DB);

  Color get _purple => AppColors.isDark
      ? const Color(0xFFB49AFF)
      : const Color(0xFF8158CF);

  Color get _orange => AppColors.isDark
      ? const Color(0xFFF5B65B)
      : const Color(0xFFC97A14);

  Color get _red => AppColors.danger;

  Color get _buttonBlue => const Color(0xFF306FD6);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  String _localized(String key, String fallback) {
    final String value = key.tr();

    return value.trim().isEmpty || value == key
        ? fallback
        : value;
  }

  Future<void> _loadSettings() async {
    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _enableNotifications =
            prefs.getBool('enable_notifications') ?? true;

        _enableSoundEffects =
            prefs.getBool('enable_sounds') ?? true;
      });
    } catch (e) {
      debugPrint('خطا در دریافت تنظیمات: $e');
    }
  }

  Future<void> _toggleNotification(bool value) async {
    if (!mounted) return;

    HapticFeedback.selectionClick();

    setState(() => _enableNotifications = value);

    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool('enable_notifications', value);
    } catch (e) {
      debugPrint('خطا در ذخیره تنظیم اعلان‌ها: $e');
    }
  }

  Future<void> _toggleSound(bool value) async {
    if (!mounted) return;

    HapticFeedback.selectionClick();

    setState(() => _enableSoundEffects = value);

    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool('enable_sounds', value);
    } catch (e) {
      debugPrint('خطا در ذخیره تنظیم صدا: $e');
    }
  }

  Future<void> _applyLanguageChange(String langCode) async {
    try {
      await context.setLocale(Locale(langCode));

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setString('selected_language', langCode);

      if (!mounted) return;

      widget.onLanguageChanged?.call(langCode);
      setState(() {});
    } catch (e) {
      debugPrint('خطا در تغییر زبان: $e');

      if (!mounted) return;

      _showMessage(
        _localized(
          'language_change_failed',
          'تغییر زبان انجام نشد، دوباره تلاش کنید',
        ),
        backgroundColor: AppColors.danger,
      );
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'pa':
      case 'ps':
        return _localized('lang_pashto', 'پښتو');

      case 'en':
        return _localized('lang_english', 'English');

      default:
        return _localized('lang_dari', 'فارسی / دری');
    }
  }

  ButtonStyle get _dialogButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: _buttonBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 11,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showLanguageDialog() {
    final String currentLang = context.locale.languageCode;

    String selectedTempLang =
        currentLang == 'pa' || currentLang == 'ps'
            ? 'ps'
            : currentLang == 'en'
                ? 'en'
                : 'fa';

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBgLight,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    color: _blue,
                    size: 27,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _localized(
                        'select_language_title',
                        'انتخاب زبان',
                      ),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageRadio(
                    title: _localized(
                      'lang_dari',
                      'فارسی / دری',
                    ),
                    value: 'fa',
                    groupValue: selectedTempLang,
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedTempLang = value;
                      });
                    },
                  ),
                  _dialogDivider(),
                  _buildLanguageRadio(
                    title: _localized(
                      'lang_pashto',
                      'پښتو',
                    ),
                    value: 'ps',
                    groupValue: selectedTempLang,
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedTempLang = value;
                      });
                    },
                  ),
                  _dialogDivider(),
                  _buildLanguageRadio(
                    title: _localized(
                      'lang_english',
                      'English',
                    ),
                    value: 'en',
                    groupValue: selectedTempLang,
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedTempLang = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    _localized('cancel', 'انصراف'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: _dialogButtonStyle,
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _applyLanguageChange(selectedTempLang);
                  },
                  child: Text(
                    _localized('confirm', 'تایید'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.fieldBorder,
    );
  }

  Widget _buildLanguageRadio({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      value: value,
      groupValue: groupValue,
      activeColor: _blue,
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }

  Future<void> _performClearCache() async {
    if (_isLoadingCache || !mounted) return;

    setState(() => _isLoadingCache = true);

    try {
      final Directory tempDir = await getTemporaryDirectory();
      bool hadFailure = false;

      if (await tempDir.exists()) {
        await for (final FileSystemEntity entity
            in tempDir.list(followLinks: false)) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            hadFailure = true;
            debugPrint('خطا در حذف فایل موقت: $e');
          }
        }
      }

      if (!mounted) return;

      if (hadFailure) {
        _showMessage(
          _localized(
            'cache_clear_partial_msg',
            'برخی فایل‌های موقت در حال استفاده بودند و پاک نشدند',
          ),
          backgroundColor: const Color(0xFF9A6417),
        );
      } else {
        _showMessage(
          _localized(
            'cache_cleared_msg',
            'حافظه موقت با موفقیت پاکسازی شد',
          ),
          backgroundColor: _buttonBlue,
        );
      }
    } catch (e) {
      debugPrint('خطا در پاکسازی کش: $e');

      if (!mounted) return;

      _showMessage(
        _localized(
          'error_occurred',
          'پاکسازی حافظه موقت انجام نشد',
        ),
        backgroundColor: AppColors.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingCache = false);
      }
    }
  }

  void _clearCacheDialog() {
    HapticFeedback.mediumImpact();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBgLight,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Icon(
                Icons.cleaning_services_rounded,
                color: _purple,
                size: 27,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _localized(
                    'clear_cache_title',
                    'پاکسازی حافظه موقت',
                  ),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _localized(
              'clear_cache_desc',
              'آیا از پاکسازی فایل‌های موقت برنامه اطمینان دارید؟',
            ),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                _localized('cancel', 'انصراف'),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: _dialogButtonStyle,
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _performClearCache();
              },
              child: Text(
                _localized('confirm', 'تایید'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLegalDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBgLight,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            8,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            8,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            12,
          ),
          title: Row(
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                content,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.85,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                _localized('close', 'بستن'),
                style: TextStyle(
                  color: _blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showServicesDialog() {
    _showLegalDialog(
      title: _localized(
        'services_safir_title',
        'خدمات سفیر',
      ),
      icon: Icons.local_taxi_rounded,
      iconColor: _orange,
      content: _localized(
        'services_safir_content',
        '''
سفیر یک پلتفرم حمل‌ونقل شهری است که ارتباط میان مسافران و رانندگان را ساده‌تر می‌سازد.

مسافران می‌توانند مبدأ و مقصد سفر را ثبت کنند، درخواست سفر بفرستند، وضعیت سفر را مشاهده کنند، اطلاعات کلی راننده و وسیلهٔ نقلیه را ببینند، سوابق سفر را بررسی کنند و مشکلات خود را از بخش پشتیبانی گزارش دهند.

رانندگان می‌توانند اطلاعات هویتی، گواهینامه و اطلاعات وسیلهٔ نقلیه را ثبت کنند، درخواست‌های سفر را مدیریت کنند، وضعیت سفر را به‌روزرسانی کنند و سوابق و درآمدهای خود را مشاهده کنند.

برخی امکانات ممکن است بر اساس شهر، وضعیت اینترنت، دسترسی راننده، نسخهٔ برنامه یا قوانین محلی در دسترس نباشند. سفیر تلاش می‌کند خدمات را به‌صورت منظم و قابل‌اعتماد ارائه کند، اما امکان اختلال موقت در اثر شرایط فنی یا عوامل خارج از کنترل وجود دارد.
''',
      ),
    );
  }

  void _showTermsDialog() {
    _showLegalDialog(
      title: _localized(
        'terms_conditions_title',
        'شرایط و قوانین استفاده',
      ),
      icon: Icons.description_rounded,
      iconColor: _blue,
      content: _localized(
        'terms_conditions_content',
        '''
با ایجاد حساب، ورود یا استفاده از اپلیکیشن سفیر، شما این شرایط و قوانین را می‌پذیرید. اگر با بخشی از این قوانین موافق نیستید، لطفاً از خدمات سفیر استفاده نکنید.

۱. حساب کاربری
کاربر باید اطلاعات صحیح، کامل و به‌روز وارد کند و مسئول حفظ امنیت شماره تلفن، کد ورود و حساب خود است.

۲. درخواست سفر
ثبت درخواست سفر به معنای تضمین پذیرش آن نیست.

۳. رفتار کاربران
مسافر و راننده باید با احترام رفتار کنند.

۴. مسئولیت راننده
راننده باید مدارک، گواهینامه و اطلاعات وسیلهٔ نقلیه را صحیح ثبت کند.

۵. کرایه و پرداخت
کرایه ممکن است بر اساس مسیر، زمان، مسافت، تعرفه و شرایط سفر تعیین شود.

۶. لغو سفر
لغو مکرر یا غیرموجه سفر توسط مسافر یا راننده ممکن است باعث محدودشدن حساب شود.

۷. محدودسازی حساب
سفیر می‌تواند در صورت تقلب، نقض قوانین یا سوءاستفاده از خدمات، حساب را مسدود کند.
''',
      ),
    );
  }

  void _showPrivacyDialog() {
    _showLegalDialog(
      title: _localized(
        'privacy_policy_title',
        'حریم خصوصی و داده‌ها',
      ),
      icon: Icons.privacy_tip_rounded,
      iconColor: _purple,
      content: _localized(
        'privacy_policy_content',
        '''
حریم خصوصی کاربران برای سفیر مهم است. این برنامه ممکن است فقط برای ارائه و بهبود خدمات، اطلاعات لازم را دریافت و پردازش کند.

۱. اطلاعاتی که ممکن است دریافت شود
اطلاعات حساب مانند نام، شماره تلفن، ایمیل، اطلاعات سفر و موقعیت مکانی.

۲. موقعیت مکانی
برای ثبت درخواست سفر، تعیین مبدأ و مقصد و نمایش مسیر استفاده می‌شود.

۳. استفاده از داده‌ها
اطلاعات فقط برای ایجاد و مدیریت حساب، انجام سفر و پشتیبانی استفاده می‌شود.

۴. اشتراک‌گذاری اطلاعات
اطلاعات ضروری سفر ممکن است میان مسافر و راننده به اشتراک گذاشته شود.
''',
      ),
    );
  }

  void _showAboutDialog() {
    _showLegalDialog(
      title: _localized(
        'about_app_title',
        'دربارهٔ اپلیکیشن',
      ),
      icon: Icons.info_rounded,
      iconColor: AppColors.iconSecondary,
      content: _localized(
        'about_app_content',
        '''
سفیر یک اپلیکیشن حمل‌ونقل شهری است که برای آسان‌ترشدن ثبت و مدیریت سفر طراحی شده است.

هدف ما ایجاد ارتباطی ساده‌تر میان مسافران و رانندگان و دسترسی سریع‌تر به خدمات سفر است.

نسخهٔ برنامه:
v1.0.0 (Safir Passengers)
''',
      ),
    );
  }

  void _showDeleteAccountDialog() {
    _showLegalDialog(
      title: _localized(
        'delete_account_title',
        'حذف حساب و داده‌ها',
      ),
      icon: Icons.delete_forever_rounded,
      iconColor: _red,
      content: _localized(
        'delete_account_content',
        '''
شما حق دارید درخواست حذف حساب سفیر و داده‌های مرتبط با آن را ثبت کنید.

در فرایند حذف، اطلاعات مرتبط با حساب بررسی می‌شوند. ممکن است برخی اطلاعات فقط در صورت ضرورت قانونی یا جلوگیری از تقلب برای مدت محدود حفظ شوند.
''',
      ),
    );
  }

  void _showMessage(
    String message, {
    required Color backgroundColor,
  }) {
    if (!mounted) return;

    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentLangCode =
        context.locale.languageCode;

    final bool isRtl = currentLangCode != 'en';

    final IconData chevronIcon = isRtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

    return Directionality(
      textDirection: isRtl
          ? ui.TextDirection.rtl
          : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            _localized('settings_title', 'تنظیمات'),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            tooltip: _localized('back', 'بازگشت'),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              10,
              16,
              28,
            ),
            children: [
              _buildSectionHeader(
                _localized(
                  'general_settings_header',
                  'عمومی',
                ),
              ),
              _buildCardGroup([
                _SettingsTile(
                  icon: Icons.language_rounded,
                  accent: _blue,
                  title: _localized(
                    'app_language_label',
                    'زبان برنامه',
                  ),
                  subtitle:
                      '${_localized('current_language_prefix', 'زبان فعلی')}: '
                      '${_getLanguageName(currentLangCode)}',
                  trailing: _buildChevron(chevronIcon),
                  onTap: _showLanguageDialog,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(
                _localized(
                  'appearance_header',
                  'ظاهر برنامه',
                ),
              ),
              _buildCardGroup([
                _buildThemeSelector(),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(
                _localized(
                  'notifications_header',
                  'اعلانات و صداها',
                ),
              ),
              _buildCardGroup([
                _buildSettingSwitchTile(
                  icon: Icons.notifications_active_rounded,
                  accent: _orange,
                  title: _localized(
                    'enable_notifications_label',
                    'دریافت اعلانات',
                  ),
                  value: _enableNotifications,
                  onChanged: _toggleNotification,
                ),
                _buildSettingSwitchTile(
                  icon: Icons.volume_up_rounded,
                  accent: _purple,
                  title: _localized(
                    'enable_sounds_label',
                    'افکت‌های صوتی',
                  ),
                  value: _enableSoundEffects,
                  onChanged: _toggleSound,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(
                _localized(
                  'privacy_cache_header',
                  'حافظه و داده‌ها',
                ),
              ),
              _buildCardGroup([
                _SettingsTile(
                  icon: Icons.cleaning_services_rounded,
                  accent: _purple,
                  loading: _isLoadingCache,
                  title: _localized(
                    'clear_cache_btn',
                    'پاکسازی حافظه موقت',
                  ),
                  subtitle: _localized(
                    'clear_cache_subtitle',
                    'آزادسازی فضای اشغال‌شده توسط عکس‌ها و نقشه‌ها',
                  ),
                  trailing: _buildChevron(chevronIcon),
                  onTap: _isLoadingCache
                      ? null
                      : _clearCacheDialog,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(
                _localized(
                  'about_safir_header',
                  'درباره سفیر',
                ),
              ),
              _buildCardGroup([
                _SettingsTile(
                  icon: Icons.local_taxi_rounded,
                  accent: _orange,
                  title: _localized(
                    'services_safir_title',
                    'خدمات سفیر',
                  ),
                  subtitle: _localized(
                    'services_safir_sub',
                    'امکانات و خدمات مسافر و راننده',
                  ),
                  trailing: _buildChevron(chevronIcon),
                  onTap: _showServicesDialog,
                ),
                _SettingsTile(
                  icon: Icons.description_rounded,
                  accent: _blue,
                  title: _localized(
                    'terms_conditions_title',
                    'شرایط و قوانین استفاده',
                  ),
                  subtitle: _localized(
                    'terms_conditions_sub',
                    'حقوق، مسئولیت‌ها و قوانین سفر',
                  ),
                  trailing: _buildChevron(chevronIcon),
                  onTap: _showTermsDialog,
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  accent: _purple,
                  title: _localized(
                    'privacy_policy_title',
                    'حریم خصوصی و داده‌ها',
                  ),
                  subtitle: _localized(
                    'privacy_policy_sub',
                    'نحوهٔ دریافت، استفاده و نگهداری اطلاعات',
                  ),
                  trailing: _buildChevron(chevronIcon),
                  onTap: _showPrivacyDialog,
                ),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  accent: _red,
                  title: _localized(
                    'delete_account_title',
                    'حذف حساب و داده‌ها',
                  ),
                  subtitle: _localized(
                    'delete_account_sub',
                    'راهنمای ثبت درخواست حذف حساب',
                  ),
                  trailing: _buildChevron(chevronIcon),
                  onTap: _showDeleteAccountDialog,
                ),
                _SettingsTile(
                  icon: Icons.info_rounded,
                  accent: AppColors.iconSecondary,
                  title: _localized(
                    'about_app_title',
                    'دربارهٔ اپلیکیشن',
                  ),
                  subtitle: _localized(
                    'about_app_sub',
                    'معرفی سفیر و نسخهٔ برنامه',
                  ),
                  trailing: _buildChevron(chevronIcon),
                  onTap: _showAboutDialog,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChevron(IconData icon) {
    return Icon(
      icon,
      size: 21,
      color: AppColors.iconSecondary.withOpacity(0.65),
    );
  }

  Widget _buildSettingSwitchTile({
    required IconData icon,
    required Color accent,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _SettingsTile(
      icon: icon,
      accent: accent,
      title: title,
      trailing: _ModernSwitch(
        value: value,
        activeColor: AppColors.primaryBrand,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildThemeSelector() {
    final ThemeMode mode = ThemeController.instance.mode;

    final options = <MapEntry<ThemeMode, String>>[
      MapEntry(
        ThemeMode.system,
        _localized('theme_system', 'خودکار'),
      ),
      MapEntry(
        ThemeMode.light,
        _localized('theme_light', 'روشن'),
      ),
      MapEntry(
        ThemeMode.dark,
        _localized('theme_dark', 'تاریک'),
      ),
    ];

    final icons = <ThemeMode, IconData>{
      ThemeMode.system: Icons.brightness_auto_rounded,
      ThemeMode.light: Icons.light_mode_rounded,
      ThemeMode.dark: Icons.dark_mode_rounded,
    };

    final colors = <ThemeMode, Color>{
      ThemeMode.system: _blue,
      ThemeMode.light: _orange,
      ThemeMode.dark: _purple,
    };

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _buildThemeOption(
                mode: options[i].key,
                selected: mode == options[i].key,
                label: options[i].value,
                icon: icons[options[i].key]!,
                iconColor: colors[options[i].key]!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required ThemeMode mode,
    required bool selected,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: selected
            ? AppColors.backgroundLight
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();

            ThemeController.instance.setMode(mode);

            if (mounted) {
              setState(() {});
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 25,
                  color: iconColor,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 20 : 6,
                  height: 3,
                  decoration: BoxDecoration(
                    color: selected
                        ? _blue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 8,
        end: 8,
        bottom: 11,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    final String languageCode = context.locale.languageCode;
    final bool isRtl = languageCode != 'en';

    final List<Widget> rows = [];

    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(
            height: 1,
            thickness: 0.5,
            indent: isRtl ? 16 : 68,
            endIndent: isRtl ? 68 : 16,
            color: AppColors.fieldBorder.withOpacity(0.65),
          ),
        );
      }

      rows.add(children[i]);
    }

    return Material(
      color: AppColors.cardBgLight,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }
}

class _ModernSwitch extends StatelessWidget {
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _ModernSwitch({
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: activeColor,
        inactiveThumbColor: AppColors.isDark
            ? const Color(0xFFD6D6D6)
            : Colors.white,
        inactiveTrackColor: AppColors.isDark
            ? const Color(0xFF505050)
            : const Color(0xFFBDBDBD),
        materialTapTargetSize:
            MaterialTapTargetSize.padded,
      ),
    );
  }
}

/// آیکن رنگی بدون مربع یا زمینه.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool loading;

  const _SettingsTile({
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: accent.withOpacity(0.10),
      highlightColor: accent.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: accent,
                        ),
                      )
                    : Icon(
                        icon,
                        color: accent,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
