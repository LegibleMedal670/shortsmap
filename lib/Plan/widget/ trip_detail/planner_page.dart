import 'package:flutter/material.dart';
import '../../models/place.dart';
import 'unifiedPlaceCard.dart';

class PlannerPage extends StatefulWidget {
  final Function(Place)? onAddPlace;
  
  const PlannerPage({
    Key? key,
    this.onAddPlace,
  }) : super(key: key);

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  // 여행 일자별 장소 목록 (일자별로 분리)
  final Map<int, List<Place>> _dayPlaces = {
    1: [ // 1일차
      Place(
        name: '롯데타워',
        description: '서울의 랜드마크',
        imageUrl: 'https://example.com/lotte.jpg',
        category: 'tourism',
        time: '09:00',
      ),
      Place(
        name: '남산타워',
        description: '서울의 전망대',
        imageUrl: 'https://example.com/namsan.jpg',
        category: 'tourism',
        time: '13:00',
      ),
    ],
    2: [ // 2일차
      Place(
        name: '경복궁',
        description: '조선시대 왕궁',
        imageUrl: 'https://example.com/palace.jpg',
        category: 'tourism',
        time: '10:00',
      ),
      Place(
        name: '인사동',
        description: '전통 문화의 거리',
        imageUrl: 'https://example.com/insadong.jpg',
        category: 'tourism',
        time: '14:00',
      ),
    ],
  };

  void _onReorder(int oldIndex, int newIndex) {
    // 헤더 위치 계산 및 실제 아이템 인덱스 조정
    List<PlaceWithDay> allItems = _getAllPlacesWithDayHeaders();
    
    // 범위 확인
    if (oldIndex < 0 || oldIndex >= allItems.length || 
        newIndex < 0 || newIndex > allItems.length) {
      print('범위 오류: oldIndex=$oldIndex, newIndex=$newIndex, length=${allItems.length}');
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
    
    setState(() {
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
      
      // 원래 날짜에서 아이템 제거
      _dayPlaces[oldDay]!.removeAt(indexInOldDay);
      
      // 새 날짜에 아이템 추가
      if (_dayPlaces[newDay] == null) {
        _dayPlaces[newDay] = [];
      }
      
      // 새 날짜의 인덱스 범위 확인 및 조정
      if (indexInNewDay > _dayPlaces[newDay]!.length) {
        indexInNewDay = _dayPlaces[newDay]!.length;
      }
      
      _dayPlaces[newDay]!.insert(indexInNewDay, place);
      
      // 각 날짜의 시간 순서 재정렬
      _updateTimesForDay(oldDay);
      if (oldDay != newDay) {
        _updateTimesForDay(newDay);
      }
    });
  }

  // 모든 장소와 날짜 헤더를 포함한 리스트 생성
  List<PlaceWithDay> _getAllPlacesWithDayHeaders() {
    List<PlaceWithDay> allItems = [];
    int globalIndex = 0;
    
    final List<int> sortedDays = _dayPlaces.keys.toList()..sort();
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
      for (int i = 0; i < (_dayPlaces[day] ?? []).length; i++) {
        allItems.add(
          PlaceWithDay(
            place: _dayPlaces[day]![i],
            day: day,
            indexInDay: i,
            globalIndex: globalIndex++,
          ),
        );
      }
    }
    
    return allItems;
  }

  void _updateTimesForDay(int day) {
    if (_dayPlaces[day] == null || _dayPlaces[day]!.isEmpty) return;
    
    // 간단한 예시: 09:00부터 1시간 간격으로 시간 재설정
    final List<Place> dayPlaces = _dayPlaces[day]!;
    for (int i = 0; i < dayPlaces.length; i++) {
      final int hour = 9 + i;
      final String formattedHour = hour.toString().padLeft(2, '0');
      final Place oldPlace = dayPlaces[i];
      
      // 새 Place 인스턴스를 생성하여 시간 업데이트
      dayPlaces[i] = Place(
        name: oldPlace.name,
        description: oldPlace.description,
        imageUrl: oldPlace.imageUrl,
        category: oldPlace.category,
        time: '$formattedHour:00',
      );
    }
  }

  void _removePlace(int day, int placeIndex) {
    setState(() {
      _dayPlaces[day]!.removeAt(placeIndex);
      _updateTimesForDay(day);
    });
  }

  void _addNewPlace(int day) {
    // 새로운 장소 추가 대화상자 표시
    showDialog(
      context: context,
      builder: (context) => _AddPlaceDialog(
        onAdd: (Place newPlace) {
          setState(() {
            _dayPlaces[day] ??= [];
            _dayPlaces[day]!.add(newPlace);
            _updateTimesForDay(day);
          });
        },
      ),
    );
  }

  void _addNewDay() {
    setState(() {
      final int newDay = _dayPlaces.keys.isEmpty ? 1 : _dayPlaces.keys.reduce((a, b) => a > b ? a : b) + 1;
      _dayPlaces[newDay] = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<int> sortedDays = _dayPlaces.keys.toList()..sort();
    final List<PlaceWithDay> allPlacesWithIndex = _getAllPlacesWithDayHeaders();
    
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
                        onPressed: _addNewDay,
                        child: const Text('새 날짜 추가하기'),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: allPlacesWithIndex.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final PlaceWithDay placeWithDay = allPlacesWithIndex[index];
                    
                    // 날짜 구분선인 경우
                    if (placeWithDay.place == null) {
                      return _buildDayHeader(
                        placeWithDay.day, 
                        _dayPlaces[placeWithDay.day]?.isEmpty ?? true,
                        key: ValueKey('day_header_${placeWithDay.day}'),
                      );
                    }
                    
                    // 일반 장소 카드
                    return UnifiedPlaceCard(
                      key: ValueKey('place_${placeWithDay.globalIndex}'),
                      place: placeWithDay.place!,
                      onDelete: () => _removePlace(placeWithDay.day, placeWithDay.indexInDay),
                      index: index,  // ReorderableDragStartListener에 전달할 인덱스
                    );
                  },
                ),
          
          // 새 날짜 추가 버튼
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'add_day_btn',
              onPressed: _addNewDay,
              child: const Icon(Icons.date_range),
              tooltip: '새 날짜 추가',
              backgroundColor: Colors.orange,
            ),
          ),
          
          // 새 장소 추가 버튼
          Positioned(
            bottom: 16,
            right: 86, // 첫 번째 버튼 옆에 배치
            child: FloatingActionButton(
              heroTag: 'add_place_btn',
              onPressed: sortedDays.isNotEmpty ? () => _addNewPlace(sortedDays.first) : null,
              child: const Icon(Icons.add_location),
              tooltip: '새 장소 추가',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(int day, bool isEmpty, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Day $day',
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
                onPressed: () => _addNewPlace(day),
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
                child: Text(
                  'Day $day에 등록된 일정이 없습니다.',
                  style: TextStyle(color: Colors.grey[600]),
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

// 새 장소 추가 대화상자
class _AddPlaceDialog extends StatefulWidget {
  final Function(Place) onAdd;

  const _AddPlaceDialog({required this.onAdd});

  @override
  _AddPlaceDialogState createState() => _AddPlaceDialogState();
}

class _AddPlaceDialogState extends State<_AddPlaceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _category = 'tourism';

  final List<String> _categories = ['tourism', 'restaurant', 'accommodation', 'shopping', 'other'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 장소 추가'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '장소명'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '장소명을 입력해주세요';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '설명'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '설명을 입력해주세요';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: '이미지 URL'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이미지 URL을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: '카테고리'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _category = newValue;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                Place(
                  name: _nameController.text,
                  description: _descriptionController.text,
                  imageUrl: _imageUrlController.text,
                  category: _category,
                  time: '00:00', // 시간은 나중에 조정됩니다
                ),
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}