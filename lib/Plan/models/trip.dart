import 'package:flutter/material.dart';

class Trip {
  final String name;
  final DateTime start;
  final DateTime end;
  final List<DateTime> days;
  final int placesCount; // 임의로 추가된 장소 수 (나중에 실제 장소 목록으로 대체 가능)

  Trip({
    required this.name,
    required this.start,
    required this.end,
    required this.days,
    this.placesCount = 0,
  });

  // 정해진 기간의 날짜 생성
  static List<DateTime> generateDays(DateTime start, DateTime end) {
    return List<DateTime>.generate(
      end.difference(start).inDays + 1,
      (i) => start.add(Duration(days: i)),
    );
  }

  // Map으로부터 Trip 객체 생성
  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      name: map['name'],
      start: map['start'],
      end: map['end'],
      days: map['days'],
      placesCount: map['placesCount'] ?? map['days'].length * 3,
    );
  }
}