import 'package:flutter/material.dart';
import '../../models/place.dart';

class PlaceCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String imageUrl;
  final VoidCallback onDelete;
  final int index;

  const PlaceCard({
    Key? key,
    required this.title,
    this.subtitle = 'nice place~~',
    this.imageUrl = 'https://picsum.photos/100',
    required this.onDelete,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(title),
          subtitle: Text(subtitle ?? 'nice place~~'),
          trailing: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
        ),
      ),
    );
  }
}