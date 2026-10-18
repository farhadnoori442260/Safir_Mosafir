import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/urban_list_tile.dart';

class SettingsScreen extends StatefulWidget {
  final String currentLanguage;
  final ValueChanged<String>? onLanguageChanged;

  const SettingsScreen({
    super.key,
    this.currentLanguage = 'fa',
    this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color primaryAccent = const Color(0xFF0066FF);
  final Color darkTextColor = const Color(0xFF0F172A);
  final Color successColor = const Color(0xFF22C55E);
  final Color borderLightColor = const Color(0xFFF1F5F9);
  final Color appBarBorderColor = const Color(0xFFCBD5E1);

  bool _enableNotifications = true;
  bool _enableSoundEffects = true;
  bool _isLoadingCache = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _enableNotifications =
          prefs.getBool('enable_notifications') ?? true;

      _enableSoundEffects =
          prefs.getBool('enable_sounds') ?? true;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    HapticFeedback.selectionClick();

    setState(() {
      _enableNotifications = value;
    });

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'enable_notifications',
      value,
    );
  }

  Future<void> _toggleSound(bool value) async {
    HapticFeedback.selectionClick();

    setState(() {
      _enableSoundEffects = value;
    });

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'enable_sounds',
      value,
    );
  }

  Future<void> _applyLanguageChange(
    String langCode,
  ) async {
    await context.setLocale(Locale(langCode));

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'selected_language',
      langCode,
    );

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

    return value.isEmpty || value == key
        ? fallback
        : value;
  }

  void _showLanguageDialog() {
    final String currentLang =
        context.locale.languageCode;

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
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    color: darkTextColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _localized(
                      'select_language_title',
                      'انتخاب زبان',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkTextColor,
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
                    onChanged: (String? value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedTempLang = value;
                      });
                    },
                  ),
                  Divider(
                    height: 1,
                    color: borderLightColor,
                  ),
                  _buildLanguageRadio(
                    title: _localized(
                      'lang_pashto',
                      'پښتو',
                    ),
                    value: 'ps',
                    groupValue: selectedTempLang,
                    onChanged: (String? value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedTempLang = value;
                      });
                    },
                  ),
                  Divider(
                    height: 1,
                    color: borderLightColor,
                  ),
                  _buildLanguageRadio(
                    title: _localized(
                      'lang_english',
                      'English',
                    ),
                    value: 'en',
                    groupValue: selectedTempLang,
                    onChanged: (String? value) {
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
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    _localized('cancel', 'انصراف'),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    await _applyLanguageChange(
                      selectedTempLang,
                    );
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
      activeColor: primaryAccent,
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }

  Future<void> _performClearCache() async {
    if (_isLoadingCache) return;

    setState(() {
      _isLoadingCache = true;
    });

    try {
      final Directory tempDir =
          await getTemporaryDirectory();

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }

      if (!mounted) return;

      _showMessage(
        _localized(
          'cache_cleared_msg',
          'حافظه موقت با موفقیت پاکسازی شد',
        ),
        backgroundColor: successColor,
      );
    } catch (error) {
      debugPrint('خطا در پاکسازی کش: $error');

      if (!mounted) return;

      _showMessage(
        _localized(
          'error_occurred',
          'پاکسازی حافظه موقت انجام نشد',
        ),
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCache = false;
        });
      }
    }
  }

  void _clearCacheDialog() {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _localized(
              'clear_cache_title',
              'پاکسازی حافظه موقت',
            ),
            style: TextStyle(
              color: darkTextColor,
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
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                _localized('cancel', 'انصراف'),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAccent,
                foregroundColor: Colors.white,
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

  void _showLegalDialog({
    required String title,
    required IconData icon,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(
              20,
              20,
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primaryAccent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: primaryAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: darkTextColor,
                      fontSize: 15,
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
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.75,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: Text(
                  _localized('close', 'بستن'),
                  style: TextStyle(
                    color: primaryAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showServicesDialog() {
    _showLegalDialog(
      title: 'خدمات سفیر',
      icon: Icons.local_taxi_rounded,
      content: '''
سفیر یک پلتفرم حمل‌ونقل شهری است که ارتباط میان مسافران و رانندگان را ساده‌تر می‌سازد.

مسافران می‌توانند مبدأ و مقصد سفر را ثبت کنند، درخواست سفر بفرستند، وضعیت سفر را مشاهده کنند، اطلاعات کلی راننده و وسیلهٔ نقلیه را ببینند، سوابق سفر را بررسی کنند و مشکلات خود را از بخش پشتیبانی گزارش دهند.

رانندگان می‌توانند اطلاعات هویتی، گواهینامه و اطلاعات وسیلهٔ نقلیه را ثبت کنند، درخواست‌های سفر را مدیریت کنند، وضعیت سفر را به‌روزرسانی کنند و سوابق و درآمدهای خود را مشاهده کنند.

برخی امکانات ممکن است بر اساس شهر، وضعیت اینترنت، دسترسی راننده، نسخهٔ برنامه یا قوانین محلی در دسترس نباشند. سفیر تلاش می‌کند خدمات را به‌صورت منظم و قابل‌اعتماد ارائه کند، اما امکان اختلال موقت در اثر شرایط فنی یا عوامل خارج از کنترل وجود دارد.
''',
    );
  }

  void _showTermsDialog() {
    _showLegalDialog(
      title: 'شرایط و قوانین استفاده',
      icon: Icons.description_outlined,
      content: '''
تاریخ آخرین به‌روزرسانی: پیش از انتشار رسمی تکمیل می‌شود.

با ایجاد حساب، ورود یا استفاده از اپلیکیشن سفیر، شما این شرایط و قوانین را می‌پذیرید. اگر با بخشی از این قوانین موافق نیستید، لطفاً از خدمات سفیر استفاده نکنید.

۱. حساب کاربری
کاربر باید اطلاعات صحیح، کامل و به‌روز وارد کند و مسئول حفظ امنیت شماره تلفن، کد ورود و حساب خود است. استفاده از اطلاعات شخص دیگر یا انتقال حساب به فرد دیگر بدون اجازه مجاز نیست.

۲. درخواست سفر
ثبت درخواست سفر به معنای تضمین پذیرش آن نیست. سفر ممکن است به دلیل نبود راننده، اختلال فنی، شرایط جوی، محدودیت منطقه‌ای، مسائل امنیتی یا نقض قوانین رد یا لغو شود. مسافر مسئول واردکردن دقیق مبدأ و مقصد است.

۳. رفتار کاربران
مسافر و راننده باید با احترام رفتار کنند. توهین، تهدید، ایجاد مزاحمت، آسیب‌رساندن به خودرو، ارائه اطلاعات نادرست، سوءاستفاده از خدمات و حمل کالاهای خطرناک یا غیرقانونی ممنوع است.

۴. مسئولیت راننده
راننده باید مدارک، گواهینامه و اطلاعات وسیلهٔ نقلیه را صحیح ثبت کند، قوانین راهنمایی و رانندگی را رعایت کند و اطلاعات شخصی مسافر را بدون اجازه ذخیره یا منتشر نکند.

۵. کرایه و پرداخت
کرایه ممکن است بر اساس مسیر، زمان، مسافت، تعرفه و شرایط سفر تعیین شود. کاربر باید پیش از تأیید سفر، مبلغ یا روش محاسبهٔ کرایه را بررسی کند. اختلاف‌های مربوط به سفر از طریق پشتیبانی قابل پیگیری است.

۶. لغو سفر
لغو مکرر یا غیرموجه سفر توسط مسافر یا راننده ممکن است باعث محدودشدن حساب شود. هرگونه هزینه یا شرایط لغو، در صورت فعال‌بودن، در برنامه اعلام خواهد شد.

۷. محدودسازی حساب
سفیر می‌تواند در صورت تقلب، نقض قوانین، ایجاد خطر امنیتی، ارائه اطلاعات نادرست یا سوءاستفاده از خدمات، حساب را بررسی، محدود یا مسدود کند.

۸. تغییر قوانین
ممکن است این شرایط برای بهبود خدمات، رعایت قوانین یا افزودن قابلیت‌های جدید به‌روزرسانی شود. نسخهٔ جدید در برنامه منتشر خواهد شد.
''',
    );
  }

  void _showPrivacyDialog() {
    _showLegalDialog(
      title: 'حریم خصوصی و داده‌ها',
      icon: Icons.privacy_tip_outlined,
      content: '''
حریم خصوصی کاربران برای سفیر مهم است. این برنامه ممکن است فقط برای ارائه و بهبود خدمات، اطلاعات لازم را دریافت و پردازش کند.

۱. اطلاعاتی که ممکن است دریافت شود
اطلاعات حساب مانند نام، شماره تلفن، ایمیل در صورت ثبت، شناسه حساب و تصویر پروفایل؛ اطلاعات سفر مانند مبدأ، مقصد، وضعیت سفر، زمان، مسافت و کرایه؛ اطلاعات راننده مانند مدارک هویتی، گواهینامه، اطلاعات خودرو و تصاویر مدارک؛ و اطلاعات فنی لازم برای عملکرد و امنیت برنامه.

۲. موقعیت مکانی
برای ثبت درخواست سفر، تعیین مبدأ و مقصد، نمایش مسیر و هماهنگی سفر، ممکن است برنامه به موقعیت مکانی دستگاه نیاز داشته باشد. کاربر می‌تواند دسترسی مکان را از تنظیمات دستگاه مدیریت کند، اما غیرفعال‌کردن آن ممکن است بخشی از خدمات را محدود کند.

۳. استفاده از داده‌ها
اطلاعات فقط برای ایجاد و مدیریت حساب، انجام و پیگیری سفر، محاسبه کرایه، پشتیبانی، جلوگیری از تقلب، حفظ امنیت، حل اختلاف‌ها و بهبود عملکرد خدمات استفاده می‌شود.

۴. اشتراک‌گذاری اطلاعات
اطلاعات ضروری سفر ممکن است میان مسافر و راننده، فقط در حد لازم برای انجام سفر، نمایش داده شود. اطلاعات همچنین ممکن است با ارائه‌دهندگان فنی موردنیاز برای اجرای برنامه، ذخیره‌سازی امن داده‌ها، ارسال اعلان یا پردازش خدمات ابری به اشتراک گذاشته شود.

۵. نگهداری و امنیت
سفیر تلاش می‌کند با استفاده از روش‌های فنی و مدیریتی مناسب، از اطلاعات کاربران محافظت کند. هیچ روش انتقال یا ذخیره‌سازی اینترنتی امنیت مطلق ندارد؛ بنابراین کاربران نیز باید از اطلاعات ورود خود محافظت کنند.

۶. حذف حساب و داده‌ها
کاربر می‌تواند از بخش «حذف حساب و داده‌ها» در تنظیمات، درخواست حذف حساب را ثبت کند. برخی اطلاعات ممکن است فقط در صورت وجود الزام قانونی، جلوگیری از تقلب، حل اختلاف یا حفظ سوابق مالی لازم، برای مدت محدود نگهداری شود.

۷. به‌روزرسانی این سیاست
ممکن است این سیاست برای بهبود خدمات یا رعایت الزامات قانونی به‌روزرسانی شود. نسخهٔ جدید در برنامه در دسترس خواهد بود.
''',
    );
  }

  void _showAboutDialog() {
    _showLegalDialog(
      title: 'دربارهٔ اپلیکیشن',
      icon: Icons.info_outline_rounded,
      content: '''
سفیر یک اپلیکیشن حمل‌ونقل شهری است که برای آسان‌ترشدن ثبت و مدیریت سفر طراحی شده است.

هدف ما ایجاد ارتباطی ساده‌تر میان مسافران و رانندگان، دسترسی سریع‌تر به خدمات سفر و فراهم‌کردن امکان مشاهدهٔ وضعیت و سوابق سفر است.

سفیر تلاش می‌کند تجربه‌ای منظم، ساده و قابل‌اعتماد ارائه کند. بازخوردها، پیشنهادها و گزارش‌های کاربران به بهبود نسخه‌های بعدی برنامه کمک می‌کند.

نسخهٔ برنامه:
v1.0.0 (Safir Passengers)

اطلاعات تماس، وب‌سایت و راه‌های پشتیبانی رسمی پیش از انتشار نهایی در این بخش اضافه خواهند شد.
''',
    );
  }

  void _showDeleteAccountDialog() {
    _showLegalDialog(
      title: 'حذف حساب و داده‌ها',
      icon: Icons.delete_forever_outlined,
      content: '''
شما حق دارید درخواست حذف حساب سفیر و داده‌های مرتبط با آن را ثبت کنید.

پس از راه‌اندازی مسیر رسمی حذف حساب، درخواست از همین بخش به پشتیبانی ارسال خواهد شد. تا زمان فعال‌شدن این قابلیت، حساب شما با این گزینه فوراً حذف نمی‌شود.

در فرایند حذف، اطلاعات مرتبط با حساب و داده‌های قابل حذف بررسی می‌شوند. ممکن است برخی اطلاعات فقط در صورت ضرورت قانونی، جلوگیری از تقلب، حل اختلاف، امنیت یا نگهداری سوابق مالی برای مدت محدود حفظ شوند.

پیش از انتشار در فروشگاه، این بخش باید به یک روش واقعی و قابل‌دسترسی برای ثبت درخواست حذف حساب متصل شود؛ مانند فرم حذف حساب، صفحهٔ وب رسمی یا درخواست پشتیبانی.
''',
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            _localized('settings_title', 'تنظیمات'),
            style: TextStyle(
              color: darkTextColor,
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
              color: darkTextColor,
              size: 20,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: appBarBorderColor,
              height: 1,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
          children: [
            _buildSectionHeader(
              _localized(
                'general_settings_header',
                'عمومی',
              ),
            ),
            _buildCardGroup([
              UrbanListTile(
                leading: Icon(
                  Icons.language_rounded,
                  color: darkTextColor,
                ),
                title: Text(
                  _localized(
                    'app_language_label',
                    'زبان برنامه',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: darkTextColor,
                  ),
                ),
                subtitle: Text(
                  '${_localized(
                    'current_language_prefix',
                    'زبان فعلی',
                  )}: ${_getLanguageName(currentLangCode)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: Icon(
                  chevronIcon,
                  color: const Color(0xFF94A3B8),
                ),
                onTap: _showLanguageDialog,
              ),
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
                indent: 56,
                color: borderLightColor,
              ),
              _buildSettingSwitchTile(
                icon: Icons.volume_up_outlined,
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
              UrbanListTile(
                leading: _isLoadingCache
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryAccent,
                        ),
                      )
                    : Icon(
                        Icons.cleaning_services_outlined,
                        color: darkTextColor,
                      ),
                title: Text(
                  _localized(
                    'clear_cache_btn',
                    'پاکسازی حافظه موقت',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: darkTextColor,
                  ),
                ),
                subtitle: Text(
                  _localized(
                    'clear_cache_subtitle',
                    'آزادسازی فضای اشغال‌شده توسط عکس‌ها و نقشه‌ها',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: Icon(
                  chevronIcon,
                  color: const Color(0xFF94A3B8),
                ),
                onTap: _isLoadingCache
                    ? null
                    : _clearCacheDialog,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('درباره سفیر'),
            _buildCardGroup([
              UrbanListTile(
                leading: Icon(
                  Icons.local_taxi_rounded,
                  color: darkTextColor,
                ),
                title: Text(
                  'خدمات سفیر',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: darkTextColor,
                  ),
                ),
                subtitle: const Text(
                  'امکانات و خدمات مسافر و راننده',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                trailing: Icon(
                  chevronIcon,
                  color: const Color(0xFF94A3B8),
                ),
                onTap: _showServicesDialog,
              ),
              Divider(
                height: 1,
                indent: 56,
                color: borderLightColor,
              ),
              UrbanListTile(
                leading: Icon(
                  Icons.description_outlined,
                  color: darkTextColor,
                ),
                title: Text(
                  'شرایط و قوانین استفاده',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: darkTextColor,
                  ),
                ),
                subtitle: const Text(
                  'حقوق، مسئولیت‌ها و قوانین سفر',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                trailing: Icon(
                  chevronIcon,
                  color: const Color(0xFF94A3B8),
                ),
                onTap: _showTermsDialog,
              ),
              Divider(
                height: 1,
                indent: 56,
                color: borderLightColor,
              ),
              UrbanListTile(
                leading: Icon(
                  Icons.privacy_tip_outlined,
                  color: darkTextColor,
                ),
                title: Text(
                  'حریم خصوصی و داده‌ها',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: darkTextColor,
                  ),
                ),
                subtitle: const Text(
                  'نحوهٔ دریافت، استفاده و نگهداری اطلاعات',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                trailing: Icon(
                  chevronIcon,
                  color: const Color(0xFF94A3B8),
                ),
                onTap: _showPrivacyDialog,
              ),
              Divider(
                height: 1,
                indent: 56,
                color: borderLightColor,
              ),
              UrbanListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.red.shade600,
                ),
                title: Text(
                  'حذف حساب و داده‌ها',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: darkTextColor,
                  ),
                ),
                subtitle: const Text(
                  'راهنمای ثبت درخواست حذف حساب',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                trailing: Icon(
                  chevronIcon,
                  color: const Color(0xFF94A3B8),
                ),
                onTap: _showDeleteAccountDialog,
              ),
              Divider(
                height: 1,
                indent: 56,
                color: borderLightColor,
              ),
              UrbanListTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: darkTextColor,
                ),
                title: Text(
                  'دربارهٔ اپلیکیشن',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: darkTextColor,
                  ),
                ),
                subtitle: const Text(
                  'معرفی سفیر و نسخهٔ برنامه',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                trailing: Icon(
                  chevronIcon,
                  color: const Color(0xFF94A3B8),
                ),
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
    return UrbanListTile(
      leading: Icon(
        icon,
        color: darkTextColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: darkTextColor,
        ),
      ),
      trailing: _ModernSwitch(
        value: value,
        activeColor: primaryAccent,
        onChanged: onChanged,
      ),
      onTap: () {
        onChanged(!value);
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkTextColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderLightColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
      label: value ? 'فعال' : 'غیرفعال',
      child: GestureDetector(
        onTap: () {
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 44,
          height: 25,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value
                ? activeColor
                : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: value
                  ? activeColor
                  : const Color(0xFFCBD5E1),
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: value
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 19,
              height: 19,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
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
}
