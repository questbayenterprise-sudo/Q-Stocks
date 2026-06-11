import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/Session/user_session.dart';
import '../../data/likes_repository.dart';

class LikedVenuesPage extends StatefulWidget {
  const LikedVenuesPage({super.key});

  @override
  State<LikedVenuesPage> createState() => _LikedVenuesPageState();
}

class _LikedVenuesPageState extends State<LikedVenuesPage> {
  final LikesRepository _repo = LikesRepository();
  List<Map<String, dynamic>> _likedVenues = [];
  bool _isLoading = true;

  bool get _isAdminOrOwner =>
      UserSession().userType == UserType.admin ||
      UserSession().userType == UserType.owner ||
      UserSession().userType == UserType.vendor ||
      UserSession().userType == UserType.manager;

  String get _userType => UserSession().userType?.name ?? 'user';

  @override
  void initState() {
    super.initState();
    _loadLikedVenues();
  }

  Future<void> _loadLikedVenues() async {
    setState(() => _isLoading = true);
    final data = await _repo.getLikedVenues(
      UserSession().userId ?? '0',
      _userType,
    );
    if (mounted) {
      setState(() {
        _likedVenues = data != null
            ? data
                .where((e) => e != null)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : [];
        _isLoading = false;
      });
    }
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.contains('uploads')) {
      return "${AppConfig.baseUrl}/${path.replaceAll('\\', '/')}";
    }
    return path;
  }

  Future<void> _unlikeVenue(int venueId, int index) async {
    final userId = int.tryParse(UserSession().userId ?? '0') ?? 0;
    await _repo.toggleLike(userId, venueId);
    if (mounted) {
      setState(() => _likedVenues.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Venue removed from favorites"),
          backgroundColor: Color(0xFF00A36C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(
          _isAdminOrOwner ? "Venue Likes" : "My Favorites",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loadLikedVenues,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)))
          : _likedVenues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _isAdminOrOwner
                            ? "No likes yet"
                            : "No favorite venues yet",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isAdminOrOwner
                            ? "Likes from users will appear here"
                            : "Tap the heart icon on venues to save them",
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      if (!_isAdminOrOwner) ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/venues'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A36C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Browse Venues",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLikedVenues,
                  color: const Color(0xFF00A36C),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _likedVenues.length,
                    itemBuilder: (context, index) {
                      final venue = _likedVenues[index];
                      return _buildLikeCard(venue, index);
                    },
                  ),
                ),
    );
  }

  Widget _buildLikeCard(Map<String, dynamic> venue, int index) {
    final venueName = (venue['venue_name'] ?? '').toString();
    final location = (venue['location'] ?? '').toString();
    final userName = (venue['user_name'] ?? '').toString();
    final imageUrl = _resolveImageUrl((venue['venue_image'] ?? '').toString());
    final totalLikes = (venue['total_likes'] as num?)?.toInt() ?? 0;
    final price = (venue['price'] as num?)?.toDouble() ?? 0.0;
    final likedAt = (venue['liked_at'] ?? '').toString();
    final venueId = (venue['venue_id'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
          children: [
            // Venue image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 110,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venueName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (_isAdminOrOwner && userName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Liked by $userName",
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Like count
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite,
                                  size: 13, color: Colors.red.shade400),
                              const SizedBox(width: 4),
                              Text(
                                "$totalLikes",
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Price
                        Text(
                          "₹${price.toStringAsFixed(0)}/hr",
                          style: const TextStyle(
                            color: Color(0xFF00A36C),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        // Liked time
                        Text(
                          likedAt,
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Unlike button (only for user's own favorites)
            if (!_isAdminOrOwner)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () => _unlikeVenue(venueId, index),
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  tooltip: "Remove from favorites",
                ),
              ),
          ],
        ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 100,
      color: Colors.grey[200],
      child: Center(
        child:
            Icon(Icons.sports_soccer, size: 32, color: Colors.grey[400]),
      ),
    );
  }
}
