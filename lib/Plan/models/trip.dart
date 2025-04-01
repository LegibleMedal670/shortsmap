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
  }) {
    // 생성자에서 days 검증
    if (days.isEmpty) {
      print('경고: Trip 생성자에 빈 days 리스트 전달됨');
    }
  }

  // 정해진 기간의 날짜 생성
  static List<DateTime> generateDays(DateTime start, DateTime end) {
    try {
      final List<DateTime> days = [];
      
      // 날짜 유효성 검사
      if (end.isBefore(start)) {
        print('오류: 종료일(${end})이 시작일(${start})보다 이전입니다. 날짜를 교체합니다.');
        final temp = start;
        start = end;
        end = temp;
      }
      
      int daysCount = end.difference(start).inDays + 1;
      
      // 디버그 출력
      print('Generating $daysCount days from $start to $end');
      
      if (daysCount <= 0) {
        print('오류: 계산된 일수가 0 이하입니다. 기본값으로 1일 설정.');
        daysCount = 1;
      }
      
      for (int i = 0; i < daysCount; i++) {
        final newDate = start.add(Duration(days: i));
        days.add(newDate);
        print('날짜 생성: $newDate');
      }
      
      // 디버그 출력 
      print('생성된 총 날짜 수: ${days.length}');
      
      // 빈 리스트 검증
      if (days.isEmpty) {
        print('경고: 생성된 날짜 리스트가 비어 있습니다. 시작일 추가!');
        days.add(start);
      }
      
      return days;
    } catch (e) {
      print('날짜 생성 중 오류 발생: $e');
      // 오류 발생 시 최소한 하루라도 반환
      return [start];
    }
  }

  // Map으로부터 Trip 객체 생성
  factory Trip.fromMap(Map<String, dynamic> map) {
    try {
      // 날짜 데이터 유효성 검사
      List<DateTime> daysList;
      if (map['days'] == null || (map['days'] is List && (map['days'] as List).isEmpty)) {
        print('경고: map에서 days 데이터가 없거나 비어 있습니다. 시작일과 종료일로 생성합니다.');
        daysList = generateDays(map['start'], map['end']);
      } else {
        daysList = map['days'];
      }
      
      return Trip(
        name: map['name'] ?? '이름 없는 여행',
        start: map['start'],
        end: map['end'],
        days: daysList,
        placesCount: map['placesCount'] ?? daysList.length * 3,
      );
    } catch (e) {
      print('Trip.fromMap 오류: $e');
      final now = DateTime.now();
      return Trip(
        name: map['name'] ?? '이름 없는 여행',
        start: now,
        end: now,
        days: [now],
        placesCount: 0,
      );
    }
  }
}