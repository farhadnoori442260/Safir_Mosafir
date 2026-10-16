import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final Color safirBrandColor = const Color(0xFF1B7A57);
final Color safirAccentColor = const Color(0xFF22C55E);

// ----------------------------------------------------
// ۱. صفحه تاریخچه سفرها (متصل به Firestore)
// ----------------------------------------------------
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  static const Color _backgroundColor = Color(0xFFF6F8FA);
  static const Color _textColor = Color(0xFF17202A);
  static const Color _mutedColor = Color(0xFF6B7280);
  static const Color _blueColor = Color(0xFF2563EB);
  static const Color _redColor = Color(0xFFDC2626);
  static const Color _orangeColor = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final String? currentUserId =
        FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _textColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'trips_history_title'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          bottom: TabBar(
            indicatorColor: safirBrandColor,
            indicatorWeight: 3,
            labelColor: safirBrandColor,
            unselectedLabelColor: _mutedColor,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            tabs: [
              Tab(text: 'tab_completed'.tr()),
              Tab(text: 'tab_active'.tr()),
              Tab(text: 'tab_canceled'.tr()),
            ],
          ),
        ),
        body: currentUserId == null
            ? _buildEmptyState(
                context,
                Icons.login_rounded,
                'trips_history_empty_msg',
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('rides')
                    .where(
                      'passengerid',
                      isEqualTo: currentUserId,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: safirBrandColor,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(context);
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return TabBarView(
                      children: [
                        _buildEmptyState(
                          context,
                          Icons.history_rounded,
                          'trips_history_empty_msg',
                        ),
                        _buildEmptyState(
                          context,
                          Icons.directions_car_outlined,
                          'no_active_trips',
                        ),
                        _buildEmptyState(
                          context,
                          Icons.cancel_outlined,
                          'no_canceled_trips',
                        ),
                      ],
                    );
                  }

                  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      rides = [...snapshot.data!.docs];

                  rides.sort((a, b) {
                    final DateTime? first =
                        _readDate(b.data()['createdAt']);
                    final DateTime? second =
                        _readDate(a.data()['createdAt']);

                    if (first == null && second == null) {
                      return 0;
                    }

                    if (first == null) {
                      return 1;
                    }

                    if (second == null) {
                      return -1;
                    }

                    return first.compareTo(second);
                  });

                  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      completed = rides.where((doc) {
                    return _isCompleted(
                      _readStatus(doc.data()),
                    );
                  }).toList();

                  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      active = rides.where((doc) {
                    return _isActive(
                      _readStatus(doc.data()),
                    );
                  }).toList();

                  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      canceled = rides.where((doc) {
                    return _isCanceled(
                      _readStatus(doc.data()),
                    );
                  }).toList();

                  return TabBarView(
                    children: [
                      _buildRidesList(
                        context,
                        completed,
                        'trips_history_empty_msg',
                      ),
                      _buildRidesList(
                        context,
                        active,
                        'no_active_trips',
                      ),
                      _buildRidesList(
                        context,
                        canceled,
                        'no_canceled_trips',
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildRidesList(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rides,
    String emptyMessageKey,
  ) {
    if (rides.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.history_rounded,
        emptyMessageKey,
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        return _RideHistoryCard(
          document: rides[index],
          onRepeatTrip: () {
            _repeatTrip(context, rides[index].data());
          },
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    IconData icon,
    String translationKey,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: safirBrandColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44,
                color: safirBrandColor.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              translationKey.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              'error_occurred'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _repeatTrip(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final String origin = _readOrigin(data);
    final String destination = _readDestination(data);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'درخواست دوباره برای $origin تا $destination آماده شد.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: safirBrandColor,
      ),
    );

    // اگر MapScreen شما پارامترهای لازم دارد،
    // اینجا Navigator.push به MapScreen اضافه شود.
  }

  static String _readStatus(
    Map<String, dynamic> data,
  ) {
    return (data['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  static bool _isCompleted(String status) {
    return status == 'completed' ||
        status == 'complete' ||
        status == 'ended' ||
        status == 'finished';
  }

  static bool _isCanceled(String status) {
    return status.contains('cancel') ||
        status == 'rejected' ||
        status == 'declined';
  }

  static bool _isActive(String status) {
    return status == 'searching' ||
        status == 'accepted' ||
        status == 'arrived' ||
        status == 'ontrip' ||
        status == 'on_trip' ||
        status == 'ongoing' ||
        status == 'in_progress';
  }

  static String _readOrigin(
    Map<String, dynamic> data,
  ) {
    return _readFirstString(
      data,
      [
        'originAddress',
        'origin_address',
        'originaddress',
        'pickupaddress',
        'pickup_address',
        'origin',
      ],
      fallback: 'مبدأ مشخص نشده',
    );
  }

  static String _readDestination(
    Map<String, dynamic> data,
  ) {
    return _readFirstString(
      data,
      [
        'destinationAddress',
        'destination_address',
        'destinationaddress',
        'dropoffaddress',
        'dropoff_address',
        'destination',
      ],
      fallback: 'مقصد مشخص نشده',
    );
  }

  static String _readFirstString(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static String _formatDate(dynamic value) {
    final DateTime? date = _readDate(value);

    if (date == null) {
      return '---';
    }

    final String day =
        date.day.toString().padLeft(2, '0');
    final String month =
        date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    final String hour =
        date.hour.toString().padLeft(2, '0');
    final String minute =
        date.minute.toString().padLeft(2, '0');

    return '$year/$month/$day  $hour:$minute';
  }

  static String _formatFare(Map<String, dynamic> data) {
    final dynamic value = data['fareAmount'] ??
        data['fare'] ??
        data['price'] ??
        data['amount'] ??
        0;

    if (value is num) {
      return value.toStringAsFixed(0);
    }

    return value.toString();
  }

  static String _readDriverName(
    Map<String, dynamic> data,
  ) {
    return _readFirstString(
      data,
      [
        'drivername',
        'driverName',
        'driver_name',
        'nameDriver',
      ],
      fallback: 'راننده سفیر',
    );
  }

  static String _readDriverPhone(
    Map<String, dynamic> data,
  ) {
    return _readFirstString(
      data,
      [
        'driverphone',
        'driverPhone',
        'driver_phone',
        'phoneNumberDriver',
      ],
      fallback: '---',
    );
  }

  static String _readCarModel(
    Map<String, dynamic> data,
  ) {
    return _readFirstString(
      data,
      [
        'cardetails',
        'carDetails',
        'carModel',
        'car_model',
        'vehicleModel',
      ],
      fallback: 'موتر سفیر',
    );
  }

  static String _readPlate(
    Map<String, dynamic> data,
  ) {
    return _readFirstString(
      data,
      [
        'plateNumber',
        'platenumber',
        'plate_number',
        'driverPlateNum',
        'driverPlateFarsiNum',
      ],
      fallback: '---',
    );
  }

  static String _readVehicleType(
    Map<String, dynamic> data,
  ) {
    return _readFirstString(
      data,
      [
        'vehicletype',
        'vehicleType',
        'serviceType',
        'service_type',
      ],
      fallback: 'موتر شهری',
    );
  }

  static String _readDriverPhoto(
    Map<String, dynamic> data,
  ) {
    return _readFirstString(
      data,
      [
        'driverphoto',
        'driverPhoto',
        'driver_photo',
        'photoDriver',
        'photo',
      ],
      fallback: '',
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  const _RideHistoryCard({
    required this.document,
    required this.onRepeatTrip,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final VoidCallback onRepeatTrip;

  static const Color textColor = Color(0xFF17202A);
  static const Color mutedColor = Color(0xFF64748B);
  static const Color blueColor = Color(0xFF2563EB);
  static const Color greenColor = Color(0xFF16A34A);
  static const Color redColor = Color(0xFFDC2626);
  static const Color orangeColor = Color(0xFFD97706);

  Map<String, dynamic> get data => document.data();

  String get status => TripsScreen._readStatus(data);

  String get origin => TripsScreen._readOrigin(data);

  String get destination =>
      TripsScreen._readDestination(data);

  String get driverName =>
      TripsScreen._readDriverName(data);

  String get driverPhone =>
      TripsScreen._readDriverPhone(data);

  String get carModel =>
      TripsScreen._readCarModel(data);

  String get plate =>
      TripsScreen._readPlate(data);

  String get vehicleType =>
      TripsScreen._readVehicleType(data);

  String get driverPhoto =>
      TripsScreen._readDriverPhoto(data);

  String get fare =>
      TripsScreen._formatFare(data);

  String get date =>
      TripsScreen._formatDate(data['createdAt']);

  bool get isCanceled =>
      TripsScreen._isCanceled(status);

  bool get isActive =>
      TripsScreen._isActive(status);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            _buildTopSection(),
            _buildDriverSection(),
            _buildRouteSection(),
            _buildFareSection(),
            _buildActionSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon,
                    color: _statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _statusTitle,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            textDirection: ui.TextDirection.ltr,
            style: const TextStyle(
              color: mutedColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        children: [
          _DriverAvatar(imageUrl: driverPhoto),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$carModel  •  $vehicleType',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _InfoPill(
            icon: Icons.confirmation_number_outlined,
            text: plate,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const Icon(
                Icons.radio_button_checked,
                color: blueColor,
                size: 18,
              ),
              Container(
                width: 1.5,
                height: 34,
                color: const Color(0xFFCBD5E1),
              ),
              const Icon(
                Icons.location_on,
                color: redColor,
                size: 19,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'مبدأ سفر',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  origin,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 17),
                const Text(
                  'مقصد سفر',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  destination,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _SmallDetail(
              icon: Icons.payments_outlined,
              title: 'کرایه سفر',
              value: '$fare افغانی',
              color: greenColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SmallDetail(
              icon: Icons.phone_outlined,
              title: 'تماس راننده',
              value: driverPhone,
              color: blueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRepeatTrip,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text(
                'درخواست دوباره',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: safirBrandColor,
                side: BorderSide(
                  color: safirBrandColor.withOpacity(0.35),
                ),
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showTripDetails(context);
              },
              icon: const Icon(
                Icons.receipt_long_outlined,
                size: 17,
              ),
              label: const Text(
                'جزئیات سفر',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: safirBrandColor,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTripDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'جزئیات سفر',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  icon: Icons.person_outline,
                  title: 'راننده',
                  value: driverName,
                ),
                _DetailRow(
                  icon: Icons.directions_car_outlined,
                  title: 'موتر',
                  value: carModel,
                ),
                _DetailRow(
                  icon: Icons.confirmation_number_outlined,
                  title: 'پلاک',
                  value: plate,
                ),
                _DetailRow(
                  icon: Icons.payments_outlined,
                  title: 'کرایه',
                  value: '$fare افغانی',
                ),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  title: 'تاریخ',
                  value: date,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color get _statusColor {
    if (isCanceled) return redColor;
    if (isActive) return orangeColor;
    return greenColor;
  }

  IconData get _statusIcon {
    if (isCanceled) {
      return Icons.cancel_outlined;
    }

    if (isActive) {
      return Icons.timelapse_rounded;
    }

    return Icons.check_circle_outline_rounded;
  }

  String get _statusTitle {
    if (isCanceled) {
      return 'لغو شده';
    }

    if (isActive) {
      return 'در حال انجام';
    }

    return 'تکمیل شده';
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EF),
        shape: BoxShape.circle,
        border: Border.all(
          color: safirBrandColor.withOpacity(0.18),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Icon(
                    Icons.person_rounded,
                    color: safirBrandColor,
                    size: 29,
                  );
                },
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: safirBrandColor,
                      ),
                    ),
                  );
                },
              )
            : Icon(
                Icons.person_rounded,
                color: safirBrandColor,
                size: 29,
              ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 95,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF475569),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: ui.TextDirection.ltr,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallDetail extends StatelessWidget {
  const _SmallDetail({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: safirBrandColor,
          ),
          const SizedBox(width: 10),
          Text(
            '$title:',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF17202A),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// ۲. صفحه دعوت از دوستان
// ----------------------------------------------------
class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String referralCode = "SAFIR-8820";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "invite_friends_title".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: safirBrandColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: safirBrandColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.card_giftcard_rounded, size: 80, color: safirBrandColor),
            ),
            const SizedBox(height: 24),
            Text(
              "invite_friends_main_title".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              "invite_friends_subtext".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: safirBrandColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    referralCode,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: safirBrandColor, letterSpacing: 2),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: safirBrandColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: referralCode));
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("copy_btn".tr())),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                    label: Text("copy_btn".tr(), style: const TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// ۳. صفحه پیام‌ها (کاملاً متصل به Firestore و پیام‌های ادمین)
// ----------------------------------------------------
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "messages_title".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: safirBrandColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: currentUserId == null
          ? Center(child: Text("messages_desc".tr()))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: safirBrandColor));
                }

                if (snapshot.hasError) {
                  return Center(child: Text("error_occurred".tr()));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          "هیچ پیامی دریافت نشده است",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                var notifications = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    var data = notifications[index].data() as Map<String, dynamic>;
                    String title = data['title'] ?? 'اطلاعیه سفیر';
                    String body = data['body'] ?? '';
                    String time = '';

                    if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
                      DateTime date = (data['timestamp'] as Timestamp).toDate();
                      time = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                    } else {
                      time = "today".tr();
                    }

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: safirBrandColor.withOpacity(0.1),
                          child: Icon(Icons.notifications_active_outlined, color: safirBrandColor),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            body,
                            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.7)),
                          ),
                       ),
                        trailing: Text(
                          time,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// ----------------------------------------------------
// ۴. صفحه کدهای تخفیف
// ----------------------------------------------------
class DiscountCodeScreen extends StatelessWidget {
  const DiscountCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController codeController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "discounts_title".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: safirBrandColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      hintText: "enter_discount_code".tr(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: safirBrandColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                  child: Text("apply_btn".tr(), style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text("discounts_empty_msg".tr(), style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// ۵. صفحه سفر بین شهری
// ----------------------------------------------------
class BinShahriScreen extends StatelessWidget {
  const BinShahriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "intercity_title".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: safirBrandColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.my_location, color: Colors.blue),
                      title: Text("origin".tr()),
                      subtitle: Text("origin_province_hint".tr()),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text("destination".tr()),
                      subtitle: Text("select_destination".tr()),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: safirBrandColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                child: Text("request_intercity_ride".tr(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// ۶. صفحه باربری سفیر
// ----------------------------------------------------
class BarbariScreen extends StatelessWidget {
  const BarbariScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "cargo_services_title".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: safirBrandColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildFreightCard(context, Icons.electric_rickshaw, "vehicle_zaranj_title".tr(), "capacity_zaranj".tr()),
          _buildFreightCard(context, Icons.local_shipping_outlined, "vehicle_pickup_title".tr(), "capacity_pickup".tr()),
          _buildFreightCard(context, Icons.fire_truck_outlined, "vehicle_truck_title".tr(), "capacity_truck".tr()),
          _buildFreightCard(context, Icons.inventory_2_outlined, "extra_cargo_services_section".tr(), "packing_help_label".tr()),
        ],
      ),
    );
  }

  Widget _buildFreightCard(BuildContext context, IconData icon, String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: safirBrandColor),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// ۷. صفحه ثبت‌نام رانندگان
// ----------------------------------------------------
class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "driver_registration_title".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: safirBrandColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.time_to_leave_rounded, size: 90, color: safirBrandColor),
            const SizedBox(height: 20),
            Text(
              "register_subtitle".tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "driver_registration_coming_soon".tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: safirBrandColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                child: Text("continue_btn".tr(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
