import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortsmap/Shorts/model/LocationData.dart';
import 'package:shortsmap/Shorts/provider/FilterProvider.dart';
import 'package:shortsmap/Shorts/widget/ShimmerWidget.dart';
import 'package:shortsmap/Shorts/widget/ShortFormWidget.dart';
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

  /// Supabase RPC 호출: search_locations
  Future<List<LocationData>> _fetchDataFromSupabase(String? region, String? category, bool orderNear, double? lat, double? lon) async {


    await clearCache();

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
        },
      );

      final locationData =
          (response as List<dynamic>).map((locationJson) {
            return LocationData.fromJson(locationJson as Map<String, dynamic>);
          }).toList();

      await Future.delayed(const Duration(milliseconds: 700));

      return locationData;
    } on PostgrestException catch (e) {
      throw Exception("Error fetching posts: ${e.code}, ${e.message}");
    }
  }


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
                        storeName: 'shortFormData.name',
                        videoURL: 'shortFormData.videoUrl',
                        storeCaption: 'shortFormData.description',
                        storeLocation: 'shortFormData.region',
                        averagePrice: 0,
                        openTime: 'shortFormData.openTime',
                        closeTime: 'shortFormData.closeTime',
                        rating: 0,
                        category: 'shortFormData.category',
                        videoId: 'shortFormData.locationId.toString()',
                        bookmarkCount: 0,
                        isEmpty: true,
                      );
                    }

                    return PageView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final shortFormData = data[index];
                        return ShortFormWidget(
                          storeName: shortFormData.name,
                          videoURL: shortFormData.videoUrl,
                          storeCaption: shortFormData.description,
                          storeLocation: shortFormData.region,
                          averagePrice: shortFormData.averagePrice,
                          openTime: shortFormData.openTime,
                          closeTime: shortFormData.closeTime,
                          rating: shortFormData.rating,
                          category: shortFormData.category,
                          videoId: shortFormData.locationId.toString(),
                          bookmarkCount: shortFormData.bookmarkCount,
                          isEmpty: false,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          BottomNavBar(context, 'shorts'),
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
