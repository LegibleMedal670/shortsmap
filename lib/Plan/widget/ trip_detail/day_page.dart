import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/TripPlanProvider.dart';
import 'unifiedPlaceCard.dart';
import 'map_placeholder.dart';
import '../../models/place.dart';
import 'new_plan_modal.dart';

class DayPage extends StatelessWidget {
  final int dayIndex; // 몇 일차인지 (0부터 시작)
  final int dayNumber; // 표시될 일차 (1일차부터 시작)

  const DayPage({Key? key, required this.dayIndex, required this.dayNumber})
    : super(key: key);

  // DayPage.dart 수정
  void _showAddPlaceDialog(BuildContext context, TripPlanProvider provider) {
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
            selectedDay: dayNumber,
          ),
    );
  }

  // 장소 재정렬 처리
  void _handleReorder(int oldIndex, int newIndex, TripPlanProvider provider) {
    final dayPlaces = provider.dayPlaces[dayNumber] ?? [];

    if (oldIndex < dayPlaces.length && newIndex <= dayPlaces.length) {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final item = dayPlaces[oldIndex];

      // 깊은 복사를 통해 현재 날짜의 장소 리스트 복제
      List<Place> updatedPlaces = List.from(dayPlaces);

      // 아이템 위치 변경
      updatedPlaces.removeAt(oldIndex);
      updatedPlaces.insert(newIndex, item);

      // 프로바이더에 업데이트된 목록 전달
      provider.updateDayPlaces(dayNumber, updatedPlaces);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripPlanProvider>(
      builder: (context, provider, child) {
        final date =
            dayIndex < provider.days.length
                ? provider.days[dayIndex]
                : DateTime.now();

        // 날짜 포맷팅 (예: 2024년 4월 1일)
        final dateStr = "${date.year}년 ${date.month}월 ${date.day}일";

        final dayPlaces = provider.dayPlaces[dayNumber] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 표시
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
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
                      '${dayNumber}일차 - $dateStr',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 지도 플레이스홀더
            const MapPlaceholder(),

            // 일정 목록 제목
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.schedule),
                  const SizedBox(width: 8),
                  Text(
                    '일정 (${dayPlaces.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 일정 목록
            Expanded(
              child:
                  dayPlaces.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${dayNumber}일차에 등록된 일정이 없습니다.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '구글 맵 연동 후 장소 추가 기능이 활성화될 예정입니다.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                      : // DayPage의 ReorderableListView 수정
                      ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: dayPlaces.length,
                        onReorder:
                            (oldIndex, newIndex) =>
                                _handleReorder(oldIndex, newIndex, provider),
                        itemBuilder: (context, index) {
                          return ReorderableDragStartListener(
                            key: ValueKey(
                              'place_day${dayNumber}_${index}',
                            ), // 여기에 key 추가
                            index: index,
                            child: UnifiedPlaceCard(
                              key: ValueKey('place_day${dayNumber}_${index}'),
                              place: dayPlaces[index],
                              index: index,
                              onDelete: () {
                                provider.deletePlace(dayPlaces[index]);
                              },
                            ),
                          );
                        },
                      ),
            ),

            // 새 장소 추가 버튼
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_location),
                label: const Text('새 장소 추가하기'),
                onPressed: () => _showAddPlaceDialog(context, provider),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
