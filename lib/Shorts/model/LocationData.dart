import 'dart:convert';

class LocationData {
  final String placeId;
  final String placeName;
  final String videoId;
  final String region;
  final String category;
  final Map<String, double> coordinates;
  final int bookmarkCount;
  final String address;
  final String naverMapLink;
  final String? description;     // optional
  final String? openTime;        // optional
  final String? closeTime;       // optional
  final double? rating;          // optional
  final double? averagePrice;    // optional
  final String? phoneNumber;     // optional
  final String? websiteLink;     // optional

  LocationData({
    required this.placeId,
    required this.placeName,
    required this.videoId,
    required this.region,
    required this.category,
    required this.coordinates,
    required this.bookmarkCount,
    required this.address,
    required this.naverMapLink,
    this.description,
    this.openTime,
    this.closeTime,
    this.rating,
    this.averagePrice,
    this.phoneNumber,
    this.websiteLink,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    // GeoJSON decode 로직 (원본 유지)
    Map<String, double>? coords;
    if (json['location'] != null && json['location'] is String) {
      final locationStr = json['location'] as String;
      final geoJson = jsonDecode(locationStr);
      if (geoJson is Map && geoJson.containsKey('coordinates')) {
        final coordinatesList = geoJson['coordinates'];
        if (coordinatesList is List && coordinatesList.length >= 2) {
          final lon = double.tryParse(coordinatesList[0].toString());
          final lat = double.tryParse(coordinatesList[1].toString());
          if (lon != null && lat != null) {
            coords = {'lat': lat, 'lon': lon};
          }
        }
      }
    }
    if (coords == null) {
      throw FormatException('Invalid or missing geojson coordinates');
    }

    return LocationData(
      placeId: json['place_id'] as String,
      placeName: json['place_name'] as String,
      videoId: json['video_id'] as String,
      region: json['region'] as String,
      category: json['category'] as String,
      coordinates: coords,
      bookmarkCount: json['bookmark_count'] as int,
      address: json['address'] as String,
      description: json['description'] as String?,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      averagePrice: (json['average_price'] as num?)?.toDouble(),
      phoneNumber: json['phone_number'] as String?,
      websiteLink: json['website_link'] as String?,
      naverMapLink: json['naver_map_link'] as String,  // JSON에서 새로 읽어옴
    );
  }
}
