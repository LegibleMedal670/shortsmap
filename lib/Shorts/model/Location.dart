class LocationData {
  final int locationId;
  final String name;
  final String? image;
  final String description;
  final String openTime;
  final String closeTime;
  final double rating;
  final int views;
  final double averagePrice;
  final String category;
  final bool verified;
  final DateTime uploadedTime;
  final String uploader;
  final String videoUrl;
  final String region;
  final Map<String, double>? coordinates; // {'lat': ..., 'lon': ...}

  LocationData({
    required this.locationId,
    required this.name,
    this.image,
    required this.description,
    required this.openTime,
    required this.closeTime,
    required this.rating,
    required this.views,
    required this.averagePrice,
    required this.category,
    required this.verified,
    required this.uploadedTime,
    required this.uploader,
    required this.videoUrl,
    required this.region,
    this.coordinates,
  });

  // JSON 데이터를 LocationTile 객체로 변환하는 팩토리 생성자
  factory LocationData.fromJson(Map<String, dynamic> json) {
    Map<String, double>? coords;
    // location 컬럼이 "POINT(lon lat)" 형식의 문자열로 들어온다고 가정
    if (json['location'] != null && json['location'] is String) {
      final locationStr = json['location'] as String;
      final regex = RegExp(r'POINT\(([-\d\.]+) ([-\d\.]+)\)');
      final match = regex.firstMatch(locationStr);
      if (match != null) {
        final lon = double.tryParse(match.group(1)!);
        final lat = double.tryParse(match.group(2)!);
        if (lon != null && lat != null) {
          coords = {'lat': lat, 'lon': lon};
        }
      }
    }

    return LocationData(
      locationId: json['location_id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
      description: json['description'] as String,
      openTime: json['open_time'] as String,
      closeTime: json['close_time'] as String,
      rating: (json['rating'] as num).toDouble(),
      views: json['views'] as int,
      averagePrice: (json['average_price'] as num).toDouble(),
      category: json['category'] as String,
      verified: json['verified'] as bool,
      uploadedTime: DateTime.parse(json['uploaded_time'] as String),
      uploader: json['uploader'] as String,
      videoUrl: json['video_url'] as String,
      region: json['region'] as String,
      coordinates: coords,
    );
  }
}
