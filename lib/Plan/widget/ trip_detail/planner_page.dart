import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/TripPlanProvider.dart';
import '../../models/place.dart';
import 'unifiedPlaceCard.dart';
import 'new_plan_modal.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({Key? key}) : super(key: key);

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  @override
  void initState() {
    super.initState();
    // Provider의 상태 변경은 다음 프레임에서 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TripPlanProvider>(context, listen: false);
      final days = provider.days;
      final dayPlaces = provider.dayPlaces;

      if (dayPlaces.isEmpty && days.isNotEmpty) {
        print('날짜 정보 초기화 시작');
        Map<int, List<Place>> updatedDayPlaces = {};
        for (int i = 0; i < days.length; i++) {
          updatedDayPlaces[i + 1] = []; // 1일차부터 시작
        }
        provider.updateAllDayPlaces(updatedDayPlaces);
        print('날짜 정보 초기화 완료: ${updatedDayPlaces.length}일');
      }
    });
  }

  void _onReorder(int oldIndex, int newIndex, TripPlanProvider provider) {
    // 헤더 위치 계산 및 실제 아이템 인덱스 조정
    List<PlaceWithDay> allItems = _getAllPlacesWithDayHeaders(provider);

    // 범위 확인
    if (oldIndex < 0 ||
        oldIndex >= allItems.length ||
        newIndex < 0 ||
        newIndex > allItems.length) {
      print(
        '범위 오류: oldIndex=$oldIndex, newIndex=$newIndex, length=${allItems.length}',
      );
      return;
    }

    // 헤더인지 확인
    if (allItems[oldIndex].place == null) {
      print('날짜 헤더는 이동할 수 없습니다');
      return;
    }

    // Flutter의 ReorderableListView는 새 위치가 이전 위치보다 크면 1을 빼줌
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // 타겟 위치가 헤더인 경우, 그 다음 아이템으로 조정
    if (newIndex < allItems.length && allItems[newIndex].place == null) {
      newIndex++;

      // 조정된 위치가 범위를 벗어나면 마지막 위치로 설정
      if (newIndex >= allItems.length) {
        newIndex = allItems.length - 1;

        // 마지막이 헤더면 헤더 바로 앞으로
        if (allItems[newIndex].place == null) {
          newIndex--;
        }
      }
    }

    // 재조정된 위치가 여전히 범위를 벗어나면 작업 중단
    if (newIndex < 0 || newIndex >= allItems.length) {
      print('조정된 위치가 범위를 벗어남: newIndex=$newIndex');
      return;
    }

    // 원본 아이템 정보 저장
    PlaceWithDay movedItem = allItems[oldIndex];
    int oldDay = movedItem.day;
    int indexInOldDay = movedItem.indexInDay;
    Place place = movedItem.place!;

    // 이동될 위치의 Day 결정
    int newDay;
    int indexInNewDay;

    if (allItems[newIndex].place == null) {
      // 타겟이 헤더인 경우
      newDay = allItems[newIndex].day;
      indexInNewDay = 0; // 해당 날짜의 첫 번째 위치로
    } else {
      // 타겟이 일반 장소인 경우
      newDay = allItems[newIndex].day;
      indexInNewDay = allItems[newIndex].indexInDay;

      // 같은 날짜 내에서 뒤로 이동하는 경우, indexInNewDay 조정
      if (oldDay == newDay && indexInOldDay < indexInNewDay) {
        indexInNewDay++;
      }
    }

    // 새로운 dayPlaces 맵 생성 (깊은 복사)
    Map<int, List<Place>> updatedDayPlaces = {};
    provider.dayPlaces.forEach((key, value) {
      updatedDayPlaces[key] = List.from(value);
    });

    // 원래 날짜에서 아이템 제거
    if (updatedDayPlaces.containsKey(oldDay)) {
      List<Place> oldDayPlaces = List.from(updatedDayPlaces[oldDay] ?? []);
      if (indexInOldDay < oldDayPlaces.length) {
        oldDayPlaces.removeAt(indexInOldDay);
        updatedDayPlaces[oldDay] = oldDayPlaces;
      }
    }

    // 새 날짜에 아이템 추가
    if (!updatedDayPlaces.containsKey(newDay)) {
      updatedDayPlaces[newDay] = [];
    }

    List<Place> newDayPlaces = List.from(updatedDayPlaces[newDay] ?? []);

    // 새 날짜의 인덱스 범위 확인 및 조정
    if (indexInNewDay > newDayPlaces.length) {
      indexInNewDay = newDayPlaces.length;
    }

    // 이동한 place의 date 속성 업데이트 - 새 객체 생성
    Place updatedPlace = Place(
      name: place.name,
      description: place.description,
      imageUrl: place.imageUrl,
      category: place.category,
      date: '${newDay}일차',
    );

    newDayPlaces.insert(indexInNewDay, updatedPlace);
    updatedDayPlaces[newDay] = newDayPlaces;

    // 프로바이더에 업데이트된 맵 전달
    provider.updateAllDayPlaces(updatedDayPlaces);
  }

  // 모든 장소와 날짜 헤더를 포함한 리스트 생성
  List<PlaceWithDay> _getAllPlacesWithDayHeaders(TripPlanProvider provider) {
    List<PlaceWithDay> allItems = [];
    int globalIndex = 0;

    final Map<int, List<Place>> dayPlaces = provider.dayPlaces;
    final List<int> sortedDays = dayPlaces.keys.toList()..sort();

    for (int day in sortedDays) {
      // 날짜 헤더 추가
      allItems.add(
        PlaceWithDay(
          place: null, // null은 날짜 구분선을 의미
          day: day,
          indexInDay: -1,
          globalIndex: globalIndex++,
        ),
      );

      // 해당 날짜의 장소들 추가
      for (int i = 0; i < (dayPlaces[day] ?? []).length; i++) {
        allItems.add(
          PlaceWithDay(
            place: dayPlaces[day]![i],
            day: day,
            indexInDay: i,
            globalIndex: globalIndex++,
          ),
        );
      }
    }

    return allItems;
  }

  // PlannerPage.dart 수정
  void _addNewPlace(BuildContext context, int day, TripPlanProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => NewPlanModal(
            onPersonalMemoCreated: (place) {
              // place 객체를 provider에 추가
              provider.addPlace(place);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('장소가 추가되었습니다: ${place.name}')),
              );
            },
            selectedDay: day,
          ),
    );
  }

  void _addNewDay(TripPlanProvider provider) {
    final Map<int, List<Place>> dayPlaces = provider.dayPlaces;
    final int newDay =
        dayPlaces.keys.isEmpty
            ? 1
            : dayPlaces.keys.reduce((a, b) => a > b ? a : b) + 1;

    // 새 날짜에 대한 빈 목록 추가
    Map<int, List<Place>> updatedDayPlaces = Map.from(dayPlaces);
    updatedDayPlaces[newDay] = [];

    // 프로바이더에 업데이트된 맵 전달
    provider.updateAllDayPlaces(updatedDayPlaces);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripPlanProvider>(
      builder: (context, provider, child) {
        final Map<int, List<Place>> dayPlaces = provider.dayPlaces;
        final List<int> sortedDays = dayPlaces.keys.toList()..sort();
        final List<PlaceWithDay> allPlacesWithIndex =
            _getAllPlacesWithDayHeaders(provider);
        final days = provider.days;

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Stack(
            children: [
              sortedDays.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('등록된 일정이 없습니다.'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _addNewDay(provider),
                          child: const Text('새 날짜 추가하기'),
                        ),
                      ],
                    ),
                  )
                  : // ReorderableListView.builder 수정
                  ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: allPlacesWithIndex.length,
                    onReorder:
                        (oldIndex, newIndex) =>
                            _onReorder(oldIndex, newIndex, provider),
                    itemBuilder: (context, index) {
                      final PlaceWithDay placeWithDay =
                          allPlacesWithIndex[index];

                      // 날짜 구분선인 경우
                      if (placeWithDay.place == null) {
                        String dateLabel = 'Day ${placeWithDay.day}';
                        if (days.isNotEmpty &&
                            placeWithDay.day <= days.length) {
                          final DateTime date = days[placeWithDay.day - 1];
                          dateLabel = '$dateLabel (${date.month}/${date.day})';
                        }

                        // 여기서 key 확인
                        return _buildDayHeader(
                          context,
                          placeWithDay.day,
                          dayPlaces[placeWithDay.day]?.isEmpty ?? true,
                          provider,
                          dateLabel: dateLabel,
                          key: ValueKey('day_header_${placeWithDay.day}'),
                        );
                      }

                      // 일반 장소 카드
                      return ReorderableDragStartListener(
                        key: ValueKey(
                          'place_${placeWithDay.globalIndex}',
                        ), // 여기에 key 추가
                        index: index,
                        child: UnifiedPlaceCard(
                          key: ValueKey('place_${placeWithDay.globalIndex}'),
                          place: placeWithDay.place!,
                          onDelete:
                              () => provider.deletePlace(placeWithDay.place!),
                          index: index,
                        ),
                      );
                    },
                  ),

              // 새 날짜 추가 버튼 (일정 수정 기능이 필요한 경우에만 표시)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'add_day_btn',
                  onPressed: () => _addNewDay(provider),
                  child: const Icon(Icons.date_range),
                  tooltip: '새 날짜 추가',
                  backgroundColor: Colors.orange,
                ),
              ),

              // 새 장소 추가 버튼
              Positioned(
                bottom: 16,
                right: 86, // 날짜 추가 버튼 옆에 위치
                child: FloatingActionButton(
                  heroTag: 'add_place_btn',
                  onPressed:
                      sortedDays.isNotEmpty
                          ? () =>
                              _addNewPlace(context, sortedDays.first, provider)
                          : null,
                  child: const Icon(Icons.add_location),
                  tooltip: '새 장소 추가',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayHeader(
    BuildContext context,
    int day,
    bool isEmpty,
    TripPlanProvider provider, {
    required Key key,
    String? dateLabel,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  dateLabel ?? 'Day $day',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: () => _addNewPlace(context, day, provider),
                tooltip: 'Day $day에 장소 추가',
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(thickness: 2),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Day $day에 등록된 일정이 없습니다.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '구글 맵 연동 후 장소 추가 기능이 활성화될 예정입니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 장소와 날짜 정보를 함께 저장하는 클래스
class PlaceWithDay {
  final Place? place; // null이면 날짜 구분선
  final int day;
  final int indexInDay; // 해당 날짜 내에서의 인덱스
  final int globalIndex; // 전체 리스트에서의 인덱스

  PlaceWithDay({
    required this.place,
    required this.day,
    required this.indexInDay,
    required this.globalIndex,
  });
}
