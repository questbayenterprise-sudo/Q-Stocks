import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/Session/user_session.dart';
import '../../domain/entities/venue.dart';
import '../bloc/venue_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VenueCard extends StatelessWidget {
  final MyVenueEntity venue;
  final bool isGrid;
final String baseUrl = AppConfig.baseUrl;
  const VenueCard({
    super.key,
    required this.venue,
    this.isGrid = false,
  });
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
      imageWidget = _buildPlaceholder();
    } else if (path.startsWith('http')) {
      imageWidget = Image.network(
        path,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (path.contains('uploads')) {
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
    void _showDeleteConfirmation(BuildContext context) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Delete Turf?"),
          content: const Text("Are you sure you want to remove this venue?"),
          actions: [
            TextButton(
              onPressed: () {
                context.read<MyVenueBloc>().add(DeleteMyVenue(venue.id));
                Navigator.pop(ctx);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                context.read<MyVenueBloc>().add(DeleteMyVenue(venue.id));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Processing deletion..."),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/my-venue-detail', extra: venue),
      child: Card(
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
                      SizedBox(
                          height: isGrid ? 24 : 32,
                          width: isGrid ? 24 : 32,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.more_vert,
                              size: isGrid ? 20 : 24,
                              color: Colors.grey,
                            ),
                            onSelected: (val) {
                              if (val == 'edit') {
                                context.read<MyVenueBloc>().add(
                                  EditMyVenueRequested(venue.id),
                                );
                              } else if (val == 'delete') {
                                _showDeleteConfirmation(context);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text("Edit"),
                              ),
                              if (UserSession().userType == UserType.admin)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text("Delete"),
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
