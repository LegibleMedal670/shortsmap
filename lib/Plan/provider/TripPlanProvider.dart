import 'package:flutter/material.dart';
import '../models/place.dart';

class TripPlanProvider extends ChangeNotifier {
  // 여행 기본 정보
  String _tripName = '';
  List<DateTime> _days = [];
  DateTimeRange? _dateRange;

  // 장소 데이터
  List<Place> _places = [];
  Map<int, List<Place>> _dayPlaces = {};

  // 생성자
  TripPlanProvider({
    required String tripName,
    required List<DateTime> days,
    List<Place>? initialPlaces,
  }) {
    _tripName = tripName;
    _days = List<DateTime>.from(days);

    if (_days.isNotEmpty) {
      _dateRange = DateTimeRange(start: _days.first, end: _days.last);
    }

    // 초기 장소 데이터 설정
    if (initialPlaces != null && initialPlaces.isNotEmpty) {
      _places = List<Place>.from(initialPlaces);
      _organizePlacesByDay();
    }
  }

  // Getter
  String get tripName => _tripName;
  List<DateTime> get days => _days;
  DateTimeRange? get dateRange => _dateRange;
  List<Place> get places => _places;
  Map<int, List<Place>> get dayPlaces => _dayPlaces;

  // 여행 이름 변경
  void updateTripName(String name) {
    _tripName = name;
    notifyListeners();
  }

  // 날짜 범위 변경
  void updateDateRange(DateTimeRange range) {
    _dateRange = range;

    // 시작일과 종료일 사이의 모든 날짜 생성
    List<DateTime> newDays = [];
    DateTime current = range.start;
    while (!current.isAfter(range.end)) {
      newDays.add(
        DateTime(current.year, current.month, current.day),
      ); // 시간 정보 제거
      current = current.add(const Duration(days: 1));
    }

    _days = newDays;

    // 날짜 수가 변경됐을 때 dayPlaces 업데이트
    Map<int, List<Place>> updatedDayPlaces = {};

    // 기존 날짜의 장소들 유지
    for (int i = 0; i < newDays.length && i < _dayPlaces.length; i++) {
      int dayNumber = i + 1;
      updatedDayPlaces[dayNumber] = _dayPlaces[dayNumber] ?? [];
    }

    // 새로 추가된 날짜에 대한 빈 배열 생성
    for (int i = _dayPlaces.length; i < newDays.length; i++) {
      updatedDayPlaces[i + 1] = [];
    }

    _dayPlaces = updatedDayPlaces;

    // places 목록 재구성
    _organizePlacesFromDayPlaces();

    notifyListeners();
  }

  // 장소 추가
  // TripPlanProvider.dart
  void addPlace(Place place) {
    _places.add(place);

    // 날짜 정보에서 몇 일차인지 추출
    if (place.date != null) {
      final regex = RegExp(r'(\d+)일차');
      final match = regex.firstMatch(place.date!);

      if (match != null) {
        int day = int.parse(match.group(1)!);

        if (_dayPlaces[day] == null) {
          _dayPlaces[day] = [];
        }
        _dayPlaces[day]!.add(place);
      }
    }

    notifyListeners();
  }

  // 새 장소 추가 (Google Maps 연동 전까지 비활성화됨)
  void addNewPlace(String category, int day) {
    // 구글 맵 연동 전까지 실제 장소 추가 기능은 비활성화
    // 모달만 표시하고 닫히는 기능은 남겨두기 위해 기능을 비워둠
    debugPrint('장소 추가 기능은 구글 맵 연동 후 활성화될 예정입니다.');
    debugPrint('카테고리: $category, 일차: $day');

    // 실제 장소 추가 코드는 주석 처리
    /*
    final String categoryDisplayName = _getCategoryDisplayName(category);
    
    // 새 장소 생성
    final newPlace = Place(
      name: 'New ${category.substring(0, 1).toUpperCase()}${category.substring(1)}',
      description: '새 $categoryDisplayName',
      imageUrl: 'https://via.placeholder.com/150',
      category: category,
      date: '${day}일차',
    );
    
    // 해당 날짜가 없으면 초기화
    if (_dayPlaces[day] == null) {
      _dayPlaces[day] = [];
    }
    
    // _dayPlaces에 추가할 복제본 생성
    final dayPlacesCopy = Place(
      name: newPlace.name,
      description: newPlace.description,
      imageUrl: newPlace.imageUrl,
      category: newPlace.category,
      date: newPlace.date,
    );
    
    // _places에 추가할 복제본 생성
    final placesCopy = Place(
      name: newPlace.name,
      description: newPlace.description,
      imageUrl: newPlace.imageUrl,
      category: newPlace.category,
      date: newPlace.date,
    );
    
    // 각각의 리스트에 별도의 객체로 추가
    _dayPlaces[day]!.add(dayPlacesCopy);
    _places.add(placesCopy);
    
    notifyListeners();
    */
  }

  // 장소 삭제
  void deletePlace(Place place) {
    // 전체 places 목록에서 삭제
    _places.remove(place);

    // 날짜별 목록에서도 삭제
    if (place.date != null) {
      final regex = RegExp(r'(\d+)일차');
      final match = regex.firstMatch(place.date!);

      if (match != null) {
        int day = int.parse(match.group(1)!);
        if (_dayPlaces.containsKey(day)) {
          _dayPlaces[day]!.remove(place);
        }
      }
    }

    notifyListeners();
  }

  // 특정 날짜의 장소 목록 업데이트 (재정렬 등)
  void updateDayPlaces(int day, List<Place> updatedPlaces) {
    // 깊은 복사를 통해 새로운 리스트 생성
    _dayPlaces[day] = List.from(updatedPlaces);

    // 각 장소 객체를 복제하여 참조 문제 방지
    for (int i = 0; i < _dayPlaces[day]!.length; i++) {
      Place oldPlace = _dayPlaces[day]![i];
      _dayPlaces[day]![i] = Place(
        name: oldPlace.name,
        description: oldPlace.description,
        imageUrl: oldPlace.imageUrl,
        category: oldPlace.category,
        date: oldPlace.date,
      );
    }

    _organizePlacesFromDayPlaces();
    notifyListeners();
  }

  // 모든 날짜의 장소 목록 업데이트 (PlannerPage에서 호출)
  void updateAllDayPlaces(Map<int, List<Place>> updatedDayPlaces) {
    // 깊은 복사를 통해 새로운 맵 생성
    Map<int, List<Place>> newDayPlaces = {};
    updatedDayPlaces.forEach((day, places) {
      newDayPlaces[day] = List.from(places);
    });

    _dayPlaces = newDayPlaces;
    _organizePlacesFromDayPlaces();
    notifyListeners();
  }

  // 카테고리 이름 한글화
  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'tourism':
        return '관광지';
      case 'restaurant':
        return '식당';
      case 'accommodation':
        return '숙소';
      case 'shopping':
        return '쇼핑';
      default:
        return '장소';
    }
  }

  // places 목록을 날짜별로 정리하는 함수
  void _organizePlacesByDay() {
    _dayPlaces = {};

    // 먼저 날짜별 빈 리스트 초기화
    for (int i = 0; i < _days.length; i++) {
      _dayPlaces[i + 1] = []; // 1일차부터 시작
    }

    // places에서 각 장소를 날짜별로 분류
    for (Place place in _places) {
      if (place.date != null) {
        // '1일차'와 같은 형식에서 숫자만 추출
        final regex = RegExp(r'(\d+)일차');
        final match = regex.firstMatch(place.date!);

        if (match != null) {
          int day = int.parse(match.group(1)!);

          if (_dayPlaces.containsKey(day)) {
            _dayPlaces[day]!.add(place);
          }
        }
      }
    }
  }

  // _dayPlaces에서 places 목록 재구성
  void _organizePlacesFromDayPlaces() {
    List<Place> newPlaces = [];
    _dayPlaces.forEach((day, dayPlaces) {
      // 각 날짜의 장소들을 순회하며 추가
      for (Place place in dayPlaces) {
        // 동일한 장소가 이미 존재하는지 확인 (이름과 날짜로 비교)
        bool exists = false;
        for (Place existingPlace in newPlaces) {
          if (existingPlace.name == place.name &&
              existingPlace.date == place.date &&
              existingPlace.category == place.category) {
            exists = true;
            break;
          }
        }

        if (!exists) {
          newPlaces.add(place);
        }
      }
    });

    _places = newPlaces;
  }

  // 특정 카테고리의 장소만 필터링해서 반환
  List<Place> getPlacesByCategory(String category, {int? day}) {
    if (day != null) {
      return _dayPlaces[day]
              ?.where((place) => place.category == category)
              .toList() ??
          [];
    }
    return _places.where((place) => place.category == category).toList();
  }
}
