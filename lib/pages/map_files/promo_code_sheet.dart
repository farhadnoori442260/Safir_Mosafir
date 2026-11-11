import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:safir_passengers/theme/app_colors.dart';

/// نتیجهٔ بررسی یک کد تخفیف
class PromoValidation {
  final bool isValid;

  /// پیام برای کاربر (خطا یا توضیح تخفیف، مثلاً «۱۰٪ تخفیف»)
  final String message;

  const PromoValidation(this.isValid, this.message);
}

class PromoCodeSheet extends StatefulWidget {
  final String initialCode;
  final Function(String code) onApply;

  /// اگر داده شود، کد قبل از اعمال بررسی می‌شود.
  /// اگر داده نشود، رفتار قبلی حفظ می‌شود (کد بدون بررسی اعمال می‌شود).
  final Future<PromoValidation> Function(String code)? validator;

  const PromoCodeSheet({
    Key? key,
    this.initialCode = '',
    required this.onApply,
    this.validator,
  }) : super(key: key);

  @override
  State<PromoCodeSheet> createState() => _PromoCodeSheetState();
}

class _PromoCodeSheetState extends State<PromoCodeSheet> {
  late TextEditingController _codeController;

  bool _checking = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// ترجمه با متن جایگزین (اگر کلید پیدا نشد، easy_localization خود کلید را برمی‌گرداند)
  String _trOr(String key, String fallback) {
    final String v = key.tr();
    return (v.isEmpty || v == key) ? fallback : v;
  }

  void _finish(String code) {
    widget.onApply(code.trim());
    if (mounted) Navigator.pop(context);
  }

  /// کد خالی = حذف کد؛ بدون validator = رفتار قبلی؛ در غیر این صورت بررسی می‌شود.
  Future<void> _apply(String raw) async {
    if (_checking) return;

    final String code = raw.trim();
    HapticFeedback.mediumImpact();

    if (code.isEmpty || widget.validator == null) {
      _finish(code);
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
      _success = null;
    });

    PromoValidation result;
    try {
      result = await widget.validator!(code);
    } catch (_) {
      result = PromoValidation(
        false,
        _trOr('promo_check_failed', 'بررسی کد انجام نشد، دوباره تلاش کنید'),
      );
    }

    if (!mounted) return;

    if (!result.isValid) {
      HapticFeedback.heavyImpact();
      setState(() {
        _checking = false;
        _error = result.message;
      });
      return;
    }

    setState(() {
      _checking = false;
      _success = result.message;
    });

    // کد تأیید شد؛ لحظه‌ای پیام موفقیت دیده شود، بعد شیت بسته شود
    widget.onApply(code);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasInitial = widget.initialCode.trim().isNotEmpty;

    // خودِ شیت پس‌زمینه دارد تا در حالت تاریک هم درست باشد
    // (اگر جایی showModalBottomSheet با backgroundColor ثابت سفید صدا می‌زنید،
    // آن را Colors.transparent کنید).
    return Material(
      color: AppColors.cardBgLight,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 12,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.handle,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.local_offer_rounded,
                    color: AppColors.warningIcon,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'opt_promo_code'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: _apply,
              onChanged: (_) {
                if (_error != null || _success != null) {
                  setState(() {
                    _error = null;
                    _success = null;
                  });
                }
              },
              cursorColor: AppColors.primaryBrand,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'enter_promo_hint'.tr(),
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
                prefixIcon: Icon(
                  Icons.confirmation_number_outlined,
                  color: _error != null
                      ? AppColors.danger
                      : AppColors.primaryBrand,
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.fieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _error != null
                        ? AppColors.danger
                        : AppColors.primaryBrand,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            // پیام نتیجهٔ بررسی (خطا یا موفقیت)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: (_error == null && _success == null)
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Icon(
                            _error != null
                                ? Icons.error_outline_rounded
                                : Icons.check_circle_rounded,
                            size: 18,
                            color: _error != null
                                ? AppColors.danger
                                : AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error ?? _success ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _error != null
                                    ? AppColors.danger
                                    : AppColors.successDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _checking ? null : () => _apply(_codeController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _checking
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.buttonText,
                        ),
                      )
                    : Text(
                        'apply_promo_btn'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.buttonText,
                        ),
                      ),
              ),
            ),
            // اگر قبلاً کدی ثبت شده، حذف آن یک لمس باشد
            if (hasInitial)
              Center(
                child: TextButton(
                  onPressed: _checking ? null : () => _apply(''),
                  child: Text(
                    _trOr('remove_promo_btn', 'حذف کد تخفیف'),
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
