import 'package:flutter/material.dart';
import 'package:shortsmap/Widgets/BottomNavBar.dart';
import 'PlanPage2.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  List<Map<String, dynamic>> tripList = [];
  bool isSavedTab = false; // trips/saved 탭 상태

  Future<void> _showAddTripDialog() async {
    String? tripName;
    DateTime? startDate;
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add new trip!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (val) => tripName = val,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked.start;
                          endDate = picked.end;
                        });
                      }
                    },
                    child: Text(
                      startDate != null && endDate != null
                          ? "${startDate!.toLocal()} ~ ${endDate!.toLocal()}"
                          : 'Select Date Range',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tripName != null &&
                        startDate != null &&
                        endDate != null) {
                      final days = List<DateTime>.generate(
                        endDate!.difference(startDate!).inDays + 1,
                        (i) => startDate!.add(Duration(days: i)),
                      );
                      setState(() {
                        tripList.add({
                          'name': tripName!,
                          'start': startDate!,
                          'end': endDate!,
                          'days': days,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTripsList() {
    if (tripList.isEmpty) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: _showAddTripDialog,
          icon: const Icon(Icons.add),
          label: const Text('New Trip'),
        ),
      );
    }

    return ListView.builder(
      itemCount: tripList.length,
      itemBuilder: (context, index) {
        final trip = tripList[index];
        final start = trip['start'] as DateTime;
        final end = trip['end'] as DateTime;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://picsum.photos/200/300',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                trip['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${trip['days'].length * 3}'),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${start.year}.${start.month}.${start.day} ~ ${end.year}.${end.month}.${end.day}',
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.more_vert),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => PlanPage2(
                          tripName: trip['name'],
                          days: trip['days'],
                        ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 가로 2개
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[300],
            ),
            alignment: Alignment.center,
            child: Text('Saved $index'),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showAddButton = !isSavedTab;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('ShortsMap', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions:
            showAddButton
                ? [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showAddTripDialog,
                  ),
                ]
                : [],
      ),
      body: Column(
        children: [
          // ✅ Saved 모드에서만 상단 필터 바 출력
          if (isSavedTab)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.travel_explore_outlined,
                    color: Colors.black,
                    size: 26,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    color: Colors.transparent,
                    child: const Text(
                      'Seoul · Food · \$10',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 🔽 trips or saved view
          Expanded(child: isSavedTab ? _buildSavedGrid() : _buildTripsList()),

          // trips / saved 탭 선택
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabButton('Trips', !isSavedTab),
                const SizedBox(width: 16),
                _buildTabButton('Saved', isSavedTab),
              ],
            ),
          ),

          // 하단 네비게이션
          BottomNavBar(context, 'plan'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isSavedTab = (label == 'Saved');
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
