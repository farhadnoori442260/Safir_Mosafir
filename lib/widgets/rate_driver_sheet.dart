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

class _RateDriverScreenState extends State<RateDriverScreen>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  bool _isSubmitting = false;

  late final TabController _tabController;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0 || _isSubmitting) {
      return;
    }

    if (widget.tripId.trim().isEmpty ||
        widget.driverId.trim().isEmpty) {
      _showError('rate_driver_missing_data'.tr());
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final FirebaseFirestore firestore =
          FirebaseFirestore.instance;

      final String passengerId =
          FirebaseAuth.instance.currentUser?.uid ?? '';

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

          final DocumentSnapshot<Map<String, dynamic>>
              driverSnapshot =
              await transaction.get(driverRef);

          final Map<String, dynamic> driverData =
              driverSnapshot.data() ?? <String, dynamic>{};

          final int oldRatingCount =
              _toInt(driverData['ratingCount']);

          final double oldRatingTotal =
              _toDouble(driverData['ratingTotal']);

          final int newRatingCount =
              oldRatingCount + 1;

          final double newRatingTotal =
              oldRatingTotal + _rating;

          final double newAverageRating =
              newRatingTotal / newRatingCount;

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

          transaction.set(
            driverRef,
            <String, dynamic>{
              'ratingCount': newRatingCount,
              'ratingTotal': newRatingTotal,
              'averageRating': double.parse(
                newAverageRating.toStringAsFixed(2),
              ),
              'lastRatingAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

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
          content: Text(
            'rate_driver_submit_success'.tr(),
          ),
          backgroundColor: Colors.green.shade700,
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

      _showError(
        'rate_driver_submit_error_detail'.tr(
          namedArgs: <String, String>{
            'error': e.message ?? e.code,
          },
        ),
      );
    } catch (e) {
      debugPrint('Driver rating error: $e');

      if (!mounted) {
        return;
      }

      final String errorText = e.toString();

      if (errorText.contains('already_rated')) {
        _showError('rate_driver_already_submitted'.tr());
      } else if (errorText.contains('trip_not_found')) {
        _showError('rate_driver_trip_not_found'.tr());
      } else {
        _showError('error_occurred'.tr());
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
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'rate_driver_title'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            _buildDriverCard(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    'select_your_rating'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      5,
                      (int index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: index < _rating
                                ? Colors.amber
                                : Colors.grey.shade400,
                            size: 38,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();

                            setState(() {
                              _rating = index + 1;

                              if (_rating <= 3) {
                                _tabController.animateTo(1);
                              } else {
                                _tabController.animateTo(0);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryBrand,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primaryBrand,
                    tabs: <Widget>[
                      Tab(
                        text: 'positive_points'.tr(),
                      ),
                      Tab(
                        text: 'negative_points'.tr(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        _buildTagsGrid(_positiveTags),
                        _buildTagsGrid(_negativeTags),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'comments_label'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'comment_hint'.tr(),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBrand,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_rating == 0 || _isSubmitting)
                    ? null
                    : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrand,
                  disabledBackgroundColor:
                      Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'submit_feedback_btn'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundImage: widget.driverPhoto.isNotEmpty
                ? NetworkImage(widget.driverPhoto)
                : null,
            child: widget.driverPhoto.isEmpty
                ? const Icon(
                    Icons.person,
                    color: Colors.grey,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.carModel.isNotEmpty
                      ? widget.carModel
                      : 'rate_driver_default_car'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  widget.driverName.isNotEmpty
                      ? widget.driverName
                      : 'rate_driver_default_name'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade400,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.plateNumber.isNotEmpty
                  ? widget.plateNumber
                  : 'rate_driver_default_plate'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsGrid(List<String> tags) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: tags.length,
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final String tagKey = tags[index];

        final bool isSelected =
            _selectedTags.contains(tagKey);

        return InkWell(
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
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Colors.green
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              tagKey.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected
                    ? Colors.green.shade800
                    : AppColors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
