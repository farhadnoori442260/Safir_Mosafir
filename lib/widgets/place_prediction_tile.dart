import 'package:flutter/material.dart';
import '../models/predicted_places.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/theme/app_colors.dart';

class PlacePredictionTileDesign extends StatelessWidget {
  final PredictedPlaces? predictedPlaces;

  const PlacePredictionTileDesign({
    super.key,
    this.predictedPlaces,
  });

  @override
  Widget build(BuildContext context) {
    final String secondary = predictedPlaces?.secondaryText ?? "";

    return Directionality(
      textDirection: TextDirection.rtl, // راست‌چین کردن نمایش آدرس‌ها و آیکون
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // آیکون لوکیشن در دایرهٔ سبز ملایم
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: AppColors.primaryBrand,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان اصلی مکان
                  Text(
                    predictedPlaces?.mainText ??
                        getTranslation(context, "unknown_place"),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (secondary.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    // توضیحات یا آدرس فرعی مکان
                    Text(
                      secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
