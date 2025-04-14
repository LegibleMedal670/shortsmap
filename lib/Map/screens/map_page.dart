import 'package:flutter/material.dart';
import 'package:shortsmap/Widgets/BottomNavBar.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: Stack(
          children: [
            // 지도가 들어갈 자리 (추후 구현)
            const Center(
              child: Text('지도가 여기에 표시됩니다', style: TextStyle(fontSize: 18)),
            ),
            // 상단 필터와 검색 버튼
            Positioned(
              top: MediaQuery.of(context).size.height * (16 / 812),
              left: MediaQuery.of(context).size.width * (16 / 375),
              right: MediaQuery.of(context).size.width * (16 / 375),
              child: Row(
                children: [
                  // 검색 버튼
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            MediaQuery.of(context).size.width * (16 / 375),
                        vertical:
                            MediaQuery.of(context).size.height * (12 / 812),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Search', style: TextStyle(fontSize: 16)),
                          const Icon(Icons.search),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * (16 / 375),
                  ),
                  // 필터 버튼
                  Container(
                    width: MediaQuery.of(context).size.width * (48 / 375),
                    height: MediaQuery.of(context).size.width * (48 / 375),
                    decoration: BoxDecoration(
                      color: Colors.lightBlueAccent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.filter_alt_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // 하단 버튼들
            Positioned(
              left: MediaQuery.of(context).size.width * (16 / 375),
              bottom: MediaQuery.of(context).size.height * (20 / 812),
              child: Column(
                children: [
                  // 즐겨찾기 버튼
                  Container(
                    width: MediaQuery.of(context).size.width * (48 / 375),
                    height: MediaQuery.of(context).size.width * (48 / 375),
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * (12 / 812),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.star, color: Colors.black),
                  ),
                  // 현재 위치 버튼
                  Container(
                    width: MediaQuery.of(context).size.width * (48 / 375),
                    height: MediaQuery.of(context).size.width * (48 / 375),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(context, 'map'),
    );
  }
}
