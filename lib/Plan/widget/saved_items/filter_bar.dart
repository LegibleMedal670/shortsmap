import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final String filterText;

  const FilterBar({
    Key? key,
    required this.filterText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.travel_explore_outlined,
            color: Colors.black,
            size: 26,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 8,
            ),
            color: Colors.transparent,
            child: Text(
              filterText,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}