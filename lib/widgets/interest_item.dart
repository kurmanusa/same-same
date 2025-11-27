import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme_proposal.dart';

class InterestItem extends StatefulWidget {
  final String label;
  final int? year;
  final String? thumbnailPath; // Path in Supabase Storage
  final int? currentValue; // -1 = dislike, 1 = like, null = not rated
  final Function(int?) onLike; // null = remove rating
  final Function(int?) onDislike; // null = remove rating

  const InterestItem({
    Key? key,
    required this.label,
    this.year,
    this.thumbnailPath,
    this.currentValue,
    required this.onLike,
    required this.onDislike,
  }) : super(key: key);

  @override
  State<InterestItem> createState() => _InterestItemState();
}

class _InterestItemState extends State<InterestItem> {
  String? _cachedImageUrl;
  static final _cacheManager = CacheManager(
    Config(
      'interestImagesCache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 1000,
    ),
  );

  @override
  void initState() {
    super.initState();
    _cacheImageUrl();
  }

  @override
  void didUpdateWidget(InterestItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnailPath != widget.thumbnailPath) {
      _cacheImageUrl();
    }
  }

  void _cacheImageUrl() {
    if (widget.thumbnailPath != null && widget.thumbnailPath!.isNotEmpty) {
      final client = SupabaseService.client;
      final url = client.storage
          .from('interest-icons')
          .getPublicUrl(widget.thumbnailPath!);
      // Store URL in state to ensure it doesn't change on rebuild
      if (_cachedImageUrl != url) {
        setState(() {
          _cachedImageUrl = url;
        });
      } else {
        _cachedImageUrl = url;
      }
    } else {
      _cachedImageUrl = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = _buildSubtitle();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: _buildThumbnail(),
      title: Text(
        widget.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: subtitleText != null && subtitleText.isNotEmpty
          ? Text(
              subtitleText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dislike button (thumbs down)
          _buildRatingButton(
            icon: Icons.thumb_down,
            isActive: widget.currentValue == -1,
            onPressed: () {
              // If already disliked, remove rating. Otherwise, set dislike
              widget.onDislike(widget.currentValue == -1 ? null : -1);
            },
            activeColor: AppThemeProposal.accentDislike,
          ),
          const SizedBox(width: 8),
          // Like button (thumbs up)
          _buildRatingButton(
            icon: Icons.thumb_up,
            isActive: widget.currentValue == 1,
            onPressed: () {
              // If already liked, remove rating. Otherwise, set like
              widget.onLike(widget.currentValue == 1 ? null : 1);
            },
            activeColor: AppThemeProposal.accentLike,
          ),
        ],
      ),
    );
  }

  String? _buildSubtitle() {
    final year = widget.year;
    if (year == null) {
      return null;
    }
    return '$year';
  }

  Widget _buildThumbnail() {
    final path = widget.thumbnailPath;
    if (path == null || path.isEmpty || _cachedImageUrl == null) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.movie, size: 24),
      );
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          key: ValueKey('img_$path'), // Stable key based on path only
          imageUrl: _cachedImageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          cacheManager: _cacheManager, // Use custom cache manager
          // Optimize cache: store only 50x50 images (2x for retina = 100x100)
          maxWidthDiskCache: 100,
          maxHeightDiskCache: 100,
          memCacheWidth: 100,
          memCacheHeight: 100,
          // Use path as cache key (stable identifier)
          cacheKey: path,
          // Keep old image while loading new one (prevents blank on rebuild)
          useOldImageOnUrlChange: true,
          // Minimal fade for better UX
          fadeInDuration: const Duration(milliseconds: 100),
          fadeOutDuration: Duration.zero,
          // Show placeholder only if image is not in cache
          placeholderFadeInDuration: const Duration(milliseconds: 150),
          placeholder: (context, url) => Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.movie, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required Color activeColor,
  }) {
    final inactiveColor = AppThemeProposal.surfaceVariant;
    final inactiveBorder = AppThemeProposal.border;
    final inactiveIconColor = const Color.fromARGB(255, 168, 168, 168); // Более светлый серый для неактивных кнопок
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? activeColor : inactiveBorder,
              width: 2,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: activeColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : inactiveIconColor,
            size: 24,
          ),
        ),
      ),
    );
  }

}

