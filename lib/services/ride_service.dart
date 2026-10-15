import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> createRideRequest({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String destinationAddress,
    required double destinationLat,
    required double destinationLng,
    required double fareAmount,
  }) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        debugPrint('کاربر وارد نشده است!');
        return null;
      }

      final DocumentReference<Map<String, dynamic>> rideRef =
          _firestore.collection('rides').doc();

      final Map<String, dynamic> rideData = <String, dynamic>{
        'ride_id': rideRef.id,

        // شناسه و اطلاعات مسافر
        'passenger_id': user.uid,
        'passenger_phone': user.phoneNumber ?? '',

        // راننده هنوز انتخاب نشده است
        'driver_id': 'waiting',

        // راننده فقط این وضعیت را در Listener می‌خواند
        'status': 'searching',

        // مبدأ
        'origin': <String, dynamic>{
          'address': pickupAddress,
          'latitude': pickupLat,
          'longitude': pickupLng,
        },
        'originLatLng': GeoPoint(pickupLat, pickupLng),
        'pickup_address': pickupAddress,
        'from_lat': pickupLat,
        'from_lng': pickupLng,

        // مقصد
        'destination': <String, dynamic>{
          'address': destinationAddress,
          'latitude': destinationLat,
          'longitude': destinationLng,
        },
        'destinationLatLng': GeoPoint(destinationLat, destinationLng),
        'dropoff_address': destinationAddress,
        'to_lat': destinationLat,
        'to_lng': destinationLng,

        // مبلغ
        'fare_amount': fareAmount,

        // زمان‌ها
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await rideRef.set(rideData);

      debugPrint('Ride created successfully: ${rideRef.id}');
      return rideRef.id;
    } catch (e, stackTrace) {
      debugPrint('خطا در ثبت درخواست سفر: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}
