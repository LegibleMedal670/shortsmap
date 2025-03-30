import 'package:flutter/material.dart';
import '../widget/ trip_detail/place_card.dart';
import '../widget/ trip_detail/category_section.dart';
import '../widget/ trip_detail/map_placeholder.dart';
import '../widget/ trip_detail/timeline_item.dart';

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
  String viewMode = 'category'; // 'category' or 'timeline'

  // 각 카테고리별 장소 목록을 관리하는 상태 변수들
  List<String> tourismPlaces = ['Tourist Spot A', 'Tourist Spot B'];
  List<String> restaurantPlaces = ['Restaurant 1', 'Restaurant 2'];
  List<String> accommodationPlaces = ['Hotel ABC'];

  @override
  void initState() {
    super.initState();
    tripName = widget.tripName;
    _tabController = TabController(length: widget.days.length, vsync: this);
    selectedRange = DateTimeRange(
      start: widget.days.first,
      end: widget.days.last,
    );
  }

  Widget _buildDayContent(int dayIndex) {
    if (viewMode == 'category') {
      return SingleChildScrollView(
        child: Column(
          children: [
            const MapPlaceholder(),
            CategorySection(
              title: 'Tourism',
              count: tourismPlaces.length,
              icon: Icons.map_outlined,
              items: tourismPlaces.asMap().entries.map((entry) {
                return PlaceCard(
                  key: ValueKey('tourism_${entry.key}'),
                  title: entry.value,
                  index: entry.key,
                  onDelete: () {
                    setState(() {
                      tourismPlaces.removeAt(entry.key);
                    });
                  },
                );
              }).toList(),
              onAddItem: () {
                setState(() {
                  tourismPlaces.add('New Tourist Spot');
                });
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = tourismPlaces.removeAt(oldIndex);
                  tourismPlaces.insert(newIndex, item);
                });
              },
            ),
            CategorySection(
              title: 'Restaurant',
              count: restaurantPlaces.length,
              icon: Icons.restaurant,
              items: restaurantPlaces.asMap().entries.map((entry) {
                return PlaceCard(
                  key: ValueKey('restaurant_${entry.key}'),
                  title: entry.value,
                  index: entry.key,
                  onDelete: () {
                    setState(() {
                      restaurantPlaces.removeAt(entry.key);
                    });
                  },
                );
              }).toList(),
              onAddItem: () {
                setState(() {
                  restaurantPlaces.add('New Restaurant');
                });
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = restaurantPlaces.removeAt(oldIndex);
                  restaurantPlaces.insert(newIndex, item);
                });
              },
            ),
            CategorySection(
              title: 'Accommodation',
              count: accommodationPlaces.length,
              icon: Icons.hotel,
              items: accommodationPlaces.asMap().entries.map((entry) {
                return PlaceCard(
                  key: ValueKey('accommodation_${entry.key}'),
                  title: entry.value,
                  index: entry.key,
                  onDelete: () {
                    setState(() {
                      accommodationPlaces.removeAt(entry.key);
                    });
                  },
                );
              }).toList(),
              onAddItem: () {
                setState(() {
                  accommodationPlaces.add('New Hotel');
                });
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = accommodationPlaces.removeAt(oldIndex);
                  accommodationPlaces.insert(newIndex, item);
                });
              },
            ),
          ],
        ),
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            const MapPlaceholder(),
            const SizedBox(height: 12),
            TimelineItem(
              time: '08:00',
              title: 'Breakfast - Café Scent',
              description: '아침 식사',
              onDelete: () {},
            ),
            TimelineItem(
              time: '10:00',
              title: 'Gyeongbok Palace',
              description: '주요 관광지',
              onDelete: () {},
            ),
            TimelineItem(
              time: '13:00',
              title: 'Lunch - Kimchi House',
              description: '한국 전통 음식',
              onDelete: () {},
            ),
            TimelineItem(
              time: '15:00',
              title: 'Shopping - Myeongdong',
              description: '쇼핑 명소',
              onDelete: () {},
            ),
            TimelineItem(
              time: '19:00',
              title: 'Hotel Check-in',
              description: '숙소',
              onDelete: () {},
            ),
          ],
        ),
      );
    }
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
            const SizedBox(height: 16),
            const Text('Display Mode'),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Category'),
                  selected: viewMode == 'category',
                  onSelected: (_) {
                    setState(() => viewMode = 'category');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Timeline'),
                  selected: viewMode == 'timeline',
                  onSelected: (_) {
                    setState(() => viewMode = 'timeline');
                    Navigator.pop(context);
                  },
                ),
              ],
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
          isScrollable: widget.days.length >= 5,
          tabs: List.generate(widget.days.length, (index) {
            return Tab(text: 'Day ${index + 1}');
          }),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          widget.days.length,
          (index) => _buildDayContent(index),
        ),
      ),
    );
  }
}