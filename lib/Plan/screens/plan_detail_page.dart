import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/TripPlanProvider.dart';
import '../widget/ trip_detail/planner_page.dart';
import '../widget/ trip_detail/day_page.dart';
import '../models/place.dart';
import '../widget/ trip_detail/planner_page.dart';
import '../widget/ trip_detail/day_page.dart';


class PlanDetailPage extends StatefulWidget {
  const PlanDetailPage({Key? key}) : super(key: key);

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    print('=== PlanDetailPage initState 시작 ===');
    
    try {
      // Provider로부터 days 목록 가져오기
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<TripPlanProvider>(context, listen: false);
        final days = provider.days;
        
        print('Provider로부터 days 목록 가져옴, 크기: ${days.length}');
        
        // TabController 초기화
        _tabController = TabController(length: days.length + 1, vsync: this);
      });
      
      // 초기값으로 TabController 설정 (Provider가 아직 준비되지 않은 경우)
      _tabController = TabController(length: 2, vsync: this);
      
      print('=== PlanDetailPage initState 완료 ===');
    } catch (e) {
      print('PlanDetailPage 초기화 중 오류 발생: $e');
      // 오류 발생 시 기본값 설정
      _tabController = TabController(length: 2, vsync: this); // Planner + 1일
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Provider 변경 감지하여 TabController 업데이트
    try {
      final provider = Provider.of<TripPlanProvider>(context);
      if (_tabController.length != provider.days.length + 1) {
        // 기존 컨트롤러 처분 후 새로 생성
        _tabController.dispose();
        _tabController = TabController(
          length: provider.days.length + 1,
          vsync: this,
        );
      }
    } catch (e) {
      print('TabController 업데이트 중 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripPlanProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          endDrawer: _buildEndDrawer(context, provider),
          appBar: _buildAppBar(context, provider),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 플래너 페이지 (전체 일정 관리용)
              const PlannerPage(),
              
              // 일자별 상세 페이지들
              ...List.generate(
                provider.days.length,
                (index) {
                  final dayNumber = index + 1;  // 1일차부터 시작
                  return DayPage(
                    dayIndex: index,
                    dayNumber: dayNumber,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // AppBar 구성
  PreferredSizeWidget _buildAppBar(BuildContext context, TripPlanProvider provider) {
    return AppBar(
      title: Text(provider.tripName),
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
          ...List.generate(provider.days.length, (index) {
            return Tab(text: 'Day ${index + 1}');
          }),
        ],
      ),
    );
  }

  // EndDrawer 구성
  Widget _buildEndDrawer(BuildContext context, TripPlanProvider provider) {
    TextEditingController tripNameController = TextEditingController(text: provider.tripName);
    
    return Drawer(
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
            controller: tripNameController,
            onChanged: (val) => provider.updateTripName(val),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime(2100),
                initialDateRange: provider.dateRange,
              );
              if (picked != null) {
                provider.updateDateRange(picked);
              }
            },
            child: Text(
              provider.dateRange != null
                  ? '${provider.dateRange!.start.year}.${provider.dateRange!.start.month}.${provider.dateRange!.start.day} ~ ${provider.dateRange!.end.year}.${provider.dateRange!.end.month}.${provider.dateRange!.end.day}'
                  : 'Select Date Range',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}