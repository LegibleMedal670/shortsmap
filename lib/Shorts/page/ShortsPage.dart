import 'package:flutter/material.dart';
import 'package:shortsmap/Shorts/widget/ShimmerWidget.dart';
import 'package:shortsmap/Shorts/widget/ShortFormWidget.dart';
import 'package:shortsmap/Widgets/BottomNavBar.dart';

class ShortsPage extends StatefulWidget {
  const ShortsPage({super.key});

  @override
  State<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {
  List<Map<String, dynamic>> tempData = [
    {
      'region': 'Seoul',
      'detailRegion': 'Seong-Su',
      'category': 'Activity',
      'price': 10,
      'name': 'Seoul Vibes',
      'siteURL': 'www.seoulvibes.com',
      'description': 'Cultural activity in trendy Seoul',
      'videoURL':
          'https://shortsmap.xyz/shortsmap_video/seongsu%3Abangintaco.mp4',
      'openTime': '11:00',
      'closeTime': '20:00',
    },
    {
      'region': 'Jeju',
      'detailRegion': null,
      'category': 'Nature',
      'price': 0,
      'name': 'Sunset Cliffs',
      'siteURL': 'www.sunsetjeju.kr',
      'description': 'Enjoy breathtaking sunsets on the cliff',
      'videoURL':
          'https://shortsmap.xyz/shortsmap_video/seongsu%3Ahddpizza.mp4',
      'openTime': '17:00',
      'closeTime': '21:00',
    },
    {
      'region': 'Busan',
      'detailRegion': 'Gwangan',
      'category': 'Food',
      'price': 18,
      'name': 'Gwangan Sushi',
      'siteURL': 'www.sushigwangan.co.kr',
      'description': 'Fresh sushi with a view of the bridge',
      'videoURL':
          'https://shortsmap.xyz/shortsmap_video/seongsu%3Akyukattjung.mp4',
      'openTime': '12:00',
      'closeTime': '22:00',
    },
    {
      'region': 'Seoul',
      'detailRegion': 'Itaewon',
      'category': 'Nightlife',
      'price': 22,
      'name': 'Midnight Lounge',
      'siteURL': 'www.mnightlounge.kr',
      'description': 'Chill out with cocktails and music',
      'videoURL': 'https://shortsmap.xyz/shortsmap_video/seongsu%3Asobamae.mp4',
      'openTime': '20:00',
      'closeTime': '03:00',
    },
    {
      'region': 'Daegu',
      'detailRegion': null,
      'category': 'Culture',
      'price': 5,
      'name': 'Daegu Museum',
      'siteURL': 'www.dgmuseum.or.kr',
      'description': 'Modern and traditional art exhibition',
      'videoURL':
          'https://shortsmap.xyz/shortsmap_video/seongsu%3Afregoclub.mp4',
      'openTime': '09:00',
      'closeTime': '18:00',
    },
    {
      'region': 'Gyeonggi',
      'detailRegion': 'Paju',
      'category': 'Shopping',
      'price': 0,
      'name': 'Paju Premium Outlets',
      'siteURL': 'www.pajuoutlets.kr',
      'description': 'Luxury shopping at discounted prices',
      'videoURL': 'https://shortsmap.xyz/shortsmap_video/seongsu%3A5to7.mp4',
      'openTime': '10:00',
      'closeTime': '21:00',
    },
    {
      'region': 'Seoul',
      'detailRegion': 'Hongdae',
      'category': 'Street Performance',
      'price': 0,
      'name': 'Live Hongdae',
      'siteURL': 'www.livehongdae.com',
      'description': 'Street music and vibrant crowd',
      'videoURL': 'https://shortsmap.xyz/shortsmap_video/seongsu%3Ajail.mp4',
      'openTime': '15:00',
      'closeTime': '23:00',
    },
    {
      'region': 'Gangwon',
      'detailRegion': null,
      'category': 'Activity',
      'price': 12,
      'name': 'River Rafting',
      'siteURL': 'www.raftinggangwon.kr',
      'description': 'Thrilling ride on the mountain rivers',
      'videoURL':
          'https://shortsmap.xyz/shortsmap_video/seongsu%3Anamjinrt.mp4',
      'openTime': '09:00',
      'closeTime': '16:00',
    },
    {
      'region': 'Incheon',
      'detailRegion': 'Songdo',
      'category': 'Cafe',
      'price': 9,
      'name': 'Sky Garden Café',
      'siteURL': 'www.skygarden.kr',
      'description': 'Modern rooftop café with skyline view',
      'videoURL': 'https://shortsmap.xyz/seongsu%3Atamgwang.mp4',
      'openTime': '10:00',
      'closeTime': '20:00',
    },
    {
      'region': 'Ulsan',
      'detailRegion': null,
      'category': 'Food',
      'price': 14,
      'name': 'Ulsan BBQ',
      'siteURL': 'www.ulsanbbq.com',
      'description': 'Authentic Korean BBQ in Ulsan',
      'videoURL':
          'https://shortsmap.xyz/shortsmap_video/seongsu%3Abdbugger.mp4',
      'openTime': '11:30',
      'closeTime': '22:30',
    },
  ];

  Future<List<dynamic>> tempFuture() async {
    ///TODO Supabase로 데이터 가져올거임

    // DocumentSnapshot documentSnapshot =
    // await _firestore.collection('shortsmap_seongsu').doc('map').get();
    //
    // Map<String, dynamic> documents = documentSnapshot.data() as Map<String,dynamic>;
    //
    // List<dynamic> data = documents['dataMapList'];

    await Future.delayed(const Duration(milliseconds: 1000));

    tempData.shuffle();

    return tempData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: tempFuture(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ShimmerWidget(mode: 'error');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ShimmerWidget(mode: 'loading');
                }

                List<dynamic> data = snapshot.data!;

                return PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> shortFormData = data[index];
                    return ShortFormWidget(
                      storeName: shortFormData['name'],
                      videoURL: shortFormData['videoURL'],
                      storeCaption: shortFormData['description'],
                      storeLocation: shortFormData['siteURL'],
                      averagePrice: 15,
                      sourceURL: shortFormData['siteURL'],
                      openTime: shortFormData['openTime'],
                      closeTime: shortFormData['closeTime'],
                      rating: 4.5,
                      category: shortFormData['category'],
                      index: index,
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
