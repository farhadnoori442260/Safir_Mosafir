import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({super.key});

  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ فقط سفرهای خود مسافر خوانده می‌شود.
  /// (قبلاً کل کلکسیون rides خوانده می‌شد و قوانین Firestore آن را رد می‌کرد
  /// و به همین دلیل صفحه همیشه خالی بود.)
  Stream<QuerySnapshot<Map<String, dynamic>>>? _ridesStream;
  String? _streamUid;

  // ───────── رنگ‌ها ─────────
  static const Color _brand = Color(0xFF145A41);
  static const Color _brandSoft = Color(0xFFE6F2EC);
  static const Color _pageBackground = Color(0xFFF6F8FA);
  static const Color _ink = Color(0xFF1F2430);
  static const Color _muted = Color(0xFF7A8290);
  static const Color _line = Color(0xFFE8ECF0);
  static const Color _action = Color(0xFF4F5BD5);

  /// سفری که بیشتر از این مدت در حالت «جستجو» مانده، منقضی حساب می‌شود
  static const Duration _searchExpiry = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _prepareStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _prepareStream() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      _ridesStream = null;
      _streamUid = null;
      return;
    }

    if (_streamUid == uid && _ridesStream != null) return;

    _streamUid = uid;
    _ridesStream = _firestore
        .collection('rides')
        .where('passenger_id', isEqualTo: uid)
        .snapshots();
  }

  // ════════════════════════════════════════════════════════════
  //  ابزارهای عدد و متن
  // ════════════════════════════════════════════════════════════

  static const String _enDigits = '0123456789';
  static const String _faDigits = '۰۱۲۳۴۵۶۷۸۹';
  static const String _arDigits = '٠١٢٣٤٥٦٧٨٩';

  /// تبدیل ارقام فارسی/عربی به انگلیسی (برای پردازش)
  String _toEnglishDigits(String input) {
    String s = input;
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(_faDigits[i], _enDigits[i]).replaceAll(_arDigits[i], _enDigits[i]);
    }
    return s;
  }

  /// تبدیل ارقام انگلیسی به فارسی (برای نمایش)
  String _toFa(Object? value) {
    String s = value.toString();
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(_enDigits[i], _faDigits[i]);
    }
    return s;
  }

  String _withThousands(int number) {
    final String raw = number.abs().toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(',');
      buffer.write(raw[i]);
    }

    return (number < 0 ? '-' : '') + buffer.toString();
  }

  String _valueToString(Object? value) {
    if (value == null) return '';
    if (value is DocumentReference) return value.id.trim();

    final String result = value.toString().trim();
    if (result.isEmpty || result == 'null') return '';
    return result;
  }

  String _getString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final String key in keys) {
      final String result = _valueToString(data[key]);
      if (result.isNotEmpty) return result;
    }
    return fallback;
  }

  /// تبدیل هر مقدار (عدد، متن فارسی، متن دارای ویرگول) به double
  double _parseNumber(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();

    String s = _toEnglishDigits(value.toString());
    s = s.replaceAll(RegExp(r'[,،٬\s]'), '').replaceAll('٫', '.');
    s = s.replaceAll(RegExp(r'[^0-9.\-]'), '');

    return double.tryParse(s) ?? 0;
  }

  // ════════════════════════════════════════════════════════════
  //  تاریخ شمسی (هجری شمسی افغانستان)
  // ════════════════════════════════════════════════════════════

  static const List<String> _afghanMonths = <String>[
    'حمل',
    'ثور',
    'جوزا',
    'سرطان',
    'اسد',
    'سنبله',
    'میزان',
    'عقرب',
    'قوس',
    'جدی',
    'دلو',
    'حوت',
  ];

  static const List<String> _weekDays = <String>[
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
  ];

  /// تبدیل میلادی به شمسی؛ خروجی: [سال، ماه، روز]
  List<int> _gregorianToJalali(int gy, int gm, int gd) {
    const List<int> gDaysBefore = <int>[
      0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334,
    ];

    int jy = gy <= 1600 ? 0 : 979;
    int y = gy <= 1600 ? gy - 621 : gy - 1600;

    final int y2 = gm > 2 ? y + 1 : y;

    int days = (365 * y) +
        ((y2 + 3) ~/ 4) -
        ((y2 + 99) ~/ 100) +
        ((y2 + 399) ~/ 400) -
        80 +
        gd +
        gDaysBefore[gm - 1];

    jy += 33 * (days ~/ 12053);
    days %= 12053;

    jy += 4 * (days ~/ 1461);
    days %= 1461;

    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }

    final int jm = days < 186 ? 1 + days ~/ 31 : 7 + (days - 186) ~/ 30;
    final int jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);

    return <int>[jy, jm, jd];
  }

  String _formatJalaliDate(DateTime date) {
    final DateTime local = date.toLocal();
    final List<int> j = _gregorianToJalali(local.year, local.month, local.day);

    final String weekDay = _weekDays[(local.weekday + 1) % 7];
    final String month = _afghanMonths[j[1] - 1];

    final int hour24 = local.hour;
    final int hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final String minute = local.minute.toString().padLeft(2, '0');

    String period;
    if (hour24 < 12) {
      period = 'صبح';
    } else if (hour24 < 16) {
      period = 'بعد از ظهر';
    } else if (hour24 < 19) {
      period = 'عصر';
    } else {
      period = 'شب';
    }

    return '$weekDay ${_toFa(j[2])} $month ${_toFa(j[0])}'
        ' • ${_toFa(hour12)}:${_toFa(minute)} $period';
  }

  // ════════════════════════════════════════════════════════════
  //  وضعیت‌ها
  // ════════════════════════════════════════════════════════════

  String _normalizeStatus(Map<String, dynamic> data) {
    final String status = _getString(
      data,
      <String>['status', 'tripStatus', 'trip_status', 'rideStatus', 'ride_status'],
    );

    return status.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  }

  bool _isCompletedStatus(String s) => const <String>{
        'completed',
        'complete',
        'ended',
        'finished',
        'done',
        'completed_trip',
      }.contains(s);

  bool _isActiveStatus(String s) => const <String>{
        'searching',
        'requested',
        'pending',
        'accepted',
        'arrived',
        'ontrip',
        'on_trip',
        'started',
        'in_progress',
        'inprogress',
        'ongoing',
        'active',
      }.contains(s);

  bool _isCancelledStatus(String s) => s.contains('cancel') || s.contains('لغو');

  DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is double) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  DateTime? _createdAt(Map<String, dynamic> data) {
    return _readDate(
      data['createdAt'] ?? data['created_at'] ?? data['timestamp'] ?? data['date'],
    );
  }

  DateTime? _displayDate(Map<String, dynamic> data) {
    return _readDate(
          data['completed_at'] ??
              data['completedAt'] ??
              data['ended_at'] ??
              data['endedAt'] ??
              data['cancelled_at'] ??
              data['cancelledAt'],
        ) ??
        _createdAt(data) ??
        _readDate(data['updated_at'] ?? data['updatedAt']);
  }

  /// مدت سفر به دقیقه (از متن «۱ ساعت و ۵ دقیقه» یا عدد)
  int _parseMinutes(Map<String, dynamic> data, double km) {
    final Object? raw = data['duration'] ??
        data['trip_duration'] ??
        data['durationMinutes'] ??
        data['estimatedDuration'];

    if (raw is num) return raw.round();

    if (raw != null) {
      final String text = _toEnglishDigits(raw.toString());

      final RegExpMatch? h = RegExp(r'(\d+)\s*ساعت').firstMatch(text);
      final RegExpMatch? m = RegExp(r'(\d+)\s*دقیقه').firstMatch(text);

      final int hours = h != null ? int.parse(h.group(1)!) : 0;
      final int minutes = m != null ? int.parse(m.group(1)!) : 0;

      if (hours > 0 || minutes > 0) return hours * 60 + minutes;

      final double plain = _parseNumber(text);
      if (plain > 0) return plain.round();
    }

    // اگر مدت ثبت نشده بود، با سرعت متوسط ۳۰ کیلومتر در ساعت تخمین بزن
    return km <= 0 ? 0 : (km / 30 * 60).round();
  }

  // ════════════════════════════════════════════════════════════
  //  ساخت مدل نمایشی (یک بار برای هر snapshot)
  // ════════════════════════════════════════════════════════════

  _TripItem _buildItem(String id, Map<String, dynamic> data) {
    final String status = _normalizeStatus(data);
    final DateTime? created = _createdAt(data);

    final bool expiredSearch = status == 'searching' &&
        created != null &&
        DateTime.now().difference(created) > _searchExpiry;

    _TripGroup group = _TripGroup.other;
    String statusText = 'سفر';
    Color statusColor = _muted;

    if (_isCompletedStatus(status)) {
      group = _TripGroup.completed;
      statusText = 'تکمیل شده';
      statusColor = _brand;
    } else if (_isCancelledStatus(status)) {
      group = _TripGroup.cancelled;
      statusColor = const Color(0xFFE5484D);

      final String reason = _getString(data, <String>['cancel_reason']);
      final String by = _getString(data, <String>['cancelled_by']).toLowerCase();

      if (reason == 'no_driver_found') {
        statusText = 'راننده‌ای پیدا نشد';
      } else if (status.contains('driver') || by == 'driver') {
        statusText = 'لغو شده توسط راننده';
      } else if (status.contains('passenger') || by == 'passenger') {
        statusText = 'لغو شده توسط شما';
      } else {
        statusText = 'لغو شده';
      }
    } else if (expiredSearch) {
      group = _TripGroup.cancelled;
      statusText = 'منقضی شد، راننده‌ای پیدا نشد';
      statusColor = const Color(0xFFE5484D);
    } else if (_isActiveStatus(status)) {
      group = _TripGroup.active;
      statusColor = const Color(0xFF2F6FED);

      switch (status) {
        case 'searching':
        case 'requested':
        case 'pending':
          statusText = 'در جستجوی راننده';
          break;
        case 'accepted':
          statusText = 'راننده در راه است';
          break;
        case 'arrived':
          statusText = 'راننده به مبدأ رسید';
          break;
        default:
          statusText = 'سفر در جریان است';
      }
    }

    final String origin = _getString(
      data,
      <String>[
        'originAddress',
        'origin_address',
        'pickup_address',
        'pickUpAddress',
        'pickupAddress',
        'originaddress',
        'pickupaddress',
        'startAddress',
        'start_address',
      ],
      fallback: 'مبدأ نامشخص',
    );

    final String destination = _getString(
      data,
      <String>[
        'destinationAddress',
        'destination_address',
        'dropoff_address',
        'dropOffAddress',
        'dropoffAddress',
        'destinationaddress',
        'dropoffaddress',
        'endAddress',
        'end_address',
      ],
      fallback: 'مقصد نامشخص',
    );

    final double fareValue = _parseNumber(
      data['final_fare'] ??
          data['total_fare'] ??
          data['fareAmount'] ??
          data['fare_amount'] ??
          data['fare'] ??
          data['price'] ??
          data['amount'] ??
          data['totalFare'],
    );

    final double km = _parseNumber(
      data['distance'] ??
          data['distanceInKm'] ??
          data['distanceKm'] ??
          data['distance_km'],
    );

    final bool hasDriver = group == _TripGroup.completed ||
        status == 'accepted' ||
        status == 'arrived' ||
        status == 'ontrip' ||
        status == 'on_trip' ||
        _getString(data, <String>['driver_name', 'driverName']).isNotEmpty;

    final String driverName = _getString(
      data,
      <String>['driver_name', 'driverName', 'drivername', 'driverFullName'],
      fallback: hasDriver ? 'راننده سفیر' : 'راننده تعیین نشده',
    );

    final String carDetails = _getString(
      data,
      <String>[
        'car_details',
        'carDetails',
        'carModel',
        'car_model',
        'vehicle',
        'vehicletype',
        'vehicleType',
      ],
      fallback: '',
    );

    final String driverPhoto = _getString(
      data,
      <String>[
        'driver_photo',
        'driverPhoto',
        'driver_profile',
        'driverProfileImage',
        'driver_image',
        'driverImage',
      ],
    );

    final DateTime? date = _displayDate(data);

    return _TripItem(
      id: id,
      group: group,
      origin: origin,
      destination: destination,
      fareText: _toFa(_withThousands(fareValue.round())),
      driverName: driverName,
      carDetails: carDetails.replaceAll(RegExp(r'^\s*-\s*|\s*-\s*$'), '').trim(),
      driverPhoto: driverPhoto,
      statusText: statusText,
      statusColor: statusColor,
      dateText: date == null ? 'تاریخ ثبت نشده' : _formatJalaliDate(date),
      sortDate: date ?? DateTime.fromMillisecondsSinceEpoch(0),
      km: km,
      minutes: _parseMinutes(data, km),
      seed: id.hashCode,
    );
  }

  // ════════════════════════════════════════════════════════════
  //  رابط کاربری
  // ════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    _prepareStream();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: _buildScaffold(
        body: _ridesStream == null
            ? _buildMessageState(
                icon: Icons.lock_outline_rounded,
                message: 'برای مشاهده تاریخچه وارد حساب کاربری شوید',
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _ridesStream,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
                ) {
                  if (snapshot.hasError) {
                    debugPrint('Trips history error: ${snapshot.error}');
                    return _buildMessageState(
                      icon: Icons.cloud_off_rounded,
                      message: 'خطا در دریافت اطلاعات سفرها.\nاتصال اینترنت را بررسی کنید.',
                      isError: true,
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _brand),
                    );
                  }

                  final List<_TripItem> trips = snapshot.data!.docs
                      .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                          _buildItem(d.id, d.data()))
                      .where((_TripItem t) => t.group != _TripGroup.other)
                      .toList()
                    ..sort((_TripItem a, _TripItem b) => b.sortDate.compareTo(a.sortDate));

                  final List<_TripItem> completed =
                      trips.where((_TripItem t) => t.group == _TripGroup.completed).toList();
                  final List<_TripItem> active =
                      trips.where((_TripItem t) => t.group == _TripGroup.active).toList();
                  final List<_TripItem> cancelled =
                      trips.where((_TripItem t) => t.group == _TripGroup.cancelled).toList();

                  // آمار فقط از سفرهای تکمیل‌شده
                  final double totalKm =
                      completed.fold<double>(0, (double s, _TripItem t) => s + t.km);
                  final int totalMinutes =
                      completed.fold<int>(0, (int s, _TripItem t) => s + t.minutes);

                  return Column(
                    children: <Widget>[
                      _buildStatsHeader(
                        km: totalKm,
                        total: completed.length,
                        minutes: totalMinutes,
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: <Widget>[
                            _buildTripsList(
                              completed,
                              'هنوز سفر تکمیل‌شده‌ای ندارید',
                            ),
                            _buildTripsList(
                              active,
                              'سفر جاری ندارید',
                            ),
                            _buildTripsList(
                              cancelled,
                              'سفر لغوشده‌ای ندارید',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildScaffold({required Widget body}) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        title: const Text(
          'سفرها',
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF555B65),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _line)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: _brand,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelColor: _ink,
              unselectedLabelColor: _muted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const <Widget>[
                Tab(text: 'تاریخچه سفرها'),
                Tab(text: 'سفرهای جاری'),
                Tab(text: 'سفرهای لغو شده'),
              ],
            ),
          ),
        ),
      ),
      body: body,
    );
  }

  Widget _buildStatsHeader({
    required double km,
    required int total,
    required int minutes,
  }) {
    final String kmText = km >= 100
        ? _toFa(km.round())
        : _toFa(km.toStringAsFixed(1)).replaceAll('.', '٫');

    final double hoursValue = minutes / 60;
    final String hoursText = hoursValue >= 10
        ? _toFa(hoursValue.round())
        : _toFa(hoursValue.toStringAsFixed(1)).replaceAll('.', '٫');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _buildStatItem(Icons.speed_rounded, kmText, 'کیلومتر'),
          _buildStatDivider(),
          _buildStatItem(Icons.local_taxi_rounded, _toFa(total), 'سفر'),
          _buildStatDivider(),
          _buildStatItem(Icons.schedule_rounded, hoursText, 'ساعت'),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 46, width: 1, color: _line);
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _brandSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _brand, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: _ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(List<_TripItem> trips, String emptyMessage) {
    if (trips.isEmpty) {
      return _buildMessageState(
        icon: Icons.history_toggle_off_rounded,
        message: emptyMessage,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: trips.length,
      itemBuilder: (BuildContext context, int index) {
        final _TripItem trip = trips[index];

        return RepaintBoundary(
          key: ValueKey<String>(trip.id),
          child: _buildTripCard(trip),
        );
      },
    );
  }

  Widget _buildTripCard(_TripItem trip) {
    final bool showActions = trip.group != _TripGroup.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildRoutePreview(trip),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: <Widget>[
                _buildDriverAvatar(trip.driverPhoto),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        trip.driverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      if (trip.carDetails.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          trip.carDetails,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: _muted),
                        ),
                      ],
                      const SizedBox(height: 7),
                      _buildStatusChip(trip),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildFarePill(trip),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: <Widget>[
                const Icon(Icons.calendar_today_rounded, size: 14, color: _muted),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    trip.dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _line),
          _buildAddressTimeline(trip),
          if (showActions) ...<Widget>[
            const Divider(height: 1, color: _line),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.swap_horiz_rounded,
                    label: 'برگشت این سفر',
                  ),
                ),
                Container(height: 44, width: 1, color: _line),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.replay_rounded,
                    label: 'تکرار این سفر',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverAvatar(String photo) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF1F3F5),
        border: Border.all(color: _line, width: 1.5),
      ),
      child: ClipOval(
        child: photo.isNotEmpty
            ? Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF9AA3AF),
                  size: 30,
                ),
                loadingBuilder: (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? progress,
                ) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _brand,
                      ),
                    ),
                  );
                },
              )
            : const Icon(
                Icons.person_rounded,
                color: Color(0xFF9AA3AF),
                size: 30,
              ),
      ),
    );
  }

  Widget _buildStatusChip(_TripItem trip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: trip.statusColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: trip.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              trip.statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: trip.statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarePill(_TripItem trip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            trip.fareText,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: _brand,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'افغانی',
            style: TextStyle(fontSize: 10, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTimeline(_TripItem trip) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: <Widget>[
          _buildAddressRow(
            address: trip.origin,
            dot: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: _brand, width: 3),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 5),
              child: Container(
                width: 2,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DAE0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          _buildAddressRow(
            address: trip.destination,
            dot: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF3B4250),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow({
    required String address,
    required Widget dot,
  }) {
    return Row(
      children: <Widget>[
        SizedBox(width: 12, child: Center(child: dot)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF4A5160),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label به‌زودی فعال می‌شود')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: _action, size: 19),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _action,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutePreview(_TripItem trip) {
    final _RouteGeometry geometry = _RouteGeometry.fromSeed(trip.seed);

    return SizedBox(
      height: 150,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;

          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoutePreviewPainter(
                    geometry: geometry,
                    routeColor: trip.group == _TripGroup.cancelled
                        ? const Color(0xFFB4BBC6)
                        : _brand,
                    seed: trip.seed,
                  ),
                ),
              ),
              Positioned(
                left: geometry.start.dx * w,
                top: geometry.start.dy * h,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -1.45),
                  child: _mapPointLabel('مبدأ'),
                ),
              ),
              Positioned(
                left: geometry.end.dx * w,
                top: geometry.end.dy * h,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -1.45),
                  child: _mapPointLabel('مقصد'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mapPointLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF3B4250),
        ),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String message,
    bool isError = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: isError
                    ? const Color(0xFFFDECEC)
                    : const Color(0xFFEFF2F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 42,
                color: isError ? const Color(0xFFE5484D) : const Color(0xFF9AA3AF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.6,
                color: isError ? const Color(0xFFE5484D) : _muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  مدل نمایشی هر سفر
// ══════════════════════════════════════════════════════════════

enum _TripGroup { completed, active, cancelled, other }

class _TripItem {
  final String id;
  final _TripGroup group;
  final String origin;
  final String destination;
  final String fareText;
  final String driverName;
  final String carDetails;
  final String driverPhoto;
  final String statusText;
  final Color statusColor;
  final String dateText;
  final DateTime sortDate;
  final double km;
  final int minutes;
  final int seed;

  const _TripItem({
    required this.id,
    required this.group,
    required this.origin,
    required this.destination,
    required this.fareText,
    required this.driverName,
    required this.carDetails,
    required this.driverPhoto,
    required this.statusText,
    required this.statusColor,
    required this.dateText,
    required this.sortDate,
    required this.km,
    required this.minutes,
    required this.seed,
  });
}

// ══════════════════════════════════════════════════════════════
//  پیش‌نمایش مسیر (سبک و بدون نیاز به نقشهٔ واقعی)
// ══════════════════════════════════════════════════════════════

class _RouteGeometry {
  final Offset start;
  final Offset end;
  final Offset c1;
  final Offset c2;
  final Offset mid;
  final Offset c3;
  final Offset c4;

  const _RouteGeometry({
    required this.start,
    required this.end,
    required this.c1,
    required this.c2,
    required this.mid,
    required this.c3,
    required this.c4,
  });

  /// برای هر سفر یک شکل ثابت اما متفاوت می‌سازد
  factory _RouteGeometry.fromSeed(int seed) {
    final Random r = Random(seed);

    double between(double a, double b) => a + r.nextDouble() * (b - a);

    return _RouteGeometry(
      start: Offset(between(0.14, 0.24), between(0.38, 0.55)),
      end: Offset(between(0.76, 0.86), between(0.58, 0.78)),
      c1: Offset(between(0.22, 0.36), between(0.18, 0.40)),
      c2: Offset(between(0.30, 0.44), between(0.60, 0.88)),
      mid: Offset(between(0.46, 0.56), between(0.42, 0.62)),
      c3: Offset(between(0.58, 0.70), between(0.20, 0.45)),
      c4: Offset(between(0.68, 0.82), between(0.30, 0.55)),
    );
  }
}

class _RoutePreviewPainter extends CustomPainter {
  final _RouteGeometry geometry;
  final Color routeColor;
  final int seed;

  const _RoutePreviewPainter({
    required this.geometry,
    required this.routeColor,
    required this.seed,
  });

  Offset _p(Offset f, Size s) => Offset(f.dx * s.width, f.dy * s.height);

  @override
  void paint(Canvas canvas, Size size) {
    // پس‌زمینه
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEEF1F3),
    );

    final Random r = Random(seed ^ 0x5bd1e995);

    // بلوک‌های ساختمانی
    final Paint blockPaint = Paint()..color = const Color(0xFFE3E7EA);
    for (int i = 0; i < 9; i++) {
      final double bw = 30 + r.nextDouble() * 50;
      final double bh = 18 + r.nextDouble() * 34;
      final double bx = r.nextDouble() * (size.width - bw);
      final double by = r.nextDouble() * (size.height - bh);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, bw, bh),
          const Radius.circular(6),
        ),
        blockPaint,
      );
    }

    // خیابان‌های فرعی
    final Paint minorRoad = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final double y = size.height * (0.15 + i * 0.24);
      canvas.drawLine(
        Offset(0, y + r.nextDouble() * 14),
        Offset(size.width, y - r.nextDouble() * 22),
        minorRoad,
      );
    }

    for (int i = 0; i < 5; i++) {
      final double x = size.width * (0.1 + i * 0.2);
      canvas.drawLine(
        Offset(x + r.nextDouble() * 12, 0),
        Offset(x - r.nextDouble() * 26, size.height),
        minorRoad,
      );
    }

    // مسیر
    final Offset start = _p(geometry.start, size);
    final Offset end = _p(geometry.end, size);

    final Path route = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        _p(geometry.c1, size).dx,
        _p(geometry.c1, size).dy,
        _p(geometry.c2, size).dx,
        _p(geometry.c2, size).dy,
        _p(geometry.mid, size).dx,
        _p(geometry.mid, size).dy,
      )
      ..cubicTo(
        _p(geometry.c3, size).dx,
        _p(geometry.c3, size).dy,
        _p(geometry.c4, size).dx,
        _p(geometry.c4, size).dy,
        end.dx,
        end.dy,
      );

    // حاشیهٔ سفید زیر مسیر
    canvas.drawPath(
      route,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    canvas.drawPath(
      route,
      Paint()
        ..color = routeColor
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // نقطهٔ مبدأ
    canvas.drawCircle(start, 9, Paint()..color = Colors.white);
    canvas.drawCircle(start, 5.5, Paint()..color = routeColor);

    // نقطهٔ مقصد
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: end, width: 18, height: 18),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: end, width: 11, height: 11),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF3B4250),
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePreviewPainter oldDelegate) {
    return oldDelegate.routeColor != routeColor || oldDelegate.seed != seed;
  }
}
