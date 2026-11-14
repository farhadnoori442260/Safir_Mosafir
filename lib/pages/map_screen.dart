import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:safir_passengers/appInfo/app_info.dart';
import 'package:safir_passengers/services/app_config_service.dart';
import 'package:safir_passengers/constants/trip_status.dart';
import 'package:safir_passengers/models/address_models.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/global/trip_var.dart';
import 'package:safir_passengers/theme/app_colors.dart';
import 'package:safir_passengers/pages/saved_addresses_screen.dart' show SavedDestinationBus;
import 'package:safir_passengers/widgets/rate_driver_sheet.dart';
import 'package:safir_passengers/widgets/safir_drawer.dart';
import 'search_destination_place.dart';

import 'map_files/map_controller_logic.dart';
import 'map_files/map_bottom_sheets.dart';
import 'map_files/smart_location_sheet.dart';
import 'map_files/intercity_sheets.dart';
import 'map_files/cargo_sheets.dart';
import 'map_files/trip_options_sheet.dart';
import 'map_files/schedule_trip_sheet.dart';
import 'map_files/promo_code_sheet.dart';
import 'map_files/home_services_sheet.dart';
import 'package:safir_passengers/services/promo_service.dart';
import '../widgets/animated_menus.dart';
import '../widgets/map_location_label.dart';

// ════════════════════════════════════════════════════════════
//  🌐 سرورهای مسیریابی OSRM (با جایگزینی خودکار)
//
//  وقتی سرور OSRM پولی/اختصاصی گذاشتی، فقط آن را «اول» این لیست بگذار.
//  اگر سرور اول خطا یا محدودیت (429) داد، درخواست خودکار به بعدی می‌رود
//  و سرورِ سالم تا خراب‌شدنش «ترجیحی» می‌ماند.
//
//  توجه: MapControllerLogic.getOSRMRoute (پیش‌نمایش مسیر قبل از سفر) در فایل
//  map_controller_logic.dart هنوز آدرس خودش را دارد؛ آن را هم می‌شود به
//  همین لیست وصل کرد.
// ════════════════════════════════════════════════════════════
const List<String> kOsrmBases = <String>[
  'https://router.project-osrm.org',
  'https://routing.openstreetmap.de/routed-car',
];

int _osrmPreferred = 0;

/// پاسخ سرور درست بوده ولی مسیر/درخواست نامعتبر است؛ سرور دیگر امتحان نمی‌شود
class _OsrmNoRoute implements Exception {
  final String code;
  const _OsrmNoRoute(this.code);

  @override
  String toString() => 'OSRM: $code';
}

/// درخواست OSRM با جایگزینی خودکار بین سرورها
Future<Map<String, dynamic>> _osrmRequest(String pathAndQuery) async {
  Object? lastError;

  for (int k = 0; k < kOsrmBases.length; k++) {
    final int idx = (_osrmPreferred + k) % kOsrmBases.length;

    try {
      final http.Response response = await http
          .get(
            Uri.parse('${kOsrmBases[idx]}$pathAndQuery'),
            headers: const {'User-Agent': 'safir_passengers'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;

        if (data['code'] == 'Ok') {
          _osrmPreferred = idx;
          return data;
        }
        throw _OsrmNoRoute('${data['code']}');
      }

      // خطای درخواست (به‌جز محدودیت نرخ) روی سرور دیگر هم همان است
      if (response.statusCode >= 400 &&
          response.statusCode < 500 &&
          response.statusCode != 429) {
        throw _OsrmNoRoute('HTTP ${response.statusCode}');
      }

      lastError = 'HTTP ${response.statusCode}';
    } on _OsrmNoRoute {
      rethrow;
    } catch (e) {
      lastError = e;
    }
  }

  throw Exception('OSRM unreachable: $lastError');
}

/// 🔹 تبدیل ویجت به تصویر برای MapLibre
Future<Uint8List> widgetToImageBytes(Widget widget) async {
  final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());
  final PipelineOwner pipelineOwner = PipelineOwner();
  final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

  final MediaQueryData mediaQueryData =
      MediaQueryData.fromView(ui.PlatformDispatcher.instance.views.first);

  final RenderView renderView = RenderView(
    view: ui.PlatformDispatcher.instance.views.first,
    child: RenderPositionedBox(alignment: Alignment.center, child: repaintBoundary),
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(mediaQueryData.size),
      devicePixelRatio: mediaQueryData.devicePixelRatio,
    ),
  );

  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

  final RenderObjectToWidgetElement<RenderBox> rootElement =
      RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    child: Directionality(
      textDirection: ui.TextDirection.rtl,
      child: widget,
    ),
  ).attachToRenderTree(buildOwner);

  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();

  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  final ui.Image image = await repaintBoundary.toImage(pixelRatio: 3.0);
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return byteData!.buffer.asUint8List();
}

/// متن‌های پیش‌فرض برای وقتی که کلید در فایل ترجمه نیست
/// (fa / en / ps؛ پشتو اگر نبود فارسی نشان داده می‌شود)
const Map<String, Map<String, String>> _mapFallbacks = {
  'origin': {'fa': 'مبدأ', 'en': 'Origin', 'ps': 'مبدأ'},
  'destination': {'fa': 'مقصد', 'en': 'Destination', 'ps': 'منزل'},
  'car_default_color': {'fa': 'سفید', 'en': 'White', 'ps': 'سپین'},
  'plate_default_province': {'fa': 'کابل', 'en': 'Kabul', 'ps': 'کابل'},
  'confirm': {'fa': 'تایید', 'en': 'Confirm', 'ps': 'تایید'},
  'gps_disruption': {
    'fa': 'اختلال در موقعیت مکانی',
    'en': 'Location signal problem',
  },
  'select_origin_destination_msg': {
    'fa': 'لطفاً مبدأ و مقصد را مشخص کنید.',
    'en': 'Please set your pickup and destination.',
  },
  'service_inactive_msg': {
    'fa': 'سرویس موقتاً غیرفعال است. لطفاً بعداً دوباره تلاش کنید.',
    'en': 'The service is temporarily unavailable. Please try again later.',
  },
  'fare_updated_msg': {
    'fa': 'کرایه به‌روزرسانی شد. قیمت جدید را ببینید و دوباره درخواست دهید.',
    'en': 'The fare was updated. Check the new price and request again.',
  },
  'driver_arrived_msg': {
    'fa': 'راننده به مبدأ شما رسید.',
    'en': 'Your driver has arrived.',
  },
  'trip_cancelled_by_driver_msg': {
    'fa': 'سفر توسط سفیر لغو گردید.',
    'en': 'The trip was cancelled by the driver.',
  },
  'request_failed_retry_msg': {
    'fa': 'ثبت درخواست انجام نشد. دوباره تلاش کنید.',
    'en': 'Could not send the request. Please try again.',
  },
  'ride_for_me': {'fa': 'برای خودم', 'en': 'For me', 'ps': 'زما لپاره'},
  'ride_for_other': {
    'fa': 'برای دیگران',
    'en': 'For someone else',
    'ps': 'د بل چا لپاره',
  },
  'other_sheet_title': {
    'fa': 'سفر برای نفر دیگر',
    'en': 'Ride for someone else',
    'ps': 'د بل کس لپاره سفر',
  },
  'other_sheet_desc': {
    'fa': 'شمارهٔ مسافر را وارد کنید تا راننده هنگام رسیدن با او تماس بگیرد.',
    'en': 'Enter the passenger\'s number so the driver can call them on arrival.',
    'ps': 'د مسافر شمېره ولیکئ ترڅو ډرایور د رسیدو پر مهال ورسره اړیکه ونیسي.',
  },
  'other_name_hint': {
    'fa': 'نام مسافر (اختیاری)',
    'en': 'Passenger name (optional)',
    'ps': 'د مسافر نوم (اختیاري)',
  },
  'other_phone_hint': {
    'fa': 'شمارهٔ تماس مسافر',
    'en': 'Passenger phone number',
    'ps': 'د مسافر د اړیکې شمېره',
  },
  'other_phone_invalid': {
    'fa': 'شمارهٔ تماس معتبر نیست.',
    'en': 'Please enter a valid phone number.',
    'ps': 'د اړیکې شمېره سمه نه ده.',
  },
  'cancel': {'fa': 'انصراف', 'en': 'Cancel', 'ps': 'لغوه'},
  'no_driver_found_msg': {
    'fa': 'راننده‌ای برای سفر شما پیدا نشد. لطفاً دوباره تلاش کنید.',
    'en': 'No driver was found for your trip. Please try again.',
  },
};

/// ترجمه با پشتیبان؛ کلیدِ ترجمه‌نشده هرگز خام نمایش داده نمی‌شود
String _mapTr(BuildContext context, String key) {
  final String v = key.tr();
  if (v.trim().isNotEmpty && v != key) return v;

  final Map<String, String>? t = _mapFallbacks[key];
  if (t == null) return key;

  final String lang = context.locale.languageCode;
  return t[lang] ?? (lang == 'ps' ? t['fa']! : t['en']!);
}

/// 🚗 ویجت مخصوص نمایش مارکر ماشین راننده روی نقشه
class DriverCarMarker extends StatelessWidget {
  const DriverCarMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Image.asset(
        'assets/images/tracking_car.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.directions_car_rounded,
            size: 38,
            color: Color(0xFF0066FF),
          );
        },
      ),
    );
  }
}

/// نتیجهٔ چسباندن یک نقطهٔ GPS به خط مسیر
class _SnapResult {
  final LatLng point;
  final double distance;
  final int segmentIndex;

  const _SnapResult(this.point, this.distance, this.segmentIndex);
}

class SafirMapScreen extends StatefulWidget {
  final String serviceType;
  final String? pickerMode;
  final LatLng? targetLocation;
  final bool isPickerOnly;

  /// وقتی true باشد، صفحه با «باتم‌شیت انتخاب سرویس» (هوم) شروع می‌شود و با
  /// انتخاب هر سرویس، فقط باتم‌شیت عوض می‌شود (نقشه تکان نمی‌خورد).
  final bool startAtHome;

  /// برای «تکرار / برگشت سفر» از تاریخچه: مبدأ و مقصد از قبل مشخص است و
  /// صفحه مستقیم به مرحلهٔ انتخاب سرویس و قیمت می‌رود.
  final LatLng? presetOrigin;
  final LatLng? presetDestination;
  final String? presetOriginName;
  final String? presetDestinationName;

  const SafirMapScreen({
    super.key,
    required this.serviceType,
    this.pickerMode,
    this.targetLocation,
    this.isPickerOnly = false,
    this.startAtHome = false,
    this.presetOrigin,
    this.presetDestination,
    this.presetOriginName,
    this.presetDestinationName,
  });

  @override
  State<SafirMapScreen> createState() => _SafirMapScreenState();
}

class _SafirMapScreenState extends State<SafirMapScreen> with TickerProviderStateMixin {
  MapLibreMapController? _mapController;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// نوع سرویس فعلی (taxi / cargo / intercity). قابل‌تغییر است تا بدون ساختن
  /// دوبارهٔ نقشه، با انتخاب سرویس از باتم‌شیت هوم عوض شود.
  late String _serviceType;

  /// true = باتم‌شیت اول (انتخاب سرویس) نشان داده می‌شود
  bool _isHome = false;

  LatLng _currentUserLatLng = const LatLng(34.5333, 69.1667);
  double _currentGpsAccuracy = 0.0;

  StreamSubscription<Position>? _positionStreamSubscription;

  // ───────── وضعیت GPS ─────────
  bool _hasGpsDisruption = false;
  StreamSubscription<ServiceStatus>? _gpsServiceSubscription;

  /// آستانه‌ها: بالاتر از ۵۰ متر = اختلال، پایین‌تر از ۳۵ متر = سالم
  /// (دو آستانهٔ جدا برای جلوگیری از چشمک‌زدن هشدار)
  static const double _gpsBadAccuracyMeters = 50.0;
  static const double _gpsGoodAccuracyMeters = 35.0;

  /// ✅ ارتفاع کل پین شناور (دایره ۳۰ + میله ۱۸). نوک پین باید دقیقاً روی
  /// مرکز نقشه بنشیند، پس پین به‌اندازهٔ «نصف ارتفاع» بالا برده می‌شود.
  static const double _pinTotalHeight = 48.0;
  static const double _pinLiftWhenMoving = 25.0;

  LatLng? _originLatLng;
  LatLng? _destinationLatLng;

  Symbol? _originSymbol;
  Symbol? _destinationSymbol;

  // ───────── ردیابی زندهٔ راننده ─────────
  Symbol? _driverLiveSymbol;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _driverLocationStreamSubscription;
  String? _assignedDriverId;

  /// کش تصویر آیکن راننده به‌ازای هر نوع وسیله (ماشین/موترسایکل/باربری)
  final Map<String, Uint8List> _cachedDriverIconBytes = {};

  /// شناسهٔ تصاویری که از قبل به استایل نقشه اضافه شده‌اند
  final Set<String> _addedDriverIconIds = {};
  String? _driverIconImageIdLoaded;
  late AnimationController _driverAnimationController;

  LatLng? _driverAnimationStart;
  LatLng? _driverAnimationEnd;

  double _driverAnimationStartBearing = 0.0;
  double _driverAnimationEndBearing = 0.0;

  /// آخرین موقعیت خامی که از Firestore آمده (برای رسم مسیر تازه)
  LatLng? _latestDriverRaw;
  double _latestDriverHeading = -1.0;

  /// صف «آخرین مقدار برنده است» تا آپدیت‌ها هم‌زمان اجرا نشوند
  LatLng? _pendingDriverRawPosition;
  double _pendingDriverRawHeading = -1.0;
  bool _isProcessingDriverUpdate = false;

  /// مبدأ و مقصد واقعی سفر (همان چیزی که در rides ذخیره شده)
  LatLng? _tripOriginLatLng;
  LatLng? _tripDestinationLatLng;

  Line? _driverRouteLine; // خط آبی (باقی‌ماندهٔ مسیر)
  Line? _driverTraveledLine; // خط خاکستری (مسیر طی‌شده)
  Line? _driverTempLine; // خط موقت (وقتی مسیر کهنه شده و مسیر جدید در راه است)
  bool _tempLineBusy = false;
  int _driverProgressIndex = 0; // پیشرفت روی مسیر (فقط به جلو)
  int _driverOffRouteCount = 0;
  int _driverLastRenderedSegment = -1;
  LatLng? _driverLastRenderedPoint;
  LatLng? _driverDisplayLatLng; // موقعیت لحظه‌ایِ مارکر (وسط انیمیشن)
  double _driverDisplayBearing = 0.0;
  DateTime? _lastDriverUpdateAt;
  DateTime? _lastDriverRouteFetchAt;

  /// فاز مسیر فعلی: 'pickup' (تا سوارشدن) یا 'onTrip' (تا مقصد)
  String? _driverRouteBuiltForPhase;

  /// اندیس نقطهٔ مبدأ روی خط مسیر (برای حساب ETA تا سوارشدن)
  int _driverPickupEndIndex = 0;

  // کنترل فریم‌های انیمیشن تا درخواست‌ها روی هم انباشته نشوند
  bool _driverFrameBusy = false;
  int _lastDriverFrameMs = 0;
  static const int _driverFrameGapMs = 33; // حدود ۳۰ فریم بر ثانیه

  // ───── خروج از مسیر و بازمسیریابی ─────
  // GPS شهری به‌راحتی ۲۰ تا ۴۰ متر خطا دارد؛ عدد ۴۰ جلوی پریدن آیکن را می‌گیرد.
  static const double _offRouteThresholdMeters = 40.0;
  static const int _offRouteConfirmCount = 2;
  static const int _rerouteCooldownSeconds = 5;

  /// خیلی دور از مسیر (بیش از این فاصله): بدون انتظار برای تایید، فوراً بازمسیریابی
  static const double _immediateOffRouteMeters = 70.0;

  /// پیچیدن به کوچهٔ کناری: وقتی ماشین بیش از این فاصله از خط دور شده و جهت
  /// حرکتش بیش از این زاویه با جهت مسیر فرق دارد، سریع‌تر تشخیص داده می‌شود
  static const double _deviationMinDistanceMeters = 15.0;
  static const double _deviationAngleDegrees = 60.0;

  /// کمترین جابه‌جایی برای محاسبهٔ جهت واقعی حرکت
  static const double _moveSampleMeters = 8.0;

  /// بازمسیریابی از نقطه‌ای این‌قدر «جلوتر» در جهت حرکت شروع می‌شود تا مسیر
  /// جدید هیچ‌وقت از پشت ماشین شروع نشود
  static const double _lookAheadMeters = 35.0;

  /// حرکت خلاف جهت مسیر (دنده‌عقب / ورود به خیابان از سمت مخالف)
  static const double _wrongWayAngleDegrees = 120.0;
  static const int _wrongWayConfirmCount = 2;

  /// سرعت فرضی شهری برای ETA محلی (متر بر ثانیه ≈ ۲۵ کیلومتر بر ساعت)
  static const double _assumedSpeedMps = 7.0;

  /// مسیر فعلی کهنه است (راننده از آن خارج شده و مسیر جدید هنوز نرسیده)
  bool _driverRouteStale = false;
  LatLng? _dirRefPoint; // نقطهٔ مرجع برای جهت واقعی حرکت
  double? _driverMoveBearing; // آخرین جهت واقعی حرکت (≥ ۱۲ متر جابه‌جایی)
  int _wrongWayCount = 0;
  int _rerouteFailCount = 0; // برای فاصلهٔ زیادشونده بین تلاش‌های ناموفق

  bool _isFetchingDriverTripRoute = false;

  // ───────── حرکت نقشه و پینِ وسط ─────────
  bool _isMapMoving = false;
  bool _isProgrammaticMove = false;
  bool _isUserGesture = false; // پرچم تشخیص لمس صفحه توسط دست کاربر
  int _activePointers = 0; // تعداد انگشت‌های روی نقشه (برای زوم دو انگشتی)
  Timer? _mapIdleFallbackTimer; // اگر onCameraIdle نیامد، پین را رها می‌کند
  bool _isSheetExpanded = true;
  Timer? _debounceTimer;

  bool _hasNotification = false;

  // ───── ثبات جهت و ETA ماشین راننده ─────
  double _driverBaseBearing = 0.0; // جهت بدون افست آیکن
  LatLng? _bearingRefPoint; // نقطه‌ی مرجع برای محاسبه‌ی جهت (≥ ۱۲ متر فاصله)
  int _etaMinutes = 0; // دقیقه‌های باقی‌مانده (فقط عدد؛ متن را زبان فعلی می‌سازد)

  // جلوگیری از پاسخ‌های کهنه و دابل‌تپ
  int _routeRequestId = 0;
  int _geocodeRequestId = 0;
  bool _isConfirming = false;
  Uint8List? _originLabelBytes;

  // ───────── حالت فقط‌انتخاب (افزودن مکان منتخب) ─────────
  String _pickerAddress = '';
  bool _pickerLoading = true;

  int _selectedCategory = 0;
  int _selectedVehicleType = 0;
  int _currentStep = 0;

  bool get _hasPreset =>
      widget.presetOrigin != null && widget.presetDestination != null;
  bool _presetApplied = false;

  DateTime? _intercityTravelDate;
  int _intercityPassengers = 1;

  String? _secondDestinationAddress;
  int _stopDurationMinutes = 0;
  bool _isRoundTrip = false;
  bool _hasExtraLuggage = false;
  bool _preferSilence = false;

  DateTime? _scheduledDateTime;
  String? _appliedPromoCode;

  // ───────── سفر برای نفر دیگر (فقط تاکسی شهری) ─────────
  bool _rideForOther = false;
  String _otherName = '';
  String _otherPhone = '';

  bool get _hasActiveTripOptions =>
      _secondDestinationAddress != null ||
      _stopDurationMinutes > 0 ||
      _isRoundTrip ||
      _hasExtraLuggage ||
      _preferSilence;

  bool get _isScheduled => _scheduledDateTime != null;
  bool get _hasPromoCode => _appliedPromoCode != null && _appliedPromoCode!.isNotEmpty;

  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _senderAddressController = TextEditingController();
  final TextEditingController _senderUnitController = TextEditingController();
  final TextEditingController _senderFloorController = TextEditingController();
  final TextEditingController _senderNoteController = TextEditingController();

  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _receiverAddressController = TextEditingController();
  final TextEditingController _receiverUnitController = TextEditingController();
  final TextEditingController _receiverFloorController = TextEditingController();
  final TextEditingController _receiverNoteController = TextEditingController();

  String _cargoPackageType = 'cargo.type_other'.tr();
  String _cargoInsurance = 'cargo.no_insurance'.tr();
  String _cargoSelectedVehicle = 'zaranj';
  String _cargoPaymentPayer = 'cargo.sender'.tr();

  String _tripDurationText = "";
  String _estimatedArrivalTime = "--:--";

  List<LatLng> _routePolylinePoints = [];
  List<LatLng> _driverTripPolylinePoints = [];
  LatLng? _lastDriverLatLng;

  bool _isDriverTripRouteVisible = false;

  DocumentReference? tripRequestRef;
  StreamSubscription<DocumentSnapshot>? tripStreamSubscription;
  final AudioPlayer _tripAudioPlayer = AudioPlayer();

  String? _lastTripStatus;
  bool _hasPlayedAcceptedSound = false;
  bool _hasPlayedArrivedSound = false;

  // جلوگیری از درخواست دوباره با دو بار کلیک، و از رفتن دوباره به صفحهٔ امتیاز
  bool _isRequestingTrip = false;
  bool _isCancellingTrip = false;
  bool _isTripFinished = false;

  // اگر تا ۵ دقیقه راننده‌ای پیدا نشد، درخواست خودکار لغو می‌شود
  static const Duration _searchTimeout = Duration(minutes: 5);
  Timer? _searchTimeoutTimer;

  double actualFareAmount = 50.0;
  double? bidAmount;
  String selectedVehicle = "Car";
  double _tripDistanceInKm = 0.0;

  String _driverPlateProvince = "";
  String _driverPlateCategory = "";
  String _driverPlateFarsiNum = "";
  String _driverPlateNum = "";
  bool _driverIsTempPlate = false;
  String _driverCarColor = "";

  final List<Map<String, dynamic>> _intercityCities = [
    {'name': 'هرات', 'province': 'هرات', 'lat': 34.3529, 'lng': 62.2040},
    {'name': 'مزار شریف', 'province': 'بلخ', 'lat': 36.7069, 'lng': 67.1108},
    {'name': 'جلال آباد', 'province': 'ننگرهار', 'lat': 34.4261, 'lng': 70.4515},
    {'name': 'کندهار', 'province': 'کندهار', 'lat': 31.6288, 'lng': 65.7372},
  ];

  @override
  void initState() {
    super.initState();
    _serviceType = widget.serviceType;
    _isHome = widget.startAtHome && !widget.isPickerOnly && !_hasPreset;

    _driverAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_animateDriverSymbol);
    selectedVehicle = widget.serviceType;
    if (selectedVehicle == "Bike") {
      _selectedCategory = 1;
    } else if (selectedVehicle == "Auto") {
      _selectedCategory = 0;
      _selectedVehicleType = 1;
    } else {
      _selectedCategory = 0;
      _selectedVehicleType = 0;
    }

    // سفر آماده (تکرار/برگشت): مستقیم به مرحلهٔ قیمت می‌رویم
    if (_hasPreset) {
      _currentStep = 2;
    }

    _startLiveLocationUpdates();
    _loadPendingPromo();

    // کلیک روی آدرس ذخیره‌شده (از هر صفحه‌ای): در مرحلهٔ اول «مبدأ» همین‌جا
    // تعیین می‌شود و بعد کاربر مقصد را خودش انتخاب می‌کند
    if (!widget.isPickerOnly) {
      SavedDestinationBus.receivers++;
      SavedDestinationBus.notifier.addListener(_onSavedDestinationPicked);
    }

    // تنظیمات کرایه از پنل ادمین (زنده)
    AppConfigService.instance.start();
    AppConfigService.instance.notifier.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    if (!widget.isPickerOnly) {
      SavedDestinationBus.notifier.removeListener(_onSavedDestinationPicked);
      SavedDestinationBus.receivers =
          max(0, SavedDestinationBus.receivers - 1);
    }
    _debounceTimer?.cancel();
    _mapIdleFallbackTimer?.cancel();
    _searchTimeoutTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _gpsServiceSubscription?.cancel();
    tripStreamSubscription?.cancel();
    _driverLocationStreamSubscription?.cancel();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _senderAddressController.dispose();
    _senderUnitController.dispose();
    _senderFloorController.dispose();
    _senderNoteController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverAddressController.dispose();
    _receiverUnitController.dispose();
    _receiverFloorController.dispose();
    _receiverNoteController.dispose();
    _tripAudioPlayer.dispose();
    AppConfigService.instance.notifier.removeListener(_onConfigChanged);
    _driverAnimationController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        backgroundColor: color,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  🏠 باتم‌شیت اول (هوم) و انتخاب سرویس
  // ════════════════════════════════════════════════════════════

  SafirService get _homeSelected {
    switch (_serviceType) {
      case 'cargo':
        return SafirService.cargo;
      case 'intercity':
        return SafirService.intercity;
      default:
        return SafirService.taxi;
    }
  }

  /// انتخاب سرویس از باتم‌شیت هوم: نقشه همان می‌ماند، فقط باتم‌شیت به
  /// مرحلهٔ «مبدأ و مقصد» همان سرویس تغییر می‌کند.
  void _selectService(SafirService service) {
    if (!_isHome) return;

    final String type = service == SafirService.cargo
        ? 'cargo'
        : service == SafirService.intercity
            ? 'intercity'
            : 'taxi';

    setState(() {
      _serviceType = type;
      selectedVehicle = type;
      _selectedCategory = 0;
      _selectedVehicleType = 0;
      _currentStep = 0;
      _isHome = false;
      _isSheetExpanded = true;
      _isMapMoving = false;
      _rideForOther = false;
      _otherName = '';
      _otherPhone = '';
    });

    // آدرس مبدأ را از مرکز فعلی نقشه تازه کن
    final LatLng? center = _mapController?.cameraPosition?.target;
    if (center != null) {
      _updateAddressFromCamera(center);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  👥 سفر برای نفر دیگر
  // ════════════════════════════════════════════════════════════

  bool get _showRideForToggle =>
      !widget.isPickerOnly &&
      !_isHome &&
      _serviceType == 'taxi' &&
      _currentStep < 3;

  Future<void> _openForOtherSheet() async {
    HapticFeedback.selectionClick();

    final Map<String, String>? result =
        await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => _ForOtherSheet(
        initialName: _otherName,
        initialPhone: _otherPhone,
        title: _mapTr(context, 'other_sheet_title'),
        description: _mapTr(context, 'other_sheet_desc'),
        nameHint: _mapTr(context, 'other_name_hint'),
        phoneHint: _mapTr(context, 'other_phone_hint'),
        invalidPhoneText: _mapTr(context, 'other_phone_invalid'),
        confirmText: _mapTr(context, 'confirm'),
        cancelText: _mapTr(context, 'cancel'),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _rideForOther = true;
      _otherName = result['name'] ?? '';
      _otherPhone = result['phone'] ?? '';
    });
  }

  Widget _buildRideForToggle() {
    Widget segment({
      required String label,
      required bool selected,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return Flexible(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryBrand : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? AppColors.buttonText
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.buttonText
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(
            label: _mapTr(context, 'ride_for_me'),
            selected: !_rideForOther,
            icon: Icons.person_rounded,
            onTap: () {
              if (!_rideForOther) return;
              HapticFeedback.selectionClick();
              setState(() {
                _rideForOther = false;
                _otherName = '';
                _otherPhone = '';
              });
            },
          ),
          segment(
            label: _mapTr(context, 'ride_for_other'),
            selected: _rideForOther,
            icon: Icons.group_rounded,
            onTap: _openForOtherSheet,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  ⭐ بعد از پایان سفر: صفحهٔ امتیاز، سپس برگشت به هوم
  // ════════════════════════════════════════════════════════════

  Future<void> _openRatingAndReset(String driverId) async {
    if (!mounted) return;

    final String tripId = tripRequestRef?.id ?? '';

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RateDriverScreen(
          tripId: tripId,
          driverId: driverId,
          driverName: nameDriver,
          carModel: carDetailsDriver,
          plateNumber: _driverPlateFarsiNum.isNotEmpty
              ? _driverPlateFarsiNum
              : _driverPlateNum,
          driverPhoto: photoDriver,
        ),
      ),
    );

    if (!mounted) return;

    if (widget.startAtHome && !widget.isPickerOnly) {
      await _resetToHomeAfterTrip();
    } else {
      // رفتار قبلی: نقشه بسته می‌شود و به صفحهٔ قبل برمی‌گردد
      Navigator.pop(context);
    }
  }

  /// همهٔ وضعیت سفر را پاک می‌کند و باتم‌شیت اول (هوم) را دوباره نشان می‌دهد
  Future<void> _resetToHomeAfterTrip() async {
    _searchTimeoutTimer?.cancel();
    _debounceTimer?.cancel();
    _geocodeRequestId++;

    await tripStreamSubscription?.cancel();
    tripStreamSubscription = null;

    await _stopListeningToDriverLocation();

    final MapLibreMapController? c = _mapController;
    if (c != null) {
      try {
        if (_originSymbol != null) await c.removeSymbol(_originSymbol!);
      } catch (_) {}
      try {
        if (_destinationSymbol != null) {
          await c.removeSymbol(_destinationSymbol!);
        }
      } catch (_) {}
      try {
        await c.clearLines();
      } catch (_) {}
    }

    _originSymbol = null;
    _destinationSymbol = null;
    _routePolylinePoints.clear();

    tripRequestRef = null;
    _lastTripStatus = null;
    _isTripFinished = false;
    _isRequestingTrip = false;
    _isCancellingTrip = false;
    _hasPlayedAcceptedSound = false;
    _hasPlayedArrivedSound = false;
    _tripOriginLatLng = null;
    _tripDestinationLatLng = null;

    _tripDistanceInKm = 0.0;
    actualFareAmount = 50.0;
    _tripDurationText = '';
    _estimatedArrivalTime = '--:--';

    _secondDestinationAddress = null;
    _stopDurationMinutes = 0;
    _isRoundTrip = false;
    _hasExtraLuggage = false;
    _preferSilence = false;
    _scheduledDateTime = null;
    _appliedPromoCode = null;
    _intercityTravelDate = null;
    _intercityPassengers = 1;

    _senderNameController.clear();
    _senderPhoneController.clear();
    _senderAddressController.clear();
    _senderUnitController.clear();
    _senderFloorController.clear();
    _senderNoteController.clear();
    _receiverNameController.clear();
    _receiverPhoneController.clear();
    _receiverAddressController.clear();
    _receiverUnitController.clear();
    _receiverFloorController.clear();
    _receiverNoteController.clear();

    if (!mounted) return;

    setState(() {
      _originLatLng = null;
      _destinationLatLng = null;
      _rideForOther = false;
      _otherName = '';
      _otherPhone = '';
      _serviceType = 'taxi';
      selectedVehicle = 'taxi';
      _selectedCategory = 0;
      _selectedVehicleType = 0;
      _currentStep = 0;
      _isHome = true;
      _isMapMoving = false;
      _isSheetExpanded = true;
    });

    _animatedMapMove(_currentUserLatLng, 15.0);
  }

  void _openMenu() {
    HapticFeedback.lightImpact();

    final bool isRtl = Directionality.of(context) == ui.TextDirection.rtl;
    if (isRtl) {
      _scaffoldKey.currentState?.openDrawer();
    } else {
      _scaffoldKey.currentState?.openEndDrawer();
    }
  }

  // ════════════════════════════════════════════════════════════
  //  🚗 ردیابی زندهٔ راننده
  // ════════════════════════════════════════════════════════════

  void _listenToDriverLiveLocation(String driverId) {
    if (_assignedDriverId == driverId && _driverLocationStreamSubscription != null) return;

    _driverLocationStreamSubscription?.cancel();
    _assignedDriverId = driverId;

    _driverLocationStreamSubscription = FirebaseFirestore.instance
        .collection('driver_locations')
        .doc(driverId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return;

        final data = snapshot.data()!;
        final double? lat = double.tryParse(data['latitude']?.toString() ?? '');
        final double? lng = double.tryParse(data['longitude']?.toString() ?? '');
        final double heading = double.tryParse(data['heading']?.toString() ?? '') ?? -1.0;

        if (lat == null || lng == null) return;

        final LatLng position = LatLng(lat, lng);

        // همیشه فقط «آخرین» مقدار نگه داشته می‌شود و آپدیت‌ها پشت سر هم
        // (نه هم‌زمان) پردازش می‌شوند.
        _latestDriverRaw = position;
        _latestDriverHeading = heading;
        _pendingDriverRawPosition = position;
        _pendingDriverRawHeading = heading;
        unawaited(_processPendingDriverUpdate());
      },
      onError: (Object e) {
        debugPrint('Driver location stream error: $e');
      },
    );
  }

  Future<void> _processPendingDriverUpdate() async {
    if (_isProcessingDriverUpdate) return;
    _isProcessingDriverUpdate = true;

    try {
      while (_pendingDriverRawPosition != null && mounted) {
        final LatLng raw = _pendingDriverRawPosition!;
        final double heading = _pendingDriverRawHeading;
        _pendingDriverRawPosition = null;

        await _updateDriverMarkerOnMap(raw, heading);
      }
    } finally {
      _isProcessingDriverUpdate = false;
    }
  }

  /// بر اساس نوع سفر (باربری) یا وسیلهٔ انتخاب‌شده (موترسایکل/ماشین)
  /// مسیر فایل آیکن و شناسهٔ تصویر مربوطه را برمی‌گرداند.
  ///
  /// نکتهٔ مهم: عکس‌ها باید «از بالا» باشند و جلوی وسیله رو به بالای عکس.
  /// اگر یکی از آیکن‌ها جهتش ثابت اشتباه بود، فقط rotationOffsetDegrees
  /// همان آیکن را روی ۹۰، ۱۸۰ یا ۲۷۰ بگذار.
  ({String assetPath, String imageId, double rotationOffsetDegrees})
      _resolveDriverIconInfo() {
    if (_serviceType == 'cargo') {
      return (
        assetPath: 'assets/images/tracking_cargo.png',
        imageId: 'driver-icon-cargo',
        rotationOffsetDegrees: 0,
      );
    }

    if (selectedVehicle == 'Bike') {
      return (
        assetPath: 'assets/images/tracking_bike.png',
        imageId: 'driver-icon-bike',
        rotationOffsetDegrees: 0,
      );
    }

    return (
      assetPath: 'assets/images/tracking_car.png',
      imageId: 'driver-icon-car',
      rotationOffsetDegrees: 0,
    );
  }

  Future<Uint8List?> _loadDriverIconBytes(String assetPath) async {
    final Uint8List? cached = _cachedDriverIconBytes[assetPath];
    if (cached != null) return cached;

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      _cachedDriverIconBytes[assetPath] = bytes;
      return bytes;
    } catch (e) {
      debugPrint('Error loading driver icon asset ($assetPath): $e');
      return null;
    }
  }

  Future<void> initDriverSymbolLayer() async {
    if (_mapController == null) return;

    final info = _resolveDriverIconInfo();

    // اگر این آیکن خاص قبلاً اضافه شده، فقط شناسهٔ فعلی را به‌روز کن
    if (_addedDriverIconIds.contains(info.imageId)) {
      _driverIconImageIdLoaded = info.imageId;
      return;
    }

    try {
      final Uint8List? iconBytes = await _loadDriverIconBytes(info.assetPath);

      if (iconBytes != null) {
        await _mapController!.addImage(info.imageId, iconBytes);
        _addedDriverIconIds.add(info.imageId);
        _driverIconImageIdLoaded = info.imageId;
        return;
      }

      // فایل مورد نظر پیدا نشد؛ موقتاً به آیکن ماشین برمی‌گردیم
      debugPrint(
        '⚠️ آیکن «${info.assetPath}» پیدا نشد؛ موقتاً از آیکن ماشین استفاده می‌شود.',
      );

      if (!_addedDriverIconIds.contains('driver-icon-car')) {
        final Uint8List? carBytes =
            await _loadDriverIconBytes('assets/images/tracking_car.png');
        if (carBytes != null) {
          await _mapController!.addImage('driver-icon-car', carBytes);
          _addedDriverIconIds.add('driver-icon-car');
        }
      }
      _driverIconImageIdLoaded = 'driver-icon-car';
    } catch (e) {
      debugPrint('Error preparing driver icon: $e');
    }
  }

  /// افست چرخش آیکنی که *واقعاً* روی نقشه نشان داده می‌شود
  double _currentDriverIconRotationOffset() {
    final info = _resolveDriverIconInfo();

    // اگر به آیکن ماشین برگشته‌ایم، افست ماشین را بگیر
    if (_driverIconImageIdLoaded == 'driver-icon-car' &&
        info.imageId != 'driver-icon-car') {
      return 0;
    }

    return info.rotationOffsetDegrees;
  }

  void _animateDriverSymbol() {
    if (!mounted ||
        _mapController == null ||
        _driverLiveSymbol == null ||
        _driverAnimationStart == null ||
        _driverAnimationEnd == null) {
      return;
    }

    // اگر فریم قبلی هنوز تمام نشده، این فریم را رد کن (جلوگیری از انباشت)؛
    // ولی فریم آخر نباید گم شود، وگرنه ماشین کمی قبل از نقطه می‌ایستد.
    if (_driverFrameBusy) {
      if (_driverAnimationController.value >= 1.0) {
        Future.delayed(const Duration(milliseconds: 40), _animateDriverSymbol);
      }
      return;
    }

    final double t = _driverAnimationController.value;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    // حدود ۳۰ فریم بر ثانیه کافی است؛ فریم آخر همیشه اعمال می‌شود
    if (t < 1.0 && nowMs - _lastDriverFrameMs < _driverFrameGapMs) return;
    _lastDriverFrameMs = nowMs;

    final double latitude = _driverAnimationStart!.latitude +
        (_driverAnimationEnd!.latitude - _driverAnimationStart!.latitude) * t;

    final double longitude = _driverAnimationStart!.longitude +
        (_driverAnimationEnd!.longitude - _driverAnimationStart!.longitude) * t;

    double bearingDifference =
        _driverAnimationEndBearing - _driverAnimationStartBearing;

    if (bearingDifference.abs() > 180) {
      bearingDifference -= 360 * bearingDifference.sign;
    }

    final double bearing =
        (_driverAnimationStartBearing + bearingDifference * t + 360) % 360;

    // موقعیت لحظه‌ای مارکر؛ آپدیت بعدی از همین نقطه شروع می‌شود
    _driverDisplayLatLng = LatLng(latitude, longitude);
    _driverDisplayBearing = bearing;

    unawaited(_pushDriverSymbolFrame(LatLng(latitude, longitude), bearing));
  }

  Future<void> _pushDriverSymbolFrame(LatLng position, double bearing) async {
    final Symbol? symbol = _driverLiveSymbol;
    if (symbol == null || _mapController == null) return;

    _driverFrameBusy = true;
    try {
      await _mapController!.updateSymbol(
        symbol,
        SymbolOptions(
          geometry: position,
          iconRotate: bearing,
          iconAnchor: 'center',
        ),
      );
    } catch (e) {
      debugPrint('Driver animation update error: $e');
      // Symbol از دست رفته؛ آپدیت بعدی راننده آن را از نو می‌سازد
      _driverLiveSymbol = null;
    } finally {
      _driverFrameBusy = false;
    }
  }

  /// فاز مسیر بر اساس وضعیت سفر
  String _currentRoutePhase() =>
      _lastTripStatus == TripStatus.onTrip ? 'onTrip' : 'pickup';

  /// زاویهٔ پایدار مسیر: از نقطه‌ای حدود ۱۲ متر جلوتر حساب می‌شود تا
  /// سر پیچ‌ها و قطعه‌های خیلی کوتاه آیکن تند نپرد.
  double _routeBearingAhead(_SnapResult snap) {
    final List<LatLng> poly = _driverTripPolylinePoints;

    for (int i = snap.segmentIndex + 1; i < poly.length; i++) {
      final double d = Geolocator.distanceBetween(
        snap.point.latitude,
        snap.point.longitude,
        poly[i].latitude,
        poly[i].longitude,
      );
      if (d >= 12) {
        return _calculateBearing(snap.point, poly[i]);
      }
    }

    final int i = min(snap.segmentIndex, poly.length - 2);
    return _calculateBearing(poly[i], poly[i + 1]);
  }

  /// منطق حرکت:
  ///  • چسباندن نقطه به مسیر (اگر ≤ ۴۰ متر) و پیشروی فقط «به جلو»
  ///  • انیمیشن از موقعیت لحظه‌ایِ مارکر شروع می‌شود (نه نقطهٔ قبلی)
  ///  • زاویه از جهت پایدار مسیر (روی مسیر) یا جهت حرکت (خارج از مسیر)
  ///  • مسیر به «طی‌شده» (خاکستری) و «باقی‌مانده» (آبی) تقسیم می‌شود
  ///  • خروج از مسیر (فاصله یا حرکت خلاف جهت) → مسیر قدیمی همان لحظه
  ///    پاک می‌شود، ماشین آزادانه حرکت می‌کند و مسیر تازه از زیر ماشین
  ///    (با جهت حرکت فعلی) کشیده می‌شود
  Future<void> _updateDriverMarkerOnMap(
    LatLng rawPosition,
    double rawHeading,
  ) async {
    if (_mapController == null) return;

    try {
      LatLng markerTarget = rawPosition;
      _SnapResult? onRouteSnap;

      // ───── جهت واقعی حرکت (از دو نقطهٔ خام با حداقل ۱۲ متر فاصله) ─────
      double? moveBearing;
      final LatLng? dirRef = _dirRefPoint;
      if (dirRef == null) {
        _dirRefPoint = rawPosition;
      } else if (Geolocator.distanceBetween(
            dirRef.latitude,
            dirRef.longitude,
            rawPosition.latitude,
            rawPosition.longitude,
          ) >=
          _moveSampleMeters) {
        moveBearing = _calculateBearing(dirRef, rawPosition);
        _driverMoveBearing = moveBearing;
        _dirRefPoint = rawPosition;
      }

      bool offRoute = false;

      if (!_driverRouteStale &&
          _isDriverTripRouteVisible &&
          _driverTripPolylinePoints.length >= 2) {
        final _SnapResult? snap = _snapToPolylineDetailed(
          rawPosition,
          _driverTripPolylinePoints,
          startIndex: _driverProgressIndex,
        );

        if (snap != null && snap.distance <= _offRouteThresholdMeters) {
          if (moveBearing != null) {
            double diff =
                (moveBearing - _routeBearingAhead(snap)).abs() % 360;
            if (diff > 180) diff = 360 - diff;

            // حرکت خلاف جهت مسیر (دنده‌عقب یا خیابان مخالف) حتی نزدیک خط
            final bool wrongWay = diff > _wrongWayAngleDegrees;

            // پیچیدن به کوچهٔ کناری: هنوز نزدیک خط است ولی جهتش فرق کرده
            final bool deviating = diff > _deviationAngleDegrees &&
                snap.distance > _deviationMinDistanceMeters;

            _wrongWayCount =
                (wrongWay || deviating) ? _wrongWayCount + 1 : 0;
          }

          if (_wrongWayCount >= _wrongWayConfirmCount) {
            offRoute = true;
          } else {
            onRouteSnap = snap;
            markerTarget = snap.point;
            _driverProgressIndex = max(_driverProgressIndex, snap.segmentIndex);
            _driverOffRouteCount = 0;
          }
        } else {
          _driverOffRouteCount++;

          // خیلی دور از مسیر: منتظر تایید دوباره نمی‌ماند
          if (snap == null || snap.distance > _immediateOffRouteMeters) {
            _driverOffRouteCount = _offRouteConfirmCount;
          }

          offRoute = _driverOffRouteCount >= _offRouteConfirmCount;
        }
      }

      // خروج از مسیر تایید شد: مسیر قدیمی همین‌جا از نقشه پاک می‌شود
      if (offRoute && !_driverRouteStale) {
        _driverRouteStale = true;
        unawaited(_hideDriverRouteLines());
      }

      _maybeRefreshDriverRoute(
        rawPosition,
        offRouteConfirmed: _driverRouteStale,
      );

      if (_driverRouteStale) {
        unawaited(_updateTempLine(rawPosition));
      }

      // خوانش پرت/ناگهانی GPS که هنوز «خارج از مسیر» تایید نشده: ماشین سر جایش
      // می‌ماند. در حالت «مسیر کهنه» ماشین هرگز یخ نمی‌زند و آزادانه می‌رود.
      if (_isDriverTripRouteVisible &&
          onRouteSnap == null &&
          !_driverRouteStale &&
          _lastDriverLatLng != null &&
          _driverLiveSymbol != null) {
        _updateLiveDriverEta(_lastDriverLatLng ?? rawPosition);
        return;
      }

      await initDriverSymbolLayer();
      if (_mapController == null) return;

      final LatLng? previousTarget = _lastDriverLatLng;

      // ───── زاویه ─────
      // جهت فقط وقتی عوض می‌شود که حرکت واقعی باشد؛ لرزش GPS ماشین را نمی‌چرخاند.
      double baseBearing = _driverBaseBearing;

      if (onRouteSnap != null) {
        // روی مسیر: زاویه‌ی پایدار خیابان
        baseBearing = _routeBearingAhead(onRouteSnap);
        _bearingRefPoint = markerTarget;
      } else if (_driverLiveSymbol == null) {
        if (rawHeading > 0) {
          baseBearing = rawHeading;
        }
        _bearingRefPoint = markerTarget;
      } else {
        final LatLng? ref = _bearingRefPoint ?? previousTarget;

        if (ref != null &&
            Geolocator.distanceBetween(
                  ref.latitude,
                  ref.longitude,
                  markerTarget.latitude,
                  markerTarget.longitude,
                ) >=
                12) {
          baseBearing = _calculateBearing(ref, markerTarget);
          _bearingRefPoint = markerTarget;
        }
      }

      _driverBaseBearing = baseBearing;

      final double markerBearing =
          (baseBearing + _currentDriverIconRotationOffset() + 360) % 360;

      // ───── مدت انیمیشن = فاصلهٔ زمانی بین دو آپدیت ─────
      final DateTime now = DateTime.now();
      final int dtMs = _lastDriverUpdateAt == null
          ? 1000
          : now.difference(_lastDriverUpdateAt!).inMilliseconds;
      _lastDriverUpdateAt = now;

      if (_driverLiveSymbol == null) {
        _driverAnimationController.stop();

        _driverLiveSymbol = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: markerTarget,
            iconImage: _driverIconImageIdLoaded ?? 'driver-icon-car',
            iconSize: 1.15,
            iconRotate: markerBearing,
            iconAnchor: 'center',
          ),
        );

        _lastDriverLatLng = markerTarget;
        _driverDisplayLatLng = markerTarget;
        _driverDisplayBearing = markerBearing;
        _driverAnimationStart = markerTarget;
        _driverAnimationEnd = markerTarget;
        _driverAnimationStartBearing = markerBearing;
        _driverAnimationEndBearing = markerBearing;
      } else {
        _driverAnimationStart =
            _driverDisplayLatLng ?? previousTarget ?? markerTarget;
        _driverAnimationEnd = markerTarget;
        _driverAnimationStartBearing = _driverDisplayBearing;
        _driverAnimationEndBearing = markerBearing;

        _driverAnimationController.stop();
        _driverAnimationController.duration = Duration(
          milliseconds: dtMs.clamp(400, 2500).toInt(),
        );
        _driverAnimationController.forward(from: 0.0);

        _lastDriverLatLng = markerTarget;
      }

      _updateLiveDriverEta(markerTarget);

      // خط طی‌شده/باقی‌مانده را بعد از شروع حرکت مارکر آپدیت کن
      if (onRouteSnap != null) {
        await _renderDriverProgress(onRouteSnap);
      }
    } catch (e) {
      debugPrint('Error updating animated driver symbol: $e');
    }
  }

  /// تصمیم می‌گیرد مسیر راننده باید دوباره کشیده شود یا نه (غیرمسدودکننده)
  void _maybeRefreshDriverRoute(
    LatLng raw, {
    required bool offRouteConfirmed,
  }) {
    if (_isFetchingDriverTripRoute || _mapController == null) return;
    if (_tripOriginLatLng == null || _tripDestinationLatLng == null) return;

    final DateTime now = DateTime.now();

    // اگر سرور جواب نداد، فاصلهٔ تلاش بعدی بیشتر می‌شود (۱۰، ۲۰، ۴۰ ثانیه)
    // تا سرور اذیت نشود و برنامه گیر نکند.
    final int cooldownSeconds = _rerouteFailCount == 0
        ? _rerouteCooldownSeconds
        : min(5 * (1 << _rerouteFailCount), 40);

    // اولین بازمسیریابی بعد از خروج از مسیر (بدون خطای قبلی) فقط ۲ ثانیه
    // فاصله می‌خواهد تا مسیر جدید دیر نیاید.
    final int effectiveCooldown =
        (_driverRouteStale && _rerouteFailCount == 0) ? 2 : cooldownSeconds;

    final bool cooledDown = _lastDriverRouteFetchAt == null ||
        now.difference(_lastDriverRouteFetchAt!).inSeconds >= effectiveCooldown;

    final bool phaseChanged = _driverRouteBuiltForPhase != _currentRoutePhase();
    final bool needsRoute =
        !_isDriverTripRouteVisible || phaseChanged || offRouteConfirmed;

    if (!needsRoute) return;

    // تغییر فاز (شروع سفر) یا اولین مسیر نباید منتظر cooldown بماند
    // (به‌شرطی که تلاش قبلی ناموفق نبوده)
    final bool urgent = _rerouteFailCount == 0 &&
        (!_isDriverTripRouteVisible || phaseChanged);
    if (!urgent && !cooledDown) return;

    unawaited(_drawDriverTripRoute(raw));
  }

  /// وقتی وضعیت سفر عوض شد (مثلاً شروع سفر) فوراً مسیر جدید بکش
  void _refreshDriverRouteNow() {
    final LatLng? raw = _latestDriverRaw;
    if (raw == null || _isFetchingDriverTripRoute) return;
    unawaited(_drawDriverTripRoute(raw));
  }

  /// نقطه‌ای در فاصلهٔ [meters] از [from] در جهت [bearing] (درجه از شمال)
  LatLng _offsetPoint(LatLng from, double bearing, double meters) {
    final double rad = bearing * pi / 180;
    final double dLat = meters * cos(rad) / 111320.0;
    final double dLng =
        meters * sin(rad) / (111320.0 * cos(from.latitude * pi / 180));
    return LatLng(from.latitude + dLat, from.longitude + dLng);
  }

  /// اگر ابتدای مسیر نسبت به جهت حرکت ماشین «به عقب» می‌رود (مثلاً دور
  /// برگردان)، آن بخش را حذف می‌کند و مسیر از ماشین به‌طرف جلو ادامه می‌یابد.
  /// فقط ۲۰۰ متر اول مسیر بررسی می‌شود.
  List<LatLng> _trimBackwardStart(
    List<LatLng> route,
    LatLng car,
    double bearing,
  ) {
    if (route.length < 3) return route;

    final double k = cos(car.latitude * pi / 180);
    final double hx = sin(bearing * pi / 180);
    final double hy = cos(bearing * pi / 180);

    // فاصلهٔ نقطه «در امتداد جهت حرکت» نسبت به ماشین (متر؛ منفی = پشت ماشین)
    double along(LatLng p) {
      final double dx = (p.longitude - car.longitude) * k * 111320.0;
      final double dy = (p.latitude - car.latitude) * 111320.0;
      return dx * hx + dy * hy;
    }

    double dist(LatLng a, LatLng b) => Geolocator.distanceBetween(
          a.latitude,
          a.longitude,
          b.latitude,
          b.longitude,
        );

    int firstBack = -1;
    double travelled = 0;
    for (int i = 0; i < route.length; i++) {
      if (i > 0) travelled += dist(route[i - 1], route[i]);
      if (travelled > 200) break;
      if (along(route[i]) < -10) {
        firstBack = i;
        break;
      }
    }

    if (firstBack == -1) return route;

    // اولین نقطه‌ای که دوباره «جلوی» ماشین است و مسیر از آن رو به جلو می‌رود
    double travelled2 = 0;
    for (int j = firstBack + 1; j < route.length - 1; j++) {
      travelled2 += dist(route[j - 1], route[j]);
      if (travelled2 > 400) break;

      if (along(route[j]) >= 0) {
        double diff =
            (_calculateBearing(route[j], route[j + 1]) - bearing).abs() % 360;
        if (diff > 180) diff = 360 - diff;

        if (diff <= 90) {
          return <LatLng>[car, ...route.sublist(j)];
        }
      }
    }

    return route;
  }

  /// مسیر OSRM با جایگزینی خودکار بین سرورها.
  /// [bearing] جهت حرکت فعلی راننده است تا مسیر جدید به‌جای «دور زدن به عقب»
  /// در همان جهتی که ماشین می‌رود شروع شود. اگر سرور نپذیرفت، بدون آن تلاش
  /// مجدد می‌شود.
  Future<List<LatLng>> _getOsrmPoints(
    LatLng from,
    LatLng to, {
    double? bearing,
  }) async {
    Future<List<LatLng>> request(bool useBearing) async {
      final String bearings = useBearing && bearing != null
          ? '&bearings=${bearing.round() % 360},50;'
          : '';

      final Map<String, dynamic> data = await _osrmRequest(
        '/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson$bearings',
      );

      final List routes = (data['routes'] as List?) ?? <dynamic>[];
      if (routes.isEmpty) {
        throw Exception('No route found');
      }

      final List coordinates = routes.first['geometry']['coordinates'] as List;

      return coordinates.map((point) {
        return LatLng(
          (point[1] as num).toDouble(),
          (point[0] as num).toDouble(),
        );
      }).toList();
    }

    if (bearing != null) {
      try {
        return await request(true);
      } catch (_) {
        // سرور جهت را نپذیرفت یا جاده‌ای در آن جهت نبود؛ بدون جهت امتحان کن
      }
    }
    return request(false);
  }

  // ───────── مسافت و ETA محلی (بدون درخواست به سرور) ─────────

  /// مسافت باقی‌ماندهٔ روی خط مسیر تا نقطهٔ هدف (مبدأ یا مقصد)؛
  /// اگر مسیر معتبر نیست null برمی‌گرداند.
  double? _remainingRouteMeters(LatLng from) {
    final List<LatLng> poly = _driverTripPolylinePoints;

    if (!_isDriverTripRouteVisible ||
        _driverRouteStale ||
        poly.length < 2 ||
        _driverRouteBuiltForPhase != _currentRoutePhase()) {
      return null;
    }

    final int endIdx = _driverRouteBuiltForPhase == 'onTrip'
        ? poly.length - 1
        : min(_driverPickupEndIndex, poly.length - 1);

    final int start = min(_driverProgressIndex + 1, endIdx);

    double meters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      poly[start].latitude,
      poly[start].longitude,
    );

    for (int i = start; i < endIdx; i++) {
      meters += Geolocator.distanceBetween(
        poly[i].latitude,
        poly[i].longitude,
        poly[i + 1].latitude,
        poly[i + 1].longitude,
      );
    }

    return meters;
  }

  /// ETA زنده؛ کاملاً محلی (بدون OSRM) و فقط اگر مقدار تغییر کرده باشد setState می‌زند
  void _updateLiveDriverEta(LatLng driverPosition) {
    if (!mounted) return;

    final LatLng? target = _lastTripStatus == TripStatus.onTrip
        ? _tripDestinationLatLng
        : _tripOriginLatLng;

    if (target == null) return;

    final double meters = _remainingRouteMeters(driverPosition) ??
        // مسیر آماده نیست: خط مستقیم × ضریب جاده
        Geolocator.distanceBetween(
              driverPosition.latitude,
              driverPosition.longitude,
              target.latitude,
              target.longitude,
            ) *
            1.35;

    final int totalMinutes = max(1, (meters / _assumedSpeedMps / 60).ceil());
    _etaMinutes = totalMinutes;

    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;

    final String durationText =
        hours > 0 ? '$hours ساعت و $minutes دقیقه' : '$minutes دقیقه';

    final DateTime arrival = DateTime.now().add(Duration(minutes: totalMinutes));

    final String arrivalText =
        '${arrival.hour.toString().padLeft(2, '0')}:'
        '${arrival.minute.toString().padLeft(2, '0')}';

    if (durationText == _tripDurationText &&
        arrivalText == _estimatedArrivalTime) {
      return;
    }

    setState(() {
      _tripDurationText = durationText;
      _estimatedArrivalTime = arrivalText;
    });
  }

  Future<void> _drawDriverTripRoute(LatLng driverPosition, {int attempt = 0}) async {
    if (_isFetchingDriverTripRoute || _mapController == null) return;
    if (_tripOriginLatLng == null || _tripDestinationLatLng == null) return;

    _isFetchingDriverTripRoute = true;
    _lastDriverRouteFetchAt = DateTime.now();

    final String phaseAtStart = _currentRoutePhase();
    bool refetchWithLatest = false;

    try {
      // جهت حرکت فعلی راننده؛ مسیر جدید باید در همین جهت شروع شود
      final double? bearingHint = _driverMoveBearing ??
          (_driverRouteStale && _latestDriverHeading > 0
              ? _latestDriverHeading
              : null);

      // بازمسیریابی بعد از خروج از مسیر: مسیر از نقطه‌ای کمی «جلوتر» در جهت
      // حرکت شروع می‌شود تا هرگز از پشت ماشین شروع نشود (دور زدن به عقب).
      final bool useLookAhead = _driverRouteStale && bearingHint != null;
      final LatLng routeStart = useLookAhead
          ? _offsetPoint(driverPosition, bearingHint!, _lookAheadMeters)
          : driverPosition;

      // ماشین را به ابتدای مسیر وصل می‌کند و اگر مسیر اول به عقب می‌رفت
      // (حتی اگر سرور جهت را نادیده گرفته باشد)، بخش عقب را حذف می‌کند.
      List<LatLng> forwardOnly(List<LatLng> leg) {
        List<LatLng> result = leg;
        if (useLookAhead) {
          result = <LatLng>[driverPosition, ...result];
        }
        if (bearingHint != null) {
          result = _trimBackwardStart(result, driverPosition, bearingHint);
        }
        return result;
      }

      final List<LatLng> fullRoute;
      int pickupEnd;

      if (phaseAtStart == 'onTrip') {
        // سفر شروع شده: مسیر راننده تا مقصد
        fullRoute = forwardOnly(
          await _getOsrmPoints(
            routeStart,
            _tripDestinationLatLng!,
            bearing: bearingHint,
          ),
        );
        pickupEnd = fullRoute.length - 1;
      } else {
        // قبل از سوارشدن: راننده → مبدأ → مقصد
        final List<LatLng> driverToOrigin = forwardOnly(
          await _getOsrmPoints(
            routeStart,
            _tripOriginLatLng!,
            bearing: bearingHint,
          ),
        );
        final List<LatLng> originToDestination =
            await _getOsrmPoints(_tripOriginLatLng!, _tripDestinationLatLng!);

        fullRoute = <LatLng>[
          ...driverToOrigin,
          ...originToDestination.skip(1),
        ];
        pickupEnd = driverToOrigin.length - 1;
      }

      // شروع خط دقیقاً از زیر ماشین باشد (بدون فاصلهٔ خالی)
      if (fullRoute.isNotEmpty) {
        final double gap = Geolocator.distanceBetween(
          driverPosition.latitude,
          driverPosition.longitude,
          fullRoute.first.latitude,
          fullRoute.first.longitude,
        );
        if (gap > 3 && gap < 60) {
          fullRoute.insert(0, driverPosition);
          pickupEnd += 1;
        }
      }

      if (!mounted || _mapController == null || _assignedDriverId == null) return;

      // اگر در حین گرفتن مسیر، راننده خیلی از نقطهٔ شروع دور شده،
      // این مسیر کهنه است؛ رسمش نکن و با موقعیت تازه دوباره بگیر.
      final LatLng? latest = _latestDriverRaw;
      if (latest != null &&
          attempt < 2 &&
          Geolocator.distanceBetween(
                driverPosition.latitude,
                driverPosition.longitude,
                latest.latitude,
                latest.longitude,
              ) >
              40) {
        refetchWithLatest = true;
      } else {
        _driverTripPolylinePoints = fullRoute;
        _driverPickupEndIndex = pickupEnd;
        _isDriverTripRouteVisible = true;
        _driverRouteBuiltForPhase = phaseAtStart;
        _driverProgressIndex = 0;
        _driverOffRouteCount = 0;
        _wrongWayCount = 0;
        _rerouteFailCount = 0;
        _driverRouteStale = false;
        _dirRefPoint = _latestDriverRaw;
        _driverLastRenderedSegment = -1;
        _driverLastRenderedPoint = null;

        await _renderDriverRouteLines(
          traveled: <LatLng>[],
          remaining: fullRoute,
        );

        // مسیر آماده شد؛ ماشین را همان لحظه با مسیر هماهنگ کن
        if (_latestDriverRaw != null) {
          _pendingDriverRawPosition = _latestDriverRaw;
          _pendingDriverRawHeading = _latestDriverHeading;
          unawaited(_processPendingDriverUpdate());
        }
      }
    } catch (e) {
      debugPrint('Error drawing driver trip route: $e');
      // تلاش‌های ناموفق پشت سر هم فاصله‌شان بیشتر می‌شود
      _rerouteFailCount = min(_rerouteFailCount + 1, 4);
    } finally {
      _isFetchingDriverTripRoute = false;
    }

    if (refetchWithLatest && _latestDriverRaw != null) {
      await _drawDriverTripRoute(_latestDriverRaw!, attempt: attempt + 1);
    }
  }

  /// خط را به دو بخش تقسیم می‌کند: طی‌شده (خاکستری) و باقی‌مانده (آبی)
  Future<void> _renderDriverProgress(_SnapResult snap) async {
    if (_mapController == null || _isFetchingDriverTripRoute) return;

    // مسیر کهنه است؛ خط قدیمی نباید دوباره کشیده شود
    if (_driverRouteStale) return;

    final List<LatLng> poly = _driverTripPolylinePoints;
    if (snap.segmentIndex + 1 >= poly.length) return;

    final LatLng? lastPoint = _driverLastRenderedPoint;
    if (snap.segmentIndex == _driverLastRenderedSegment &&
        lastPoint != null &&
        Geolocator.distanceBetween(
              lastPoint.latitude,
              lastPoint.longitude,
              snap.point.latitude,
              snap.point.longitude,
            ) <
            3) {
      return;
    }

    _driverLastRenderedSegment = snap.segmentIndex;
    _driverLastRenderedPoint = snap.point;

    final List<LatLng> traveled = <LatLng>[
      for (int i = 0; i <= snap.segmentIndex; i++) poly[i],
      snap.point,
    ];
    final List<LatLng> remaining = <LatLng>[
      snap.point,
      for (int i = snap.segmentIndex + 1; i < poly.length; i++) poly[i],
    ];

    await _renderDriverRouteLines(traveled: traveled, remaining: remaining);
  }

  Future<void> _renderDriverRouteLines({
    required List<LatLng> traveled,
    required List<LatLng> remaining,
  }) async {
    if (_mapController == null || remaining.isEmpty) return;

    // یک خط با دو نقطهٔ یکسان روی نقشه دیده نمی‌شود
    final List<LatLng> grey =
        traveled.length >= 2 ? traveled : <LatLng>[remaining.first, remaining.first];

    try {
      if (_driverRouteLine != null && _driverTraveledLine != null) {
        await _mapController!.updateLine(
          _driverTraveledLine!,
          LineOptions(geometry: grey),
        );
        await _mapController!.updateLine(
          _driverRouteLine!,
          LineOptions(geometry: remaining),
        );
        return;
      }
    } catch (_) {
      // خط‌ها پاک شده‌اند؛ پایین‌تر دوباره اضافه می‌شوند
      _driverRouteLine = null;
      _driverTraveledLine = null;
    }

    try {
      await _mapController!.clearLines();
      _driverTempLine = null; // clearLines خط موقت را هم پاک کرد

      _driverTraveledLine = await _mapController!.addLine(
        LineOptions(
          geometry: grey,
          lineColor: AppColors.routeTraveledHex,
          lineWidth: 5.5,
        ),
      );

      _driverRouteLine = await _mapController!.addLine(
        LineOptions(
          geometry: remaining,
          lineColor: AppColors.routeLineHex,
          lineWidth: 5.5,
        ),
      );
    } catch (e) {
      debugPrint('Error rendering driver route lines: $e');
      _driverRouteLine = null;
      _driverTraveledLine = null;
    }
  }

  /// مسیر قدیمی را فوراً از نقشه برمی‌دارد (وقتی راننده از مسیر خارج شد)
  Future<void> _hideDriverRouteLines() async {
    final MapLibreMapController? c = _mapController;
    if (c == null) return;

    final Line? a = _driverRouteLine;
    final Line? b = _driverTraveledLine;

    _driverRouteLine = null;
    _driverTraveledLine = null;
    _driverLastRenderedSegment = -1;
    _driverLastRenderedPoint = null;

    try {
      if (a != null) await c.removeLine(a);
    } catch (_) {}
    try {
      if (b != null) await c.removeLine(b);
    } catch (_) {}
  }

  /// تا رسیدن مسیر جدید، یک خط نازک و کم‌رنگ از ماشین تا هدف نشان می‌دهد
  /// تا نقشه خالی نماند و مسیر غلط قبلی هم دیده نشود.
  Future<void> _updateTempLine(LatLng from) async {
    if (_tempLineBusy || !_driverRouteStale || _mapController == null) return;

    final LatLng? target = _lastTripStatus == TripStatus.onTrip
        ? _tripDestinationLatLng
        : _tripOriginLatLng;
    if (target == null) return;

    _tempLineBusy = true;
    try {
      final List<LatLng> geometry = <LatLng>[from, target];

      if (_driverTempLine == null) {
        _driverTempLine = await _mapController!.addLine(
          LineOptions(
            geometry: geometry,
            lineColor: AppColors.routeLineHex,
            lineWidth: 4.0,
            lineOpacity: 0.4,
          ),
        );
      } else {
        await _mapController!.updateLine(
          _driverTempLine!,
          LineOptions(geometry: geometry),
        );
      }

      // در همین فاصله مسیر جدید رسیده بود؛ خط موقت دیگر لازم نیست
      if (!_driverRouteStale && _driverTempLine != null) {
        final Line temp = _driverTempLine!;
        _driverTempLine = null;
        try {
          await _mapController!.removeLine(temp);
        } catch (_) {}
      }
    } catch (_) {
      _driverTempLine = null;
    } finally {
      _tempLineBusy = false;
    }
  }

  Future<void> _stopListeningToDriverLocation() async {
    _driverAnimationController.stop();
    await _driverLocationStreamSubscription?.cancel();
    _driverLocationStreamSubscription = null;
    _assignedDriverId = null;

    _pendingDriverRawPosition = null;
    _latestDriverRaw = null;
    _lastDriverLatLng = null;
    _driverAnimationStart = null;
    _driverAnimationEnd = null;
    _driverTripPolylinePoints.clear();
    _isDriverTripRouteVisible = false;
    _isFetchingDriverTripRoute = false;
    _driverRouteLine = null;
    _driverTraveledLine = null;
    _driverTempLine = null;
    _tempLineBusy = false;
    _driverProgressIndex = 0;
    _driverOffRouteCount = 0;
    _driverLastRenderedSegment = -1;
    _driverLastRenderedPoint = null;
    _driverDisplayLatLng = null;
    _lastDriverUpdateAt = null;
    _driverRouteBuiltForPhase = null;
    _driverPickupEndIndex = 0;
    _lastDriverRouteFetchAt = null;
    _driverFrameBusy = false;
    _bearingRefPoint = null;
    _driverBaseBearing = 0.0;
    _etaMinutes = 0;
    _driverRouteStale = false;
    _dirRefPoint = null;
    _driverMoveBearing = null;
    _wrongWayCount = 0;
    _rerouteFailCount = 0;

    if (_driverLiveSymbol != null && _mapController != null) {
      try {
        await _mapController!.removeSymbol(_driverLiveSymbol!);
      } catch (e) {
        debugPrint('Error removing driver symbol: $e');
      }
      _driverLiveSymbol = null;
    }

    if (_mapController != null) {
      try {
        await _mapController!.clearLines();
      } catch (_) {}
    }
  }

  /// بعد از لغو (توسط مسافر، راننده یا زمان‌گذشته) به مرحلهٔ انتخاب سرویس
  /// برمی‌گردد و مسیر پیش‌نمایش را دوباره می‌کشد.
  Future<void> _resetToRequestStep() async {
    _searchTimeoutTimer?.cancel();

    // ✅ پنل سفر همان لحظه بسته می‌شود؛ پاک‌سازی نقشه بعدش انجام می‌شود
    if (mounted) {
      setState(() => _currentStep = 2);
    }

    await _stopListeningToDriverLocation();
    _lastTripStatus = null;

    if (!mounted) return;

    _fetchRoute();
  }

  // ════════════════════════════════════════════════════════════
  //  📍 موقعیت مسافر و وضعیت GPS
  // ════════════════════════════════════════════════════════════

  void _setGpsDisruption(bool value) {
    if (_hasGpsDisruption == value || !mounted) return;
    setState(() => _hasGpsDisruption = value);
  }

  /// تصمیم‌گیری هشدار بر اساس دقت، با دو آستانه تا هشدار چشمک نزند
  void _evaluateGpsAccuracy(double accuracy) {
    if (accuracy > _gpsBadAccuracyMeters) {
      _setGpsDisruption(true);
    } else if (accuracy <= _gpsGoodAccuracyMeters) {
      _setGpsDisruption(false);
    }
  }

  Future<void> _startLiveLocationUpdates() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setGpsDisruption(true);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setGpsDisruption(true);
        return;
      }

      // اولین موقعیت جدا گرفته می‌شود تا خطایش، استریم را متوقف نکند
      try {
        final Position initialPosition = await Geolocator.getCurrentPosition(
          // ✅ دقت بیشتر برای نقطهٔ شروع (قبلاً high بود)
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 10),
        );

        if (mounted) {
          final LatLng target =
              LatLng(initialPosition.latitude, initialPosition.longitude);

          setState(() {
            _currentUserLatLng = target;
            _currentGpsAccuracy = initialPosition.accuracy;
          });

          _evaluateGpsAccuracy(initialPosition.accuracy);

          // در سفر آماده، دوربین نباید به موقعیت کاربر برگردد
          if (!_hasPreset) {
            _animatedMapMove(target, 15.0);

            if (_currentStep < 2 && !_isHome) {
              _updateAddressFromCamera(target);
            }
          }
        }
      } catch (e) {
        debugPrint('Initial GPS fix failed: $e');
        _setGpsDisruption(true);
      }

      // خاموش‌شدن GPS در حین کار
      _gpsServiceSubscription?.cancel();
      _gpsServiceSubscription =
          Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
        if (status == ServiceStatus.disabled) {
          _setGpsDisruption(true);
        }
      });

      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          // ✅ دقت بیشتر در استریم (قبلاً medium بود)
          accuracy: LocationAccuracy.best,
          distanceFilter: 3,
          intervalDuration: const Duration(seconds: 1),
        ),
      ).listen(
        (Position position) {
          if (!mounted) return;

          // این مقادیر فقط در لحظهٔ نیاز خوانده می‌شوند؛ بدون setState
          // تا کل صفحه با هر خوانش GPS rebuild نشود.
          _currentUserLatLng = LatLng(position.latitude, position.longitude);
          _currentGpsAccuracy = position.accuracy;

          _evaluateGpsAccuracy(position.accuracy);
        },
        onError: (Object e) {
          debugPrint('GPS stream error: $e');
          _setGpsDisruption(true);
        },
      );
    } catch (e) {
      debugPrint("Error fetching GPS location stream: $e");
      _setGpsDisruption(true);
    }
  }

  Future<void> _handleGpsTap() async {
    HapticFeedback.lightImpact();
    _animatedMapMove(_currentUserLatLng, 16.8);

    try {
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 4),
      );

      final LatLng freshPoint = LatLng(pos.latitude, pos.longitude);

      if (mounted) {
        setState(() {
          _currentUserLatLng = freshPoint;
          _currentGpsAccuracy = pos.accuracy;
        });

        _evaluateGpsAccuracy(pos.accuracy);

        _animatedMapMove(freshPoint, 16.8);

        if (_currentStep < 2) {
          _updateAddressFromCamera(freshPoint);
        }
      }
    } catch (_) {
      // زمان‌گذشته یا GPS خاموش؛ اگر سرویس خاموش است هشدار بده
      try {
        if (!await Geolocator.isLocationServiceEnabled()) {
          _setGpsDisruption(true);
        }
      } catch (_) {}
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (_mapController == null) return;
    _isProgrammaticMove = true;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(destLocation, destZoom),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  📌 پینِ وسط نقشه (بالا‌رفتن هنگام حرکت، فرود هنگام توقف)
  //
  //  باگ قبلی: وقتی کشوی پایین بسته بود، فقط متغیر _isMapMoving عوض می‌شد
  //  ولی setState صدا زده نمی‌شد؛ پس پین بالا نمی‌پرید و روی نقشه می‌چسبید.
  //  همچنین اگر onCameraIdle نمی‌آمد یا پرچم «حرکت برنامه‌ای» گیر می‌کرد،
  //  پین تا لمس بعدی خراب می‌ماند.
  // ════════════════════════════════════════════════════════════

  void _onMapPointerDown() {
    _activePointers++;
    _isUserGesture = true;
    // لمس کاربر همیشه بر هر حرکت برنامه‌ای قبلی غلبه می‌کند
    _isProgrammaticMove = false;
    _mapIdleFallbackTimer?.cancel();
  }

  void _onMapPointerReleased() {
    _activePointers = max(0, _activePointers - 1);

    if (_activePointers == 0) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _activePointers == 0) {
          _isUserGesture = false;
        }
      });

      if (_isMapMoving) {
        _restartMapIdleFallback();
      }
    }
  }

  void _onMapCameraMove() {
    // پین فقط وقتی بالا می‌آید که دست کاربر نقشه را حرکت داده باشد
    // (در حالت هوم پین نداریم)
    if (_isUserGesture &&
        !_isProgrammaticMove &&
        !_isHome &&
        _currentStep < 2 &&
        !_isMapMoving &&
        mounted) {
      setState(() {
        _isMapMoving = true;
        _isSheetExpanded = false;
      });
    }

    if (_isMapMoving) {
      _restartMapIdleFallback();
    }
  }

  /// اگر به هر دلیلی onCameraIdle نیامد، بعد از مدتی که دوربین حرکت نکرد
  /// پین خودش پایین می‌آید.
  void _restartMapIdleFallback() {
    _mapIdleFallbackTimer?.cancel();
    _mapIdleFallbackTimer = Timer(
      const Duration(milliseconds: 900),
      _onMapIdleFallback,
    );
  }

  void _onMapIdleFallback() {
    if (!mounted || !_isMapMoving) return;
    if (_activePointers > 0) return; // انگشت هنوز روی نقشه است
    _handleMapIdle();
  }

  void _handleMapIdle() {
    _mapIdleFallbackTimer?.cancel();

    final bool wasProgrammaticMove = _isProgrammaticMove;

    if (_isMapMoving && mounted) {
      setState(() {
        _isMapMoving = false;
      });
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _isProgrammaticMove = false;
      }
    });

    if (!wasProgrammaticMove &&
        !_isHome &&
        _currentStep < 2 &&
        _mapController != null) {
      final LatLng? target = _mapController!.cameraPosition?.target;
      if (target != null) {
        _updateAddressFromCamera(target);
      }
    }
  }

  /// ✅ ژئوکدینگ معکوس مرکز نقشه.
  ///
  /// اصلاح مهم: مرحله‌ای که درخواست در آن شروع شده ذخیره می‌شود و اگر تا
  /// رسیدن پاسخ مرحله عوض شده باشد (مثلاً کاربر مبدأ را تأیید کرده)، پاسخ
  /// دور ریخته می‌شود. قبلاً پاسخ دیررسیده، مختصات «مبدأ» را روی «مقصد»
  /// (یا برعکس) می‌نوشت و مارکر/سفر با چند متر خطا ثبت می‌شد.
  void _updateAddressFromCamera(LatLng center) {
    if (widget.isPickerOnly && mounted && !_pickerLoading) {
      setState(() => _pickerLoading = true);
    }

    final int stepAtRequest = _currentStep;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final int requestId = ++_geocodeRequestId;

      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${center.latitude}&lon=${center.longitude}&accept-language=fa,ps,en',
        );
        final response = await http
            .get(url, headers: {'User-Agent': 'safir_passengers'})
            .timeout(const Duration(seconds: 8));

        // پاسخ کهنه (کاربر نقشه را دوباره جابه‌جا کرده یا تأیید زده) نادیده گرفته می‌شود
        if (requestId != _geocodeRequestId) return;
        if (!widget.isPickerOnly && stepAtRequest != _currentStep) return;

        if (response.statusCode == 200 && mounted) {
          final data = json.decode(response.body);
          final addressObj = data['address'];

          String formattedAddress = 'selected_location'.tr();

          if (addressObj != null) {
            String city = addressObj['city'] ?? addressObj['town'] ?? addressObj['county'] ?? addressObj['state'] ?? '';
            String suburb = addressObj['suburb'] ?? addressObj['neighbourhood'] ?? addressObj['quarter'] ?? addressObj['residential'] ?? '';
            String road = addressObj['road'] ?? addressObj['pedestrian'] ?? addressObj['path'] ?? '';

            List<String> addressParts = [];
            if (city.isNotEmpty) addressParts.add(city);
            if (suburb.isNotEmpty && suburb != city) addressParts.add(suburb);
            if (road.isNotEmpty && road != suburb) addressParts.add(road);

            if (addressParts.isNotEmpty) {
              formattedAddress = addressParts.join(context.locale.languageCode == 'en' ? ', ' : '، ');
            } else {
              formattedAddress = data['display_name'] ?? formattedAddress;
            }
          }

          if (!mounted) return;

          AddressModel userLocation = AddressModel(
            placeName: formattedAddress,
            humanReadableAddress: formattedAddress,
            latitudePosition: center.latitude,
            longitudePosition: center.longitude,
          );

          // حالت فقط‌انتخاب: به AppInfo (مبدأ/مقصد سفر) دست نمی‌زنیم
          if (widget.isPickerOnly) {
            setState(() {
              _pickerAddress = formattedAddress;
              _pickerLoading = false;
            });
            return;
          }

          var appInfo = Provider.of<AppInfo>(context, listen: false);
          if (_currentStep == 0) {
            appInfo.updatePickUpLocation(userLocation);
            _senderAddressController.text = formattedAddress;
          } else if (_currentStep == 1) {
            appInfo.updateDropOffLocation(userLocation);
            _receiverAddressController.text = formattedAddress;
          }
        } else if (widget.isPickerOnly && mounted) {
          setState(() => _pickerLoading = false);
        }
      } catch (e) {
        debugPrint("Error reverse geocoding: $e");
        if (widget.isPickerOnly && mounted) {
          setState(() => _pickerLoading = false);
        }
      }
    });
  }

  /// با تأیید مبدأ/مقصد، هر ژئوکدینگ در راه باطل می‌شود
  void _cancelPendingGeocode() {
    _debounceTimer?.cancel();
    _geocodeRequestId++;
  }

  // ───────── مارکرهای مبدأ و مقصد ─────────

  Future<void> _addOriginMarker(LatLng point) async {
    final MapLibreMapController? c = _mapController;
    if (c == null) return;

    final Uint8List bytes = _originLabelBytes ??=
        await widgetToImageBytes(MapOriginLabel(labelText: 'origin'.tr()));
    if (_mapController == null) return;

    await c.addImage('origin-marker-icon', bytes);

    if (_originSymbol != null) {
      try {
        await c.removeSymbol(_originSymbol!);
      } catch (_) {}
    }

    _originSymbol = await c.addSymbol(
      SymbolOptions(
        geometry: point,
        iconImage: 'origin-marker-icon',
        iconAnchor: 'bottom',
      ),
    );
  }

  Future<void> _addDestinationMarker(LatLng point) async {
    final MapLibreMapController? c = _mapController;
    if (c == null) return;

    final Uint8List bytes = await widgetToImageBytes(
      MapDestinationLabel(
        labelText: 'destination'.tr(),
        arrivalTime: _estimatedArrivalTime,
      ),
    );
    if (_mapController == null) return;

    await c.addImage('dest-marker-icon', bytes);

    if (_destinationSymbol != null) {
      try {
        await c.removeSymbol(_destinationSymbol!);
      } catch (_) {}
    }

    _destinationSymbol = await c.addSymbol(
      SymbolOptions(
        geometry: point,
        iconImage: 'dest-marker-icon',
        iconAnchor: 'bottom',
      ),
    );
  }

  /// ✅ وقتی استایل نقشه دوباره لود می‌شود (مثلاً با عوض‌شدن تم)، مارکرها و
  /// خط مسیر پیش‌نمایش پاک می‌شوند؛ این تابع آن‌ها را سر جای خودشان برمی‌گرداند.
  Future<void> _restoreTripMarkers() async {
    _originSymbol = null;
    _destinationSymbol = null;

    try {
      if (_originLatLng != null) {
        await _addOriginMarker(_originLatLng!);
      }
      if (_destinationLatLng != null) {
        await _addDestinationMarker(_destinationLatLng!);
      }

      if (_currentStep == 2 &&
          _routePolylinePoints.length >= 2 &&
          _mapController != null) {
        await _mapController!.addLine(
          LineOptions(
            geometry: _routePolylinePoints,
            lineColor: AppColors.routeLineHex,
            lineWidth: 5.5,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error restoring markers: $e');
    }
  }

  /// مبدأ و مقصد آمادهٔ «تکرار/برگشت سفر» را روی نقشه می‌گذارد
  Future<void> _applyPresetTrip() async {
    if (_presetApplied || !_hasPreset || _mapController == null || !mounted) {
      return;
    }
    _presetApplied = true;

    final LatLng origin = widget.presetOrigin!;
    final LatLng destination = widget.presetDestination!;

    final String originName = (widget.presetOriginName ?? '').trim().isNotEmpty
        ? widget.presetOriginName!.trim()
        : 'origin'.tr();
    final String destinationName =
        (widget.presetDestinationName ?? '').trim().isNotEmpty
            ? widget.presetDestinationName!.trim()
            : 'destination'.tr();

    final AppInfo appInfo = Provider.of<AppInfo>(context, listen: false);

    appInfo.updatePickUpLocation(
      AddressModel(
        placeName: originName,
        humanReadableAddress: originName,
        latitudePosition: origin.latitude,
        longitudePosition: origin.longitude,
      ),
    );

    appInfo.updateDropOffLocation(
      AddressModel(
        placeName: destinationName,
        humanReadableAddress: destinationName,
        latitudePosition: destination.latitude,
        longitudePosition: destination.longitude,
      ),
    );

    try {
      await _addOriginMarker(origin);
      await _addDestinationMarker(destination);
    } catch (e) {
      debugPrint('Error adding preset markers: $e');
    }

    if (!mounted) return;

    setState(() {
      _originLatLng = origin;
      _destinationLatLng = destination;
      _currentStep = 2;
      _isSheetExpanded = true;
    });

    _fetchRoute();
  }

  /// [at] و [name] وقتی کاربر از جستجو مکانی انتخاب کرده پر می‌شوند؛
  /// وگرنه مرکز فعلی نقشه استفاده می‌شود.
  Future<void> _confirmOrigin({LatLng? at, String? name}) async {
    if (_isConfirming) return;
    _isConfirming = true;
    try {
      await _confirmOriginImpl(at: at, name: name);
    } finally {
      _isConfirming = false;
    }
  }

  Future<void> _confirmOriginImpl({LatLng? at, String? name}) async {
    HapticFeedback.mediumImpact();

    if (_mapController == null) return;

    // ✅ هر ژئوکدینگ نیمه‌کاره باطل شود تا بعد از تأیید، مختصات را عوض نکند
    _cancelPendingGeocode();

    LatLng? center = at;
    if (center == null) {
      final camera = await _mapController!.queryCameraPosition();
      center = camera?.target;
    }
    if (center == null) return;

    final LatLng currentCenter = center;
    if (!mounted) return;
    final appInfo = Provider.of<AppInfo>(context, listen: false);

    appInfo.updatePickUpLocation(
      AddressModel(
        latitudePosition: currentCenter.latitude,
        longitudePosition: currentCenter.longitude,
        placeName: name ?? appInfo.pickUpLocation?.placeName ?? 'origin'.tr(),
        humanReadableAddress:
            name ?? appInfo.pickUpLocation?.humanReadableAddress,
      ),
    );

    await _addOriginMarker(currentCenter);

    if (!mounted) return;

    setState(() {
      _originLatLng = currentCenter;
    });

    _animatedMapMove(currentCenter, 16.5);

    if (_serviceType == 'cargo') {
      CargoSheets.showSenderDialog(
        context: context,
        nameController: _senderNameController,
        phoneController: _senderPhoneController,
        addressController: _senderAddressController,
        unitController: _senderUnitController,
        floorController: _senderFloorController,
        noteController: _senderNoteController,
        onConfirm: () {
          setState(() {
            _currentStep = 1;
            _isSheetExpanded = true;
          });
        },
      );
    } else if (_serviceType == 'intercity') {
      setState(() {
        _currentStep = 1;
        _isSheetExpanded = true;
      });
      IntercitySheets.showCityPicker(
        context: context,
        targetCities: _intercityCities,
        onCitySelected: (selectedCity) {
          LatLng cityLatLng = LatLng(selectedCity['lat'], selectedCity['lng']);
          _animatedMapMove(cityLatLng, 13.0);
        },
      );
    } else {
      setState(() {
        _currentStep = 1;
        _isSheetExpanded = true;
      });
    }
  }

  Future<void> _confirmDestination({LatLng? at, String? name}) async {
    if (_isConfirming) return;
    _isConfirming = true;
    try {
      await _confirmDestinationImpl(at: at, name: name);
    } finally {
      _isConfirming = false;
    }
  }

  Future<void> _confirmDestinationImpl({LatLng? at, String? name}) async {
    HapticFeedback.mediumImpact();

    if (_mapController == null) return;

    // ✅ هر ژئوکدینگ نیمه‌کاره باطل شود
    _cancelPendingGeocode();

    LatLng? center = at;
    if (center == null) {
      final camera = await _mapController!.queryCameraPosition();
      center = camera?.target;
    }
    if (center == null) return;

    final LatLng currentCenter = center;
    if (!mounted) return;
    final appInfo = Provider.of<AppInfo>(context, listen: false);

    appInfo.updateDropOffLocation(
      AddressModel(
        latitudePosition: currentCenter.latitude,
        longitudePosition: currentCenter.longitude,
        placeName: name ?? appInfo.dropOffLocation?.placeName ?? 'destination'.tr(),
        humanReadableAddress:
            name ?? appInfo.dropOffLocation?.humanReadableAddress,
      ),
    );

    await _addDestinationMarker(currentCenter);

    if (!mounted) return;

    setState(() {
      _destinationLatLng = currentCenter;
    });

    if (_serviceType == 'cargo') {
      CargoSheets.showReceiverDialog(
        context: context,
        nameController: _receiverNameController,
        phoneController: _receiverPhoneController,
        addressController: _receiverAddressController,
        unitController: _receiverUnitController,
        floorController: _receiverFloorController,
        noteController: _receiverNoteController,
        selectedPackageType: _cargoPackageType,
        onPackageTypeChanged: (val) => setState(() => _cargoPackageType = val ?? ''),
        selectedInsurance: _cargoInsurance,
        onInsuranceChanged: (val) => setState(() => _cargoInsurance = val ?? ''),
        onConfirm: () {
          setState(() => _currentStep = 2);
          _fetchRoute();
        },
      );
    } else {
      setState(() => _currentStep = 2);
      _fetchRoute();
    }
  }

  Future<void> _clearPreviewRoute() async {
    _routeRequestId++; // هر درخواست مسیرِ در راه نادیده گرفته شود
    _routePolylinePoints.clear();
    _driverRouteLine = null;
    _driverTraveledLine = null;
    _driverTempLine = null;

    if (_mapController != null) {
      await _mapController!.clearLines();
    }
  }

  // ════════════════════════════════════════════════════════════
  //  💰 کرایه بر اساس تنظیمات پنل ادمین
  // ════════════════════════════════════════════════════════════

  /// کرایهٔ سفر فعلی بر اساس مسافت و تنظیمات ادمین
  double _computeFare(double km) {
    final AppConfig cfg = AppConfigService.instance.config;

    if (_serviceType == 'cargo') {
      return CargoSheets.calculateFareForVehicle(_cargoSelectedVehicle, km);
    }

    if (_serviceType == 'intercity') {
      return cfg.intercityFare(km, passengers: _intercityPassengers);
    }

    return cfg.fareForVehicle(selectedVehicle, km);
  }

  /// وقتی ادمین قیمت‌ها را عوض کرد، قیمت روی صفحه همان لحظه به‌روز می‌شود
  void _onConfigChanged() {
    if (!mounted) return;

    setState(() {
      if (_currentStep == 2 && _tripDistanceInKm > 0) {
        actualFareAmount = _computeFare(_tripDistanceInKm);
      }
    });
  }

  void _fetchRoute() {
    var appInfo = Provider.of<AppInfo>(context, listen: false);
    if (appInfo.pickUpLocation == null || _mapController == null) return;

    final int requestId = ++_routeRequestId;

    setState(() {
      _routePolylinePoints.clear();
    });
    _driverTempLine = null;
    unawaited(_mapController!.clearLines());

    LatLng originLatLng = _originLatLng ??
        LatLng(appInfo.pickUpLocation!.latitudePosition!, appInfo.pickUpLocation!.longitudePosition!);
    LatLng destLatLng = _destinationLatLng ??
        _mapController!.cameraPosition?.target ??
        _currentUserLatLng;

    MapControllerLogic.getOSRMRoute(
      context: context,
      selectedVehicle: selectedVehicle,
      customOrigin: originLatLng,
      customDestination: destLatLng,
      onRouteFetched: (points, fare, durationText, arrivalTime, distanceKm) async {
        // اگر در این فاصله درخواست جدیدتری ثبت شده، این پاسخ کهنه است
        if (mounted && requestId == _routeRequestId) {
          setState(() {
            _routePolylinePoints = points;
            // مسافت دقیقاً همان عددی است که OSRM از روی مسیر واقعی جاده حساب
            // کرده و برای کرایه هم استفاده می‌شود.
            _tripDistanceInKm = distanceKm;
            // ✅ کرایه از تنظیمات پنل ادمین حساب می‌شود
            // (پارامتر fare قدیمی دیگر استفاده نمی‌شود)
            actualFareAmount = _computeFare(distanceKm);
            _tripDurationText = durationText;
            _estimatedArrivalTime = arrivalTime;
          });

          if (_routePolylinePoints.isNotEmpty && _mapController != null) {
            // مسیر قبلی کاملاً پاک شود تا دو خط روی هم نیفتد
            await _mapController!.clearLines();
            if (!mounted || requestId != _routeRequestId) return;

            await _mapController!.addLine(
              LineOptions(
                geometry: _routePolylinePoints,
                lineColor: AppColors.routeLineHex,
                lineWidth: 5.5,
              ),
            );

            double minLat = _routePolylinePoints.map((p) => p.latitude).reduce(min);
            double maxLat = _routePolylinePoints.map((p) => p.latitude).reduce(max);
            double minLng = _routePolylinePoints.map((p) => p.longitude).reduce(min);
            double maxLng = _routePolylinePoints.map((p) => p.longitude).reduce(max);

            _isProgrammaticMove = true;
            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(minLat, minLng),
                  northeast: LatLng(maxLat, maxLng),
                ),
                left: 50,
                top: 120,
                right: 50,
                // پایین مسیر نباید زیر کشوی انتخاب سرویس (~۴۲٪ صفحه) بماند
                bottom: MediaQuery.of(context).size.height * 0.5,
              ),
            );
          }
        }
      },
    );
  }

  void _openTripOptionsSheet() {
    MapBottomSheets.showTripOptions(
      context,
      TripOptionsSheet(
        secondDestination: _secondDestinationAddress,
        stopMinutes: _stopDurationMinutes,
        isRoundTrip: _isRoundTrip,
        hasLuggage: _hasExtraLuggage,
        preferSilence: _preferSilence,
        onSelectSecondDestinationOnMap: () async {
          final response = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const SearchDestinationPlace(updateDropOff: false),
            ),
          );
          final AddressModel? picked = _pickedAddress(response);
          if (picked == null || !mounted) return;
          // مقصد اصلی سفر دست‌نخورده می‌ماند؛ فقط مقصد دوم ثبت می‌شود
          setState(() {
            _secondDestinationAddress = picked.placeName;
          });
          _fetchRoute();
        },
        onSave: (secondDest, stop, round, luggage, silence) {
          setState(() {
            _secondDestinationAddress = secondDest;
            _stopDurationMinutes = stop;
            _isRoundTrip = round;
            _hasExtraLuggage = luggage;
            _preferSilence = silence;
          });
          _fetchRoute();
        },
      ),
    );
  }

  void _openScheduleSheet() {
    MapBottomSheets.showScheduleTrip(
      context,
      ScheduleTripSheet(
        initialDateTime: _scheduledDateTime,
        onScheduleConfirmed: (selectedTime) {
          setState(() {
            _scheduledDateTime = selectedTime;
          });
        },
      ),
    );
  }

  void _openPromoCodeSheet() {
    MapBottomSheets.showPromoCode(
      context,
      PromoCodeSheet(
        initialCode: _appliedPromoCode ?? '',
        validator: _validatePromoCode,
        onApply: (code) {
          setState(() {
            _appliedPromoCode = code.isEmpty ? null : code.toUpperCase();
          });
          // با منوی پروفایل هماهنگ بماند
          if (code.isEmpty) {
            PromoService.clearPending();
          } else {
            PromoService.savePending(code);
          }
        },
      ),
    );
  }

  Future<PromoValidation> _validatePromoCode(String code) =>
      PromoService.validate(code);

  /// کد تأییدشده‌ای که کاربر قبلاً (مثلاً از منوی پروفایل) ثبت کرده بود، خودکار اعمال می‌شود
  Future<void> _loadPendingPromo() async {
    final String? code = await PromoService.loadPending();
    if (!mounted || code == null || _hasPromoCode) return;
    setState(() => _appliedPromoCode = code);
  }

  Future<void> _playTripStatusSound(String tripStatus) async {
    try {
      if (tripStatus == TripStatus.accepted && !_hasPlayedAcceptedSound) {
        _hasPlayedAcceptedSound = true;

        await _tripAudioPlayer.stop();
        await _tripAudioPlayer.play(
          AssetSource('audio/fa/driver_accepted.mp3'),
          volume: 1.0,
        );
      }

      if (tripStatus == TripStatus.arrived && !_hasPlayedArrivedSound) {
        _hasPlayedArrivedSound = true;

        await _tripAudioPlayer.stop();
        await _tripAudioPlayer.play(
          AssetSource('audio/fa/driver_arrived.mp3'),
          volume: 1.0,
        );
      }
    } catch (e) {
      debugPrint('Trip status audio error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  //  🚕 ثبت، پیگیری و لغو سفر
  // ════════════════════════════════════════════════════════════

  void startTrip() async {
    HapticFeedback.heavyImpact();

    if (_isRequestingTrip) return;

    var appInfo = Provider.of<AppInfo>(context, listen: false);

    if (appInfo.pickUpLocation == null || appInfo.dropOffLocation == null) {
      _showSnack(_mapTr(context, 'select_origin_destination_msg'));
      return;
    }

    _isRequestingTrip = true;

    try {
      // ✅ آخرین تنظیمات (قیمت و فعال‌بودن سرویس) را مستقیم از سرور بگیر
      final AppConfig latestConfig = await AppConfigService.instance.refresh();
      if (!mounted) return;

      if (!latestConfig.isServiceActive) {
        _showSnack(
          _mapTr(context, 'service_inactive_msg'),
          color: Colors.orange.shade800,
        );
        return;
      }

      // اگر در این فاصله قیمت‌ها عوض شده، قیمت جدید را نشان بده
      final double freshFare = _computeFare(_tripDistanceInKm);
      if ((freshFare - actualFareAmount).abs() >= 1) {
        setState(() => actualFareAmount = freshFare);
        _showSnack(
          _mapTr(context, 'fare_updated_msg'),
        );
        return;
      }

      await _clearPreviewRoute();
      if (!mounted) return;

      // اگر استریم سفر قبلی هنوز باز است، ببند
      await tripStreamSubscription?.cancel();
      tripStreamSubscription = null;
      _searchTimeoutTimer?.cancel();

      // مبدأ و مقصد واقعی سفر (همان‌هایی که در rides ذخیره می‌شود)
      _tripOriginLatLng = LatLng(
        appInfo.pickUpLocation!.latitudePosition!,
        appInfo.pickUpLocation!.longitudePosition!,
      );
      _tripDestinationLatLng = LatLng(
        appInfo.dropOffLocation!.latitudePosition!,
        appInfo.dropOffLocation!.longitudePosition!,
      );

      setState(() {
        _driverTripPolylinePoints.clear();
        _lastDriverLatLng = null;
        _isDriverTripRouteVisible = false;
        _isFetchingDriverTripRoute = false;
        _currentStep = 3;
      });
      _latestDriverRaw = null;
      _pendingDriverRawPosition = null;
      _driverRouteLine = null;
      _driverTraveledLine = null;
      _driverTempLine = null;
      _tempLineBusy = false;
      _driverProgressIndex = 0;
      _driverOffRouteCount = 0;
      _driverLastRenderedSegment = -1;
      _driverLastRenderedPoint = null;
      _driverDisplayLatLng = null;
      _lastDriverUpdateAt = null;
      _driverRouteBuiltForPhase = null;
      _driverPickupEndIndex = 0;
      _lastDriverRouteFetchAt = null;
      _driverRouteStale = false;
      _dirRefPoint = null;
      _driverMoveBearing = null;
      _wrongWayCount = 0;
      _rerouteFailCount = 0;
      _hasPlayedAcceptedSound = false;
      _hasPlayedArrivedSound = false;
      _lastTripStatus = null;
      _isTripFinished = false;

      try {
        tripRequestRef = FirebaseFirestore.instance.collection('rides').doc();

        String passengerUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        String passengerNameVal = FirebaseAuth.instance.currentUser?.displayName ?? 'مسافر سفیر';
        String passengerPhoneVal = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

        Map<String, dynamic> passengerTripDetails = {
          'ride_id': tripRequestRef!.id,
          'status': TripStatus.searching,
          'driver_id': 'waiting',
          'createdAt': FieldValue.serverTimestamp(),

          'passenger_id': passengerUid,
          'passenger_name': passengerNameVal,
          'passenger_phone': passengerPhoneVal,
          'userName': passengerNameVal,
          'userPhone': passengerPhoneVal,
          'userRating': '4.8',

          'originAddress': appInfo.pickUpLocation!.placeName ?? '',
          'destinationAddress': appInfo.dropOffLocation!.placeName ?? '',
          'origin_address': appInfo.pickUpLocation!.placeName ?? '',
          'destination_address': appInfo.dropOffLocation!.placeName ?? '',
          'pickup_address': appInfo.pickUpLocation!.placeName ?? '',
          'dropoff_address': appInfo.dropOffLocation!.placeName ?? '',

          'origin': {
            'latitude': appInfo.pickUpLocation!.latitudePosition,
            'longitude': appInfo.pickUpLocation!.longitudePosition,
          },
          'destination': {
            'latitude': appInfo.dropOffLocation!.latitudePosition,
            'longitude': appInfo.dropOffLocation!.longitudePosition,
          },
          // ناحیهٔ جغرافیایی مبدأ (شبکهٔ ۰٫۱ درجه ≈ ۱۰ کیلومتر)؛ راننده‌ها فقط
          // سفرهای ناحیهٔ خودشان و ناحیه‌های اطراف را می‌خوانند.
          // فرمول باید دقیقاً با اپ راننده یکی باشد: «عرض_طول»
          'geo_cell':
              '${(appInfo.pickUpLocation!.latitudePosition! / 0.1).floor()}_'
              '${(appInfo.pickUpLocation!.longitudePosition! / 0.1).floor()}',
          'originLatLng': GeoPoint(
            appInfo.pickUpLocation!.latitudePosition!,
            appInfo.pickUpLocation!.longitudePosition!,
          ),
          'destinationLatLng': GeoPoint(
            appInfo.dropOffLocation!.latitudePosition!,
            appInfo.dropOffLocation!.longitudePosition!,
          ),

          'fareAmount': actualFareAmount,
          'fare': actualFareAmount,
          'price': actualFareAmount,
          // ✅ گرد‌شده تا اعداد اعشاری بی‌معنی (مثل 7.0463000000001) ذخیره نشود
          'distance': double.parse(_tripDistanceInKm.toStringAsFixed(2)),
          'duration': _tripDurationText,
          'service_type': _serviceType,
          'vehicle_type': selectedVehicle,

          // ───── گزینه‌های سفر (قبلاً ذخیره نمی‌شدند) ─────
          'is_round_trip': _isRoundTrip,
          'has_extra_luggage': _hasExtraLuggage,
          'prefer_silence': _preferSilence,
          'stop_duration_minutes': _stopDurationMinutes,
          'second_destination_address': _secondDestinationAddress,
          'is_scheduled': _isScheduled,
          'scheduled_at': _scheduledDateTime != null
              ? Timestamp.fromDate(_scheduledDateTime!)
              : null,
          'promo_code': _appliedPromoCode,

          // ───── سفر برای نفر دیگر ─────
          // راننده باید هنگام رسیدن با «contact_phone» تماس بگیرد
          'ride_for_other': _serviceType == 'taxi' && _rideForOther,
          'contact_phone': (_serviceType == 'taxi' && _rideForOther)
              ? _otherPhone
              : passengerPhoneVal,
          'contact_name': (_serviceType == 'taxi' && _rideForOther)
              ? (_otherName.isNotEmpty ? _otherName : 'مسافر')
              : passengerNameVal,
          if (_serviceType == 'taxi' && _rideForOther) ...<String, dynamic>{
            'other_passenger_name': _otherName,
            'other_passenger_phone': _otherPhone,
          },

          // ───── باربری ─────
          if (_serviceType == 'cargo') ...<String, dynamic>{
            'cargo_vehicle': _cargoSelectedVehicle,
            'cargo_package_type': _cargoPackageType,
            'cargo_insurance': _cargoInsurance,
            'cargo_payer': _cargoPaymentPayer,
            'cargo_sender_name': _senderNameController.text.trim(),
            'cargo_sender_phone': _senderPhoneController.text.trim(),
            'cargo_sender_address': _senderAddressController.text.trim(),
            'cargo_sender_unit': _senderUnitController.text.trim(),
            'cargo_sender_floor': _senderFloorController.text.trim(),
            'cargo_sender_note': _senderNoteController.text.trim(),
            'cargo_receiver_name': _receiverNameController.text.trim(),
            'cargo_receiver_phone': _receiverPhoneController.text.trim(),
            'cargo_receiver_address': _receiverAddressController.text.trim(),
            'cargo_receiver_unit': _receiverUnitController.text.trim(),
            'cargo_receiver_floor': _receiverFloorController.text.trim(),
            'cargo_receiver_note': _receiverNoteController.text.trim(),
          },

          // ───── بین‌شهری ─────
          if (_serviceType == 'intercity') ...<String, dynamic>{
            'intercity_date': _intercityTravelDate != null
                ? Timestamp.fromDate(_intercityTravelDate!)
                : null,
            'intercity_passengers': _intercityPassengers,
          },
        };

        await tripRequestRef!.set(passengerTripDetails);

        // کد تخفیف در این سفر مصرف شد؛ برای سفر بعد دوباره نیاز به ثبت دارد
        if (_hasPromoCode) {
          PromoService.clearPending();
        }

        // اگر در حین ثبت، صفحه بسته شد یا کاربر منصرف شد
        if (!mounted) return;

        _startSearchTimeout(tripRequestRef!.id);

        tripStreamSubscription = tripRequestRef!.snapshots().listen((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return;

          final data = snapshot.data() as Map<String, dynamic>;
          final String tripStatus = data["status"] ?? TripStatus.searching;
          final String driverId = data["driver_id"] ?? data["driverId"] ?? "";

          if (_lastTripStatus != tripStatus) {
            _lastTripStatus = tripStatus;
            _playTripStatusSound(tripStatus);

            // وقتی از حالت جستجو خارج شد، تایمر انقضا لازم نیست
            if (tripStatus != TripStatus.searching) {
              _searchTimeoutTimer?.cancel();
            }

            // سفر شروع شد → مسیر باید از راننده تا مقصد باشد
            if (tripStatus == TripStatus.onTrip) {
              _refreshDriverRouteNow();
            }
          }

          final bool isDriverActive = tripStatus == TripStatus.accepted ||
              tripStatus == TripStatus.arrived ||
              tripStatus == TripStatus.onTrip;

          if (mounted) {
            setState(() {
              nameDriver = data["driver_name"] ?? data["driverName"] ?? nameDriver;
              phoneNumberDriver = data["driver_phone"] ?? data["driverPhone"] ?? phoneNumberDriver;
              photoDriver = data["driver_photo"] ?? data["driverPhoto"] ?? photoDriver;
              carDetailsDriver = data["car_details"] ?? data["carModel"] ?? carDetailsDriver;

              _driverCarColor = data["car_color"] ?? data["carColor"] ?? _mapTr(context, 'car_default_color');
              _driverPlateProvince = data["plate_province"] ?? _mapTr(context, 'plate_default_province');
              _driverPlateCategory = data["plate_category"] ?? "ش";
              _driverPlateFarsiNum = data["plate_farsi_num"] ?? data["plateNumber"] ?? "";
              _driverPlateNum = data["plate_num"] ?? data["plateNumber"] ?? "";
              _driverIsTempPlate = data["is_temp_plate"] ?? false;

              if (isDriverActive) {
                _currentStep = 4;
              }
            });

            if (isDriverActive && driverId.isNotEmpty && driverId != "waiting") {
              _listenToDriverLiveLocation(driverId);
            }

            if (tripStatus == TripStatus.arrived) {
              _showSnack(_mapTr(context, 'driver_arrived_msg'));
            }

            if (tripStatus == TripStatus.cancelledByDriver) {
              tripStreamSubscription?.cancel();
              tripStreamSubscription = null;

              // برگشت به مرحلهٔ انتخاب سرویس و کشیدن دوبارهٔ مسیر پیش‌نمایش
              unawaited(_resetToRequestStep());

              _showSnack(_mapTr(context, 'trip_cancelled_by_driver_msg'), color: Colors.red);
            }
          }

          if (tripStatus == TripStatus.completed || tripStatus == TripStatus.ended) {
            if (_isTripFinished) return;
            _isTripFinished = true;

            _searchTimeoutTimer?.cancel();
            tripStreamSubscription?.cancel();
            tripStreamSubscription = null;
            _stopListeningToDriverLocation();

            if (mounted) {
              unawaited(_openRatingAndReset(driverId));
            }
          }
        });
      } catch (e) {
        debugPrint("Error starting trip: $e");
        _searchTimeoutTimer?.cancel();
        if (mounted) {
          setState(() => _currentStep = 2);
          _fetchRoute();
          _showSnack(_mapTr(context, 'request_failed_retry_msg'), color: Colors.red);
        }
      }
    } finally {
      _isRequestingTrip = false;
    }
  }

  /// اگر تا ۵ دقیقه راننده‌ای قبول نکرد، درخواست را لغو می‌کند
  /// (راننده‌ها هم سفرهای قدیمی‌تر از ۵ دقیقه را نادیده می‌گیرند).
  void _startSearchTimeout(String tripId) {
    _searchTimeoutTimer?.cancel();
    _searchTimeoutTimer = Timer(_searchTimeout, () {
      unawaited(_handleSearchTimeout(tripId));
    });
  }

  Future<void> _handleSearchTimeout(String tripId) async {
    if (!mounted) return;

    final DocumentReference? ref = tripRequestRef;
    if (ref == null || ref.id != tripId) return;

    try {
      final bool cancelled =
          await FirebaseFirestore.instance.runTransaction<bool>((Transaction tx) async {
        final DocumentSnapshot snap = await tx.get(ref);
        if (!snap.exists) return false;

        final Map<String, dynamic> data =
            (snap.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

        final String status =
            data['status']?.toString().trim().toLowerCase() ?? '';

        // فقط اگر هنوز در حال جستجو است (راننده‌ای قبول نکرده)
        if (status != TripStatus.searching.toString().toLowerCase()) {
          return false;
        }

        tx.update(ref, {
          'status': TripStatus.cancelledByPassenger,
          'cancelled_by': 'system_timeout',
          'cancel_reason': 'no_driver_found',
          'cancelled_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        return true;
      });

      if (!cancelled || !mounted) return;

      await tripStreamSubscription?.cancel();
      tripStreamSubscription = null;

      await _resetToRequestStep();

      _showSnack(
        _mapTr(context, 'no_driver_found_msg'),
        color: Colors.orange.shade800,
      );
    } catch (e) {
      debugPrint('Search timeout cancel error: $e');
    }
  }

  void cancelTrip() {
    unawaited(_cancelTripInternal());
  }

  Future<void> _cancelTripInternal() async {
    HapticFeedback.lightImpact();

    if (_isCancellingTrip) return;

    // سفری که از قبل تمام یا لغو شده دوباره لغو نمی‌شود
    final String last = (_lastTripStatus ?? '').trim().toLowerCase();
    final bool alreadyFinished = last == TripStatus.completed.toLowerCase() ||
        last == TripStatus.ended.toLowerCase() ||
        last == TripStatus.cancelledByDriver.toLowerCase() ||
        last == TripStatus.cancelledByPassenger.toLowerCase();

    if (alreadyFinished) return;

    _isCancellingTrip = true;
    _searchTimeoutTimer?.cancel();

    try {
      final DocumentReference? ref = tripRequestRef;

      // استریم سفر را قبل از هر کاری ببند تا وضعیت قبلی صفحه را برنگرداند
      final StreamSubscription<DocumentSnapshot>? oldSubscription =
          tripStreamSubscription;
      tripStreamSubscription = null;
      unawaited(oldSubscription?.cancel());

      // ✅ لغو بدون منتظر ماندن برای سرور:
      // نوشتن روی Firestore به‌صورت محلی همان لحظه اعمال می‌شود و
      // وقتی اینترنت وصل بود خودکار به سرور می‌رسد.
      if (ref != null) {
        unawaited(
          ref.update(<String, dynamic>{
            'status': TripStatus.cancelledByPassenger,
            'cancelled_by': 'passenger',
            'cancelled_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          }).catchError((Object e) {
            debugPrint('Cancel trip server error: $e');
          }),
        );
      }

      // ✅ پنل سفر همان لحظه بسته می‌شود
      await _resetToRequestStep();
    } finally {
      _isCancellingTrip = false;
    }
  }

  void _onSavedDestinationPicked() {
    final AddressModel? address = SavedDestinationBus.notifier.value;
    if (address == null || !mounted) return;

    SavedDestinationBus.notifier.value = null;

    // هر صفحه‌ای روی نقشه باز است (منوی پروفایل، آدرس‌ها) بسته شود
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route != null) {
      Navigator.of(context).popUntil((Route<dynamic> r) => r == route);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handleSavedAddressTap(address);
      }
    });
  }

  /// کلیک روی آدرس ذخیره‌شده («خانه / محل کار / ...»):
  ///  • مرحلهٔ ۰ (انتخاب مبدأ): آدرس ذخیره‌شده «مبدأ» سفر می‌شود، نقشه روی آن
  ///    می‌رود و صفحه به مرحلهٔ انتخاب مقصد می‌رود؛ مقصد را کاربر خودش
  ///    انتخاب می‌کند.
  ///  • مرحلهٔ ۱ (انتخاب مقصد): مبدأ از قبل تعیین شده؛ آدرس ذخیره‌شده
  ///    «مقصد» می‌شود.
  Future<void> _handleSavedAddressTap(AddressModel address) async {
    final double? lat = address.latitudePosition;
    final double? lng = address.longitudePosition;
    if (lat == null || lng == null || _isConfirming) return;

    // اگر باتم‌شیت اول (هوم) باز بود، با کلیک روی آدرس ذخیره‌شده (مثلاً از
    // منوی کناری) به مرحلهٔ انتخاب مبدأ تاکسی می‌رویم
    if (_isHome) {
      setState(() {
        _isHome = false;
        _serviceType = 'taxi';
        selectedVehicle = 'taxi';
        _selectedCategory = 0;
        _selectedVehicleType = 0;
        _currentStep = 0;
        _isSheetExpanded = true;
      });
    }

    final LatLng target = LatLng(lat, lng);
    final String? name = address.placeName ?? address.humanReadableAddress;

    if (_currentStep == 0) {
      // مبدأ = آدرس ذخیره‌شده. برای باربری و بین‌شهری هم همین تابع، مرحله‌های
      // اضافه (فرم فرستنده / انتخاب شهر) را به‌صورت عادی نشان می‌دهد.
      await _confirmOrigin(at: target, name: name);
      return;
    }

    if (_currentStep == 1) {
      await _confirmDestination(at: target, name: name);
    }
  }

  /// نتیجه‌ی صفحه‌ی جستجو یک Map است (نه رشته)؛ آدرس معتبر را برمی‌گرداند.
  AddressModel? _pickedAddress(dynamic response) {
    if (response is! Map) return null;
    final dynamic address = response['address'];
    if (address is! AddressModel) return null;
    if (address.latitudePosition == null || address.longitudePosition == null) {
      return null;
    }
    return address;
  }

  void _handleBackAction() {
    HapticFeedback.lightImpact();

    // وقتی سفر ثبت شده (جستجوی راننده / راننده در راه)، دکمهٔ برگشت مرحله را
    // کم نمی‌کند؛ لغو فقط با دکمهٔ «لغو سفر» انجام می‌شود. قبلاً این‌جا
    // مرحله کم می‌شد ولی سفر فعال می‌ماند و صفحه به هم می‌ریخت.
    if (_currentStep >= 3) return;

    // ✅ با برگشتن به مرحلهٔ قبل، ژئوکدینگ در راه باطل شود
    _cancelPendingGeocode();

    if (_currentStep == 0) {
      // صفحهٔ اصلی اپ: برگشت از مرحلهٔ مبدأ، باتم‌شیت اول (هوم) را نشان می‌دهد
      if (widget.startAtHome && !widget.isPickerOnly) {
        setState(() {
          _isHome = true;
          _isMapMoving = false;
        });
      } else {
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _currentStep--;
        if (_currentStep == 0) {
          _originLatLng = null;
          if (_originSymbol != null) {
            _mapController?.removeSymbol(_originSymbol!);
            _originSymbol = null;
          }
          _routePolylinePoints.clear();
          _mapController?.clearLines();
        } else if (_currentStep == 1) {
          _destinationLatLng = null;
          if (_destinationSymbol != null) {
            _mapController?.removeSymbol(_destinationSymbol!);
            _destinationSymbol = null;
          }
          _routePolylinePoints.clear();
          _mapController?.clearLines();
        }
      });
    }
  }

  void _showAdvancedProfile() {
    if (_hasNotification) {
      setState(() => _hasNotification = false);
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileAnimatedMenu(),
      ),
    );
  }

  /// نوار هشدار GPS برای مرحله‌هایی که SmartLocationSheet نمایش داده نمی‌شود
  Widget _buildGpsBanner() {
    final String text = _mapTr(context, 'gps_disruption');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.warningIcon,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.warningText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// پنل پایین حالت فقط‌انتخاب: آدرس نقطه‌ی وسط نقشه + دکمه‌ی تأیید
  Widget _buildPickerPanel() {
    final bool canConfirm = !_pickerLoading && _pickerAddress.isNotEmpty;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.cardBgLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.star_rounded,
                      color: AppColors.primaryBrand, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _pickerLoading || _pickerAddress.isEmpty
                          ? 'fetching_address'.tr()
                          : _pickerAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 51,
                child: ElevatedButton(
                  onPressed: canConfirm ? _confirmPickerLocation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    foregroundColor: AppColors.buttonText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _mapTr(context, 'confirm'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmPickerLocation() {
    final LatLng? target = _mapController?.cameraPosition?.target;
    if (target == null || _pickerAddress.isEmpty) return;

    HapticFeedback.mediumImpact();

    Navigator.pop<AddressModel>(
      context,
      AddressModel(
        placeName: _pickerAddress,
        humanReadableAddress: _pickerAddress,
        latitudePosition: target.latitude,
        longitudePosition: target.longitude,
      ),
    );
  }

  /// دکمهٔ گرد بالای نقشه (منو / برگشت / پروفایل) با ظاهر یکسان
  Widget _buildRoundTopButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardBgLight,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppInfo? appInfo;
    try {
      appInfo = Provider.of<AppInfo>(context, listen: true);
    } catch (_) {}

    String currentOrigin = appInfo?.pickUpLocation?.placeName ?? 'current_location_origin'.tr();
    String currentDestination = appInfo?.dropOffLocation?.placeName ?? 'select_destination_hint'.tr();

    Color activePinColor = _currentStep == 0 ? AppColors.originBlue : AppColors.primaryBrand;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    final bool isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    // حالت صفحهٔ اصلی: برگشت سیستم از مرحله‌ها به باتم‌شیت اول می‌رود
    final bool canPopRoute =
        widget.isPickerOnly || !widget.startAtHome || _isHome;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.cardBgLight,
        statusBarIconBrightness:
            AppColors.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            AppColors.isDark ? Brightness.dark : Brightness.light,
      ),
      child: PopScope(
        canPop: canPopRoute,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (!didPop) {
            _handleBackAction();
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          resizeToAvoidBottomInset: false,
          drawer: (!widget.isPickerOnly && isRtl) ? const SafirDrawer() : null,
          endDrawer: (!widget.isPickerOnly && !isRtl) ? const SafirDrawer() : null,
          // کشیدن لبهٔ صفحه با حرکت نقشه تداخل دارد؛ منو فقط با دکمه باز می‌شود
          drawerEnableOpenDragGesture: false,
          endDrawerEnableOpenDragGesture: false,
          body: Stack(
            children: [
              // 🗺️ ۱. نقشه تمام صفحه
              RepaintBoundary(
                child: Listener(
                  onPointerDown: (_) => _onMapPointerDown(),
                  onPointerUp: (_) => _onMapPointerReleased(),
                  onPointerCancel: (_) => _onMapPointerReleased(),
                  child: MapLibreMap(
                    // با عوض شدن تم، نقشه با استایل مناسب دوباره ساخته می‌شود
                    key: ValueKey('safir_map_${AppColors.isDark}'),
                    initialCameraPosition: _mapController?.cameraPosition ??
                        CameraPosition(
                          target: widget.targetLocation ??
                              widget.presetOrigin ??
                              _currentUserLatLng,
                          zoom: 15.0,
                        ),
                    styleString: AppColors.mapStyleAsset,
                    myLocationEnabled: _currentStep < 3,
                    // دنبال‌کردن خودکار GPS با درگ کاربر دعوا می‌کرد و نقشه می‌پرید؛
                    // دوربین فقط با GPS اولیه و دکمه‌ی موقعیت جابه‌جا می‌شود.
                    myLocationTrackingMode: MyLocationTrackingMode.none,
                    myLocationRenderMode: MyLocationRenderMode.normal,
                    trackCameraPosition: true,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _isProgrammaticMove = true;
                      if (widget.targetLocation != null) {
                        _animatedMapMove(widget.targetLocation!, 17.8);
                      }
                    },
                    onStyleLoadedCallback: () async {
                      // با هر بار لود استایل، همهٔ آیتم‌های قبلی نقشه پاک می‌شوند؛
                      // رفرنس‌های قدیمی باید null شوند تا از نو ساخته شوند.
                      _addedDriverIconIds.clear();
                      _driverIconImageIdLoaded = null;
                      _driverLiveSymbol = null;
                      _driverRouteLine = null;
                      _driverTraveledLine = null;
                      _driverTempLine = null;
                      _tempLineBusy = false;
                      _driverLastRenderedSegment = -1;
                      _driverLastRenderedPoint = null;

                      await initDriverSymbolLayer();

                      // ✅ مارکر مبدأ/مقصد و خط پیش‌نمایش را بعد از لود دوباره استایل برگردان
                      await _restoreTripMarkers();

                      // اگر سفر فعال بود، مسیر و آیکن دوباره رسم شوند
                      if (_driverTripPolylinePoints.length >= 2 &&
                          !_driverRouteStale) {
                        await _renderDriverRouteLines(
                          traveled: <LatLng>[],
                          remaining: _driverTripPolylinePoints,
                        );
                      }

                      if (_driverTripPolylinePoints.length >= 2 ||
                          _driverRouteStale) {
                        if (_latestDriverRaw != null) {
                          _pendingDriverRawPosition = _latestDriverRaw;
                          _pendingDriverRawHeading = _latestDriverHeading;
                          unawaited(_processPendingDriverUpdate());
                        }
                      }

                      // سفر آماده (تکرار/برگشت) را فقط یک بار اعمال کن
                      unawaited(_applyPresetTrip());
                    },
                    onCameraMove: (CameraPosition position) {
                      _onMapCameraMove();
                    },
                    onCameraIdle: () {
                      _handleMapIdle();
                    },
                    onMapClick: (_, __) {},
                  ),
                ),
              ),

              // 📍 ۲. پین شناور در وسط نقشه (در حالت هوم نیست)
              //
              // ✅ نوک پین دقیقاً روی مرکز نقشه است:
              //   ارتفاع پین = ۴۸ (دایره ۳۰ + میله ۱۸) و Column وسط‌چین است،
              //   پس برای اینکه «انتهای میله» روی مرکز بنشیند باید نصف ارتفاع
              //   (۲۴) به بالا برود. هنگام حرکت ۲۵ پیکسل بیشتر بالا می‌رود.
              //   (قبلاً مقدار ۲۰ بود و نوک پین ۴ پیکسل پایین‌تر از مرکز می‌ماند.)
              if (_currentStep < 2 && !_isHome)
                IgnorePointer(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: _isMapMoving ? 42 : 32,
                          height: _isMapMoving ? 42 : 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isMapMoving
                                ? Colors.black.withOpacity(0.08)
                                : Colors.black.withOpacity(0.15),
                          ),
                          child: Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.40),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          transform: Matrix4.translationValues(
                            0,
                            _isMapMoving
                                ? -(_pinTotalHeight / 2 + _pinLiftWhenMoving)
                                : -(_pinTotalHeight / 2),
                            0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: activePinColor,
                                  shape: _currentStep == 0 ? BoxShape.circle : BoxShape.rectangle,
                                  borderRadius: _currentStep == 0 ? null : BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: _currentStep == 0 ? BoxShape.circle : BoxShape.rectangle,
                                      borderRadius: _currentStep == 0 ? null : BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 2.0,
                                height: 18,
                                color: AppColors.textPrimary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 🔘 ۳. دکمه‌های شناور بالای صفحه
              Positioned(
                top: statusBarHeight + 8,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _isHome
                      ? [
                          // حالت هوم: عنوان + دکمهٔ منوی کناری (Drawer)
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.cardBgLight,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              'Safir',
                              style: TextStyle(
                                color: AppColors.primaryBrand,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _buildRoundTopButton(
                            onTap: _openMenu,
                            child: Icon(
                              Icons.menu_rounded,
                              color: AppColors.textPrimary,
                              size: 26,
                            ),
                          ),
                        ]
                      : [
                          _buildRoundTopButton(
                            onTap: _handleBackAction,
                            child: Icon(
                              _currentStep == 0
                                  ? (widget.isPickerOnly
                                      ? Icons.close_rounded
                                      : (widget.startAtHome
                                          ? Icons.arrow_back
                                          : Icons.home_outlined))
                                  : Icons.arrow_back,
                              color: AppColors.textPrimary,
                              size: 26,
                            ),
                          ),
                          if (!widget.isPickerOnly)
                            Expanded(
                              child: Center(
                                child: _showRideForToggle
                                    ? _buildRideForToggle()
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          if (!widget.isPickerOnly)
                            _buildRoundTopButton(
                              onTap: _showAdvancedProfile,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    color: AppColors.textPrimary,
                                    size: 26,
                                  ),
                                  if (_hasNotification)
                                    Positioned(
                                      top: 3,
                                      right: 3,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                ),
              ),

              // ⚠️ هشدار GPS در مرحله‌های بعد از انتخاب مبدأ/مقصد و در حالت هوم
              if (_hasGpsDisruption && (_currentStep >= 2 || _isHome))
                Positioned(
                  top: statusBarHeight + 68,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: Center(child: _buildGpsBanner()),
                  ),
                ),

              // 📄 ۵. باتم‌شیت‌ها بر اساس مراحل
              if (widget.isPickerOnly)
                _buildPickerPanel(),

              // 🏠 باتم‌شیت اول: انتخاب سرویس (هوم)
              if (!widget.isPickerOnly && _isHome)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: HomeServicesSheet(
                    selected: _homeSelected,
                    onServiceSelected: _selectService,
                    onSearchTap: () => _selectService(SafirService.taxi),
                  ),
                ),

              if (!widget.isPickerOnly &&
                  !_isHome &&
                  (_currentStep == 0 || _currentStep == 1))
                SmartLocationSheet(
                  currentStep: _currentStep,
                  currentAddress: currentOrigin,
                  currentDestination: currentDestination,
                  isMapIdle: !_isMapMoving,
                  isExpanded: _isSheetExpanded,
                  hasGpsDisruption: _hasGpsDisruption,
                  onExpandChanged: (expanded) {
                    setState(() => _isSheetExpanded = expanded);
                  },
                  onConfirmStep: () {
                    if (_currentStep == 0) {
                      _confirmOrigin();
                    } else {
                      _confirmDestination();
                    }
                  },
                  onSearchOriginTap: (addr) async {
                    final response = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const SearchDestinationPlace(updateDropOff: false),
                      ),
                    );
                    final AddressModel? picked = _pickedAddress(response);
                    if (picked == null || !mounted) return;
                    await _confirmOrigin(
                      at: LatLng(picked.latitudePosition!, picked.longitudePosition!),
                      name: picked.placeName,
                    );
                  },
                  onSearchDestinationTap: () async {
                    if (_serviceType == 'intercity') {
                      IntercitySheets.showCityPicker(
                        context: context,
                        targetCities: _intercityCities,
                        onCitySelected: (selectedCity) {
                          LatLng cityLatLng = LatLng(selectedCity['lat'], selectedCity['lng']);
                          _animatedMapMove(cityLatLng, 13.0);
                        },
                      );
                    } else {
                      final response = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const SearchDestinationPlace(updateDropOff: false),
                        ),
                      );
                      final AddressModel? picked = _pickedAddress(response);
                      if (picked == null || !mounted) return;
                      // مارکر مقصد، ذخیره در AppInfo و رسم مسیر همه اینجا انجام می‌شود
                      await _confirmDestination(
                        at: LatLng(picked.latitudePosition!, picked.longitudePosition!),
                        name: picked.placeName,
                      );
                    }
                  },
                  onGpsTap: _handleGpsTap,
                  onSavedAddressSelected: _handleSavedAddressTap,
                  onPickFavoriteOnMap: () => Navigator.push<AddressModel>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SafirMapScreen(
                        serviceType: _serviceType,
                        isPickerOnly: true,
                      ),
                    ),
                  ),
                ),

              if (_currentStep == 2)
                _serviceType == 'cargo'
                    ? CargoSheets.buildCargoSummarySheet(
                        context: context,
                        fareAmount: actualFareAmount,
                        distanceInKm: _tripDistanceInKm,
                        selectedVehicleType: _cargoSelectedVehicle,
                        onVehicleSelected: (vehicleId) {
                          setState(() {
                            _cargoSelectedVehicle = vehicleId;
                            // قیمت واقعی همزمان با قیمت نمایش‌داده‌شده هماهنگ می‌شود
                            actualFareAmount = CargoSheets.calculateFareForVehicle(
                              vehicleId,
                              _tripDistanceInKm,
                            );
                          });
                        },
                        paymentPayer: _cargoPaymentPayer,
                        onPayerChanged: (payer) {
                          setState(() => _cargoPaymentPayer = payer);
                        },
                        onRequestTrip: () => startTrip(),
                      )
                    : _serviceType == 'intercity'
                        ? IntercitySheets.buildStep2IntercitySheet(
                            context: context,
                            fareAmount: actualFareAmount,
                            distanceInKm: _tripDistanceInKm,
                            originAddress: currentOrigin,
                            destinationAddress: currentDestination,
                            travelDate: _intercityTravelDate,
                            passengerCount: _intercityPassengers,
                            // ✅ ویرایش مبدأ/مقصد: به مرحلهٔ قبل برمی‌گردد
                            onEditOrigin: () {
                              _handleBackAction();
                              _handleBackAction();
                            },
                            onEditDestination: _handleBackAction,
                            onDateSelected: (date) => setState(() {
                              _intercityTravelDate = date is DateTime ? date : null;
                            }),
                            onPassengersChanged: (count) => setState(() {
                              _intercityPassengers = count;
                              // کرایه با تعداد مسافر دوباره حساب می‌شود
                              if (_tripDistanceInKm > 0) {
                                actualFareAmount = _computeFare(_tripDistanceInKm);
                              }
                            }),
                            onRequestTrip: () => startTrip(),
                          )
                        : MapBottomSheets.buildStep2(
                            selectedCategory: _selectedCategory,
                            selectedVehicleType: _selectedVehicleType,
                            actualFareAmount: actualFareAmount,
                            distanceInKm: _tripDistanceInKm,
                            ecoFare: AppConfigService.instance.config
                                .taxiFare(_tripDistanceInKm),
                            vipFare: AppConfigService.instance.config
                                .vipFare(_tripDistanceInKm),
                            bikeFare: AppConfigService.instance.config
                                .bikeFare(_tripDistanceInKm),
                            safirColor: AppColors.primaryBrand,
                            hasActiveTripOptions: _hasActiveTripOptions,
                            isScheduled: _isScheduled,
                            hasPromoCode: _hasPromoCode,
                            onCategoryChanged: (cat) {
                              setState(() {
                                _selectedCategory = cat;
                                _selectedVehicleType = 0;
                                selectedVehicle = cat == 0 ? "Car" : "Bike";
                              });
                              _fetchRoute();
                            },
                            onVehicleSelected: (index, vType) {
                              setState(() {
                                _selectedVehicleType = index;
                                selectedVehicle = vType;
                              });
                              _fetchRoute();
                            },
                            onRequestTrip: () => startTrip(),
                            onTripOptionsTap: _openTripOptionsSheet,
                            onScheduleTap: _openScheduleSheet,
                            onPromoCodeTap: _openPromoCodeSheet,
                          ),

              if (_currentStep == 3) ...[
                MapBottomSheets.buildStep3(
                  safirColor: AppColors.primaryBrand,
                  originAddress: currentOrigin,
                  destinationAddress: currentDestination,
                  fareAmount: actualFareAmount,
                  onCancel: cancelTrip,
                ),
              ] else if (_currentStep == 4) ...[
                MapBottomSheets.buildStep4(
                  AppColors.primaryBrand,
                  tripId: tripRequestRef?.id ?? "",
                  nameDriver: nameDriver,
                  photoDriver: photoDriver,
                  phoneNumberDriver: phoneNumberDriver,
                  carDetailsDriver: carDetailsDriver,
                  carColorDriver: _driverCarColor,
                  plateProvinceDriver: _driverPlateProvince,
                  plateCategoryDriver: _driverPlateCategory,
                  plateFarsiNumDriver: _driverPlateFarsiNum,
                  plateNumDriver: _driverPlateNum,
                  isTempPlateDriver: _driverIsTempPlate,
                  tripFareAmount: actualFareAmount,
                  etaMinutes: _etaMinutes > 0 ? _etaMinutes : 5,
                  isOnTrip: _lastTripStatus == TripStatus.onTrip,
                  onCancelTrip: cancelTrip,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 نزدیک‌ترین نقطه روی مسیر (فقط «به جلو» از نقطهٔ پیشرفت).
  // جلوی پرش به سمت برگشتِ مسیر (مثلاً دور برگردان) را می‌گیرد.
  _SnapResult? _snapToPolylineDetailed(
    LatLng gpsPoint,
    List<LatLng> polyline, {
    int startIndex = 0,
    double maxAheadMeters = 150,
  }) {
    if (polyline.length < 2) return null;

    final int from = max(0, min(startIndex - 1, polyline.length - 2));

    double minDistance = double.infinity;
    LatLng closestPoint = polyline[from];
    int bestIndex = from;
    double travelled = 0;

    for (int i = from; i < polyline.length - 1; i++) {
      final LatLng a = polyline[i];
      final LatLng b = polyline[i + 1];

      final LatLng projected = _getClosestPointOnSegment(gpsPoint, a, b);

      final double distance = Geolocator.distanceBetween(
        gpsPoint.latitude,
        gpsPoint.longitude,
        projected.latitude,
        projected.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = projected;
        bestIndex = i;
      }

      travelled += Geolocator.distanceBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
      if (travelled > maxAheadMeters) break;
    }

    return _SnapResult(closestPoint, minDistance, bestIndex);
  }

  // 🔹 تصویرسازی نقطه روی پاره‌خط
  LatLng _getClosestPointOnSegment(LatLng p, LatLng a, LatLng b) {
    // طول جغرافیایی در عرض‌های بالا کوتاه‌تر است؛ برای فاصله‌ی درست مقیاس می‌شود
    final double k = cos(p.latitude * pi / 180);

    final double x = p.longitude * k, y = p.latitude;
    final double x1 = a.longitude * k, y1 = a.latitude;
    final double x2 = b.longitude * k, y2 = b.latitude;

    final double dx = x2 - x1;
    final double dy = y2 - y1;

    if (dx == 0 && dy == 0) return a;

    double t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0).toDouble();

    return LatLng(y1 + t * dy, (x1 + t * dx) / k);
  }

  // 🔹 محاسبه زاویه حرکت در امتداد مسیر خیابان
  double _calculateBearing(LatLng start, LatLng end) {
    double startLatRad = start.latitude * pi / 180;
    double startLngRad = start.longitude * pi / 180;
    double endLatRad = end.latitude * pi / 180;
    double endLngRad = end.longitude * pi / 180;

    double dLng = endLngRad - startLngRad;

    double y = sin(dLng) * cos(endLatRad);
    double x = cos(startLatRad) * sin(endLatRad) -
        sin(startLatRad) * cos(endLatRad) * cos(dLng);

    double bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }
}


/// باتم‌شیت گرفتن شمارهٔ نفر دیگر (برای سفر «برای دیگران»)
class _ForOtherSheet extends StatefulWidget {
  const _ForOtherSheet({
    required this.initialName,
    required this.initialPhone,
    required this.title,
    required this.description,
    required this.nameHint,
    required this.phoneHint,
    required this.invalidPhoneText,
    required this.confirmText,
    required this.cancelText,
  });

  final String initialName;
  final String initialPhone;
  final String title;
  final String description;
  final String nameHint;
  final String phoneHint;
  final String invalidPhoneText;
  final String confirmText;
  final String cancelText;

  @override
  State<_ForOtherSheet> createState() => _ForOtherSheetState();
}

class _ForOtherSheetState extends State<_ForOtherSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _cleanPhone =>
      _phoneController.text.replaceAll(RegExp(r'[\s\-()]'), '');

  bool get _isPhoneValid => RegExp(r'^\+?\d{9,15}$').hasMatch(_cleanPhone);

  void _submit() {
    if (!_isPhoneValid) {
      HapticFeedback.lightImpact();
      setState(() => _showError = true);
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.pop<Map<String, String>>(context, <String, String>{
      'name': _nameController.text.trim(),
      'phone': _cleanPhone,
    });
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.primaryBrand, size: 22),
      counterText: '',
      filled: true,
      fillColor: AppColors.backgroundLight,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primaryBrand, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBgLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.handle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(Icons.group_rounded,
                        color: AppColors.primaryBrand, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  maxLength: 40,
                  textInputAction: TextInputAction.next,
                  cursorColor: AppColors.primaryBrand,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration:
                      _decoration(widget.nameHint, Icons.person_outline_rounded),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  maxLength: 16,
                  keyboardType: TextInputType.phone,
                  textDirection: ui.TextDirection.ltr,
                  textInputAction: TextInputAction.done,
                  cursorColor: AppColors.primaryBrand,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
                  ],
                  onChanged: (_) {
                    if (_showError) setState(() => _showError = false);
                  },
                  onSubmitted: (_) => _submit(),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration:
                      _decoration(widget.phoneHint, Icons.phone_rounded),
                ),
                if (_showError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 4, left: 4),
                    child: Text(
                      widget.invalidPhoneText,
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.fieldBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            widget.cancelText,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryButton,
                            foregroundColor: AppColors.buttonText,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            widget.confirmText,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
