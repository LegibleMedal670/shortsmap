import 'package:flutter/material.dart';
import '../widget/ trip_detail/place_card.dart';
import '../widget/ trip_detail/category_section.dart';
import '../widget/ trip_detail/map_placeholder.dart';


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
              count: 3,
              icon: Icons.map_outlined,
              items: [
                PlaceCard(
                  title: 'Tourist Spot A',
                  onDelete: () {},
                ),
                PlaceCard(
                  title: 'Tourist Spot B',
                  onDelete: () {},
                ),
              ],
              onAddItem: () {},
            ),
            CategorySection(
              title: 'Restaurant',
              count: 2,
              icon: Icons.restaurant,
              items: [
                PlaceCard(
                  title: 'Restaurant 1',
                  onDelete: () {},
                ),
                PlaceCard(
                  title: 'Restaurant 2',
                  onDelete: () {},
                ),
              ],
              onAddItem: () {},
            ),
            CategorySection(
              title: 'Accommodation',
              count: 1,
              icon: Icons.hotel,
              items: [
                PlaceCard(
                  title: 'Hotel ABC',
                  onDelete: () {},
                ),
              ],
              onAddItem: () {},
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
            PlaceCard(
              title: '08:00 · Breakfast - Café Scent',
              onDelete: () {},
            ),
            PlaceCard(
              title: '10:00 · Gyeongbok Palace',
              onDelete: () {},
            ),
            PlaceCard(
              title: '13:00 · Lunch - Kimchi House',
              onDelete: () {},
            ),
            PlaceCard(
              title: '15:00 · Shopping - Myeongdong',
              onDelete: () {},
            ),
            PlaceCard(
              title: '19:00 · Hotel Check-in',
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
              onChanged: (val) => tripName = val,
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