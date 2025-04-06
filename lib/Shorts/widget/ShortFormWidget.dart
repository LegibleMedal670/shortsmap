import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortsmap/Shorts/provider/FilterProvider.dart';
import 'package:shortsmap/UserDataProvider.dart';
import 'package:shortsmap/Welcome/LoginPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  /// Supabase client
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

      _controller.loadVideoById(videoId: 'VxVo4cRxYTM');

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

  void getBookmarkInfoFromCache() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    List<String> bookMarkList = preferences.getStringList('bookMarkList') ?? [];

    setState(() {
      _isBookmarked = bookMarkList.contains(widget.videoId);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                onTap: (){
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
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              // color: Color(0xff121212),
              color: Colors.black,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          top: 115,
                          child: YoutubeValueBuilder(
                            controller: _controller,
                            builder: (context, value) {
                              // _checkAndRestart(value);
                              if (value.playerState == PlayerState.ended) {
                                _controller.seekTo(seconds: 0);
                                _controller.playVideo();
                              }
                              return IgnorePointer(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: Container(
                                    // 원래 영상의 비율을 유지하는 크기 지정 (9:16)
                                    width: MediaQuery.of(context).size.width * 0.89,
                                    height: (MediaQuery.of(context).size.width * 0.89) * (16 / 9),
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
                onTap: (){
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

          ///More 버튼
          Positioned(
            right: MediaQuery.of(context).size.width * 0.05,
            child: SafeArea(
              child: GestureDetector(
                onTap: (){
                  showInfoModal(context);
                },
                child: Container(
                  padding: EdgeInsets.all(5),
                  color: Colors.transparent,
                  child: Icon(
                    Icons.more_vert,
                    color: shortPageWhite,
                    size: 32,
                  ),
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
                            showInfoModal(context);
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
                                  width: MediaQuery.of(context).size.width * 0.8,
                                  color: Colors.transparent,
                                  child: Text(
                                    widget.storeCaption,
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
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),

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
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),

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

  void showLocationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return Container();
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
          initialChildSize: 0.4,
          minChildSize: 0.3999,
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
                          child: Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              children: [
                                Icon(Icons.closed_caption, size: 24),
                                SizedBox(width: 20),
                                Text(
                                  'Subtitle',
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

  ///More 버튼을 누르면 나오는 ModalBottomSheet
  void showInfoModal(BuildContext context) {
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
          maxChildSize: 0.9,
          initialChildSize: 0.4,
          minChildSize: 0.3999,
          expand: false,
          snap: true,
          snapSizes: const [0.4, 0.9],
          builder:
              (context, infoScrollController) => SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  // physics: const ClampingScrollPhysics(),
                  controller: infoScrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.storeName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(width: 15),
                            Text(
                              '음식점유형',
                              style: TextStyle(color: Colors.black54),
                            ),
                            SizedBox(width: 15),
                            // Text('${Geolocator.distanceBetween(Provider.of<UserDataProvider>(context, listen: false,).currentLon!, Provider.of<UserDataProvider>(context, listen: false,).currentLat!, widget.storeLocation,)}', style: TextStyle(color: Colors.black54)),
                            Spacer(),
                            Container(
                              margin: EdgeInsets.only(right: 10),
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 0.5,
                                ),
                              ),
                              child: Text('북마크'),
                            ),
                          ],
                        ),
                        SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.28,
                              height: MediaQuery.of(context).size.width * 0.28,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.28,
                              height: MediaQuery.of(context).size.width * 0.28,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.28,
                              height: MediaQuery.of(context).size.width * 0.28,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 25),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        SizedBox(height: 15),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        SizedBox(height: 15),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ),
        );
      },
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
        padding: const EdgeInsets.symmetric(vertical: 14,),
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
