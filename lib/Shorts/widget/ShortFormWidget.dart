import 'dart:convert';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortsmap/Shorts/provider/FilterProvider.dart';
import 'package:shortsmap/UserDataProvider.dart';
import 'package:shortsmap/Welcome/LoginPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class ShortFormWidget extends StatefulWidget {
  final String storeName;
  final String videoURL;
  final String storeCaption;
  final String storeLocation;
  final String openTime;
  final String closeTime;
  final double rating;
  final String category;
  final double averagePrice;
  final String videoId;
  final int bookmarkCount;
  final bool isEmpty;
  final Map<String, double> coordinates;
  final PageController pageController;

  const ShortFormWidget({
    required this.storeName,
    required this.videoURL,
    required this.storeCaption,
    required this.storeLocation,
    required this.openTime,
    required this.closeTime,
    required this.rating,
    required this.category,
    required this.averagePrice,
    required this.videoId,
    required this.bookmarkCount,
    required this.isEmpty,
    required this.coordinates,
    required this.pageController,
    super.key,
  });

  @override
  State<ShortFormWidget> createState() => _ShortFormWidgetState();
}

class _ShortFormWidgetState extends State<ShortFormWidget> {
  late YoutubePlayerController _controller;
  IconData _currentIcon = Icons.pause;
  double _pauseIconOpacity = 0.0;
  IconData restaurantCategory = Icons.restaurant_outlined;
  bool _isExpanded = false;

  late int _bookmarkCount;

  bool _hasRecordedSeen = false;

  //Supabase client
  final _supabase = Supabase.instance.client;

  final List<String> regionOptions = [
    'All',
    'Near Me',
    '서울',
    '부산',
    '세글자',
    '대구',
    '광주',
    '제주',
    '네글자임',
    '명동',
    '성수',
    '성남',
    '대전',
    '다섯글자임',
  ];
  final List<String> categoryOptions = ['All', '한식', '양식', '일식', '중식', '카페'];
  final List<String> priceOptions = [
    'All',
    '\$10',
    '\$20',
    '\$30',
    '\$40',
    '\$50',
    '\$50~',
  ];

  // 현재 선택된 값(단일 선택)
  String? selectedRegion;
  String? selectedCategory;
  String? selectedPrice;

  Color shortPageWhite = Colors.grey[200] as Color;

  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isEmpty) {
      getRestaurantCategory(widget.category);
      getBookmarkInfoFromCache();

      _bookmarkCount = widget.bookmarkCount;

      _controller = YoutubePlayerController(
        params: YoutubePlayerParams(
          mute: false,
          showControls: false,
          showFullscreenButton: false,
          loop: false,
          showVideoAnnotations: false,
          pointerEvents: PointerEvents.none,
        ),
      );

      _controller.loadVideoById(videoId: 'NscOnNp2x8M');
    }
  }

  @override
  void dispose() {
    if (!widget.isEmpty) {
      _controller.close();
    }
    super.dispose();
  }

  ///stop + resume
  void _toggleVideo() {
    final wasPlaying = _controller.value.playerState == PlayerState.playing;
    setState(() {
      _currentIcon = wasPlaying ? Icons.pause : Icons.play_arrow;
      _pauseIconOpacity = 1.0;
    });

    if (wasPlaying) {
      // _playerController.pause();
      _controller.pauseVideo();
    } else {
      _controller.playVideo();
      // _playerController.play();
    }

    // 애니메이션 처리
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _pauseIconOpacity = 0.0);
      }
    });
  }

  ///카테고리 계산 ( 사진 넣어줄거면 필요 없음 )
  void getRestaurantCategory(String category) {
    switch (category) {
      case "kr":
        setState(() {
          restaurantCategory = Icons.rice_bowl;
        });
        break;
      case "jp":
        setState(() {
          restaurantCategory = Icons.ramen_dining;
        });
        break;
      case "cn":
        setState(() {
          restaurantCategory = Icons.soup_kitchen;
        });
        break;
      case "we":
        setState(() {
          restaurantCategory = Icons.local_pizza;
        });
        break;
      case "cf":
        setState(() {
          restaurantCategory = Icons.local_cafe;
        });
        break;
      case "bs":
        setState(() {
          restaurantCategory = Icons.kebab_dining;
        });
        break;
      case "br":
        setState(() {
          restaurantCategory = Icons.sports_bar;
        });
        break;
      case "et":
        setState(() {
          restaurantCategory = Icons.dining;
        });
        break;
      default:
        setState(() {
          restaurantCategory = Icons.dining;
        });
        break;
    }
  }

  ///북마크 여부를 캐시에서 불러옴
  void getBookmarkInfoFromCache() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    List<String> bookMarkList = preferences.getStringList('bookMarkList') ?? [];

    setState(() {
      _isBookmarked = bookMarkList.contains(widget.videoId);
    });
  }

  ///영상 시청 여부 저장
  Future<void> recordSeenVideo(String? currentUserUid) async {

    ///로그인한 경우에는 서버에 저장
    if (currentUserUid != null) {
      try {
        // 서버에 저장
        await _supabase.from('seenvideos').insert({
          'user_id': currentUserUid,
          'location_id': widget.videoId,
        });
      } catch (e) {
        // 예외가 발생하면 에러 메시지를 출력합니다. TODO 에러 처리 어떻게할지 고민
        print('Insert 에러: $e');
      }
    } else {

      /// 로그인하지 않은 경우에는 캐시에 저장
      SharedPreferences preferences = await SharedPreferences.getInstance();

      List<String> seenVideoIds = preferences.getStringList('seenVideoIds') ?? [];

      // videoId 추가
      seenVideoIds.add(widget.videoId);

      // Set을 이용해 중복 제거
      seenVideoIds = seenVideoIds.toSet().toList();

      // 캐시에 200개 이상 쌓이면 초기화
      if(seenVideoIds.length > 200) {
        seenVideoIds = [];
      }

      // 업데이트된 리스트 저장
      await preferences.setStringList('seenVideoIds', seenVideoIds);

      print(preferences.getStringList('seenVideoIds') ?? []);


    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.black, // Color for Android
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark
    ));
    /// TODO: 빈 위젯 등 위젯들 분리
    if (widget.isEmpty) {
      return Stack(
        children: [
          ///상단 필터 위젯
          SafeArea(
            child: GestureDetector(
              onTap: () {
                showFilterModal(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.travel_explore_outlined,
                    color: shortPageWhite,
                    size: 26,
                  ),
                  Consumer<FilterProvider>(
                    builder: (providerContext, filterProvider, child) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        color: Colors.transparent,
                        child: Text(
                          '${filterProvider.filterRegion ?? 'All'} · ${filterProvider.filterCategory ?? 'All'} ',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: shortPageWhite,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          ///뒤로가기 버튼
          Positioned(
            left: MediaQuery.of(context).size.width * 0.05,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(5),
                  color: Colors.transparent,
                  child: Icon(
                    CupertinoIcons.back,
                    color: shortPageWhite,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Explored All Videos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'Try Another Filter Please',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Stack(
        children: [
          ///동영상위젯 탭, 더블탭 액션
          GestureDetector(
            onTap: () {
              _toggleVideo();
            },
            onLongPress: () {
              showOptionsModal(context);
            },
            // onDoubleTap: () {
            //   print('doubletap');
            // },
            child: SafeArea(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                // color: Color(0xff121212),
                padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.046),
                color: Colors.black,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          YoutubeValueBuilder(
                            controller: _controller,
                            builder: (context, value) {

                              if (value.playerState == PlayerState.playing && !_hasRecordedSeen) {
                                _hasRecordedSeen = true; // 한 번 기록했음을 표시
                                // 현재 사용자 UID를 전달하여 recordSeenVideo 실행
                                recordSeenVideo(Provider.of<UserDataProvider>(context, listen: false).currentUserUID);
                              }

                              if (value.playerState == PlayerState.ended) {
                                _controller.seekTo(seconds: 0);
                                _controller.playVideo();
                              }
                              return IgnorePointer(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: Container(
                                    // 원래 영상의 비율을 유지하는 크기 지정 (9:16)
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.89,
                                    height:
                                        (MediaQuery.of(context).size.width *
                                            0.89) *
                                        (16 / 9),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                    child: YoutubePlayer(
                                      controller: _controller,
                                      backgroundColor: Colors.black,
                                      // aspectRatio는 이제 FittedBox로 크기를 조절하므로 제거하거나 동일하게 유지할 수 있음.
                                      // aspectRatio: 9 / 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          ///위아래 위젯들 가시성을 위한 그림자
                          // IgnorePointer(
                          //   child: Container(
                          //     // color: Colors.black.withOpacity(0.2),
                          //     decoration: BoxDecoration(
                          //       gradient: LinearGradient(
                          //         begin: Alignment.topCenter,
                          //         end: Alignment.bottomCenter,
                          //         colors: [
                          //           Colors.black.withValues(alpha: 0.5),
                          //           Colors.transparent,
                          //           Colors.transparent,
                          //           Colors.black.withValues(alpha: 0.5),
                          //         ],
                          //       ),
                          //     ), // 어두운 투명 레이어
                          //   ),
                          // ),

                          ///정지/재개 아이콘
                          Center(
                            child: AnimatedOpacity(
                              opacity: _pauseIconOpacity,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCirc,
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _currentIcon,
                                  color: shortPageWhite,
                                  size: 50.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // VideoProgressIndicator(
                    //   _playerController,
                    //   padding: EdgeInsets.zero,
                    //   allowScrubbing: true, // 스크럽 허용
                    //   colors: const VideoProgressColors(
                    //     playedColor: Color.fromRGBO(220, 20, 60, 1),
                    //     // 재생된 부분 색상
                    //     bufferedColor: Colors.grey,
                    //     // 버퍼링된 부분 색상
                    //     backgroundColor: Colors.grey,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),

          ///설명 Expanded 되었을 때 가독성을 위한 그림자
          if (_isExpanded)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = false;
                });
              },
              child: Container(
                // color: Colors.black.withOpacity(0.2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2), // 상단은 투명
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.4), // 중간은 약간 어두움
                      Colors.black.withValues(alpha: 0.6), // 하단은 더 어두움
                    ],
                  ),
                ), // 어두운 투명 레이어
              ),
            ),

          ///상단 필터 위젯
          SafeArea(
            child: GestureDetector(
              onTap: () {
                showFilterModal(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.travel_explore_outlined,
                    color: shortPageWhite,
                    size: 26,
                  ),
                  Consumer<FilterProvider>(
                    builder: (providerContext, filterProvider, child) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        color: Colors.transparent,
                        child: Text(
                          '${filterProvider.orderNear == true ? 'Near Me' : filterProvider.filterRegion ?? 'All'} · ${filterProvider.filterCategory ?? 'All'} ',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: shortPageWhite,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          ///뒤로가기 버튼
          Positioned(
            left: MediaQuery.of(context).size.width * 0.05,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(5),
                  color: Colors.transparent,
                  child: Icon(
                    CupertinoIcons.back,
                    color: shortPageWhite,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),

          ///Options 버튼
          Positioned(
            right: MediaQuery.of(context).size.width * 0.05,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  showOptionsModal(context);
                },
                child: Container(
                  padding: EdgeInsets.all(5),
                  color: Colors.transparent,
                  child: Icon(Icons.more_vert, color: shortPageWhite, size: 32),
                ),
              ),
            ),
          ),

          ///우측 버튼 위젯
          Positioned(
            right: MediaQuery.of(context).size.width * 0.05,
            bottom: MediaQuery.of(context).size.height * 0.001,
            child: SafeArea(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ItemButton(
                    icon:
                        _isBookmarked
                            ? CupertinoIcons.bookmark_fill
                            : CupertinoIcons.bookmark,
                    value: _bookmarkCount.toString(),
                    action:
                        () => saveBookmarkInfo(
                          Provider.of<UserDataProvider>(
                            context,
                            listen: false,
                          ).currentUserUID,
                        ),
                  ),
                  // ItemButton(icon: CupertinoIcons.bubble_right, value: '32'),
                  // ItemButton(icon: CupertinoIcons.paperplane, value: 'Share'),
                  // ItemButton(icon: Icons.travel_explore_outlined, value: 'Map'),
                ],
              ),
            ),
          ),

          ///하단 정보 위젯
          Positioned(
            left: MediaQuery.of(context).size.width * 0.05,
            bottom: MediaQuery.of(context).size.height * 0.001,
            child: SafeArea(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.82,
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ///사진 + 이름 + More
                    Row(
                      children: [
                        ///사진 or 카테고리 아이콘
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: shortPageWhite,
                          child: Icon(
                            restaurantCategory,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 10),

                        ///이름
                        Flexible(
                          child: Text(
                            widget.storeName,
                            // '대왕암공원',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: shortPageWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 10),

                        ///More 버튼
                        GestureDetector(
                          onTap: () {
                            showInfoModal(context, 'ChIJydcugP6jfDUR0thfS3gHASk');
                          },
                          child: Container(
                            width: 70,
                            height: 30,
                            padding: EdgeInsets.only(bottom: 3),
                            child: Center(
                              child: Text(
                                'More',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: shortPageWhite,
                                ),
                              ),
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                width: 1.2,
                                color: shortPageWhite,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),

                    ///캡션
                    GestureDetector(
                      onTap:
                          () => setState(() {
                            _isExpanded = !_isExpanded;
                          }),
                      child: AnimatedContainer(
                        color: Colors.transparent,
                        padding: EdgeInsets.only(top: _isExpanded ? 5 : 0),
                        constraints: BoxConstraints(
                          maxHeight:
                              _isExpanded
                                  ? MediaQuery.of(context).size.height *
                                      (320 / 812)
                                  : 25,
                          minHeight:
                              _isExpanded
                                  ? MediaQuery.of(context).size.height *
                                      (100 / 812)
                                  : 25,
                        ),
                        duration: const Duration(milliseconds: 200),
                        child:
                            _isExpanded
                                ? SingleChildScrollView(
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    color: Colors.transparent,
                                    child: Text(
                                      widget.storeCaption,
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                            0.04,
                                        color: shortPageWhite,
                                      ),
                                    ),
                                  ),
                                )
                                : Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  color: Colors.transparent,
                                  child: Text(
                                    widget.storeCaption,
                                    // '대왕암 공원은 우리나라에서 울주군 간절곶과 함께 해가 가장 빨리 뜨는 대왕암이 있는 곳이다. 우리나라 동남단에서 동해 쪽으로 가장 뾰족하게 나온 부분의 끝 지점에 해당하는 대왕암공원은 동해의 길잡이를 하는 울기항로표지소로도 유명하다. ',
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                          0.04,
                                      color: shortPageWhite,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                      ),
                    ),
                    SizedBox(height: 5),

                    ///운영시간 + 별점 + 가격
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ///운영시간
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 18,
                                color: shortPageWhite,
                              ),
                              SizedBox(width: 5),
                              Text(
                                '${widget.openTime} ~ ${widget.closeTime}',
                                style: TextStyle(
                                  color: shortPageWhite,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.032,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.02,
                        ),

                        ///별점
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 18, color: shortPageWhite),
                              SizedBox(width: 5),
                              Text(
                                widget.rating.toString(),
                                style: TextStyle(
                                  color: shortPageWhite,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.032,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.02,
                        ),

                        ///가격
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.payments,
                                size: 18,
                                color: shortPageWhite,
                              ),
                              SizedBox(width: 5),
                              Text(
                                '\$${widget.averagePrice}~',
                                style: TextStyle(
                                  color: shortPageWhite,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.032,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  ///북마크 저장
  Future<void> saveBookmarkInfo(String? currentUserUid) async {
    // 로그인 되어있는 경우
    if (currentUserUid != null) {
      // 눌렀을 때 진동
      HapticFeedback.lightImpact();

      // 먼저 캐시에 저장
      SharedPreferences preferences = await SharedPreferences.getInstance();
      List<String> bookMarkList =
          preferences.getStringList('bookMarkList') ?? [];

      // 북마크되지 않은 영상의 경우
      if (!bookMarkList.contains(widget.videoId)) {
        bookMarkList.add(widget.videoId);

        // bookmarked를 True로 바꿔줘 색상을 채우고 현재 값에 +1 해줌
        setState(() {
          _isBookmarked = true;
          _bookmarkCount++;
        });

        // 캐시 업데이트
        await preferences.setStringList('bookMarkList', bookMarkList);

        try {
          // 서버에 저장
          await _supabase.from('bookmarks').insert({
            'user_id': currentUserUid,
            'location_id': widget.videoId,
            'category': widget.category,
            'bookmarked_at': DateTime.now().toIso8601String(),
          });

          // 저장 되었음을 표시해주는 스낵바 TODO ( UI 조정 필요 )
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.lightBlueAccent,
              content: Text('Successfully added bookmark'),
              action: SnackBarAction(
                label: 'Plan',
                textColor: Color(0xff121212),
                onPressed: () {
                  print('plan');
                },
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.06,
                left: 20.0,
                right: 20.0,
              ),
            ),
          );
        } catch (e) {
          // 예외가 발생하면 에러 메시지를 출력합니다. TODO 에러 처리 어떻게할지 고민
          print('Insert 에러: $e');
        }
      } else {
        // 북마크된 영상의 경우 캐시에서 삭제
        bookMarkList.remove(widget.videoId);

        // bookmarked를 false로 바꿔줘 색상을 비우고 현재 값에 -1 해줌
        setState(() {
          _isBookmarked = false;
          _bookmarkCount--;
        });

        // 캐시 업데이트
        await preferences.setStringList('bookMarkList', bookMarkList);

        try {
          // 서버에서 삭제
          await _supabase.from('bookmarks').delete().match({
            'user_id': currentUserUid,
            'location_id': widget.videoId,
          });
          // 삭제 되었음을 알려주는 스낵바 TODO ( UI 조정 필요 )
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.lightBlueAccent,
              content: Text('Successfully deleted bookmark'),
              action: SnackBarAction(
                label: 'Plan',
                textColor: Color(0xff121212),
                onPressed: () {
                  print('plan');
                },
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.06,
                left: 20.0,
                right: 20.0,
              ),
            ),
          );
        } catch (e) {
          // 에러 메세지 출력 TODO 에러 처리 어떻게할지 고민
          print('Delete 에러: $e');
        }
      }
    } else {
      // 로그인 되어있지 않은 경우엔 로그인하라는 스낵바 띄워줌 TODO ( UI 조정 필요 )
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.lightBlueAccent,
          content: Text('Login To Bookmark Location'),
          action: SnackBarAction(
            label: 'Login',
            textColor: Color(0xff121212),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.06,
            left: 20.0,
            right: 20.0,
          ),
        ),
      );
    }
  }

  ///현재 위치와 장소 위치간의 거리를 계산해서 소요시간 계산
  String calculateTimeRequired(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    double distanceInMeters = Geolocator.distanceBetween(
      lat1,
      lon1,
      lat2,
      lon2,
    );

    // 평균속도 30km/h (500미터/분)를 가정하여 소요 시간 계산
    int travelTimeMinutes = (distanceInMeters / 500).round();

    return travelTimeMinutes.toString();
  }

  ///TODO API KEY 숨겨야함
  String apiKey = "AIzaSyC0fC5Xjg33ZeaBChPXIK-ijjblzI4SnB4";

  // 1단계: 특정 장소의 사진들 중 맨 첫번째 사진의 name만 가져오는 함수
  Future<String> getFirstPhotoName(String placeId) async {
    final url = Uri.parse(
      'https://places.googleapis.com/v1/places/$placeId?fields=photos&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List photos = data['photos'] as List? ?? [];

      if (photos.isNotEmpty) {
        // 첫 번째 사진의 name을 반환
        return photos.first['name'] as String;
      } else {
        throw Exception('해당 장소에 사진이 없습니다.');
      }
    } else {
      throw Exception('장소의 사진을 가져오지 못했습니다.');
    }
  }

  // 2단계: name을 사용해 사진 URL(photoUri)을 얻는 함수
  Future<String> getPhotoUrl(
      String photoName, {
        int maxHeightPx = 400,
        int maxWidthPx = 400,
      }) async {
    final encodedPhotoName = Uri.encodeFull(photoName);
    final url = Uri.parse(
      'https://places.googleapis.com/v1/$encodedPhotoName/media'
          '?key=$apiKey&maxHeightPx=$maxHeightPx&maxWidthPx=$maxWidthPx&skipHttpRedirect=true',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['photoUri'] as String;
    } else {
      throw Exception('사진의 URL을 가져오지 못했습니다.');
    }
  }

  // 3단계: 장소의 첫 번째 사진 URL을 가져오는 함수
  Future<String> fetchFirstPhotoUrl(String placeId) async {
    try {
      // 첫 번째 사진의 name을 가져옴
      final firstPhotoName = await getFirstPhotoName(placeId);
      // 해당 name을 사용해 사진 URL을 가져옴
      final photoUrl = await getPhotoUrl(firstPhotoName);
      return photoUrl;
    } catch (e) {
      print(e);
      throw Exception('첫 번째 사진 URL을 가져오는 중 오류가 발생했습니다.');
    }
  }

  ///More 버튼을 누르면 나오는 ModalBottomSheet
  void showInfoModal(BuildContext context, String placeId) {
    // Future를 미리 변수에 담아 두면 동일한 Future 인스턴스를 재사용할 수 있습니다.
    final futurePhotos = fetchFirstPhotoUrl(placeId);
    final double? userLat = Provider.of<UserDataProvider>(context, listen: false).currentLat;
    final double? userLon = Provider.of<UserDataProvider>(context, listen: false).currentLon;
    final double? locationLat = widget.coordinates['lat'];
    final double? locationLon = widget.coordinates['lon'];

    showModalBottomSheet(
      backgroundColor: shortPageWhite,
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          maxChildSize: 0.9,
          initialChildSize: 0.37,
          minChildSize: 0.3699,
          expand: false,
          snap: true,
          snapSizes: const [0.38, 0.9],
          builder: (context, infoScrollController) {
            return SingleChildScrollView(
              controller: infoScrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    // 상단의 프로필 및 기본정보 Row (사진, 매장명, 카테고리, 시간 등)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FutureBuilder를 사용하여 첫 번째 사진을 CircleAvatar 이미지로 설정
                        FutureBuilder<String>(
                          future: futurePhotos,
                          builder: (context, snapshot) {
                            String imageUrl = 'https://placehold.co/400.png';

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.lightBlue,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: CircleAvatar(
                                    radius: 90,
                                    backgroundColor: Colors.black26,
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasData && snapshot.data!.isEmpty) {
                              return Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.lightBlue,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: CircleAvatar(
                                    radius: 90,
                                    backgroundColor: Colors.black26,
                                    child: Text('빔'),
                                  ),
                                ),
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              if (snapshot.hasData &&
                                  snapshot.data!.isNotEmpty) {
                                imageUrl = snapshot.data!;
                              }
                            }
                            return Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.lightBlue,
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: CircleAvatar(
                                  radius: 90,
                                  backgroundImage: NetworkImage(imageUrl),
                                  backgroundColor: shortPageWhite,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        // 텍스트 정보: 매장명, 카테고리, 평균 가격 등
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.storeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${widget.category} · \$${widget.averagePrice.round()}~',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.bus,
                                  color: Colors.black26,
                                  size: 18,
                                ),
                                Text(
                                  (locationLat != null && userLat != null && locationLon != null && userLon != null)
                                      ? ' ${calculateTimeRequired(userLat, userLon, locationLat, locationLon)}분 · ${widget.storeLocation}'
                                      : ' 30분 · ${widget.storeLocation}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.time,
                                  color: Colors.black26,
                                  size: 18,
                                ),
                                Text(
                                  ' ${widget.openTime} ~ ${widget.closeTime}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        // 공유, 닫기 버튼
                        GestureDetector(
                          onTap: (){
                            Share.share(
                              ///TODO 실제 영상 ID로 바꿔줘야함
                              'https://www.youtube.com/shorts/NscOnNp2x8M',
                              subject: widget.storeName,
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 15),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black12,
                            ),
                            child: const Icon(
                              CupertinoIcons.share,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: (){
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black12,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    // 버튼 Row (Call, Route, Save)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () async{
                            final Uri phoneUri = Uri(
                              scheme: 'tel',
                              path: '+82 10 5475 6096', //TODO : 전화번호 적용
                            );

                            if (await canLaunchUrl(phoneUri)) {
                            await launchUrl(phoneUri);
                            } else {
                            debugPrint('전화 걸기 실패');
                            }
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  CupertinoIcons.phone,
                                  color: Colors.black,
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async{
                            await launchUrl( ///TODO PlaceId 받아와서 넣어줘야함
                              Uri.parse('https://www.google.com/maps/dir/?api=1&origin=$userLat,$userLon&destination=${widget.storeName}&destination_place_id=ChIJq5SjCJKlfDURGqkGbzT21Y8&travelmode=transit'),
                              mode: LaunchMode.externalApplication
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.directions_car,
                                  color: Colors.black,
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Route',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: (){
                            Navigator.pop(context);
                            saveBookmarkInfo(Provider.of<UserDataProvider>(context, listen: false).currentUserUID);
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  CupertinoIcons.bookmark,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    // 사진 리스트: FutureBuilder로 모든 사진을 불러온 후, ListView로 좌우 스크롤 구현
                    // FutureBuilder<List<String>>(
                    //   future: futurePhotos,
                    //   builder: (context, snapshot) {
                    //     if (snapshot.connectionState ==
                    //         ConnectionState.waiting) {
                    //       return Row(
                    //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //         children: [
                    //           Container(
                    //             width: MediaQuery.of(context).size.width * 0.3,
                    //             height: MediaQuery.of(context).size.width * 0.3,
                    //             decoration: BoxDecoration(
                    //               color: Colors.black26,
                    //               borderRadius: BorderRadius.circular(8),
                    //             ),
                    //           ),
                    //           Container(
                    //             width: MediaQuery.of(context).size.width * 0.3,
                    //             height: MediaQuery.of(context).size.width * 0.3,
                    //             decoration: BoxDecoration(
                    //               color: Colors.black26,
                    //               borderRadius: BorderRadius.circular(8),
                    //             ),
                    //           ),
                    //           Container(
                    //             width: MediaQuery.of(context).size.width * 0.3,
                    //             height: MediaQuery.of(context).size.width * 0.3,
                    //             decoration: BoxDecoration(
                    //               color: Colors.black26,
                    //               borderRadius: BorderRadius.circular(8),
                    //             ),
                    //           ),
                    //         ],
                    //       );
                    //     } else if (snapshot.hasError ||
                    //         !snapshot.hasData ||
                    //         snapshot.data!.isEmpty) {
                    //       return SizedBox.shrink();
                    //     } else {
                    //       final photoUrls = snapshot.data!;
                    //       return SizedBox(
                    //         height: MediaQuery.of(context).size.width * 0.3,
                    //         child: ListView.builder(
                    //           scrollDirection: Axis.horizontal,
                    //           itemCount: photoUrls.length,
                    //           itemBuilder: (context, index) {
                    //             return Container(
                    //               margin: const EdgeInsets.symmetric(
                    //                 horizontal: 4,
                    //               ),
                    //               width: MediaQuery.of(context).size.width * 0.3,
                    //               height: MediaQuery.of(context).size.width * 0.3,
                    //               decoration: BoxDecoration(
                    //                 borderRadius: BorderRadius.circular(8),
                    //                 image: DecorationImage(
                    //                   image: NetworkImage(photoUrls[index]),
                    //                   fit: BoxFit.cover,
                    //                 ),
                    //               ),
                    //             );
                    //           },
                    //         ),
                    //       );
                    //     }
                    //   },
                    // ),
                    // const SizedBox(height: 25),
                    // 추가 정보 리스트 (주소, 전화번호, 웹사이트 등)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: shortPageWhite,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildListTile(
                            icon: Icons.location_on_outlined,
                            title: 'Address',
                            subtitle: '주소어쩌구저쩌구~~ \n누르면 구글맵 or 애플맵 or 자체화면',
                            onTap: () async {
                              await launchUrl( ///TODO PlaceId 받아와서 넣어줘야함
                              Uri.parse('https://www.google.com/maps/search/?api=1&query=${widget.storeName}&query_place_id=ChIJq5SjCJKlfDURGqkGbzT21Y8'),
                              mode: LaunchMode.externalApplication
                              );
                            },
                          ),
                          const Divider(height: 2),
                          _buildListTile(
                            icon: Icons.phone,
                            title: 'Call',
                            subtitle: '전화번호~~ \n누르면 전화걸어줌',
                            onTap: () async {
                              final Uri phoneUri = Uri(
                                scheme: 'tel',
                                path: '+82 10 5475 6096', //TODO : 전화번호 적용
                              );

                              if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                              } else {
                              debugPrint('전화 걸기 실패');
                              }
                            },
                          ),
                          const Divider(height: 2),
                          _buildListTile(
                            icon: Icons.language,
                            title: 'Visit Website',
                            subtitle: '웹사이트 있으면 \n누르면 웹사이트로 이동',
                            onTap: () async {
                              await launchUrl(Uri.parse('https://www.naver.com'), mode: LaunchMode.inAppBrowserView);
                            },
                          ),
                          const Divider(height: 2),
                          _buildListTile(
                            icon: Icons.flag,
                            title: 'Report',
                            onTap: () {
                              // TODO: 신고 기능 추가
                              showReportModal(context);
                            },
                          ),
                          const Divider(height: 2),
                          _buildListTile(
                            icon: Icons.verified_outlined,
                            title: 'I am owner of this place',
                            onTap: () async{
                              // TODO: 소유자 인증 기능 추가
                              await launchUrl(Uri.parse('https://forms.gle/Ji5br34NseKr8m1Q6'), mode: LaunchMode.inAppBrowserView);
                            },
                          ),
                        ],
                      ),
                    ),
                    // 추가 위젯들...
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  ///동영상을 꾹 눌렀을 때 나오는 옵션들이 있는 ModalBottomSheet
  void showOptionsModal(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.35,
          expand: false,
          builder:
              (context, optionScrollController) => SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  // physics: const ClampingScrollPhysics(),
                  controller: optionScrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            saveBookmarkInfo(
                              Provider.of<UserDataProvider>(
                                context,
                                listen: false,
                              ).currentUserUID,
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.only(top: 10, bottom: 20),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.bookmark, size: 24),
                                SizedBox(width: 20),
                                Text(
                                  'Bookmark',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: (){
                            Navigator.pop(context);
                            widget.pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              children: [
                                Icon(Icons.block, size: 24),
                                SizedBox(width: 20),
                                Text(
                                  'Not Interested',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: (){
                            showReportModal(context);
                          },
                          child: Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              children: [
                                Icon(Icons.flag_outlined, size: 24),
                                SizedBox(width: 20),
                                Text(
                                  'Report',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Share.share(
                              ///TODO 실제 영상 ID로 바꿔줘야함
                              'https://www.youtube.com/shorts/NscOnNp2x8M',
                              subject: widget.storeName,
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.paperplane, size: 24),
                                SizedBox(width: 20),
                                Text(
                                  'Share',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        );
      },
    );
  }

  ///영상 필터 ModalBottomSheet
  void showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      backgroundColor: Color(0xff121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter filterState) {
            return DraggableScrollableSheet(
              maxChildSize: 0.9,
              initialChildSize: 0.9,
              minChildSize: 0.9,
              expand: false,
              snap: false,
              builder: (context, filterScrollController) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: filterScrollController,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Region',
                                style: TextStyle(
                                  color: shortPageWhite,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 1.0,
                                children:
                                    regionOptions.map((region) {
                                      return ChoiceChip(
                                        selected: selectedRegion == region,
                                        label: Text(
                                          region,
                                          style: TextStyle(
                                            color:
                                                (selectedRegion == region)
                                                    ? Colors.black
                                                    : shortPageWhite,
                                          ),
                                        ),
                                        selectedColor: shortPageWhite,
                                        backgroundColor: Color(0xff222222),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        onSelected: (bool selected) {
                                          filterState(() {
                                            selectedRegion =
                                                selected ? region : null;
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),

                              Text(
                                'Category',
                                style: TextStyle(
                                  color: shortPageWhite,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 1.0,
                                children:
                                    categoryOptions.map((category) {
                                      return ChoiceChip(
                                        selected: selectedCategory == category,
                                        label: Text(
                                          category,
                                          style: TextStyle(
                                            color:
                                                (selectedCategory == category)
                                                    ? Colors.black
                                                    : shortPageWhite,
                                          ),
                                        ),
                                        selectedColor: shortPageWhite,
                                        backgroundColor: Color(0xff222222),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        onSelected: (bool selected) {
                                          filterState(() {
                                            selectedCategory =
                                                selected ? category : null;
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              Text(
                                'Average Price',
                                style: TextStyle(
                                  color: shortPageWhite,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 1.0,
                                children:
                                    priceOptions.map((price) {
                                      return ChoiceChip(
                                        selected: selectedPrice == price,
                                        label: Text(
                                          price,
                                          style: TextStyle(
                                            color:
                                                (selectedPrice == price)
                                                    ? Colors.black
                                                    : shortPageWhite,
                                          ),
                                        ),
                                        selectedColor: shortPageWhite,
                                        backgroundColor: Color(0xff222222),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        onSelected: (bool selected) {
                                          filterState(() {
                                            selectedPrice =
                                                selected ? price : null;
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                              // Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Consumer<FilterProvider>(
                        builder: (
                          filterProviderContext,
                          filterProvider,
                          child,
                        ) {
                          return GestureDetector(
                            onTap: () async {
                              if (selectedRegion == 'Near Me') {
                                await filterProvider.setAroundVideoCategory(
                                  context,
                                  (selectedCategory == 'All')
                                      ? null
                                      : selectedCategory,
                                );
                                await Provider.of<UserDataProvider>(
                                  context,
                                  listen: false,
                                ).setCurrentLocation(
                                  filterProvider.filterLat,
                                  filterProvider.filterLon,
                                );
                              } else {
                                filterProvider.setBasicVideoCategory(
                                  (selectedRegion == 'All')
                                      ? null
                                      : selectedRegion,
                                  (selectedCategory == 'All')
                                      ? null
                                      : selectedCategory,
                                );
                              }

                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              width: MediaQuery.of(context).size.width * 0.8,
                              decoration: BoxDecoration(
                                color: Color(0xff309053),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Update Filter',
                                  style: TextStyle(
                                    color: shortPageWhite,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  ///신고 모달 TODO 실제신고기능추가필요
  void showReportModal(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.25,
          minChildSize: 0.25,
          expand: false,
          builder:
              (context, reportScrollController) => SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              // physics: const ClampingScrollPhysics(),
              controller: reportScrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        color: Colors.transparent,
                        padding: EdgeInsets.only(top: 10, bottom: 20),
                        child: Text(
                          'Out of service',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.red
                          ),
                        ),
                      ),
                    ),
                    Divider(),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        color: Colors.transparent,
                        padding: EdgeInsets.only(top: 10, bottom: 20),
                        child: Text(
                          'Inappropriate content',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.red
                          ),
                        ),
                      ),
                    ),
                    Divider(),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        color: Colors.transparent,
                        padding: EdgeInsets.only(top: 10, bottom: 20),
                        child: Text(
                          'Incorrect information',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.red
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ///More modal의 타일 위젯
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle:
          subtitle != null
              ? Text(subtitle, style: TextStyle(fontSize: 15))
              : null,
      trailing: const Icon(Icons.chevron_right, size: 26),
      onTap: onTap,
    );
  }

  ///우측 버튼들
  Widget ItemButton({
    IconData icon = Icons.bookmark,
    String? value,
    VoidCallback? action,
  }) {
    return GestureDetector(
      onTap: () {
        if (action != null) {
          action();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: EdgeInsets.only(right: 5),
        color: Colors.transparent,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                // 배경을 투명하게 두되, 가운데부터 투명해지는 RadialGradient 적용
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.3), // 중앙이 좀 더 어두운 영역
                    Colors.transparent, // 가장자리로 갈수록 투명
                  ],
                  center: Alignment.center,
                  radius: 0.6, // 0 ~ 1 사이에서 조절 (값을 높이면 더 넓게 퍼짐)
                ),
              ),
              child: Icon(icon, size: 40, color: shortPageWhite),
            ),
            const SizedBox(height: 5),
            if (value != null)
              Container(
                decoration: BoxDecoration(
                  // 배경을 투명하게 두되, 가운데부터 투명해지는 RadialGradient 적용
                  gradient: RadialGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.3), // 중앙이 좀 더 어두운 영역
                      Colors.transparent, // 가장자리로 갈수록 투명
                    ],
                    center: Alignment.center,
                    radius: 0.6, // 0 ~ 1 사이에서 조절 (값을 높이면 더 넓게 퍼짐)
                  ),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: shortPageWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
