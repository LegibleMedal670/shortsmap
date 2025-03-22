import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ShortFormWidget extends StatefulWidget {
  final String storeName;
  final String videoURL;
  final String storeCaption;
  final String storeLocation;
  final String sourceURL;
  final String openTime;
  final String closeTime;
  final double rating;
  final String category;
  final int averagePrice;
  final int index;

  const ShortFormWidget({
    required this.storeName,
    required this.videoURL,
    required this.storeCaption,
    required this.storeLocation,
    required this.sourceURL,
    required this.openTime,
    required this.closeTime,
    required this.rating,
    required this.category,
    required this.averagePrice,
    required this.index,
    super.key,
  });

  @override
  State<ShortFormWidget> createState() => _ShortFormWidgetState();
}

class _ShortFormWidgetState extends State<ShortFormWidget> {
  late VideoPlayerController _playerController;
  IconData _currentIcon = Icons.pause;
  double _iconOpacity = 0.0;
  IconData restaurantCategory = Icons.restaurant_outlined;
  bool _isExpanded = false;

  Color shortPageWhite = Colors.grey[200] as Color;

  @override
  void initState() {
    super.initState();
    getRestaurantCategory(widget.category);
    _playerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoURL),
      )
      ..initialize().then((value) {
        _playerController.setLooping(true);

        // Future.delayed(const Duration(milliseconds: 500), () {
        //   _playerController.play();
        // });

        ///다음 영상 넘어갈 때 사운드가 겹쳐서 넣어준 딜레이
        ///추후에 중간 이상 넘어가면 기존 영상을 멈추고 다음 영상을 재생하는 방식 적용해야함
        ///음...
        // 0.5초 후 비디오 재생
        // if (widget.index == 0) {
        //   Future.delayed(const Duration(milliseconds: 500), () {
        //     _playerController.play();
        //   });
        // } else {
        //   Future.delayed(const Duration(milliseconds: 700), () {
        //     _playerController.play();
        //   });
        // }
      });
  }

  @override
  void dispose() {
    // _logData();
    _playerController.dispose();
    super.dispose();
  }

  ///stop + resume
  void _toggleVideo() {
    final wasPlaying = _playerController.value.isPlaying;
    setState(() {
      _currentIcon = wasPlaying ? Icons.pause : Icons.play_arrow;
      _iconOpacity = 1.0;
    });

    if (wasPlaying) {
      _playerController.pause();
    } else {
      _playerController.play();
    }

    // 애니메이션 처리
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _iconOpacity = 0.0);
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ///동영상위젯 탭, 더블탭 액션
        GestureDetector(
          onTap: () {
            _toggleVideo();
          },
          // onDoubleTap: () {
          //   print('doubletap');
          // },
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.black,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_playerController),
                      ///위아래 위젯들 가시성을 위한 그림자
                      IgnorePointer(
                        child: Container(
                          // color: Colors.black.withOpacity(0.2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ), // 어두운 투명 레이어
                        ),
                      ),
                      ///정지/재개 아이콘
                      AnimatedOpacity(
                        opacity: _iconOpacity,
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
                    ],
                  ),
                ),
                VideoProgressIndicator(
                  _playerController,
                  padding: EdgeInsets.zero,
                  allowScrubbing: true, // 스크럽 허용
                  colors: const VideoProgressColors(
                    playedColor: Color.fromRGBO(220, 20, 60, 1),
                    // 재생된 부분 색상
                    bufferedColor: Colors.grey,
                    // 버퍼링된 부분 색상
                    backgroundColor: Colors.grey,
                  ),
                ),
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
        Positioned(
          child: SafeArea(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.travel_explore_outlined,
                    color: Colors.grey[200],
                    size: 26,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    color: Colors.transparent,
                    child: Text('Seoul · Food · \$10',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[200]
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
        ///우측 버튼 위젯
        Positioned(
          right: MediaQuery.of(context).size.width * 0.03,
          bottom: MediaQuery.of(context).size.height * 0.02,
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // GestureDetector(
              //   onTap: () {},
              //   child: Container(
              //     width: 55,
              //     height: 55,
              //     color: Colors.transparent,
              //     child: Icon(
              //       CupertinoIcons.bookmark,
              //       color: shortPageWhite,
              //       size: MediaQuery.of(context).size.height * (30 / 812),
              //     ),
              //   ),
              // ),
              // SizedBox(height: 20),
              // GestureDetector(
              //   onTap: () {},
              //   child: Container(
              //     width: 55,
              //     height: 55,
              //     color: Colors.transparent,
              //     child: Icon(
              //       CupertinoIcons.bubble_right,
              //       color: shortPageWhite,
              //       size: MediaQuery.of(context).size.height * (30 / 812),
              //     ),
              //   ),
              // ),
              // SizedBox(height: 20),
              // GestureDetector(
              //   onTap: () {},
              //   child: Container(
              //     width: 55,
              //     height: 55,
              //     color: Colors.transparent,
              //     child: Icon(
              //       CupertinoIcons.paperplane,
              //       color: shortPageWhite,
              //       size: MediaQuery.of(context).size.height * (30 / 812),
              //     ),
              //   ),
              // ),
              // SizedBox(height: 20),
              // GestureDetector(
              //   onTap: () {},
              //   child: Container(
              //     width: 55,
              //     height: 55,
              //     color: Colors.transparent,
              //     child: Icon(
              //       Icons.more_horiz,
              //       color: shortPageWhite,
              //       size: MediaQuery.of(context).size.height * (30 / 812),
              //     ),
              //   ),
              // ),
              // SizedBox(height: 20),
              ItemButton(icon: CupertinoIcons.bookmark),
              // ItemButton(icon: CupertinoIcons.bubble_right),
              ItemButton(icon: CupertinoIcons.paperplane),
              ItemButton(icon: Icons.travel_explore_outlined),
            ],
          ),
        ),
        ///하단 정보 위젯
        Positioned(
          left: MediaQuery.of(context).size.width * 0.015,
          bottom: MediaQuery.of(context).size.height * 0.015,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.82,
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
                          border: Border.all(width: 1.2, color: shortPageWhite,),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                ///캡션
                GestureDetector(
                  onTap: () => setState(() {
                    _isExpanded = !_isExpanded;
                  }),
                  child: AnimatedContainer(
                    padding: EdgeInsets.only(top: _isExpanded ? 5 : 0),
                    constraints: BoxConstraints(
                      maxHeight: _isExpanded
                          ? MediaQuery.of(context).size.height * (320 / 812)
                          : 25,
                      minHeight: _isExpanded
                          ? MediaQuery.of(context).size.height * (100 / 812)
                          : 25,
                    ),
                    duration: const Duration(milliseconds: 200),
                    child: _isExpanded
                        ? SingleChildScrollView(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        color: Colors.transparent,
                        child: Text(
                          widget.storeCaption,
                          style: TextStyle(
                            fontSize:
                            MediaQuery.of(context).size.width * 0.04,
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
                          MediaQuery.of(context).size.width * 0.04,
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
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(243, 244, 246, 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 18, color: Colors.black),
                          SizedBox(width: 5),
                          Text(
                            '${widget.openTime} ~ ${widget.closeTime}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize:
                              MediaQuery.of(context).size.width * 0.035,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    ///별점
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(243, 244, 246, 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 18, color: Colors.black),
                          SizedBox(width: 5),
                          Text(
                            widget.rating.toString(),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize:
                              MediaQuery.of(context).size.width * 0.035,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    ///가격
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(243, 244, 246, 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.payments, size: 18, color: Colors.black),
                          SizedBox(width: 5),
                          Text(
                            '\$${widget.averagePrice}~',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize:
                              MediaQuery.of(context).size.width * 0.035,
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
      ],
    );
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

  ///More 버튼을 누르면 나오는 BottomModalSheet
  void showInfoModal(BuildContext context) {
    showModalBottomSheet(
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
              (context, scrollController) => SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  // physics: const ClampingScrollPhysics(),
                  controller: scrollController,
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
                            Text('거리', style: TextStyle(color: Colors.black54)),
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
  Widget ItemButton({IconData icon = Icons.bookmark, int? amount}) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, size: 40, color: shortPageWhite),
          SizedBox(height: 5),
          (amount != null)
              ? Text(
                amount.toString(),
                style: TextStyle(
                  color: shortPageWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
