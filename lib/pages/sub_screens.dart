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

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            "trips_history_title".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: safirBrandColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "tab_completed".tr()),
              Tab(text: "tab_active".tr()),
              Tab(text: "tab_canceled".tr()),
            ],
          ),
        ),
        body: currentUserId == null
            ? _buildEmptyState(context, Icons.history, "trips_history_empty_msg")
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('rides').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: safirBrandColor));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(context, Icons.history, "trips_history_empty_msg");
                  }

                  var userRides = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String pId = data['passenger_id'] ?? data['passengerId'] ?? data['userID'] ?? '';
                    return pId == currentUserId;
                  }).toList();

                  var completed = userRides.where((doc) {
                    String st = (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase() ?? '';
                    return st == 'completed' || st == 'ended';
                  }).toList();

                  var active = userRides.where((doc) {
                    String st = (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase() ?? '';
                    return st == 'searching' || st == 'accepted' || st == 'arrived' || st == 'ontrip' || st == 'on_trip';
                  }).toList();

                  var canceled = userRides.where((doc) {
                    String st = (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase() ?? '';
                    return st.contains('cancel');
                  }).toList();

                  return TabBarView(
                    children: [
                      _buildRidesList(context, completed, "trips_history_empty_msg"),
                      _buildRidesList(context, active, "no_active_trips"),
                      _buildRidesList(context, canceled, "no_canceled_trips"),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildRidesList(BuildContext context, List<QueryDocumentSnapshot> docs, String emptyMsgKey) {
    if (docs.isEmpty) {
      return _buildEmptyState(context, Icons.history, emptyMsgKey);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var data = docs[index].data() as Map<String, dynamic>;
        String origin = data['originAddress'] ?? data['origin_address'] ?? data['pickup_address'] ?? '-';
        String destination = data['destinationAddress'] ?? data['destination_address'] ?? data['dropoff_address'] ?? '-';
        String fare = data['fareAmount']?.toString() ?? data['fare']?.toString() ?? '0';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text("$origin ➔ $destination", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("کرایه: $fare افغانی", style: TextStyle(color: safirBrandColor, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String translationKey) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            translationKey.tr(),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
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
                            style: const TextStyle(fontSize: 12, color: Colors.black70),
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
