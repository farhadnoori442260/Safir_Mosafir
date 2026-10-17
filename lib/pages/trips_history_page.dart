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

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final Color safirBrandColor = const Color(0xFF145A41);
  final Color pageBackground = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final String key in keys) {
      final Object? value = data[key];

      if (value == null) continue;

      final String result = value.toString().trim();

      if (result.isNotEmpty && result != 'null') {
        return result;
      }
    }

    return fallback;
  }

  String _getPassengerId(Map<String, dynamic> data) {
    return _getString(data, [
      'passengerid',
      'passenger_id',
      'passengerId',
      'passengerID',
      'userid',
      'user_id',
      'userId',
      'userID',
    ]);
  }

  String _getStatus(Map<String, dynamic> data) {
    return _getString(data, ['status'])
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  bool _isCompleted(String status) {
    return [
      'completed',
      'complete',
      'ended',
      'finished',
    ].contains(status);
  }

  bool _isActive(String status) {
    return [
      'searching',
      'requested',
      'pending',
      'accepted',
      'arrived',
      'ontrip',
      'on_trip',
      'started',
      'in_progress',
    ].contains(status);
  }

  bool _isCancelled(String status) {
    return status.contains('cancel');
  }

  double _getDistance(Map<String, dynamic> data) {
    final Object? value = data['distance'] ??
        data['distanceInKm'] ??
        data['distanceKm'];

    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    final String cleaned = value
        .toString()
        .replaceAll(',', '')
        .replaceAll('km', '')
        .replaceAll('کیلومتر', '')
        .trim();

    return double.tryParse(cleaned) ?? 0;
  }

  DateTime? _getDate(Map<String, dynamic> data) {
    final Object? value = data['completedAt'] ??
        data['endedAt'] ??
        data['updatedAt'] ??
        data['createdAt'] ??
        data['created_at'] ??
        data['timestamp'] ??
        data['date'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  String _formatDate(Map<String, dynamic> data) {
    final DateTime? date = _getDate(data);

    if (date == null) {
      return 'تاریخ ثبت نشده';
    }

    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');

    return '$year/$month/$day  •  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return _buildScaffold(
        body: _buildEmptyState(
          'برای مشاهده تاریخچه وارد حساب کاربری شوید',
        ),
      );
    }

    return _buildScaffold(
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('rides')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(
              'خطا در دریافت اطلاعات سفرها',
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: safirBrandColor,
              ),
            );
          }

          final List<Map<String, dynamic>> passengerTrips =
              <Map<String, dynamic>>[];

          for (final QueryDocumentSnapshot<
              Map<String, dynamic>> document
              in snapshot.data?.docs ?? <QueryDocumentSnapshot<
                  Map<String, dynamic>> >[]) {
            final Map<String, dynamic> data =
                document.data();

            final String passengerId =
                _getPassengerId(data);

            if (passengerId != currentUser.uid) {
              continue;
            }

            passengerTrips.add(<String, dynamic>{
              'documentId': document.id,
              ...data,
            });
          }

          passengerTrips.sort((a, b) {
            final DateTime dateA =
                _getDate(a) ??
                    DateTime.fromMillisecondsSinceEpoch(0);

            final DateTime dateB =
                _getDate(b) ??
                    DateTime.fromMillisecondsSinceEpoch(0);

            return dateB.compareTo(dateA);
          });

          if (passengerTrips.isEmpty) {
            return _buildEmptyState(
              'هیچ سفری در تاریخچه شما ثبت نشده است',
            );
          }

          final List<Map<String, dynamic>> completedTrips =
              passengerTrips.where((trip) {
            return _isCompleted(_getStatus(trip));
          }).toList();

          final List<Map<String, dynamic>> activeTrips =
              passengerTrips.where((trip) {
            return _isActive(_getStatus(trip));
          }).toList();

          final List<Map<String, dynamic>> cancelledTrips =
              passengerTrips.where((trip) {
            return _isCancelled(_getStatus(trip));
          }).toList();

          final double totalKm = passengerTrips.fold<double>(
            0,
            (double total, Map<String, dynamic> trip) {
              return total + _getDistance(trip);
            },
          );

          final int estimatedHours =
              totalKm <= 0 ? 0 : (totalKm / 30).ceil();

          return Column(
            children: [
              _buildStatsHeader(
                km: totalKm.toStringAsFixed(1),
                total: passengerTrips.length,
                hours: estimatedHours,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTripsList(
                      completedTrips,
                      'تکمیل شده',
                    ),
                    _buildTripsList(
                      activeTrips,
                      'جاری',
                    ),
                    _buildTripsList(
                      cancelledTrips,
                      'لغو شده',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScaffold({
    required Widget body,
  }) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'سفرها',
          style: TextStyle(
            color: Color(0xFF242631),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF555B65),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: safirBrandColor,
          indicatorWeight: 3,
          labelColor: const Color(0xFF242631),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'تاریخچه سفرها'),
            Tab(text: 'سفرهای جاری'),
            Tab(text: 'سفرهای لغو شده'),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _buildStatsHeader({
    required String km,
    required int total,
    required int hours,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            Icons.speed_rounded,
            km,
            'کیلومتر',
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.local_taxi_rounded,
            '$total',
            'سفر',
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.access_time_rounded,
            '$hours',
            'ساعت',
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 48,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: safirBrandColor,
            size: 29,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF31343B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(
    List<Map<String, dynamic>> trips,
    String tabName,
  ) {
    if (trips.isEmpty) {
      return _buildEmptyState(
        'هیچ سفری در بخش $tabName یافت نشد',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return _buildTripCard(
          trip: trips[index],
        );
      },
    );
  }

  Widget _buildTripCard({
    required Map<String, dynamic> trip,
  }) {
    final String origin = _getString(
      trip,
      [
        'originAddress',
        'originaddress',
        'pickupaddress',
        'pickup_address',
        'pickUpAddress',
      ],
      fallback: 'مبدأ نامشخص',
    );

    final String destination = _getString(
      trip,
      [
        'destinationAddress',
        'destinationaddress',
        'dropoffaddress',
        'dropoff_address',
        'dropOffAddress',
      ],
      fallback: 'مقصد نامشخص',
    );

    final String fare = _getString(
      trip,
      [
        'fareAmount',
        'fare',
        'price',
        'amount',
      ],
      fallback: '0',
    );

    final String driverName = _getString(
      trip,
      [
        'driver_name',
        'driverName',
        'drivername',
      ],
      fallback: 'راننده سفیر',
    );

    final String carDetails = _getString(
      trip,
      [
        'car_details',
        'carDetails',
        'carModel',
        'car_model',
        'vehicle',
        'vehicletype',
      ],
      fallback: 'خودرو سفیر',
    );

    final String driverPhoto = _getString(
      trip,
      [
        'driver_photo',
        'driverPhoto',
        'driver_profile',
        'driverProfileImage',
        'driver_image',
        'driverImage',
      ],
    );

    final String status =
        _getStatus(trip);

    String statusText = 'تکمیل شده';
    Color statusColor = safirBrandColor;

    if (_isCancelled(status)) {
      statusText = status.contains('driver')
          ? 'لغو شده توسط راننده'
          : 'لغو شده توسط شما';
      statusColor = Colors.redAccent;
    } else if (_isActive(status)) {
      statusText = 'سفر جاری';
      statusColor = Colors.blue;
    }

    return _buildTripCardUi(
      origin: origin,
      destination: destination,
      fare: fare,
      driverName: driverName,
      carDetails: carDetails,
      driverPhoto: driverPhoto,
      statusText: statusText,
      statusColor: statusColor,
      date: _formatDate(trip),
    );
  }

  Widget _buildTripCardUi({
    required String origin,
    required String destination,
    required String fare,
    required String driverName,
    required String carDetails,
    required String driverPhoto,
    required String statusText,
    required Color statusColor,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRoutePreview(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              12,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 29,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: driverPhoto.isNotEmpty
                      ? NetworkImage(driverPhoto)
                      : null,
                  child: driverPhoto.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 11),
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333640),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        carDetails,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: statusColor,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              statusText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        fare,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: safirBrandColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'افغانی',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (date.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                10,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),
          _buildAddressRow(
            icon: Icons.circle,
            iconColor: const Color(0xFF69717B),
            address: origin,
          ),
          _buildAddressRow(
            icon: Icons.stop_rounded,
            iconColor: const Color(0xFF69717B),
            address: destination,
          ),
          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'برگشت این سفر',
                ),
              ),
              Container(
                height: 43,
                width: 1,
                color: Colors.grey.shade200,
              ),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.repeat_rounded,
                  label: 'تکرار این سفر',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePreview() {
    return Container(
      height: 155,
      color: const Color(0xFFF0F1F2),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RoutePreviewPainter(
                routeColor: safirBrandColor,
              ),
            ),
          ),
          Positioned(
            top: 39,
            left: 22,
            child: _mapPointLabel(
              'مبدأ',
              Icons.circle,
            ),
          ),
          Positioned(
            bottom: 35,
            right: 22,
            child: _mapPointLabel(
              'مقصد',
              Icons.stop_rounded,
            ),
          ),
          Positioned(
            top: 9,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.map_outlined,
                size: 18,
                color: safirBrandColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapPointLabel(
    String label,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: const Color(0xFF555D65),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF42464D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required Color iconColor,
    required String address,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 15,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF747982),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$label به‌زودی فعال می‌شود',
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF5965C5),
              size: 19,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF5965C5),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 58,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 54,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePreviewPainter extends CustomPainter {
  final Color routeColor;

  const _RoutePreviewPainter({
    required this.routeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint minorRoadPaint = Paint()
      ..color = const Color(0xFFDADDE0)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final Paint roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint routePaint = Paint()
      ..color = routeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final double y = size.height * (i + 1) / 6;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y - 14),
        minorRoadPaint,
      );
    }

    for (int i = 0; i < 6; i++) {
      final double x = size.width * (i + 1) / 7;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x - 22, size.height),
        minorRoadPaint,
      );
    }

    final Path roadPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..lineTo(size.width * 0.25, size.height * 0.58)
      ..lineTo(size.width * 0.48, size.height * 0.67)
      ..lineTo(size.width * 0.68, size.height * 0.40)
      ..lineTo(size.width, size.height * 0.32);

    canvas.drawPath(roadPath, roadPaint);

    final Path routePath = Path()
      ..moveTo(size.width * 0.12, size.height * 0.36)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.20,
        size.width * 0.34,
        size.height * 0.83,
        size.width * 0.52,
        size.height * 0.65,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.45,
        size.width * 0.78,
        size.height * 0.35,
        size.width * 0.88,
        size.height * 0.70,
      );

    canvas.drawPath(routePath, routePaint);

    final Paint pointBorderPaint = Paint()
      ..color = Colors.white;

    final Paint startPaint = Paint()
      ..color = routeColor;

    final Paint endPaint = Paint()
      ..color = const Color(0xFF555D65);

    final Offset start = Offset(
      size.width * 0.12,
      size.height * 0.36,
    );

    final Offset end = Offset(
      size.width * 0.88,
      size.height * 0.70,
    );

    canvas.drawCircle(start, 8, pointBorderPaint);
    canvas.drawCircle(start, 5, startPaint);

    canvas.drawCircle(end, 8, pointBorderPaint);
    canvas.drawCircle(end, 5, endPaint);
  }

  @override
  bool shouldRepaint(
    covariant _RoutePreviewPainter oldDelegate,
  ) {
    return oldDelegate.routeColor != routeColor;
  }
}
