import 'package:flutter/material.dart';

class SavedGridItem extends StatelessWidget {
  final int index;

  const SavedGridItem({
    Key? key,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[300],
      ),
      alignment: Alignment.center,
      child: Text('Saved $index'),
    );
  }
}