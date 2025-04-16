class BookmarkLocation {
  final int locationId;
  final String category;
  final String name;
  final double longitude;
  final double latitude;
  final DateTime bookmarkedAt;

  BookmarkLocation({
    required this.locationId,
    required this.category,
    required this.name,
    required this.longitude,
    required this.latitude,
    required this.bookmarkedAt,
  });

  factory BookmarkLocation.fromMap(Map<String, dynamic> map) {
    return BookmarkLocation(
      locationId: map['location_id'],
      category: map['category'],
      name: map['name'],
      longitude: (map['longitude'] as num).toDouble(),
      latitude: (map['latitude'] as num).toDouble(),
      bookmarkedAt: DateTime.parse(map['bookmarked_at']),
    );
  }
}
