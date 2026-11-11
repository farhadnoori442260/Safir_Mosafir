import 'package:flutter/material.dart';

/// پلاک موتر افغانستان.
///
/// پلاک یک شیء فیزیکی است و همیشه روشن با نوشتهٔ تیره دیده می‌شود
/// (حتی در حالت تاریک)، پس رنگ‌های آن عمداً از تم تبعیت نمی‌کنند.
class AfghanistanLicensePlate extends StatelessWidget {
  final String province;
  final String categoryLetter;
  final String farsiNumber;
  final String englishNumber;
  final bool isTemporary;

  const AfghanistanLicensePlate({
    super.key,
    this.province = "کابل",
    this.categoryLetter = "ش",
    required this.farsiNumber,
    this.englishNumber = "",
    this.isTemporary = false,
  });

  // رنگ‌های ثابت پلاک
  static const Color _plateBg = Color(0xFFFCFCFA);
  static const Color _plateInk = Color(0xFF15171A);
  static const Color _plateAccent = Color(0xFFC62828);
  static const Color _plateMuted = Color(0xFF8A8F96);

  @override
  Widget build(BuildContext context) {
    // انتخاب شماره پلاک (ترجیحاً شماره فارسی و در غیر این صورت انگلیسی)
    final String displayNum = farsiNumber.trim().isNotEmpty
        ? farsiNumber.trim()
        : (englishNumber.trim().isNotEmpty ? englishNumber.trim() : "---");

    final String displayProvince =
        province.trim().isNotEmpty ? province.trim() : "کابل";
    final String displayCategory =
        categoryLetter.trim().isNotEmpty ? categoryLetter.trim() : "ش";

    final Widget content = isTemporary
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "موقت",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _plateAccent,
                ),
              ),
              const SizedBox(width: 8),
              _number(displayNum),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // حرف دستهٔ پلاک (مثلاً «ش»)
              Text(
                displayCategory,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _plateAccent,
                ),
              ),
              _divider(),
              // شمارهٔ پلاک
              _number(displayNum),
              _divider(),
              // نام ولایت
              Text(
                displayProvince,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _plateInk,
                ),
              ),
            ],
          );

    return Semantics(
      label: isTemporary
          ? 'پلاک موقت $displayNum'
          : 'پلاک $displayCategory $displayNum $displayProvince',
      child: Directionality(
        // ترتیب اجزای پلاک همیشه راست‌به‌چپ است، فارغ از زبان اپ
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _plateBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _plateInk, width: 1.6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 1.5),
              ),
            ],
          ),
          // قاب داخلی نازک، شبیه پلاک واقعی
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _plateInk.withOpacity(0.28),
                width: 0.8,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _number(String value) {
    return Text(
      value,
      textDirection: TextDirection.ltr,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: _plateInk,
        letterSpacing: 0.8,
        height: 1.15,
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        "-",
        style: TextStyle(
          fontSize: 13,
          color: _plateMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
