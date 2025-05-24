class BookmarkLocationData {
  final String placeId;
  final String videoId;
  final String category;
  final String placeName;
  final double longitude;
  final double latitude;
  final DateTime bookmarkedAt;


  BookmarkLocationData({
    required this.placeId,
    required this.videoId,
    required this.category,
    required this.placeName,
    required this.longitude,
    required this.latitude,
    required this.bookmarkedAt,
  });

  factory BookmarkLocationData.fromMap(Map<String, dynamic> map) {
    return BookmarkLocationData(
      placeId: map['place_id'],
      videoId: map['video_id'],
      category: map['category'],
      placeName: map['place_name'],
      longitude: (map['longitude'] as num).toDouble(),
      latitude: (map['latitude'] as num).toDouble(),
      bookmarkedAt: DateTime.parse(map['bookmarked_at']),
    );
  }
}
