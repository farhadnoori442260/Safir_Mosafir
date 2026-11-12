import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:safir_passengers/theme/app_colors.dart';
import 'package:safir_passengers/theme/theme_controller.dart';

// لینک واقعی صفحات سفیر را بین کوتیشن‌ها وارد کن.
const String _safirFacebookUrl = '';
const String _safirInstagramUrl = '';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _enableNotifications =
          prefs.getBool('enable_notifications') ?? true;
      _enableSoundEffects = prefs.getBool('enable_sounds') ?? true;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    HapticFeedback.selectionClick();

    setState(() {
      _enableNotifications = value;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notifications', value);
  }

  Future<void> _toggleSound(bool value) async {
    HapticFeedback.selectionClick();

    setState(() {
      _enableSoundEffects = value;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_sounds', value);
  }

  Future<void> _applyLanguageChange(String langCode) async {
    await context.setLocale(Locale(langCode));

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', langCode);

    widget.onLanguageChanged?.call(langCode);

    if (!mounted) return;
    setState(() {});
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'pa':
      case 'ps':
        final String value = 'lang_pashto'.tr();
        return value.isEmpty ? 'پښتو' : value;

      case 'en':
        final String value = 'lang_english'.tr();
        return value.isEmpty ? 'English' : value;

      case 'fa':
      case 'dr':
      default:
        final String value = 'lang_dari'.tr();
        return value.isEmpty ? 'فارسی / دری' : value;
    }
  }

  String _localized(String key, String fallback) {
    final String value = key.tr();
    return value.isEmpty || value == key ? fallback : value;
  }

  void _showLanguageDialog() {
    final String currentLang = context.locale.languageCode;

    String selectedTempLang =
        (currentLang == 'pa' || currentLang == 'ps')
            ? 'ps'
            : currentLang == 'en'
                ? 'en'
                : 'fa';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            return AlertDialog(
              backgroundColor: AppColors.cardBgLight,
              surfaceTintColor: AppColors.cardBgLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _localized('select_language_title', 'انتخاب زبان'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageRadio(
                    title: _localized('lang_dari', 'فارسی / دری'),
                    value: 'fa',
                    groupValue: selectedTempLang,
                    onChanged: (String? value) {
                      if (value == null) return;
                      setDialogState(() => selectedTempLang = value);
                    },
                  ),
                  Divider(height: 1, color: AppColors.fieldBorder),
                  _buildLanguageRadio(
                    title: _localized('lang_pashto', 'پښتو'),
                    value: 'ps',
                    groupValue: selectedTempLang,
                    onChanged: (String? value) {
                      if (value == null) return;
                      setDialogState(() => selectedTempLang = value);
                    },
                  ),
                  Divider(height: 1, color: AppColors.fieldBorder),
                  _buildLanguageRadio(
                    title: _localized('lang_english', 'English'),
                    value: 'en',
                    groupValue: selectedTempLang,
                    onChanged: (String? value) {
                      if (value == null) return;
                      setDialogState(() => selectedTempLang = value);
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBrand,
                    foregroundColor: AppColors.buttonText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _applyLanguageChange(selectedTempLang);
                  },
                  child: Text(
                    _localized('confirm', 'تایید'),
                    style: const TextStyle(
                      fontSize: 14,
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

  Widget _buildLanguageRadio({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.primaryBrand,
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }

  Future<void> _performClearCache() async {
    if (_isLoadingCache) return;

    setState(() => _isLoadingCache = true);

    try {
      final Directory tempDir = await getTemporaryDirectory();

      if (await tempDir.exists()) {
        // فقط محتوای پوشه حذف می‌شود، نه خود پوشه.
        await for (final FileSystemEntity entity in tempDir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }

      if (!mounted) return;

      _showMessage(
        _localized(
          'cache_cleared_msg',
          'حافظه موقت با موفقیت پاکسازی شد',
        ),
        backgroundColor: AppColors.success,
      );
    } catch (error) {
      debugPrint('خطا در پاکسازی کش: $error');

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

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBgLight,
          surfaceTintColor: AppColors.cardBgLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _localized('clear_cache_title', 'پاکسازی حافظه موقت'),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            _localized(
              'clear_cache_desc',
              'آیا از پاکسازی فایل‌های موقت برنامه اطمینان دارید؟',
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                _localized('cancel', 'انصراف'),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrand,
                foregroundColor: AppColors.buttonText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _performClearCache();
              },
              child: Text(
                _localized('confirm', 'تایید'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // این متد اکنون به‌جای دیالوگ، صفحه تمام‌صفحه باز می‌کند.
  void _showLegalDialog({
    required String title,
    required IconData icon,
    required String content,
    Color? accentColor,
    bool isAbout = false,
  }) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => _SafirInformationScreen(
          title: title,
          icon: icon,
          content: content,
          accentColor: accentColor ?? AppColors.primaryBrand,
          isAbout: isAbout,
        ),
      ),
    );
  }

  void _showServicesDialog() {
    _showLegalDialog(
      title: _localized('services_safir_title', 'خدمات سفیر'),
      icon: Icons.local_taxi_rounded,
      accentColor: const Color(0xFFF59E0B),
      content: _localized(
        'services_safir_content',
        """سفیر یک پلتفرم حمل‌ونقل شهری است که ارتباط میان مسافران و رانندگان را ساده‌تر می‌سازد.

مسافران می‌توانند مبدأ و مقصد سفر را ثبت کنند، درخواست سفر بفرستند، وضعیت سفر را مشاهده کنند، اطلاعات کلی راننده و وسیلهٔ نقلیه را ببینند، سوابق سفر را بررسی کنند و مشکلات خود را از بخش پشتیبانی گزارش دهند.

رانندگان می‌توانند اطلاعات هویتی، گواهینامه و اطلاعات وسیلهٔ نقلیه را ثبت کنند، درخواست‌های سفر را مدیریت کنند، وضعیت سفر را به‌روزرسانی کنند و سوابق و درآمدهای خود را مشاهده کنند.

برخی امکانات ممکن است بر اساس شهر، وضعیت اینترنت، دسترسی راننده، نسخهٔ برنامه یا قوانین محلی در دسترس نباشند. سفیر تلاش می‌کند خدمات را به‌صورت منظم و قابل‌اعتماد ارائه کند، اما امکان اختلال موقت در اثر شرایط فنی یا عوامل خارج از کنترل وجود دارد.""",
      ),
    );
  }

  void _showTermsDialog() {
    _showLegalDialog(
      title: _localized('terms_conditions_title', 'شرایط و قوانین استفاده'),
      icon: Icons.description_outlined,
      accentColor: const Color(0xFF6366F1),
      content: _localized(
        'terms_conditions_content',
        """با ایجاد حساب، ورود یا استفاده از اپلیکیشن سفیر، شما این شرایط و قوانین را می‌پذیرید. اگر با بخشی از این قوانین موافق نیستید، لطفاً از خدمات سفیر استفاده نکنید.

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
سفیر می‌تواند در صورت تقلب، نقض قوانین یا سوءاستفاده از خدمات، حساب را مسدود کند.""",
      ),
    );
  }

  void _showPrivacyDialog() {
    _showLegalDialog(
      title: _localized('privacy_policy_title', 'حریم خصوصی و داده‌ها'),
      icon: Icons.privacy_tip_outlined,
      accentColor: const Color(0xFF8B5CF6),
      content: _localized(
        'privacy_policy_content',
        """حریم خصوصی کاربران برای سفیر مهم است. این برنامه ممکن است فقط برای ارائه و بهبود خدمات، اطلاعات لازم را دریافت و پردازش کند.

۱. اطلاعاتی که ممکن است دریافت شود
اطلاعات حساب مانند نام، شماره تلفن، ایمیل، اطلاعات سفر و موقعیت مکانی.

۲. موقعیت مکانی
برای ثبت درخواست سفر، تعیین مبدأ و مقصد و نمایش مسیر استفاده می‌شود.

۳. استفاده از داده‌ها
اطلاعات فقط برای ایجاد و مدیریت حساب، انجام سفر و پشتیبانی استفاده می‌شود.

۴. اشتراک‌گذاری اطلاعات
اطلاعات ضروری سفر ممکن است میان مسافر و راننده به اشتراک گذاشته شود.""",
      ),
    );
  }

  void _showAboutDialog() {
    _showLegalDialog(
      title: _localized('about_app_title', 'دربارهٔ اپلیکیشن'),
      icon: Icons.info_outline_rounded,
      accentColor: const Color(0xFF0EA5E9),
      isAbout: true,
      content: _localized(
        'about_app_content',
        """سفیر یک اپلیکیشن حمل‌ونقل شهری است که برای آسان‌ترشدن ثبت و مدیریت سفر طراحی شده است.

هدف ما ایجاد ارتباطی ساده‌تر میان مسافران و رانندگان و دسترسی سریع‌تر به خدمات سفر است.

نسخهٔ برنامه:
v1.0.0 (Safir Passengers)""",
      ),
    );
  }

  void _showDeleteAccountDialog() {
    _showLegalDialog(
      title: _localized('delete_account_title', 'حذف حساب و داده‌ها'),
      icon: Icons.delete_forever_outlined,
      accentColor: AppColors.danger,
      content: _localized(
        'delete_account_content',
        """شما حق دارید درخواست حذف حساب سفیر و داده‌های مرتبط با آن را ثبت کنید.

در فرایند حذف، اطلاعات مرتبط با حساب بررسی می‌شوند. ممکن است برخی اطلاعات فقط در صورت ضرورت قانونی یا جلوگیری از تقلب برای مدت محدود حفظ شوند.""",
      ),
    );
  }

  void _showMessage(
    String message, {
    required Color backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentLangCode = context.locale.languageCode;
    final bool isRtl = currentLangCode != 'en';

    final IconData chevronIcon = isRtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

    return Directionality(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          surfaceTintColor: AppColors.backgroundLight,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            _localized('settings_title', 'تنظیمات'),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              isRtl
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
          children: [
            _buildSectionHeader(
              _localized('general_settings_header', 'عمومی'),
            ),
            _buildCardGroup([
              _SettingsTile(
                leading: const Icon(
                  Icons.language_rounded,
                  color: Color(0xFF3B82F6),
                ),
                title: Text(
                  _localized('app_language_label', 'زبان برنامه'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${_localized('current_language_prefix', 'زبان فعلی')}: '
                  '${_getLanguageName(currentLangCode)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: Icon(chevronIcon, color: AppColors.handle),
                onTap: _showLanguageDialog,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader(
              _localized('appearance_header', 'ظاهر برنامه'),
            ),
            _buildCardGroup([_buildThemeSelector()]),
            const SizedBox(height: 24),
            _buildSectionHeader(
              _localized('notifications_header', 'اعلانات و صداها'),
            ),
            _buildCardGroup([
              _buildSettingSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: _localized(
                  'enable_notifications_label',
                  'دریافت اعلانات',
                ),
                value: _enableNotifications,
                onChanged: _toggleNotification,
              ),
              Divider(
                height: 1,
                indent: 70,
                color: AppColors.fieldBorder,
              ),
              _buildSettingSwitchTile(
                icon: Icons.volume_up_outlined,
                title: _localized('enable_sounds_label', 'افکت‌های صوتی'),
                value: _enableSoundEffects,
                onChanged: _toggleSound,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader(
              _localized('privacy_cache_header', 'حافظه و داده‌ها'),
            ),
            _buildCardGroup([
              _SettingsTile(
                leading: _isLoadingCache
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryBrand,
                        ),
                      )
                    : const Icon(
                        Icons.cleaning_services_outlined,
                        color: Color(0xFFEC4899),
                      ),
                title: Text(
                  _localized('clear_cache_btn', 'پاکسازی حافظه موقت'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  _localized(
                    'clear_cache_subtitle',
                    'آزادسازی فضای اشغال‌شده توسط عکس‌ها و نقشه‌ها',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: Icon(chevronIcon, color: AppColors.handle),
                onTap: _isLoadingCache ? null : _clearCacheDialog,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader(
              _localized('about_safir_header', 'درباره سفیر'),
            ),
            _buildCardGroup([
              _SettingsTile(
                leading: const Icon(
                  Icons.local_taxi_rounded,
                  color: Color(0xFFF59E0B),
                ),
                title: Text(
                  _localized('services_safir_title', 'خدمات سفیر'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  _localized(
                    'services_safir_sub',
                    'امکانات و خدمات مسافر و راننده',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(chevronIcon, color: AppColors.handle),
                onTap: _showServicesDialog,
              ),
              Divider(
                height: 1,
                indent: 70,
                color: AppColors.fieldBorder,
              ),
              _SettingsTile(
                leading: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF6366F1),
                ),
                title: Text(
                  _localized(
                    'terms_conditions_title',
                    'شرایط و قوانین استفاده',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  _localized(
                    'terms_conditions_sub',
                    'حقوق، مسئولیت‌ها و قوانین سفر',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(chevronIcon, color: AppColors.handle),
                onTap: _showTermsDialog,
              ),
              Divider(
                height: 1,
                indent: 70,
                color: AppColors.fieldBorder,
              ),
              _SettingsTile(
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Color(0xFF8B5CF6),
                ),
                title: Text(
                  _localized(
                    'privacy_policy_title',
                    'حریم خصوصی و داده‌ها',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  _localized(
                    'privacy_policy_sub',
                    'نحوهٔ دریافت، استفاده و نگهداری اطلاعات',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(chevronIcon, color: AppColors.handle),
                onTap: _showPrivacyDialog,
              ),
              Divider(
                height: 1,
                indent: 70,
                color: AppColors.fieldBorder,
              ),
              _SettingsTile(
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: Color(0xFFEF4444),
                ),
                title: Text(
                  _localized(
                    'delete_account_title',
                    'حذف حساب و داده‌ها',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  _localized(
                    'delete_account_sub',
                    'راهنمای ثبت درخواست حذف حساب',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(chevronIcon, color: AppColors.handle),
                accent: AppColors.danger,
                onTap: _showDeleteAccountDialog,
              ),
              Divider(
                height: 1,
                indent: 70,
                color: AppColors.fieldBorder,
              ),
              _SettingsTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF0EA5E9),
                ),
                title: Text(
                  _localized('about_app_title', 'دربارهٔ اپلیکیشن'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  _localized(
                    'about_app_sub',
                    'معرفی سفیر و نسخهٔ برنامه',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(chevronIcon, color: AppColors.handle),
                onTap: _showAboutDialog,
              ),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _SettingsTile(
      leading: Icon(
        icon,
        color: icon == Icons.notifications_active_outlined
            ? const Color(0xFFF97316)
            : const Color(0xFFA855F7),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: _ModernSwitch(
        value: value,
        activeColor: AppColors.primaryBrand,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildThemeSelector() {
    final mode = ThemeController.instance.mode;

    final options = <MapEntry<ThemeMode, List<Object>>>[
      MapEntry(
        ThemeMode.system,
        [
          Icons.brightness_auto_rounded,
          _localized('theme_system', 'خودکار'),
        ],
      ),
      MapEntry(
        ThemeMode.light,
        [
          Icons.light_mode_rounded,
          _localized('theme_light', 'روشن'),
        ],
      ),
      MapEntry(
        ThemeMode.dark,
        [
          Icons.dark_mode_rounded,
          _localized('theme_dark', 'تاریک'),
        ],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (final o in options)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ThemeController.instance.setMode(o.key);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: mode == o.key
                          ? AppColors.primaryButton
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          o.value[0] as IconData,
                          size: 18,
                          color: mode == o.key
                              ? AppColors.buttonText
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          o.value[1] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: mode == o.key
                                ? AppColors.buttonText
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
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
    return Semantics(
      button: true,
      toggled: value,
      label: value
          ? _localizedKey('switch_active', 'فعال')
          : _localizedKey('switch_inactive', 'غیرفعال'),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 44,
          height: 25,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? activeColor : AppColors.fieldBorder,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: value ? activeColor : AppColors.borderLight,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment:
                value ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                color: AppColors.buttonText,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _localizedKey(String key, String fallback) {
    final String value = key.tr();
    return value.isEmpty || value == key ? fallback : value;
  }
}

/// ردیف تنظیمات: آیکن رنگی بدون کادر.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.accent,
  });

  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color accent = this.accent ?? AppColors.primaryBrand;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(color: accent, size: 27),
                    child: leading,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      subtitle!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// صفحه مشترک برای پنج بخش اطلاعاتی سفیر.
class _SafirInformationScreen extends StatelessWidget {
  const _SafirInformationScreen({
    required this.title,
    required this.icon,
    required this.content,
    required this.accentColor,
    this.isAbout = false,
  });

  final String title;
  final IconData icon;
  final String content;
  final Color accentColor;
  final bool isAbout;

  String _followUsLabel(BuildContext context) {
    final String value = 'follow_us'.tr();

    if (value.isNotEmpty && value != 'follow_us') {
      return value;
    }

    switch (context.locale.languageCode) {
      case 'en':
        return 'Follow us';
      case 'ps':
      case 'pa':
        return 'موږ تعقیب کړئ';
      default:
        return 'ما را دنبال کنید';
    }
  }

  String _linkErrorLabel(BuildContext context) {
    final String value = 'social_link_error'.tr();

    if (value.isNotEmpty && value != 'social_link_error') {
      return value;
    }

    switch (context.locale.languageCode) {
      case 'en':
        return 'Unable to open the link.';
      case 'ps':
      case 'pa':
        return 'لینک خلاص نه شو.';
      default:
        return 'لینک باز نشد.';
    }
  }

  Future<void> _openSocialLink(
    BuildContext context,
    String url,
  ) async {
    if (url.trim().isEmpty) return;

    bool opened = false;

    try {
      final Uri? uri = Uri.tryParse(url.trim());

      if (uri != null &&
          uri.host.isNotEmpty &&
          (uri.scheme == 'https' || uri.scheme == 'http')) {
        opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (error) {
      debugPrint('Error opening social link: $error');
    }

    if (!context.mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_linkErrorLabel(context)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String languageCode = context.locale.languageCode;
    final bool isRtl = languageCode != 'en';

    final List<String> paragraphs = content
        .split(RegExp(r'\n\s*\n'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();

    return Directionality(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          surfaceTintColor: AppColors.backgroundLight,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: BackButton(
            color: AppColors.textPrimary,
          ),
          title: Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withOpacity(0.16),
                            accentColor.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: accentColor.withOpacity(0.18),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.cardBgLight,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: accentColor.withOpacity(0.15),
                              ),
                            ),
                            child: Icon(
                              isAbout ? Icons.local_taxi_rounded : icon,
                              size: 39,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            isAbout ? 'Safir' : title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: isAbout ? 27 : 21,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                            ),
                          ),
                          if (isAbout) ...[
                            const SizedBox(height: 6),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // متن با حفظ محتوا و جداسازی پاراگراف‌ها.
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.fieldBorder,
                        ),
                      ),
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (int i = 0; i < paragraphs.length; i++) ...[
                              if (i > 0)
                                const SizedBox(height: 20),
                              Text(
                                paragraphs[i],
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  height: 1.9,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    if (isAbout) ...[
                      const SizedBox(height: 28),
                      Text(
                        _followUsLabel(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 24,
                        runSpacing: 16,
                        children: [
                          _SafirSocialButton(
                            icon: FontAwesomeIcons.facebookF,
                            label: 'Facebook',
                            color: const Color(0xFF1877F2),
                            onTap: _safirFacebookUrl.trim().isEmpty
                                ? null
                                : () => _openSocialLink(
                                      context,
                                      _safirFacebookUrl,
                                    ),
                          ),
                          _SafirSocialButton(
                            icon: FontAwesomeIcons.instagram,
                            label: 'Instagram',
                            color: const Color(0xFFE1306C),
                            onTap: _safirInstagramUrl.trim().isEmpty
                                ? null
                                : () => _openSocialLink(
                                      context,
                                      _safirInstagramUrl,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SafirSocialButton extends StatelessWidget {
  const _SafirSocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: label,
          button: true,
          enabled: enabled,
          child: Tooltip(
            message: label,
            child: Material(
              color: enabled
                  ? color.withOpacity(0.12)
                  : AppColors.fieldBorder.withOpacity(0.35),
              shape: CircleBorder(
                side: BorderSide(
                  color: enabled
                      ? color.withOpacity(0.24)
                      : AppColors.fieldBorder,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: FaIcon(
                      icon,
                      size: 25,
                      color: enabled ? color : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
