import 'package:flutter/material.dart';

class MapPlaceholder extends StatelessWidget {
  final double height;
  final String text;

  const MapPlaceholder({
    Key? key,
    this.height = 200.0,
    this.text = '지도 Placeholder\n(Google Map)',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: Text(text),
    );
  }
}