
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
  late TabController _tabController;

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

  String _getString(Map<String, dynamic> data, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _formatDate(Map<String, dynamic> trip) {
    dynamic value = trip['createdAt'] ??
        trip['created_at'] ??
        trip['timestamp'] ??
        trip['date'];

    if (value == null) return '';

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is int) {
      date = DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return value.toString();

    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$y/$m/$d  •  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF555B65)),
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
      body: currentUserId == null
          ? _buildEmptyState('برای مشاهده تاریخچه وارد حساب کاربری شوید')
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'خطا در دریافت اطلاعات: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: safirBrandColor,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState('هیچ سفری یافت نشد');
                }

                final allDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final pId = _getString(data, [
                    'passenger_id',
                    'passengerId',
                    'userID',
                  ]);
                  return pId == currentUserId;
                }).toList();

                if (allDocs.isEmpty) {
                  return _buildEmptyState(
                    'هیچ سفری در تاریخچه شما ثبت نشده است',
                  );
                }

                double totalKm = 0;
                for (final doc in allDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final distance = data['distance'];
                  if (distance != null) {
                    totalKm +=
                        double.tryParse(distance.toString()) ?? 0.0;
                  }
                }

                final totalTrips = allDocs.length;
                final estimatedHours = (totalKm / 30).ceil();

                final completedTrips = allDocs.where((doc) {
                  final status = _getString(
                    doc.data() as Map<String, dynamic>,
                    ['status'],
                  ).toLowerCase();
                  return status == 'completed' || status == 'ended';
                }).toList();

                final activeTrips = allDocs.where((doc) {
                  final status = _getString(
                    doc.data() as Map<String, dynamic>,
                    ['status'],
                  ).toLowerCase();
                  return [
                    'searching',
                    'accepted',
                    'arrived',
                    'ontrip',
                    'on_trip',
                  ].contains(status);
                }).toList();

                final cancelledTrips = allDocs.where((doc) {
                  final status = _getString(
                    doc.data() as Map<String, dynamic>,
                    ['status'],
                  ).toLowerCase();
                  return status.contains('cancel');
                }).toList();

                return Column(
                  children: [
                    _buildStatsHeader(
                      totalKm.toStringAsFixed(1),
                      totalTrips,
                      estimatedHours,
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTripsList(completedTrips, 'تکمیل شده'),
                          _buildTripsList(activeTrips, 'جاری'),
                          _buildTripsList(cancelledTrips, 'لغو شده'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildStatsHeader(String km, int total, int hours) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
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
          _buildStatItem(Icons.speed_rounded, km, 'کیلومتر'),
          _buildStatDivider(),
          _buildStatItem(Icons.local_taxi_rounded, '$total', 'سفر'),
          _buildStatDivider(),
          _buildStatItem(Icons.access_time_rounded, '$hours', 'ساعت'),
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

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: safirBrandColor, size: 29),
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
          const SizedBox(height: 3),
          Text(
            'با سفیر!',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(
    List<QueryDocumentSnapshot> docs,
    String tabName,
  ) {
    if (docs.isEmpty) {
      return _buildEmptyState('هیچ سفری در بخش $tabName یافت نشد');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final trip = docs[index].data() as Map<String, dynamic>;

        final origin = _getString(trip, [
          'originAddress',
          'origin_address',
          'pickup_address',
        ], fallback: 'مبدأ نامشخص');

        final destination = _getString(trip, [
          'destinationAddress',
          'destination_address',
          'dropoff_address',
        ], fallback: 'مقصد نامشخص');

        final fare = _getString(trip, [
          'fareAmount',
          'fare',
          'price',
        ], fallback: '0');

        final driverName = _getString(trip, [
          'driver_name',
          'driverName',
        ], fallback: 'راننده سفیر');

        final carDetails = _getString(trip, [
          'car_details',
          'carModel',
          'car_model',
          'vehicle',
        ], fallback: 'خودرو سفیر');

        final driverPhoto = _getString(trip, [
          'driver_photo',
          'driverPhoto',
          'driver_profile',
          'driverProfileImage',
          'driver_image',
          'driverImage',
        ]);

        final status = _getString(trip, ['status']);
        final date = _formatDate(trip);

        final lowerStatus = status.toLowerCase();
        String statusText = 'تکمیل شده';
        Color statusColor = safirBrandColor;

        if (lowerStatus.contains('cancel')) {
          statusText = lowerStatus.contains('passenger')
              ? 'لغو شده توسط شما'
              : 'لغو شده توسط راننده';
          statusColor = Colors.redAccent;
        } else if ([
          'searching',
          'accepted',
          'arrived',
          'ontrip',
          'on_trip',
        ].contains(lowerStatus)) {
          statusText = 'سفر جاری';
          statusColor = Colors.blue;
        }

        return _buildTripCard(
          origin: origin,
          destination: destination,
          fare: fare,
          driverName: driverName,
          carDetails: carDetails,
          driverPhoto: driverPhoto,
          statusText: statusText,
          statusColor: statusColor,
          date: date,
        );
      },
    );
  }

  Widget _buildTripCard({
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
          // پیش‌نمایش مسیر
          _buildRoutePreview(),

          // اطلاعات راننده و کرایه
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                    border: Border.all(color: Colors.grey.shade200),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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

          Divider(height: 1, color: Colors.grey.shade200),

          // مبدأ
          _buildAddressRow(
            icon: Icons.circle,
            iconColor: const Color(0xFF69717B),
            address: origin,
          ),

          // مقصد
          _buildAddressRow(
            icon: Icons.stop_rounded,
            iconColor: const Color(0xFF69717B),
            address: destination,
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // دکمه‌های پایین کارت
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'برگشت این سفر',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'برای برگشت به مبدأ، این قابلیت هنوز متصل نشده است',
                        ),
                      ),
                    );
                  },
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'برای تکرار سفر، این قابلیت هنوز متصل نشده است',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // پیش‌نمایش گرافیکی مسیر
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
            child: _mapPointLabel('مبدأ', Icons.circle),
          ),
          Positioned(
            bottom: 35,
            right: 22,
            child: _mapPointLabel('مقصد', Icons.stop_rounded),
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

  Widget _mapPointLabel(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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
          Icon(icon, size: 13, color: const Color(0xFF555D65)),
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
          Icon(icon, color: iconColor, size: 15),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
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
}

// ترسیم مسیر تزئینی برای پیش‌نمایش کارت
class _RoutePreviewPainter extends CustomPainter {
  final Color routeColor;

  _RoutePreviewPainter({required this.routeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = const Color(0xFFDADDE0)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = routeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // خیابان‌های پس‌زمینه
    for (int i = 0; i < 5; i++) {
      final y = size.height * (i + 1) / 6;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y - 14),
        minorRoadPaint,
      );
    }

    for (int i = 0; i < 6; i++) {
      final x = size.width * (i + 1) / 7;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - 22, size.height),
        minorRoadPaint,
      );
    }

    // خیابان اصلی
    final roadPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..lineTo(size.width * 0.25, size.height * 0.58)
      ..lineTo(size.width * 0.48, size.height * 0.67)
      ..lineTo(size.width * 0.68, size.height * 0.40)
      ..lineTo(size.width, size.height * 0.32);

    canvas.drawPath(roadPath, roadPaint);

    // مسیر سفر
    final path = Path()
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

    canvas.drawPath(path, routePaint);

    // نقطه‌های ابتدا و انتهای مسیر
    final pointPaint = Paint()..color = Colors.white;
    final startPaint = Paint()..color = routeColor;
    final endPaint = Paint()..color = const Color(0xFF555D65);

    final start = Offset(size.width * 0.12, size.height * 0.36);
    final end = Offset(size.width * 0.88, size.height * 0.70);

    canvas.drawCircle(start, 8, pointPaint);
    canvas.drawCircle(start, 5, startPaint);

    canvas.drawCircle(end, 8, pointPaint);
    canvas.drawCircle(end, 5, endPaint);
  }

  @override
  bool shouldRepaint(covariant _RoutePreviewPainter oldDelegate) {
    return oldDelegate.routeColor != routeColor;
  }
}
