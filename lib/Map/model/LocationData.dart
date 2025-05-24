import 'BookmarkLocationData.dart';

class MarkerLocationData {
  final String placeId;
  final String videoId;
  final String category;
  final String placeName;
  final double longitude;
  final double latitude;
  final DateTime? bookmarkedAt;

  MarkerLocationData({
    required this.placeId,
    required this.videoId,
    required this.category,
    required this.placeName,
    required this.longitude,
    required this.latitude,
    this.bookmarkedAt,
  });

  factory MarkerLocationData.fromBookmark(BookmarkLocationData bookmark) {
    return MarkerLocationData(
      placeId: bookmark.placeId,
      videoId: bookmark.videoId,
      category: bookmark.category,
      placeName: bookmark.placeName,
      longitude: bookmark.longitude,
      latitude: bookmark.latitude,
      bookmarkedAt: bookmark.bookmarkedAt,
    );
  }

  factory MarkerLocationData.fromMap(Map<String, dynamic> map) {
    return MarkerLocationData(
      placeId: map['place_id'],
      videoId: map['video_id'],
      category: map['category'],
      placeName: map['place_name'],
      longitude: (map['longitude'] as num).toDouble(),
      latitude: (map['latitude'] as num).toDouble(),
    );
  }
}