import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:safir_passengers/theme/app_colors.dart';

class RateDriverScreen extends StatefulWidget {
  final String tripId;
  final String driverId;
  final String driverName;
  final String carModel;
  final String plateNumber;
  final String driverPhoto;

  const RateDriverScreen({
    super.key,
    required this.tripId,
    required this.driverId,
    required this.driverName,
    required this.carModel,
    required this.plateNumber,
    this.driverPhoto = '',
  });

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  int _rating = 0;
  bool _isSubmitting = false;

  final List<String> _selectedTags = <String>[];
  final TextEditingController _commentController =
      TextEditingController();

  final List<String> _positiveTags = <String>[
    'rate_tag_punctual',
    'rate_tag_polite',
    'rate_tag_clean_car',
    'rate_tag_safe_driving',
    'rate_tag_good_route',
    'rate_tag_fair_price',
  ];

  final List<String> _negativeTags = <String>[
    'rate_tag_delay',
    'rate_tag_impolite',
    'rate_tag_dirty_car',
    'rate_tag_unsafe_driving',
    'rate_tag_wrong_route',
  ];

  // متن فارسی جایگزین برای برچسب‌ها (اگر ترجمه در فایل زبان نبود)
  static const Map<String, String> _tagFallback = <String, String>{
    'rate_tag_punctual': 'وقت‌شناس',
    'rate_tag_polite': 'با ادب',
    'rate_tag_clean_car': 'موتر تمیز',
    'rate_tag_safe_driving': 'رانندگی ایمن',
    'rate_tag_good_route': 'مسیر خوب',
    'rate_tag_fair_price': 'کرایه منصفانه',
    'rate_tag_delay': 'تأخیر',
    'rate_tag_impolite': 'بی‌ادبی',
    'rate_tag_dirty_car': 'موتر کثیف',
    'rate_tag_unsafe_driving': 'رانندگی خطرناک',
    'rate_tag_wrong_route': 'مسیر اشتباه',
  };

  /// ترجمه با متن جایگزین (اگر کلید نبود، خود کلید نشان داده نشود)
  String _t(String key, String fallback) {
    final String v = key.tr();
    return (v.trim().isEmpty || v == key) ? fallback : v;
  }

  bool get _isPositiveGroup => _rating >= 4;

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return _t('rate_label_1', 'خیلی بد');
      case 2:
        return _t('rate_label_2', 'بد');
      case 3:
        return _t('rate_label_3', 'معمولی');
      case 4:
        return _t('rate_label_4', 'خوب');
      case 5:
        return _t('rate_label_5', 'عالی');
      default:
        return _t('select_your_rating', 'به این سفر امتیاز بدهید');
    }
  }

  void _setRating(int value) {
    HapticFeedback.selectionClick();
    setState(() {
      _rating = value;
      // برچسب‌های گروه دیگر (مثبت/منفی) نباید همراه امتیاز ثبت شوند
      final List<String> allowed =
          _isPositiveGroup ? _positiveTags : _negativeTags;
      _selectedTags.removeWhere((String t) => !allowed.contains(t));
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0 || _isSubmitting) {
      return;
    }

    if (widget.tripId.trim().isEmpty ||
        widget.driverId.trim().isEmpty) {
      _showError(_t('rate_driver_missing_data', 'اطلاعات سفر کامل نیست'));
      return;
    }

    final String passengerId =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    if (passengerId.isEmpty) {
      _showError(_t('rate_driver_error', 'ثبت امتیاز انجام نشد، دوباره تلاش کنید'));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final FirebaseFirestore firestore =
          FirebaseFirestore.instance;

      final DocumentReference<Map<String, dynamic>> tripRef =
          firestore.collection('rides').doc(widget.tripId);

      final DocumentReference<Map<String, dynamic>> driverRef =
          firestore.collection('drivers').doc(widget.driverId);

      final DocumentReference<Map<String, dynamic>> ratingRef =
          firestore
              .collection('driver_ratings')
              .doc(widget.tripId);

      final String comment =
          _commentController.text.trim();

      await firestore.runTransaction(
        (
          Transaction transaction,
        ) async {
          final DocumentSnapshot<Map<String, dynamic>>
              tripSnapshot = await transaction.get(tripRef);

          if (!tripSnapshot.exists) {
            throw Exception('trip_not_found');
          }

          final Map<String, dynamic> tripData =
              tripSnapshot.data() ?? <String, dynamic>{};

          final bool alreadyRated =
              tripData['ratingSubmitted'] == true ||
                  tripData['passengerRating'] != null;

          if (alreadyRated) {
            throw Exception('already_rated');
          }

          // ۱) امتیاز در خود سفر
          transaction.set(
            tripRef,
            <String, dynamic>{
              'passengerRating': _rating,
              'passengerRatingTags':
                  List<String>.from(_selectedTags),
              'passengerReview': comment,
              'ratingSubmitted': true,
              'ratedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // ۲) شمارندهٔ امتیاز راننده
          //
          // ✅ مسافر اجازهٔ «خواندن» سند راننده را ندارد (اطلاعات خصوصی
          // راننده آنجاست)؛ پس به‌جای خواندن و محاسبهٔ میانگین، فقط
          // شمارنده‌ها به‌صورت اتمی زیاد می‌شوند:
          //   میانگین = ratingTotal ÷ ratingCount
          transaction.set(
            driverRef,
            <String, dynamic>{
              'ratingCount': FieldValue.increment(1),
              'ratingTotal': FieldValue.increment(_rating),
              'lastRatingAt': FieldValue.serverTimestamp(),
              'lastRatingTripId': widget.tripId,
            },
            SetOptions(merge: true),
          );

          // ۳) سند امتیاز (شناسهٔ آن همان شناسهٔ سفر است؛ پس هر سفر
          // فقط یک بار امتیاز می‌گیرد)
          transaction.set(
            ratingRef,
            <String, dynamic>{
              'tripId': widget.tripId,
              'driverId': widget.driverId,
              'driverName': widget.driverName,
              'passengerId': passengerId,
              'rating': _rating,
              'tags': List<String>.from(_selectedTags),
              'comment': comment,
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _t('rate_driver_submit_success', 'امتیاز شما ثبت شد، ممنون!'),
            style: TextStyle(color: AppColors.buttonText),
          ),
          backgroundColor: AppColors.successDark,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      debugPrint(
        'Driver rating Firebase error: '
        '${e.code} | ${e.message}',
      );

      if (!mounted) {
        return;
      }

      // متن فنی خطا به کاربر نشان داده نمی‌شود (در لاگ هست)
      _showError(_t('rate_driver_error', 'ثبت امتیاز انجام نشد، دوباره تلاش کنید'));
    } catch (e) {
      debugPrint('Driver rating error: $e');

      if (!mounted) {
        return;
      }

      final String errorText = e.toString();

      if (errorText.contains('already_rated')) {
        _showError(_t('rate_driver_already_submitted', 'برای این سفر قبلاً امتیاز ثبت شده است'));
      } else if (errorText.contains('trip_not_found')) {
        _showError(_t('rate_driver_trip_not_found', 'سفر پیدا نشد'));
      } else {
        _showError(_t('rate_driver_error', 'ثبت امتیاز انجام نشد، دوباره تلاش کنید'));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: TextStyle(color: AppColors.buttonText),
        ),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> tags =
        _isPositiveGroup ? _positiveTags : _negativeTags;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          _t('rate_driver_title', 'امتیاز به راننده'),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: Text(
              _t('skip', 'بعداً'),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: <Widget>[
              _buildDriverCard(),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                decoration: _cardDecoration(),
                child: Column(
                  children: <Widget>[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        _ratingLabel,
                        key: ValueKey<int>(_rating),
                        style: TextStyle(
                          fontSize: _rating == 0 ? 15 : 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(5, (int index) {
                        final bool filled = index < _rating;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _setRating(index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedScale(
                              scale: filled ? 1.0 : 0.88,
                              duration: const Duration(milliseconds: 160),
                              child: Icon(
                                filled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: filled
                                    ? AppColors.warning
                                    : AppColors.handle,
                                size: 46,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    // برچسب‌ها فقط بعد از امتیاز دادن؛ مثبت یا منفی بر اساس امتیاز
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      alignment: Alignment.topCenter,
                      child: _rating == 0
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    _isPositiveGroup
                                        ? _t('positive_points', 'نکات مثبت')
                                        : _t('negative_points', 'نکات منفی'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: tags
                                        .map((String k) => _buildTagChip(k))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _t('comments_label', 'نظر شما (اختیاری)'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      maxLength: 300,
                      cursorColor: AppColors.primaryBrand,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: _t('comment_hint', 'تجربهٔ خود را بنویسید...'),
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        counterStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
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
                            color: AppColors.primaryBrand,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_rating == 0 || _isSubmitting)
                      ? null
                      : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    disabledBackgroundColor: AppColors.fieldBorder,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.buttonText,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Text(
                          _t('submit_feedback_btn', 'ثبت امتیاز'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _rating == 0
                                ? AppColors.textSecondary
                                : AppColors.buttonText,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.cardBgLight,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.fieldBorder),
    );
  }

  Widget _buildDriverCard() {
    final bool hasPhoto = widget.driverPhoto.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.fieldBorder, width: 1.2),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.backgroundLight,
              backgroundImage:
                  hasPhoto ? NetworkImage(widget.driverPhoto) : null,
              onBackgroundImageError: hasPhoto ? (_, __) {} : null,
              child: hasPhoto
                  ? null
                  : Icon(
                      Icons.person_rounded,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.driverName.isNotEmpty
                      ? widget.driverName
                      : _t('rate_driver_default_name', 'راننده'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.carModel.isNotEmpty
                      ? widget.carModel
                      : _t('rate_driver_default_car', 'موتر'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              border: Border.all(color: AppColors.fieldBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.plateNumber.isNotEmpty
                  ? widget.plateNumber
                  : _t('rate_driver_default_plate', '---'),
              textDirection: ui.TextDirection.ltr,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tagKey) {
    final bool isSelected = _selectedTags.contains(tagKey);
    // مثبت = سبز، منفی = قرمز؛ فقط وقتی انتخاب شده باشد
    final Color accent =
        _isPositiveGroup ? AppColors.successDark : AppColors.danger;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedTags.remove(tagKey);
          } else {
            _selectedTags.add(tagKey);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withOpacity(0.14)
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : AppColors.fieldBorder,
            width: 1.3,
          ),
        ),
        child: Text(
          _t(tagKey, _tagFallback[tagKey] ?? tagKey),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? accent : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
