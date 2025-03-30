import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../widget/common/tab_button.dart';
import '../widget/trip_list/trip_card.dart';
import '../widget/trip_list/add_trip_dialog.dart';
import '../widget/saved_items/saved_grid_item.dart';
import '../widget/saved_items/filter_bar.dart';
import 'plan_detail_page.dart';
import '../../../widgets/BottomNavBar.dart';  // 경로는 실제 상황에 맞게 조정

class PlanPage extends StatefulWidget {
  const PlanPage({Key? key}) : super(key: key);

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  List<Trip> tripList = [];
  bool isSavedTab = false;

  Future<void> _showAddTripDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AddTripDialog(
          onAddTrip: (newTrip) {
            setState(() {
              tripList.add(newTrip);
            });
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
        
        return TripCard(
          trip: trip,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlanDetailPage(
                  tripName: trip.name,
                  days: trip.days,
                ),
              ),
            );
          },
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
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          return SavedGridItem(index: index);
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
        actions: showAddButton
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
          // 저장 탭에서만 필터 바 표시
          if (isSavedTab)
            FilterBar(filterText: 'Seoul · Food · \$10'),

          // 여행 목록 또는 저장된 항목 그리드 표시
          Expanded(child: isSavedTab ? _buildSavedGrid() : _buildTripsList()),

          // trips / saved 탭 선택 버튼
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                TabButton(
                  label: 'Trips',
                  selected: !isSavedTab,
                  onTap: () {
                    setState(() {
                      isSavedTab = false;
                    });
                  },
                ),
                const SizedBox(width: 16),
                TabButton(
                  label: 'Saved',
                  selected: isSavedTab,
                  onTap: () {
                    setState(() {
                      isSavedTab = true;
                    });
                  },
                ),
              ],
            ),
          ),

          // 하단 네비게이션 바
          BottomNavBar(context, 'plan'),
        ],
      ),
    );
  }
}