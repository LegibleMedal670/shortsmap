class Place {
  final String name;
  final String description;
  final String imageUrl;
  final String category; // 'tourism', 'restaurant', 'accommodation' 등
  final String? date; // 날짜 정보 (선택적)

  Place({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.date,
  });
}
