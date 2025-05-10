import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shortsmap/Provider/UserDataProvider.dart';
import 'package:shortsmap/Widgets/Modal/ShareModal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class MapShortsPage extends StatefulWidget {
  final String placeName;
  final String placeId;
  final String videoId;
  final String storeCaption;
  final String storeLocation;
  final String openTime;
  final String closeTime;
  final double rating;
  final String category;
  final double averagePrice;
  final String address;
  final String naverMapLink;
  final Map<String, double> coordinates;
  final String? imageUrl;
  final String? phoneNumber;
  final String? website;


  const MapShortsPage({
    super.key,
    required this.placeName,
    required this.placeId,
    required this.videoId,
    required this.storeCaption,
    required this.storeLocation,
    required this.openTime,
    required this.closeTime,
    required this.rating,
    required this.category,
    required this.averagePrice,
    required this.imageUrl,
    required this.coordinates,
    required this.phoneNumber,
    required this.website,
    required this.address,
    required this.naverMapLink,
  });

  @override
  State<MapShortsPage> createState() => _MapShortsPageState();
}

class _MapShortsPageState extends State<MapShortsPage> {
  late YoutubePlayerController _controller;
  IconData _currentIcon = Icons.pause;
  double _pauseIconOpacity = 0.0;
  Color shortPageWhite = Colors.grey[200] as Color;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
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

    _controller.loadVideoById(videoId: widget.videoId);
  }

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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.black, // Color for Android
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Stack(
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
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.046,
                      ),
                      color: Colors.black,
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                SafeArea(
                                  child: YoutubeValueBuilder(
                                    controller: _controller,
                                    builder: (context, value) {
                                      if (value.playerState ==
                                          PlayerState.ended) {
                                        _controller.seekTo(seconds: 0);
                                        _controller.playVideo();
                                      }
                                      return IgnorePointer(
                                        child: FittedBox(
                                          fit: BoxFit.cover,
                                          child: Container(
                                            // 원래 영상의 비율을 유지하는 크기 지정 (9:16)
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.89,
                                            height:
                                                (MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.89) *
                                                (16 / 9),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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

                                ///정지/재개 아이콘
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 150.0),
                                  child: Center(
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
                                ),
                              ],
                            ),
                          ),
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

                ///뒤로가기 버튼
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.01,
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
                  right: MediaQuery.of(context).size.width * 0.01,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: () {
                        showOptionsModal(context);
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

                ///하단 정보 위젯
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.02,
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
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: shortPageWhite,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: widget.imageUrl == null ? null : NetworkImage(widget.imageUrl!),
                                  child: widget.imageUrl == null ? Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.black,
                                    size: 30,
                                  ) : null,
                                ),
                              ),
                              SizedBox(width: 10),

                              ///이름
                              Flexible(
                                child: GestureDetector(
                                  onTap: () async {
                                    final played = await _controller.currentTime;
                                    showInfoModal(context, widget.placeId, played.round());
                                  },
                                  child: Text(
                                    widget.placeName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: shortPageWhite,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),

                              ///More 버튼
                              GestureDetector(
                                onTap: () async {
                                  final played = await _controller.currentTime;
                                  showInfoModal(context, widget.placeId, played.round());
                                },
                                child: Container(
                                  width: 60,
                                  height: 30,
                                  // padding: EdgeInsets.only(bottom: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      width: 1.2,
                                      color: shortPageWhite,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '더보기',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: shortPageWhite,
                                      ),
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
                              padding: EdgeInsets.only(
                                top: _isExpanded ? 5 : 0,
                              ),
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
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.8,
                                          color: Colors.transparent,
                                          child: Text(
                                            widget.storeCaption,
                                            style: TextStyle(
                                              fontSize:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.04,
                                              color: shortPageWhite,
                                            ),
                                          ),
                                        ),
                                      )
                                      : Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.8,
                                        color: Colors.transparent,
                                        child: Text(
                                          widget.storeCaption,
                                          style: TextStyle(
                                            fontSize:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
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
                                            MediaQuery.of(context).size.width *
                                            0.032,
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
                                    Icon(
                                      Icons.star,
                                      size: 18,
                                      color: shortPageWhite,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      widget.rating.toString(),
                                      style: TextStyle(
                                        color: shortPageWhite,
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                            0.032,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.02,
                              ),

                              ///가격
                              // Container(
                              //   padding: EdgeInsets.symmetric(
                              //     vertical: 2,
                              //     horizontal: 8,
                              //   ),
                              //   decoration: BoxDecoration(
                              //     color: Colors.black.withValues(alpha: 0.2),
                              //     borderRadius: BorderRadius.circular(12),
                              //     border: Border.all(
                              //       color: Colors.white.withValues(alpha: 0.3),
                              //       width: 0.5,
                              //     ),
                              //   ),
                              //   child: Row(
                              //     children: [
                              //       Icon(
                              //         Icons.payments,
                              //         size: 18,
                              //         color: shortPageWhite,
                              //       ),
                              //       SizedBox(width: 5),
                              //       Text(
                              //         '\$${widget.averagePrice}~',
                              //         style: TextStyle(
                              //           color: shortPageWhite,
                              //           fontSize:
                              //               MediaQuery.of(context).size.width *
                              //               0.032,
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),

                              ///거리
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 2,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(50), // withValues → withAlpha
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(80),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.location_solid,
                                      size: 18,
                                      color: shortPageWhite,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      (() {
                                        final userLat =
                                            Provider.of<UserDataProvider>(context, listen: false).currentLat;
                                        final userLon =
                                            Provider.of<UserDataProvider>(context, listen: false).currentLon;
                                        final targetLat = widget.coordinates['lat'];
                                        final targetLon = widget.coordinates['lon'];

                                        if (userLat == null ||
                                            userLon == null ||
                                            targetLat == null ||
                                            targetLon == null) {
                                          return "???km";
                                        }

                                        return calculateDistanceTextInKm(
                                            userLat, userLon, targetLat, targetLon);
                                      })(),
                                      style: TextStyle(
                                        color: shortPageWhite,
                                        fontSize: MediaQuery.of(context).size.width * 0.032,
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
            ),
          ),
        ],
      ),
    );
  }

  ///More 버튼을 누르면 나오는 ModalBottomSheet
  void showInfoModal(BuildContext context, String placeId, int duration) {
    final double? userLat =
        Provider.of<UserDataProvider>(context, listen: false).currentLat;
    final double? userLon =
        Provider.of<UserDataProvider>(context, listen: false).currentLon;
    final double? locationLat = widget.coordinates['lat'];
    final double? locationLon = widget.coordinates['lon'];


    FirebaseAnalytics.instance.logEvent(
      name: "show_info_modal",
      parameters: {
        "video_id": widget.videoId,
        "watch_duration": _controller.currentTime
      },
    );

    showModalBottomSheet(
      backgroundColor: shortPageWhite,
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      // showDragHandle: true,
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
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // 상단의 프로필 및 기본정보 Row (사진, 매장명, 카테고리, 시간 등)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
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
                              backgroundColor: Colors.black12,
                              backgroundImage: widget.imageUrl == null ? null : NetworkImage(widget.imageUrl!),
                              child: widget.imageUrl == null ? Icon(
                                Icons.location_on_outlined,
                                color: Colors.black,
                                size: 30,
                              ) : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 텍스트 정보: 매장명, 카테고리, 평균 가격 등
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.placeName,
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
                                  (locationLat != null &&
                                          userLat != null &&
                                          locationLon != null &&
                                          userLon != null)
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
                          onTap: () {
                            /// TODO: 네이버 맵 링크 받아와서 넣어주기
                            showShareModal(context, widget.placeName, widget.videoId, 'https://map.naver.com/p/entry/place/1481312779');
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
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
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
                          onTap: () async {
                            final Uri phoneUri = Uri(
                              scheme: 'tel',
                              path: widget.phoneNumber, //TODO : 전화번호 적용
                            );

                            FirebaseAnalytics.instance.logEvent(
                              name: "tap_call",
                              parameters: {
                                "video_id": widget.videoId,
                              },
                            );

                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('지정된 전화번호가 없습니다.'),
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.only(
                                    bottom: MediaQuery.of(context).size.height * 0.06,
                                    left: 20.0,
                                    right: 20.0,
                                  ),
                                ),
                              );
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
                                  '전화걸기',
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
                          onTap: () async {

                            FirebaseAnalytics.instance.logEvent(
                              name: "tap_route",
                              parameters: {
                                "video_id": widget.videoId,
                              },
                            );

                            String deepRouteUrl = 'nmap://route/public?slat=$userLat&slng=$userLon&sname=내위치&dlat=${widget.coordinates['lat']}&dlng=${widget.coordinates['lon']}&dname=${widget.placeName}&appname=com.hwsoft.shortsmap';

                            String webRouteUrl = 'http://m.map.naver.com/route.nhn?menu=route&sname=내위치&sx=$userLon&sy=$userLat&ename=${widget.placeName}&ex=${widget.coordinates['lon']}&ey=${widget.coordinates['lat']}&pathType=1&showMap=true';


                            if (await canLaunchUrl(Uri.parse(deepRouteUrl))){
                              await launchUrl(
                                Uri.parse(deepRouteUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              await launchUrl(
                                Uri.parse(webRouteUrl),
                                mode: LaunchMode.externalApplication,
                              );
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
                                  CupertinoIcons.car,
                                  color: Colors.black,
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '길찾기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        /// 북마크 삭제 버튼 넣기?
                        // GestureDetector(
                        //   onTap: (){
                        //     Navigator.pop(context);
                        //     saveBookmarkInfo(Provider.of<UserDataProvider>(context, listen: false).currentUserUID);
                        //   },
                        //   child: Container(
                        //     width: MediaQuery.of(context).size.width * 0.3,
                        //     padding: const EdgeInsets.symmetric(vertical: 6),
                        //     decoration: BoxDecoration(
                        //       color: Colors.lightBlue,
                        //       borderRadius: BorderRadius.circular(20),
                        //     ),
                        //     child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: const [
                        //         Icon(
                        //           CupertinoIcons.bookmark,
                        //           color: Colors.white,
                        //           size: 22,
                        //         ),
                        //         SizedBox(width: 8),
                        //         Text(
                        //           'Save',
                        //           style: TextStyle(
                        //             fontSize: 16,
                        //             fontWeight: FontWeight.w500,
                        //             color: Colors.white,
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
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
                            subtitle: widget.address,
                            onTap: () async {

                              FirebaseAnalytics.instance.logEvent(
                                name: "tap_address",
                                parameters: {
                                  "video_id": widget.videoId,
                                },
                              );

                              /// TODO: 실제 링크 받아와서 넣어주기
                              /// TODO: 그냥 네이버 링크 받아와서 ID 분리해서 쓰기
                              String deepMapUrl = 'nmap://place?id=1481312779&appname=com.hwsoft.shortsmap';

                              String webMapUrl = 'https://map.naver.com/p/entry/place/1481312779';


                              if (await canLaunchUrl(Uri.parse(deepMapUrl))){
                                await launchUrl(
                                  Uri.parse(deepMapUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                await launchUrl(
                                  Uri.parse(webMapUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                          ),
                          if (widget.phoneNumber != null)
                            const Divider(height: 2),
                          if (widget.phoneNumber != null)
                            _buildListTile(
                              icon: Icons.phone,
                              title: 'Call',
                              subtitle: '눌러서 전화걸기',
                              onTap: () async {

                                FirebaseAnalytics.instance.logEvent(
                                  name: "tap_call",
                                  parameters: {
                                    "video_id": widget.videoId,
                                  },
                                );

                                final Uri phoneUri = Uri(
                                  scheme: 'tel',
                                  path: widget.phoneNumber,
                                );

                                if (await canLaunchUrl(phoneUri)) {
                                  await launchUrl(phoneUri);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('지정된 전화번호가 없습니다.'),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.only(
                                        bottom: MediaQuery.of(context).size.height * 0.06,
                                        left: 20.0,
                                        right: 20.0,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          if (widget.website != null)
                            const Divider(height: 2),
                          if (widget.website != null)
                            _buildListTile(
                              icon: Icons.language,
                              title: 'Visit Website',
                              subtitle: '웹사이트 방문하기',
                              onTap: () async {

                                FirebaseAnalytics.instance.logEvent(
                                  name: "tap_visit_website",
                                  parameters: {
                                    "video_id": widget.videoId,
                                  },
                                );

                                await launchUrl(
                                  Uri.parse(widget.website!),
                                  mode: LaunchMode.inAppBrowserView,
                                );
                              },
                            ),
                          const Divider(height: 2),
                          _buildListTile(
                            icon: Icons.flag,
                            title: '신고하기',
                            onTap: () {
                              showReportModal(context);
                            },
                          ),
                          const Divider(height: 2),
                          _buildListTile(
                            icon: Icons.verified_outlined,
                            title: '장소 소유자 인증하기',
                            onTap: () async {

                              FirebaseAnalytics.instance.logEvent(
                                name: "tap_place_owner",
                                parameters: {
                                  "video_id": widget.videoId,
                                },
                              );

                              await launchUrl(
                                Uri.parse(
                                  'https://forms.gle/yXcva654ddrWfWwYA',
                                ),
                                mode: LaunchMode.inAppBrowserView,
                              );
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
          initialChildSize: 0.2,
          minChildSize: 0.2,
          maxChildSize: 0.2,
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
                            /// TODO: 네이버 맵 링크 받아와서 넣어주기
                            showShareModal(context, widget.placeName, widget.videoId, 'https://map.naver.com/p/entry/place/1481312779');
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
          initialChildSize: 0.3,
          minChildSize: 0.3,
          maxChildSize: 0.3,
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
                            FirebaseAnalytics.instance.logEvent(
                              name: "report",
                              parameters: {
                                "video_id": widget.videoId,
                                "report_reason": 'out_of_service',
                              },
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            color: Colors.transparent,
                            padding: EdgeInsets.only(top: 10, bottom: 20),
                            child: Text(
                              '현재 운영하지 않는 장소에요',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        Divider(),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            FirebaseAnalytics.instance.logEvent(
                              name: "report",
                              parameters: {
                                "video_id": widget.videoId,
                                "report_reason": 'incorrect_information',
                              },
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            color: Colors.transparent,
                            padding: EdgeInsets.only(top: 10, bottom: 20),
                            child: Text(
                              '정보가 부정확해요',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        Divider(),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            FirebaseAnalytics.instance.logEvent(
                              name: "report",
                              parameters: {
                                "video_id": widget.videoId,
                                "report_reason": 'inappropriate_content',
                              },
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            color: Colors.transparent,
                            padding: EdgeInsets.only(top: 10, bottom: 20),
                            child: Text(
                              '컨텐츠가 부적절해요',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        Divider(),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            FirebaseAnalytics.instance.logEvent(
                              name: "report",
                              parameters: {
                                "video_id": widget.videoId,
                                "report_reason": 'video_not_working',
                              },
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            color: Colors.transparent,
                            padding: EdgeInsets.only(top: 10, bottom: 20),
                            child: Text(
                              '동영상 재생이 안돼요',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.red,
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

  /// 현재 위치와 장소 위치 간의 거리를 km 단위 문자열로 반환 ("2.34 km" 형식)
  String calculateDistanceTextInKm(
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

    double distanceInKm = distanceInMeters / 1000;
    return "${distanceInKm.toStringAsFixed(2)} km";
  }

  void showShareModal(BuildContext context, String placeName, String videoId, String naverMapLink) {
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
        return ShareModal(
          placeName: placeName,
          videoId: videoId,
          source: 'MapShorts',
          naverMapLink: naverMapLink,
        );
      },
    );
  }

}
