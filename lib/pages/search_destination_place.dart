import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:safir_passengers/appInfo/app_info.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/models/address_models.dart';
import 'package:safir_passengers/models/predicted_places.dart';
import 'package:safir_passengers/widgets/place_prediction_tile.dart';

class SearchDestinationPlace extends StatefulWidget {
  /// اگر false باشد، انتخاب کاربر در مقصد سفر ذخیره نمی‌شود
  /// و فقط به‌عنوان نتیجه به صفحهٔ قبلی برمی‌گردد.
  final bool updateDropOff;

  const SearchDestinationPlace({
    super.key,
    this.updateDropOff = true,
  });

  @override
  State<SearchDestinationPlace> createState() =>
      _SearchDestinationPlaceState();
}

class _SearchDestinationPlaceState
    extends State<SearchDestinationPlace> {
  List<PredictedPlaces> placesPredictedList = [];
  bool isLoading = false;

  Timer? _searchDebounce;
  http.Client? _activeClient;

  final TextEditingController pickupTextEditingController =
      TextEditingController();

  final TextEditingController destinationTextEditingController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    final pickUpLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;

    if (pickUpLocation != null) {
      pickupTextEditingController.text =
          pickUpLocation.placeName ?? '';
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _activeClient?.close();
    pickupTextEditingController.dispose();
    destinationTextEditingController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged(String inputText) {
    _searchDebounce?.cancel();

    if (inputText.trim().length <= 1) {
      if (mounted) {
        setState(() {
          placesPredictedList = [];
          isLoading = false;
        });
      }

      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () {
        findPlaceAutoCompleteSearch(inputText);
      },
    );
  }

  Future<void> findPlaceAutoCompleteSearch(
    String inputText,
  ) async {
    if (!mounted) return;

    _activeClient?.close();
    _activeClient = http.Client();

    setState(() {
      isLoading = true;
    });

    try {
      final appInfo =
          Provider.of<AppInfo>(context, listen: false);

      final userLat = appInfo.pickUpLocation?.latitudePosition;
      final userLng = appInfo.pickUpLocation?.longitudePosition;
      final queryText = inputText.trim();

      String locationBiasParams = '';

      if (userLat != null && userLng != null) {
        const double delta = 0.5;

        final double left = userLng - delta;
        final double bottom = userLat - delta;
        final double right = userLng + delta;
        final double top = userLat + delta;

        locationBiasParams =
            '&viewbox=$left,$top,$right,$bottom'
            '&lat=$userLat'
            '&lon=$userLng';
      }

      final Uri url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'format=json'
        '&q=${Uri.encodeComponent(queryText)}'
        '$locationBiasParams'
        '&countrycodes=af'
        '&addressdetails=1'
        '&limit=20'
        '&accept-language=fa,ps,en',
      );

      final http.Response response = await _activeClient!
          .get(
            url,
            headers: const <String, String>{
              'User-Agent':
                  'SafirPassengerApp/1.0 (contact@safirapp.com)',
              'Accept-Language': 'fa,ps,en',
            },
          )
          .timeout(const Duration(seconds: 7));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> responseData =
            json.decode(response.body) as List<dynamic>;

        final List<PredictedPlaces> tempPlaces = responseData
            .map<PredictedPlaces>(
              (dynamic data) => PredictedPlaces.fromJson(data),
            )
            .toList();

        setState(() {
          placesPredictedList = tempPlaces;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in place autocomplete search: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onPlaceSelected(PredictedPlaces place) {
    HapticFeedback.lightImpact();

    if (place.lat == null || place.lng == null) {
      return;
    }

    final AddressModel selectedDestination = AddressModel(
      placeName: place.mainText ?? place.secondaryText,
      humanReadableAddress:
          place.secondaryText ?? place.mainText,
      latitudePosition: place.lat,
      longitudePosition: place.lng,
    );

    if (widget.updateDropOff) {
      Provider.of<AppInfo>(context, listen: false)
          .updateDropOffLocation(selectedDestination);
    }

    Navigator.pop(
      context,
      <String, dynamic>{
        'result': 'placeSelected',
        'address': selectedDestination,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDestinationText =
        destinationTextEditingController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
        title: Text(
          getTranslation(
            context,
            'search_address_and_destination_title',
          ),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: pickupTextEditingController,
                          readOnly: true,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: getTranslation(
                              context,
                              'pickup_location_hint',
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller:
                              destinationTextEditingController,
                          autofocus: true,
                          onChanged: (String value) {
                            setState(() {});
                            _onSearchTextChanged(value);
                          },
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: getTranslation(
                              context,
                              'where_to_destination_hint',
                            ),
                            border: InputBorder.none,
                            suffixIcon: hasDestinationText
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      destinationTextEditingController
                                          .clear();

                                      _onSearchTextChanged('');

                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF169365),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isLoading)
            const LinearProgressIndicator(
              color: Color(0xFF169365),
              backgroundColor: Color(0xFFE5E7EB),
            ),
          const SizedBox(height: 5),
          Expanded(
            child: placesPredictedList.isNotEmpty
                ? ListView.separated(
                    itemCount: placesPredictedList.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (
                      BuildContext context,
                      int index,
                    ) {
                      return InkWell(
                        onTap: () {
                          _onPlaceSelected(
                            placesPredictedList[index],
                          );
                        },
                        child: PlacePredictionTileDesign(
                          predictedPlaces:
                              placesPredictedList[index],
                        ),
                      );
                    },
                    separatorBuilder: (
                      BuildContext context,
                      int index,
                    ) {
                      return const Divider(
                        height: 1,
                        color: Colors.black12,
                        thickness: 0.5,
                      );
                    },
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            destinationTextEditingController
                                    .text.isEmpty
                                ? getTranslation(
                                    context,
                                    'search_address_empty_prompt',
                                  )
                                : getTranslation(
                                    context,
                                    'search_address_no_results',
                                  ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
