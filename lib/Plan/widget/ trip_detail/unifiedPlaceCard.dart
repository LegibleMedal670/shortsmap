import 'package:flutter/material.dart';
import '../../models/place.dart';

class UnifiedPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onDelete;
  final int? index; // 드래그 앤 드롭에 사용

  const UnifiedPlaceCard({
    Key? key,
    required this.place,
    required this.onDelete,
    this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  place.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 24),
                    );
                  },
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  place.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 정보 (있을 경우만)
                  if (place.date != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            place.date!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    place.description,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 카테고리 표시
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(place.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      place.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 드래그 핸들과 삭제 버튼
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index != null)
                        ReorderableDragStartListener(
                          index: index!,
                          child: const Icon(Icons.drag_handle, color: Colors.grey),
                        ),
                      if (index != null) const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tourism':
        return Colors.blue;
      case 'restaurant':
        return Colors.orange;
      case 'accommodation':
        return Colors.green;
      case 'shopping':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}