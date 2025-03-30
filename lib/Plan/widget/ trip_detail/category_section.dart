import 'package:flutter/material.dart';

class CategorySection extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final List<Widget> items;
  final VoidCallback onAddItem;
  final Function(int oldIndex, int newIndex) onReorder;

  const CategorySection({
    Key? key,
    required this.title,
    required this.count,
    required this.icon,
    required this.items,
    required this.onAddItem,
    required this.onReorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(
                '$title · $count',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onAddItem,
                icon: const Icon(Icons.add),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.expand_more),
              ),
            ],
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            onReorder: onReorder,
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) => items[index],
          ),
        ],
      ),
    );
  }
}