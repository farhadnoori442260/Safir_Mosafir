import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:safir_passengers/appInfo/app_info.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/utils/time_helper.dart';

class MapControllerLogic {
  /// 🛣️ دریافت مسیر OSRM به همراه محاسبه کرایه و زمان دقیق رسیدن (ETA)
  static Future<void> getOSRMRoute({
    required BuildContext context,
    required String selectedVehicle,
    LatLng? customOrigin,
    LatLng? customDestination,
    // 🔧 FIX: مسافت دقیقی که خودِ OSRM برای این مسیر محاسبه کرده هم به
    // تماس‌گیرنده پاس داده می‌شود، تا دیگر لازم نباشد با جمع کردن فاصلهٔ
    // تک‌تک نقاط پالی‌لاین (که کمی نادقیق‌تر از عدد خودِ OSRM است) دوباره
    // بازسازی شود.
    required Function(
      List<LatLng> points,
      double fare,
      String durationText,
      String arrivalTime,
      double distanceInKm,
    ) onRouteFetched,
  }) async {
    try {
      if (!context.mounted) return;
      var appInfo = Provider.of<AppInfo>(context, listen: false);
      var pickUp = appInfo.pickUpLocation;
      var dropOff = appInfo.dropOffLocation;

      // دریافت مختصات از ورودی دستی یا AppInfo
      double? pLat = customOrigin?.latitude ?? pickUp?.latitudePosition;
      double? pLng = customOrigin?.longitude ?? pickUp?.longitudePosition;
      double? dLat = customDestination?.latitude ?? dropOff?.latitudePosition;
      double? dLng = customDestination?.longitude ?? dropOff?.longitudePosition;

      if (pLat == null || pLng == null || dLat == null || dLng == null) {
        debugPrint("OSRM Error: PickUp or DropOff coordinates are null.");
        return;
      }

      // ⚠️ OSRM ورودی آدرس را به فرمت longitude,latitude می‌پذیرد.
      final Uri url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$pLng,$pLat;$dLng,$dLat'
        '?overview=full&geometries=geojson',
      );

      // افزودن مهلت زمانی ۱۰ ثانیه‌ای برای جلوگیری از معطل ماندن UI
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final List coordinates = route['geometry']['coordinates'] ?? [];
          final double distanceInMeters = (route['distance'] as num?)?.toDouble() ?? 0.0; 
          final double durationInSeconds = (route['duration'] as num?)?.toDouble() ?? 0.0;

          // 📊 محاسبه فرمت متنی زمان و ساعت رسیدن
          String durationText = TimeHelper.formatDuration(durationInSeconds);
          String arrivalTime = TimeHelper.getArrivalTime(durationInSeconds);

          // 🔴 تبدیل GeoJSON [lng, lat] به MapLibre GL LatLng(lat, lng)
          List<LatLng> points = coordinates.map<LatLng>((coord) {
            return LatLng(
              (coord[1] as num).toDouble(), // Latitude
              (coord[0] as num).toDouble(), // Longitude
            );
          }).toList();
          
          // 💰 محاسبه کرایه پایه
          double distanceInKm = distanceInMeters / 1000;
          double baseFare = 30.0;
          double calculatedFare = baseFare + (distanceInKm * 10);
          double actualFare = calculatedFare;

          // ضریب وسایل نقلیه مختلف
          switch (selectedVehicle.toLowerCase()) {
            case 'auto':
            case 'rickshaw':
              actualFare = calculatedFare * 1.4;
              break;
            case 'bike':
            case 'motorcycle':
              actualFare = calculatedFare * 0.5;
              break;
            default:
              actualFare = calculatedFare; // تاکسی سواری عادی
              break;
          }

          // 📤 تحویل خروجی به UI — همراه با مسافت دقیق خودِ OSRM
          onRouteFetched(points, actualFare, durationText, arrivalTime, distanceInKm);
        }
      } else {
        debugPrint("OSRM HTTP Failed with status: ${response.statusCode}");
      }
    } on TimeoutException {
      debugPrint("OSRM Request timed out.");
    } catch (e) {
      debugPrint("Error fetching OSRM route: $e");
    }
  }

  /// 🚀 تابع ارسال درخواست سفر به Firestore به همراه ثبت فیلدهای زمان
  /// ⚠️ توجه: این تابع در حال حاضر در جریان واقعی اپ (map_screen.dart →
  /// startTrip) صدا زده نمی‌شود؛ آن تابع مستقیماً سند rides را خودش
  /// می‌سازد. این متد اینجا نگه داشته شده ولی روی رفتار فعلی اپ اثری ندارد.
  static DocumentReference makeTripRequest({
    required BuildContext context,
    required double actualFareAmount,
    required double? bidAmount,
    required String selectedVehicle,
    String? tripDurationText,
    String? estimatedArrivalTime,
    required Function(String status) onStatusChanged,
    required VoidCallback onTripEnded,
  }) {
    DocumentReference tripRef = FirebaseFirestore.instance.collection("rides").doc();
    
    var appInfo = Provider.of<AppInfo>(context, listen: false);
    var pickUp = appInfo.pickUpLocation;
    var dropOff = appInfo.dropOffLocation;

    // پیش‌فرض‌های کابل در صورت خالی بودن
    double pLat = pickUp?.latitudePosition ?? 34.5553;
    double pLng = pickUp?.longitudePosition ?? 69.2073;
    double dLat = dropOff?.latitudePosition ?? 34.5200;
    double dLng = dropOff?.longitudePosition ?? 69.1800;

    String validUserId = (userID != null && userID!.isNotEmpty) 
        ? userID! 
        : "passenger_${DateTime.now().millisecondsSinceEpoch}";
    String validPhone = (userPhone != null && userPhone!.isNotEmpty) 
        ? userPhone! 
        : "+93788231515";
    String validName = (userName != null && userName!.isNotEmpty) 
        ? userName! 
        : "Passenger";

    String vehicleClean = selectedVehicle.toLowerCase(); 
    num finalFare = (bidAmount ?? actualFareAmount).round();

    Map<String, dynamic> dataMap = {
      "tripId": tripRef.id,
      "tripID": tripRef.id,
      "created_at": FieldValue.serverTimestamp(),
      "timestamp": FieldValue.serverTimestamp(),
      
      // اطلاعات مسافر
      "full_name": validName,
      "userName": validName,
      "phone": validPhone,
      "userPhone": validPhone,
      "passengerId": validUserId,
      "user_id": validUserId,
      "userID": validUserId,
      
      // اطلاعات مبدأ و مقصد
      "pickup_address": pickUp?.placeName ?? "مبدأ",
      "dropoff_address": dropOff?.placeName ?? "مقصد",
      "from_lat": pLat,
      "from_lng": pLng,
      "to_lat": dLat,
      "to_lng": dLng,
      "from": GeoPoint(pLat, pLng),
      "to": GeoPoint(dLat, dLng),
      
      // زمان‌بندی مسیر
      "tripDuration": tripDurationText ?? "",
      "estimatedArrivalTime": estimatedArrivalTime ?? "",
      
      // وضعیت و قیمت
      "driverId": "waiting",
      "driver_id": "",
      "fare": finalFare,
      "fareAmount": finalFare.toString(),
      "status": "requested",
      "serviceType": vehicleClean,
      "vehicleType": vehicleClean,
    };

    tripRef.set(dataMap);
    return tripRef;
  }
}
