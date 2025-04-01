import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../provider/TripPlanProvider.dart';
import '../widget/common/tab_button.dart';
import '../widget/trip_list/trip_card.dart';
import '../widget/trip_list/add_trip_dialog.dart';
import '../widget/saved_items/saved_grid_item.dart';
import '../widget/saved_items/filter_bar.dart';
import '../screens/plan_detail_page.dart';
import '../../../widgets/BottomNavBar.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({Key? key}) : super(key: key);

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  List<Trip> tripList = [];
  bool isSavedTab = false;

  Future<void> _showAddTripDialog() async {
    try {
      await showDialog(
        context: context,
        builder: (context) {
          return AddTripDialog(
            onAddTrip: (newTrip) {
              print('새 여행이 추가됨: ${newTrip.name}');
              print('시작일: ${newTrip.start}, 종료일: ${newTrip.end}');
              print('날짜 수: ${newTrip.days.length}');
              
              setState(() {
                tripList.add(newTrip);
              });
            },
          );
        },
      );
    } catch (e) {
      print('여행 추가 다이얼로그 오류: $e');
    }
  }

  void _navigateToPlanDetail(Trip trip) {
    // 이동 전 상세 디버그 정보 출력
    print('=== 여행 디테일 페이지로 이동 시도 ===');
    print('여행 이름: ${trip.name}');
    print('여행 날짜: ${trip.start} ~ ${trip.end}');
    print('날짜 리스트 크기: ${trip.days.length}');
    
    List<DateTime> effectiveDays;
    
    if (trip.days.isEmpty) {
      print('경고: 날짜 리스트가 비어 있습니다!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('여행 날짜가 설정되지 않았습니다. 기본 날짜를 사용합니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // 기본 날짜 생성
      effectiveDays = [DateTime.now()];
      print('기본 날짜 사용: $effectiveDays');
    } else {
      try {
        print('days 리스트 내용:');
        for (int i = 0; i < trip.days.length; i++) {
          print('  day[$i]: ${trip.days[i]}');
        }
        
        // 깊은 복사를 통해 days 리스트 전달
        effectiveDays = List<DateTime>.from(trip.days);
        print('복사된 days 리스트 크기: ${effectiveDays.length}');
      } catch (e) {
        print('날짜 복사 중 오류 발생: $e');
        effectiveDays = [DateTime.now()];
      }
    }
    
    // Provider 사용하여 PlanDetailPage로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => TripPlanProvider(
            tripName: trip.name,
            days: effectiveDays,
            initialPlaces: [],
          ),
          child: const PlanDetailPage(),
        ),
      ),
    );
    print('PlanDetailPage로 이동 완료');
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

    return ReorderableListView.builder(
      itemCount: tripList.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = tripList.removeAt(oldIndex);
          tripList.insert(newIndex, item);
        });
      },
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final trip = tripList[index];
        
        return TripCard(
          key: UniqueKey(),
          trip: trip,
          onTap: () => _navigateToPlanDetail(trip),
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