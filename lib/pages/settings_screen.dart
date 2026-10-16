import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
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
  State<SettingsScreen> createState() => _SettingsScreenState();
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
    final prefs = await SharedPreferences.getInstance();

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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notifications', value);
  }

  Future<void> _toggleSound(bool value) async {
    HapticFeedback.selectionClick();

    setState(() {
      _enableSoundEffects = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_sounds', value);
  }

  Future<void> _applyLanguageChange(String langCode) async {
    await context.setLocale(Locale(langCode));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', langCode);

    widget.onLanguageChanged?.call(langCode);

    if (!mounted) return;

    setState(() {});
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'pa':
      case 'ps':
        final value = 'lang_pashto'.tr();
        return value.isEmpty ? 'پښتو' : value;

      case 'en':
        final value = 'lang_english'.tr();
        return value.isEmpty ? 'English' : value;

      case 'fa':
      case 'dr':
      default:
        final value = 'lang_dari'.tr();
        return value.isEmpty ? 'فارسی / دری' : value;
    }
  }

  void _showLanguageDialog() {
    final currentLang = context.locale.languageCode;

    String selectedTempLang =
        (currentLang == 'pa' || currentLang == 'ps')
            ? 'ps'
            : currentLang == 'en'
                ? 'en'
                : 'fa';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    onChanged: (value) {
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
                    onChanged: (value) {
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
      final tempDir = await getTemporaryDirectory();

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
      builder: (dialogContext) {
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

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _localized(
              'terms_of_service',
              'قوانین و مقررات',
            ),
            style: TextStyle(
              color: darkTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              _localized(
                'terms_of_service_detail',
                'استفاده از اپلیکیشن تاکسی آنلاین سفیر به منزله پذیرش تمامی قوانین مربوط به حریم خصوصی، امنیت سفر و پرداخت‌ها می‌باشد.',
              ),
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w400,
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _localized(String key, String fallback) {
    final value = key.tr();

    return value.isEmpty || value == key ? fallback : value;
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
    final currentLangCode = context.locale.languageCode;
    final bool isRtl = currentLangCode != 'en';

    final IconData chevronIcon = isRtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

    return Directionality(
      textDirection:
          isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
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
                  '${_localized('current_language_prefix', 'زبان فعلی')}: '
                  '${_getLanguageName(currentLangCode)}',
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
            _buildSectionHeader(
              _localized(
                'about_app_header',
                'درباره سفیر',
              ),
            ),
            _buildCardGroup([
              UrbanListTile(
                leading: Icon(
                  Icons.description_outlined,
                  color: darkTextColor,
                ),
                title: Text(
                  _localized(
                    'terms_of_service',
                    'شرایط و قوانین استفاده',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: darkTextColor,
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
                  Icons.info_outline_rounded,
                  color: darkTextColor,
                ),
                title: Text(
                  _localized(
                    'app_version_label',
                    'نسخه برنامه',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: darkTextColor,
                  ),
                ),
                subtitle: const Text(
                  'v1.0.0 (Safir Passengers)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _localized(
                      'up_to_date',
                      'به‌روز است',
                    ),
                    style: TextStyle(
                      color: primaryAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
