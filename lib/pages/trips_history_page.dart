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

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "تاریخچه سفرها",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: safirBrandColor,
          indicatorWeight: 3,
          labelColor: safirBrandColor,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "تکمیل شده"),
            Tab(text: "جاری"),
            Tab(text: "لغو شده"),
          ],
        ),
      ),
      body: currentUserId == null
          ? _buildEmptyState("برای مشاهده تاریخچه وارد حساب کاربری شوید")
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "خطا در دریافت اطلاعات: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: safirBrandColor),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState("هیچ سفری یافت نشد");
                }

                // 📍 فیلتر کردن سفرهای متعلق به مسافر فعلی
                var allDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String pId = data['passenger_id'] ?? data['passengerId'] ?? data['userID'] ?? '';
                  return pId == currentUserId;
                }).toList();

                if (allDocs.isEmpty) {
                  return _buildEmptyState("هیچ سفری در تاریخچه شما ثبت نشده است");
                }

                // محاسبه خلاصه آمار
                int totalTrips = allDocs.length;
                double totalKm = 0.0;
                for (var doc in allDocs) {
                  var data = doc.data() as Map<String, dynamic>;
                  var dist = data['distance'];
                  if (dist != null) {
                    totalKm += (double.tryParse(dist.toString()) ?? 0.0);
                  }
                }
                int estimatedHours = (totalKm / 30).ceil(); // تخمین تقریبی زمان

                // جداسازی بر اساس وضعیت
                var completedTrips = allDocs.where((doc) {
                  String st = (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase() ?? '';
                  return st == 'completed' || st == 'ended';
                }).toList();

                var activeTrips = allDocs.where((doc) {
                  String st = (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase() ?? '';
                  return st == 'searching' || st == 'accepted' || st == 'arrived' || st == 'ontrip' || st == 'on_trip';
                }).toList();

                var cancelledTrips = allDocs.where((doc) {
                  String st = (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase() ?? '';
                  return st.contains('cancel');
                }).toList();

                return Column(
                  children: [
                    // 📊 کارت خلاصه آمار مشابه اسنپ
                    _buildStatsHeader(totalKm.toStringAsFixed(1), totalTrips, estimatedHours),

                    // 📄 لیست سفرها در زبانه‌ها
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTripsList(completedTrips, "تکمیل شده"),
                          _buildTripsList(activeTrips, "جاری"),
                          _buildTripsList(cancelledTrips, "لغو شده"),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // 📊 کارت آمار (کیلومتر، تعداد سفر، ساعت)
  Widget _buildStatsHeader(String km, int total, int hours) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.speed_rounded, "$km", "کیلومتر با سفیر"),
          Container(width: 1, height: 35, color: Colors.grey.shade200),
          _buildStatItem(Icons.local_taxi_rounded, "$total", "سفر با سفیر"),
          Container(width: 1, height: 35, color: Colors.grey.shade200),
          _buildStatItem(Icons.access_time_rounded, "$hours", "ساعت با سفیر"),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: safirBrandColor, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // 📄 ویجت لیست سفرهای هر زبانه
  Widget _buildTripsList(List<QueryDocumentSnapshot> docs, String tabName) {
    if (docs.isEmpty) {
      return _buildEmptyState("هیچ سفری در بخش $tabName یافت نشد");
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var trip = docs[index].data() as Map<String, dynamic>;

        String origin = trip['originAddress'] ?? trip['origin_address'] ?? trip['pickup_address'] ?? 'مبدأ نامشخص';
        String destination = trip['destinationAddress'] ?? trip['destination_address'] ?? trip['dropoff_address'] ?? 'مقصد نامشخص';
        String fare = trip['fareAmount']?.toString() ?? trip['fare']?.toString() ?? trip['price']?.toString() ?? '0';
        String driverName = trip['driver_name'] ?? trip['driverName'] ?? 'راننده سفیر';
        String carDetails = trip['car_details'] ?? trip['carModel'] ?? 'خودرو سفیر';
        String status = trip['status']?.toString() ?? '';

        String statusText = "تکمیل شده";
        Color statusColor = safirBrandColor;

        if (status.contains('cancel')) {
          statusText = status.contains('Passenger') ? "سفر لغو شده توسط شما" : "سفر لغو شده توسط راننده";
          statusColor = Colors.redAccent;
        } else if (status == 'searching' || status == 'accepted' || status == 'ontrip') {
          statusText = "سفر جاری";
          statusColor = Colors.blue;
        }

        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // راننده و قیمت
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey.shade100,
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            carDetails,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$fare افغانی",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: safirBrandColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),

                // آدرس مبدأ
                Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.blue, size: 10),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        origin,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // آدرس مقصد
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent, size: 12),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
