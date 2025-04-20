import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortsmap/Shorts/model/LocationData.dart';
import 'package:shortsmap/Shorts/provider/FilterProvider.dart';
import 'package:shortsmap/Shorts/widget/ShimmerWidget.dart';
import 'package:shortsmap/Shorts/widget/ShortFormWidget.dart';
import 'package:shortsmap/Provider/UserDataProvider.dart';
import 'package:shortsmap/Widgets/BottomNavBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShortsPage extends StatefulWidget {
  const ShortsPage({super.key});

  @override
  State<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {

  /// Supabase client
  final _supabase = Supabase.instance.client;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Supabase RPC 호출: search_locations
  Future<List<LocationData>> _fetchDataFromSupabase(String? region, String? category, bool orderNear, double? lat, double? lon, String? uid) async {

    //북마크 캐시 삭제
    await clearCache();

    if (uid != null) {
      try {
        // RPC 파라미터 구성
        final response = await _supabase.rpc(
          'get_locations',
          params: {
            '_region': region,
            '_category': category,
            '_order_near': orderNear,
            '_lat': lat,
            '_lon': lon,
            '_user_id': uid,
          },
        );

        final locationData =
        (response as List<dynamic>).map((locationJson) {
          return LocationData.fromJson(locationJson as Map<String, dynamic>);
        }).toList();

        //로딩 시간이 있는척하기 위한 딜레이
        await Future.delayed(const Duration(milliseconds: 700));

        return locationData;
      } on PostgrestException catch (e) {
        throw Exception("Error fetching posts: ${e.code}, ${e.message}");
      }
    } else {

      SharedPreferences preferences = await SharedPreferences.getInstance();

      List<String> seenVideoIds = preferences.getStringList('seenVideoIds') ?? [];

      try {
        // RPC 파라미터 구성
        final response = await _supabase.rpc(
          'get_locations_no_auth',
          params: {
            '_region': region,
            '_category': category,
            '_order_near': orderNear,
            '_lat': lat,
            '_lon': lon,
            '_exclude_video_ids': seenVideoIds,
          },
        );

        final locationData =
        (response as List<dynamic>).map((locationJson) {
          return LocationData.fromJson(locationJson as Map<String, dynamic>);
        }).toList();

        //로딩 시간이 있는척하기 위한 딜레이
        await Future.delayed(const Duration(milliseconds: 700));

        return locationData;
      } on PostgrestException catch (e) {
        throw Exception("Error fetching posts: ${e.code}, ${e.message}");
      }
    }
  }

  ///북마크 캐시 삭제
  Future<void> clearCache() async {

    SharedPreferences preferences = await SharedPreferences.getInstance();

    preferences.remove('bookMarkList');

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Consumer<FilterProvider>(
              builder: (context, provider, child) {
                return FutureBuilder(
                  future: _fetchDataFromSupabase(
                    provider.filterRegion,
                    provider.filterCategory,
                    provider.orderNear,
                    provider.filterLat,
                    provider.filterLon,
                    Provider.of<UserDataProvider>(context, listen: false).currentUserUID
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print(snapshot.error);
                      return ShimmerWidget(mode: 'error');

                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ShimmerWidget(mode: 'loading');
                    }

                    List<dynamic> data = snapshot.data!;

                    if (data.isEmpty) {
                      return ShortFormWidget(
                        placeName: 'shortFormData.name',
                        description: 'shortFormData.description',
                        placeRegion: 'shortFormData.region',
                        averagePrice: 0,
                        openTime: 'shortFormData.openTime',
                        closeTime: 'shortFormData.closeTime',
                        rating: 0,
                        category: 'shortFormData.category',
                        videoId: 'shortFormData.locationId.toString()',
                        bookmarkCount: 0,
                        isEmpty: true,
                        coordinates: {},
                        pageController: _pageController,
                        placeId: '',
                      );
                    }

                    return PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final LocationData shortFormData = data[index];
                        return ShortFormWidget(
                          placeName: shortFormData.placeName,
                          description: shortFormData.description,
                          placeRegion: shortFormData.region,
                          averagePrice: shortFormData.averagePrice,
                          openTime: shortFormData.openTime,
                          closeTime: shortFormData.closeTime,
                          rating: shortFormData.rating,
                          category: shortFormData.category,
                          videoId: shortFormData.videoId,
                          bookmarkCount: shortFormData.bookmarkCount,
                          isEmpty: false,
                          coordinates: shortFormData.coordinates,
                          pageController: _pageController,
                          placeId: shortFormData.placeId,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // BottomNavBar(context, 'shorts'),
        ],
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   type: BottomNavigationBarType.fixed,
      //   backgroundColor: Colors.black,
      //   selectedItemColor: Colors.grey[200],
      //   selectedFontSize: 13,
      //   unselectedItemColor: Colors.grey,
      //   unselectedFontSize: 13,
      //   elevation: 0,
      //   currentIndex: 0,
      //   onTap: (index) {
      //     HapticFeedback.lightImpact();
      //     if (index != 0){
      //       print(index);
      //     }
      //   },
      //   items: [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.travel_explore),
      //       label: 'Explore',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.calendar_month),
      //       label: 'Plan',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(CupertinoIcons.tickets),
      //       label: 'Reserve',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.forum_outlined),
      //       label: 'Community',
      //     ),
      //   ],
      // ),
    );
  }
}
