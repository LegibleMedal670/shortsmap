import 'package:flutter/material.dart';
import '../widget/ trip_detail/unifiedPlaceCard.dart';
import '../widget/ trip_detail/category_section.dart';
import '../widget/ trip_detail/map_placeholder.dart';
import '../widget/ trip_detail/planner_page.dart';
import '../models/place.dart';

class PlanDetailPage extends StatefulWidget {
  final String tripName;
  final List<DateTime> days;

  const PlanDetailPage({
    required this.tripName,
    required this.days,
    Key? key,
  }) : super(key: key);

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String tripName = '';
  DateTimeRange? selectedRange;

  // 장소 목록을 관리하는 상태 변수
  List<Place> places = [
    Place(
      name: 'Tourist Spot A',
      description: '관광지 A',
      imageUrl: 'https://via.placeholder.com/150',
      category: 'tourism',
      time: '09:00',
    ),
    Place(
      name: 'Restaurant 1',
      description: '맛있는 식당',
      imageUrl: 'https://via.placeholder.com/150',
      category: 'restaurant',
      time: '12:00',
    ),
    Place(
      name: 'Hotel ABC',
      description: '호텔',
      imageUrl: 'https://via.placeholder.com/150',
      category: 'accommodation',
      time: '20:00',
    ),
    Place(
      name: 'Tourist Spot B',
      description: '관광지 B',
      imageUrl: 'https://via.placeholder.com/150',
      category: 'tourism',
      time: '10:00',
    ),
    Place(
      name: 'Restaurant 2',
      description: '저녁 식당',
      imageUrl: 'https://via.placeholder.com/150',
      category: 'restaurant',
      time: '18:00',
    ),
  ];

  @override
  void initState() {
    super.initState();
    tripName = widget.tripName;
    _tabController = TabController(length: widget.days.length + 1, vsync: this);
    selectedRange = DateTimeRange(
      start: widget.days.first,
      end: widget.days.last,
    );
  }

  // 카테고리별로 필터링된 장소 목록을 반환하는 함수
  List<Place> getPlacesByCategory(String category) {
    return places.where((place) => place.category == category).toList();
  }

  Widget _buildCategoryView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const MapPlaceholder(),
          const SizedBox(height: 12),
          CategorySection(
            title: '관광지',
            count: getPlacesByCategory('tourism').length,
            icon: Icons.map_outlined,
            items: getPlacesByCategory('tourism').asMap().entries.map((entry) {
              return UnifiedPlaceCard(
                key: ValueKey('tourism_${entry.key}'),
                place: entry.value,
                index: entry.key,
                onDelete: () {
                  setState(() {
                    places.remove(entry.value);
                  });
                },
              );
            }).toList(),
            onAddItem: () {
              setState(() {
                places.add(Place(
                  name: 'New Tourist Spot',
                  description: '새 관광지',
                  imageUrl: 'https://via.placeholder.com/150',
                  category: 'tourism',
                ));
              });
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                final categoryPlaces = getPlacesByCategory('tourism');
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = categoryPlaces[oldIndex];
                // 원래 리스트에서 삭제
                places.remove(item);
                // 새 위치에 삽입 (카테고리 리스트 기준이 아닌 전체 리스트 기준으로)
                final tourismPlaces = getPlacesByCategory('tourism');
                final insertIndex = places.indexOf(
                  newIndex < tourismPlaces.length
                      ? tourismPlaces[newIndex]
                      : tourismPlaces.last,
                );
                places.insert(insertIndex >= 0 ? insertIndex : places.length, item);
              });
            },
          ),
          CategorySection(
            title: '식당',
            count: getPlacesByCategory('restaurant').length,
            icon: Icons.restaurant,
            items: getPlacesByCategory('restaurant').asMap().entries.map((entry) {
              return UnifiedPlaceCard(
                key: ValueKey('restaurant_${entry.key}'),
                place: entry.value,
                index: entry.key,
                onDelete: () {
                  setState(() {
                    places.remove(entry.value);
                  });
                },
              );
            }).toList(),
            onAddItem: () {
              setState(() {
                places.add(Place(
                  name: 'New Restaurant',
                  description: '새 식당',
                  imageUrl: 'https://via.placeholder.com/150',
                  category: 'restaurant',
                ));
              });
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                final categoryPlaces = getPlacesByCategory('restaurant');
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = categoryPlaces[oldIndex];
                // 원래 리스트에서 삭제
                places.remove(item);
                // 새 위치에 삽입
                final restaurantPlaces = getPlacesByCategory('restaurant');
                final insertIndex = places.indexOf(
                  newIndex < restaurantPlaces.length
                      ? restaurantPlaces[newIndex]
                      : restaurantPlaces.last,
                );
                places.insert(insertIndex >= 0 ? insertIndex : places.length, item);
              });
            },
          ),
          CategorySection(
            title: '숙소',
            count: getPlacesByCategory('accommodation').length,
            icon: Icons.hotel,
            items: getPlacesByCategory('accommodation').asMap().entries.map((entry) {
              return UnifiedPlaceCard(
                key: ValueKey('accommodation_${entry.key}'),
                place: entry.value,
                index: entry.key,
                onDelete: () {
                  setState(() {
                    places.remove(entry.value);
                  });
                },
              );
            }).toList(),
            onAddItem: () {
              setState(() {
                places.add(Place(
                  name: 'New Hotel',
                  description: '새 호텔',
                  imageUrl: 'https://via.placeholder.com/150',
                  category: 'accommodation',
                ));
              });
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                final categoryPlaces = getPlacesByCategory('accommodation');
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = categoryPlaces[oldIndex];
                // 원래 리스트에서 삭제
                places.remove(item);
                // 새 위치에 삽입
                final accommodationPlaces = getPlacesByCategory('accommodation');
                final insertIndex = places.indexOf(
                  newIndex < accommodationPlaces.length
                      ? accommodationPlaces[newIndex]
                      : accommodationPlaces.last,
                );
                places.insert(insertIndex >= 0 ? insertIndex : places.length, item);
              });
            },
          ),
          // 추가 버튼 (새 장소 추가)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('새 장소 추가하기'),
              onPressed: () {
                // 새 장소 추가 로직 구현
                _showAddPlaceDialog();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPlaceDialog() {
    // 간단한 구현: 카테고리 선택 후 기본 장소 추가
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 장소 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  places.add(Place(
                    name: 'New Tourist Spot',
                    description: '새 관광지',
                    imageUrl: 'https://via.placeholder.com/150',
                    category: 'tourism',
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('관광지 추가'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  places.add(Place(
                    name: 'New Restaurant',
                    description: '새 식당',
                    imageUrl: 'https://via.placeholder.com/150',
                    category: 'restaurant',
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('식당 추가'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  places.add(Place(
                    name: 'New Hotel',
                    description: '새 호텔',
                    imageUrl: 'https://via.placeholder.com/150',
                    category: 'accommodation',
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('숙소 추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _addPlace(Place place) {
    setState(() {
      places.add(place);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Edit Trip Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Trip Name'),
              controller: TextEditingController(text: tripName),
              onChanged: (val) => setState(() => tripName = val),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2100),
                  initialDateRange: selectedRange,
                );
                if (picked != null) {
                  setState(() {
                    selectedRange = picked;
                  });
                }
              },
              child: Text(
                selectedRange != null
                    ? '${selectedRange!.start.year}.${selectedRange!.start.month}.${selectedRange!.start.day} ~ ${selectedRange!.end.year}.${selectedRange!.end.month}.${selectedRange!.end.day}'
                    : 'Select Date Range',
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(tripName),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.ios_share),
          ),
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Planner'),
            ...List.generate(widget.days.length, (index) {
              return Tab(text: 'Day ${index + 1}');
            }),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PlannerPage(onAddPlace: _addPlace),
          ...List.generate(
            widget.days.length,
            (index) => _buildCategoryView(),
          ),
        ],
      ),
    );
  }
}