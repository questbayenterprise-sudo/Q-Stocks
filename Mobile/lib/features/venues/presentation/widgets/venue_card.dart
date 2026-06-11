import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/venue.dart';

class VenueCard extends StatelessWidget {
  final VenueEntity venue;
  final bool isGrid; // Added to distinguish layout
final String baseUrl = AppConfig.baseUrl;
  const VenueCard({
    super.key,
    required this.venue,
    this.isGrid = false, // Default to false for backward compatibility
  });
  // Helper to build the default placeholder from assets
  Widget _buildPlaceholder() {
    return Image.asset(
      'assets/images/no-turf-image.png',
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    String path = venue.imageUrl;
    Widget imageWidget;

    if (path.isEmpty) {
      // Case 1: No image path provided at all
      imageWidget = _buildPlaceholder();
    } else if (path.startsWith('http')) {
      // Case 2: Full URL
      imageWidget = Image.network(
        path,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (path.contains('uploads')) {
      // Case 3: Go Backend path (uploads\venues\...)
      String cleanPath = path.replaceAll('\\', '/');
          String fullUrl = "$baseUrl/$cleanPath";

      imageWidget = Image.network(
        fullUrl,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      // Case 4: Local path (from Image Picker on AddVenuePage)
      File file = File(path);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } else {
        imageWidget = _buildPlaceholder();
      }
    }

    final double imageHeight = isGrid ? 140 : 180;
    final double titleSize = isGrid ? 14 : 18;
    final double subTitleSize = isGrid ? 12 : 14;
    final double cardPadding = isGrid ? 10 : 16;
    return GestureDetector(
      onTap: () => context.push('/venue-detail', extra: venue),
      child: Card(
        // List uses 16px bottom margin as per existing design
        margin: EdgeInsets.only(bottom: isGrid ? 0 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: imageWidget,
            ),
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: titleSize,
                            color: null,
                          ),
                        ),
                      ),
                      // Text(
                      //   "₹${venue.price.toInt()}",
                      //   style: TextStyle(
                      //     color: const Color(0xFF00A36C),
                      //     fontWeight: FontWeight.bold,
                      //     fontSize: titleSize,
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          venue.locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: subTitleSize,
                          ),
                        ),
                      ),
                      if (venue.distance > 0 && venue.distance < 9999)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A36C).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.near_me, size: 12, color: const Color(0xFF00A36C)),
                              const SizedBox(width: 3),
                              Text(
                                venue.distance < 1
                                    ? "${(venue.distance * 1000).toStringAsFixed(0)} m"
                                    : "${venue.distance.toStringAsFixed(1)} km",
                                style: TextStyle(
                                  color: const Color(0xFF00A36C),
                                  fontSize: isGrid ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
