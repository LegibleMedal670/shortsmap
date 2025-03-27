class Place {
  final String name;
  final String description;
  final String imageUrl;
  final String category; // 'tourism', 'restaurant', 'accommodation' 등
  final String? time;    // 타임라인 모드에서 사용 (선택적)

  Place({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.time,
  });
}