import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:safir_passengers/theme/app_colors.dart';

/// نوع سرویس‌ها. در فایل نقشه هم از همین enum استفاده کنید.
enum SafirService { taxi, cargo, intercity }

/// باتم‌شیت اول (صفحهٔ هوم).
/// این ویجت هیچ وابستگی‌ای به نقشه ندارد؛ فقط ظاهر و کلیک‌ها را مدیریت می‌کند.
/// موقعیت‌دهی آن (مثلاً Align پایین صفحه) با فایل نقشه است.
class HomeServicesSheet extends StatelessWidget {
  const HomeServicesSheet({
    super.key,
    required this.selected,
    required this.onServiceSelected,
    required this.onSearchTap,
  });

  final SafirService selected;
  final ValueChanged<SafirService> onServiceSelected;
  final VoidCallback onSearchTap;

  String _t(String key, String fallback) {
    final String value = key.tr();
    return value.isEmpty || value == key ? fallback : value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.fieldBorder),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.handle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SearchField(
                hint: _t('where_to_go', 'کجا می‌روید؟'),
                onTap: onSearchTap,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final SafirService s in SafirService.values) ...[
                    if (s != SafirService.values.first)
                      const SizedBox(width: 10),
                    Expanded(
                      child: _ServiceTile(
                        icon: _iconOf(s),
                        label: _labelOf(s),
                        selected: s == selected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onServiceSelected(s);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconOf(SafirService s) {
    switch (s) {
      case SafirService.taxi:
        return Icons.local_taxi_rounded;
      case SafirService.cargo:
        return Icons.local_shipping_rounded;
      case SafirService.intercity:
        return Icons.add_road_rounded;
    }
  }

  String _labelOf(SafirService s) {
    switch (s) {
      case SafirService.taxi:
        return _t('service_taxi', 'سفیر');
      case SafirService.cargo:
        return _t('service_cargo', 'باربری');
      case SafirService.intercity:
        return _t('service_intercity', 'بین‌ولایتی');
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundLight,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.primaryBrand),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hint,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color brand = AppColors.primaryBrand;
    final Color dark = Color.lerp(brand, Colors.black, 0.35)!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 88,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [brand, dark],
                )
              : null,
          color: selected ? null : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? brand : AppColors.fieldBorder,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: brand.withOpacity(0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
              color: selected ? AppColors.buttonText : brand,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.buttonText
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
