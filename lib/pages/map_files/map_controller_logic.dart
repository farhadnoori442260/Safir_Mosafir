import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import 'package:safir_passengers/appInfo/app_info.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/utils/time_helper.dart';

class MapControllerLogic {
  static final DocumentReference<Map<String, dynamic>> _settingsRef =
      FirebaseFirestore.instance
          .collection('settings')
          .doc('app_config');

  static Future<Map<String, dynamic>> _getPricingConfig() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _settingsRef.get(
        const GetOptions(
          source: Source.serverAndCache,
        ),
      );

      return snapshot.data() ?? <String, dynamic>{};
    } catch (e) {
      debugPrint('Pricing settings read error: $e');
      return <String, dynamic>{};
    }
  }

  static double _toDouble(
    dynamic value, {
    required double fallback,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString().replaceAll(',', '').trim() ?? '',
        ) ??
        fallback;
  }

  static double _calculateFare({
    required String selectedVehicle,
    required double distanceInKm,
    required Map<String, dynamic> config,
  }) {
    final String vehicle =
        selectedVehicle.toLowerCase().trim();

    double baseFare = _toDouble(
      config['base_fare_taxi'],
      fallback: 30,
    );

    double perKmFare = _toDouble(
      config['per_km_taxi'],
      fallback: 10,
    );

    switch (vehicle) {
      case 'bike':
      case 'motorcycle':
        baseFare = _toDouble(
          config['base_fare_bike'],
          fallback: 20,
        );
        perKmFare = _toDouble(
          config['per_km_bike'],
          fallback: 5,
        );
        break;

      case 'auto':
      case 'rickshaw':
        // پنل فعلی فیلد مستقل Auto ندارد،
        // پس فعلاً همان نرخ تاکسی استفاده می‌شود.
        break;
    }

    return baseFare + (distanceInKm * perKmFare);
  }

  static Future<void> getOSRMRoute({
    required BuildContext context,
    required String selectedVehicle,
    LatLng? customOrigin,
    LatLng? customDestination,
    required Function(
      List<LatLng> points,
      double fare,
      String durationText,
      String arrivalTime,
      double distanceInKm,
    ) onRouteFetched,
  }) async {
    try {
      if (!context.mounted) {
        return;
      }

      final AppInfo appInfo = Provider.of<AppInfo>(
        context,
        listen: false,
      );

      final pickUp = appInfo.pickUpLocation;
      final dropOff = appInfo.dropOffLocation;

      final double? pickupLat =
          customOrigin?.latitude ?? pickUp?.latitudePosition;

      final double? pickupLng =
          customOrigin?.longitude ?? pickUp?.longitudePosition;

      final double? destinationLat =
          customDestination?.latitude ?? dropOff?.latitudePosition;

      final double? destinationLng =
          customDestination?.longitude ?? dropOff?.longitudePosition;

      if (pickupLat == null ||
          pickupLng == null ||
          destinationLat == null ||
          destinationLng == null) {
        debugPrint('OSRM Error: coordinates are missing.');
        return;
      }

      final Uri url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$pickupLng,$pickupLat;$destinationLng,$destinationLat'
        '?overview=full&geometries=geojson',
      );

      final http.Response response = await http
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint(
          'OSRM HTTP failed: ${response.statusCode}',
        );
        return;
      }

      final Map<String, dynamic> routeData =
          jsonDecode(response.body) as Map<String, dynamic>;

      final List<dynamic> routes =
          (routeData['routes'] as List<dynamic>?) ?? <dynamic>[];

      if (routes.isEmpty) {
        debugPrint('OSRM returned no route.');
        return;
      }

      final Map<String, dynamic> route =
          routes.first as Map<String, dynamic>;

      final List<dynamic> coordinates =
          (route['geometry']?['coordinates'] as List<dynamic>?) ??
              <dynamic>[];

      final double distanceInMeters =
          (route['distance'] as num?)?.toDouble() ?? 0.0;

      final double durationInSeconds =
          (route['duration'] as num?)?.toDouble() ?? 0.0;

      final List<LatLng> points = coordinates
          .whereType<List<dynamic>>()
          .where((List<dynamic> point) => point.length >= 2)
          .map(
            (List<dynamic> point) => LatLng(
              (point[1] as num).toDouble(),
              (point[0] as num).toDouble(),
            ),
          )
          .toList();

      final double distanceInKm =
          distanceInMeters / 1000.0;

      final Map<String, dynamic> pricingConfig =
          await _getPricingConfig();

      final bool serviceIsActive =
          pricingConfig['is_service_active'] != false;

      if (!serviceIsActive) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'سرویس سفیر موقتاً غیرفعال است.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }

        return;
      }

      final double finalFare = _calculateFare(
        selectedVehicle: selectedVehicle,
        distanceInKm: distanceInKm,
        config: pricingConfig,
      );

      onRouteFetched(
        points,
        finalFare,
        TimeHelper.formatDuration(durationInSeconds),
        TimeHelper.getArrivalTime(durationInSeconds),
        distanceInKm,
      );
    } on TimeoutException {
      debugPrint('OSRM request timed out.');
    } catch (error, stackTrace) {
      debugPrint('Error fetching OSRM route: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static DocumentReference<Map<String, dynamic>> makeTripRequest({
    required BuildContext context,
    required double actualFareAmount,
    required double? bidAmount,
    required String selectedVehicle,
    String? tripDurationText,
    String? estimatedArrivalTime,
    required Function(String status) onStatusChanged,
    required VoidCallback onTripEnded,
  }) {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw StateError('کاربر وارد حساب نشده است.');
    }

    final AppInfo appInfo = Provider.of<AppInfo>(
      context,
      listen: false,
    );

    final pickUp = appInfo.pickUpLocation;
    final dropOff = appInfo.dropOffLocation;

    final double pickupLat =
        pickUp?.latitudePosition ?? 34.5553;

    final double pickupLng =
        pickUp?.longitudePosition ?? 69.2073;

    final double destinationLat =
        dropOff?.latitudePosition ?? 34.5200;

    final double destinationLng =
        dropOff?.longitudePosition ?? 69.1800;

    final String passengerName =
        userName?.trim().isNotEmpty == true
            ? userName!.trim()
            : currentUser.displayName ?? '';

    final String passengerPhone =
        userPhone?.trim().isNotEmpty == true
            ? userPhone!.trim()
            : currentUser.phoneNumber ?? '';

    final String vehicleType =
        selectedVehicle.toLowerCase().trim();

    final num fareAmount =
        (bidAmount ?? actualFareAmount).round();

    final DocumentReference<Map<String, dynamic>> tripRef =
        FirebaseFirestore.instance
            .collection('rides')
            .doc();

    final Map<String, dynamic> dataMap =
        <String, dynamic>{
      'ride_id': tripRef.id,
      'passenger_id': currentUser.uid,
      'passenger_name': passengerName,
      'passenger_phone': passengerPhone,
      'driver_id': 'waiting',
      'status': 'searching',

      'origin': <String, dynamic>{
        'address': pickUp?.placeName ?? 'مبدأ',
        'latitude': pickupLat,
        'longitude': pickupLng,
      },
      'originLatLng': GeoPoint(
        pickupLat,
        pickupLng,
      ),
      'pickup_address': pickUp?.placeName ?? 'مبدأ',
      'from_lat': pickupLat,
      'from_lng': pickupLng,

      'destination': <String, dynamic>{
        'address': dropOff?.placeName ?? 'مقصد',
        'latitude': destinationLat,
        'longitude': destinationLng,
      },
      'destinationLatLng': GeoPoint(
        destinationLat,
        destinationLng,
      ),
      'dropoff_address': dropOff?.placeName ?? 'مقصد',
      'to_lat': destinationLat,
      'to_lng': destinationLng,

      'fare_amount': fareAmount,
      'fare': fareAmount,
      'price': fareAmount,
      'service_type': vehicleType,
      'vehicle_type': vehicleType,
      'trip_duration': tripDurationText ?? '',
      'estimated_arrival_time':
          estimatedArrivalTime ?? '',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    tripRef.set(dataMap);
    return tripRef;
  }
}
