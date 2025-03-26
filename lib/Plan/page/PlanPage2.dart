import 'package:flutter/material.dart';

class PlanPage2 extends StatefulWidget {
  final String tripName;
  final List<DateTime> days;

  const PlanPage2({required this.tripName, required this.days, super.key});

  @override
  State<PlanPage2> createState() => _PlanPage2State();
}

class _PlanPage2State extends State<PlanPage2>
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

  Widget _buildCategorySection(
    String title,
    int count,
    IconData icon,
    List<Widget> items,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(
                '$title · $count',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.expand_more)),
            ],
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildPlaceCard([String? title]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://picsum.photos/100',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(title ?? 'Place name'),
          subtitle: const Text('nice place~~'),
          trailing: IconButton(icon: const Icon(Icons.close), onPressed: () {}),
        ),
      ),
    );
  }

  Widget _buildDayContent(int dayIndex) {
    if (viewMode == 'category') {
      return SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 200,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: const Text('지도 Placeholder\n(Google Map)'),
            ),
            _buildCategorySection('Tourism', 3, Icons.map_outlined, [
              _buildPlaceCard('Tourist Spot A'),
              _buildPlaceCard('Tourist Spot B'),
            ]),
            _buildCategorySection('Restaurant', 2, Icons.restaurant, [
              _buildPlaceCard('Restaurant 1'),
              _buildPlaceCard('Restaurant 2'),
            ]),
            _buildCategorySection('Accommodation', 1, Icons.hotel, [
              _buildPlaceCard('Hotel ABC'),
            ]),
          ],
        ),
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 200,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: const Text('지도 Placeholder\n(Google Map)'),
            ),
            const SizedBox(height: 12),
            _buildPlaceCard('08:00 · Breakfast - Café Scent'),
            _buildPlaceCard('10:00 · Gyeongbok Palace'),
            _buildPlaceCard('13:00 · Lunch - Kimchi House'),
            _buildPlaceCard('15:00 · Shopping - Myeongdong'),
            _buildPlaceCard('19:00 · Hotel Check-in'),
          ],
        ),
      );
    }
  }

  Future<void> _openDrawer() async {
    Scaffold.of(context).openEndDrawer();
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.ios_share)),
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: _openDrawer,
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
