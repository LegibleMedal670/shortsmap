import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shortsmap/Map/page/MapShortsPage.dart';
import 'package:shortsmap/Provider/MarkerProvider.dart';
import 'package:shortsmap/Provider/PhotoCacheServiceProvider.dart';
import 'package:shortsmap/Provider/UserSessionProvider.dart';
import 'package:shortsmap/Widgets/BottomNavBar.dart';
import 'package:shortsmap/Widgets/Modal/ShareModal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riv;

class MapPage extends riv.ConsumerStatefulWidget {
  final String? placeId;
  final String? videoId;
  final double? placeLat;
  final double? placeLng;

  const MapPage({
    super.key,
    this.placeId,
    this.videoId,
    this.placeLat,
    this.placeLng,
  });

  @override
  riv.ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends riv.ConsumerState<MapPage> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final ValueNotifier<double> _sheetExtent = ValueNotifier(0.1);

  late GoogleMapController _mapController;

  // 맵이 처음 생성되었을 때를 체크하기 위한 변수
  bool _isFirstLoad = true;

  // 카메라가 움직였을 때를 체크하기 위한 변수
  bool _isCameraIdle = true;

  double _widgetHeight = 0;

  final Map<String, Future<String>> _photoFutures = {};

  CameraPosition? _initialCameraPosition;

  Future<void> _moveToCurrentLocation() async {
    FirebaseAnalytics.instance.logEvent(name: "my_location_button_clicked");

    final position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        forceLocationManager: true,
        accuracy: LocationAccuracy.lowest,
      ),
    );
    final cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 18,
    );
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.placeId != null) {
      ref.read(markerDataProvider.notifier).setSelectedLocation =
          widget.placeId;
      ref.read(markerDataProvider.notifier).setSelectedVideoId = widget.videoId;

      _initialCameraPosition = CameraPosition(
        target: LatLng(widget.placeLat!, widget.placeLng!),
        zoom: 17.0,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _widgetHeight = MediaQuery.of(context).size.height;
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _sheetExtent.dispose();
    super.dispose();
  }

  /// URL에서 마지막 숫자(ID)만 꺼내는 함수
  String extractNaverPlaceId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';

    final segments = uri.pathSegments;
    final placeIndex = segments.indexOf('place');
    if (placeIndex != -1 && placeIndex + 1 < segments.length) {
      return segments[placeIndex + 1];
    }
    return '';
  }

  Future<void> openNaverMap(String webMapUrl) async {
    // 1) 웹 링크에서 ID 추출
    final placeId = extractNaverPlaceId(webMapUrl);

    // 2) placeId가 비어있지 않을 때만 딥링크 시도
    if (placeId.isNotEmpty) {
      final deepMapUrl =
          'nmap://place?id=$placeId&appname=com.hwsoft.shortsmap';
      if (await canLaunchUrl(Uri.parse(deepMapUrl))) {
        await launchUrl(
          Uri.parse(deepMapUrl),
          mode: LaunchMode.externalApplication,
        );
        return;
      }
    }

    // 3) placeId가 없거나(형식 불일치) 딥링크 실패 시 웹 URL 열기
    if (await canLaunchUrl(Uri.parse(webMapUrl))) {
      await launchUrl(
        Uri.parse(webMapUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Could not launch $webMapUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLat = ref.watch(
      userSessionProvider.select((user) => user.currentLat),
    );
    final userLon = ref.watch(
      userSessionProvider.select((user) => user.currentLon),
    );
    ref.watch(markerDataProvider);
    final markerProvider = ref.read(markerDataProvider.notifier);

    ref.listen<String?>(
      markerDataProvider.select((state) => state.selectedLocation),
      (prev, next) {
        if (prev == next || next == null) return;
        _sheetController.animateTo(
          0.55,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                /// 지도
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.white,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _sheetExtent,
                    builder: (valueContext, extent, _) {
                      final fabPos = extent * _widgetHeight;
                      final mapPadding =
                          extent <= 0.5
                              ? extent * _widgetHeight
                              : 0.5 * _widgetHeight;
                      final bottomPad =
                          (fabPos < 300) ? mapPadding : mapPadding - 20;

                      return GoogleMap(
                        padding: EdgeInsets.only(bottom: bottomPad),
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        onCameraIdle: () async {
                          if (_isFirstLoad) {
                            _isFirstLoad = false;
                            final bounds =
                                await _mapController.getVisibleRegion();
                            final result = await markerProvider
                                .loadLocationsInViewport(
                                  minLat: bounds.southwest.latitude,
                                  maxLat: bounds.northeast.latitude,
                                  minLng: bounds.southwest.longitude,
                                  maxLng: bounds.northeast.longitude,
                                );

                            if (!mounted) return;
                            if (result == MarkerLoadResult.viewportTooWide) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '지도를 더 확대해 주세요. 현재 범위가 너무 넓습니다.',
                                  ),
                                ),
                              );
                            }
                          }
                          setState(() {
                            _isCameraIdle = true;
                          });
                        },
                        onCameraMoveStarted: () {
                          if (markerProvider.isProgrammaticMove) {
                            markerProvider.setIsProgrammaticMove = false;
                            return;
                          }
                          _sheetController.animateTo(
                            0.05,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        onTap: (LatLng) {
                          _sheetController.animateTo(
                            0.05,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        initialCameraPosition:
                            _initialCameraPosition != null
                                ? _initialCameraPosition!
                                : userLat != null && userLon != null
                                ? CameraPosition(
                                  target: LatLng(userLat, userLon),
                                  zoom: 17.0,
                                )
                                : CameraPosition(
                                  target: LatLng(37.5563, 126.9220),
                                  zoom: 18.0,
                                ), // TODO 현재 위치로 설정해야함 맵을 킬 때의
                        markers: markerProvider.locationMarkers,

                        /// TODO: 마커 관리 방식 변경
                      );
                    },
                  ),
                ),

                /// 검색창, 위치검색
                ValueListenableBuilder(
                  valueListenable: _sheetExtent,
                  builder: (searchWidgetContext, extent, _) {
                    final fabPos = extent * _widgetHeight;

                    return Visibility(
                      visible:
                          ((markerProvider.selectedLocation == null) &&
                              fabPos < 700),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Container(
                                      // width: MediaQuery.of(context).size.width * 0.9,
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.055,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withValues(
                                              alpha: 0.5,
                                            ),
                                            spreadRadius: 3,
                                            blurRadius: 3,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.02,
                                          ),
                                          Icon(Icons.location_on_outlined),
                                          SizedBox(
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.02,
                                          ),
                                          Text(
                                            'Search Here!',
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.038,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      markerProvider.setBookmarkMode = true;
                                    },
                                    child: Container(
                                      width: 40,
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.055,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withValues(
                                              alpha: 0.5,
                                            ),
                                            spreadRadius: 3,
                                            blurRadius: 3,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(CupertinoIcons.bookmark),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Visibility(
                                visible:
                                    (_isFirstLoad != true && _isCameraIdle) ||
                                    markerProvider.isMarkerLoading,
                                child: ElevatedButton(
                                  child:
                                      markerProvider.isMarkerLoading
                                          ? CupertinoActivityIndicator()
                                          : Text('이 지역 탐색'),
                                  onPressed: () async {
                                    setState(() {
                                      _isCameraIdle = false;
                                    });
                                    final bounds =
                                        await _mapController.getVisibleRegion();
                                    final result = await markerProvider
                                        .loadLocationsInViewport(
                                          minLat: bounds.southwest.latitude,
                                          maxLat: bounds.northeast.latitude,
                                          minLng: bounds.southwest.longitude,
                                          maxLng: bounds.northeast.longitude,
                                        );

                                    if (!mounted) return;
                                    if (result ==
                                        MarkerLoadResult.viewportTooWide) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '지도를 더 확대해 주세요. 현재 범위가 너무 넓습니다.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                /// 내위치버튼
                ValueListenableBuilder(
                  valueListenable: _sheetExtent,
                  builder: (myLocationValueContext, extent, _) {
                    final fabPos = extent * _widgetHeight;
                    final bottom =
                        fabPos < 300
                            ? fabPos + 5
                            : fabPos < 500
                            ? fabPos - 20
                            : fabPos - 40;

                    return Visibility(
                      visible: fabPos < 700,
                      child: Positioned(
                        bottom: bottom,
                        left: 10,
                        child: Row(
                          children: [
                            Container(
                              color: Colors.transparent,
                              height: 45,
                              width: 45,
                              child: FittedBox(
                                child: FloatingActionButton(
                                  heroTag: UniqueKey().toString(),
                                  backgroundColor: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 2.0),
                                    child: const Icon(
                                      CupertinoIcons.paperplane_fill,
                                      color: Colors.black54,
                                      size: 28,
                                    ),
                                  ),
                                  onPressed: () {
                                    _moveToCurrentLocation();
                                    _sheetController.animateTo(
                                      0.05,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                ),
                              ),
                            ),
                            Container(
                              color: Colors.transparent,
                              height: 45,
                              width: MediaQuery.of(context).size.width - 55,
                              padding: EdgeInsets.only(left: 5),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children:
                                      markerProvider.availableCategories.map((
                                        category,
                                      ) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                            right: 4.0,
                                          ),
                                          child: ChoiceChip(
                                            selected:
                                                markerProvider
                                                    .selectedCategory ==
                                                category,
                                            label: Text(
                                              category,
                                              style: TextStyle(
                                                color:
                                                    (markerProvider
                                                                .selectedCategory ==
                                                            category)
                                                        ? Colors.black
                                                        : Colors.white,
                                              ),
                                            ),
                                            selectedColor: Colors.white,
                                            backgroundColor: Color(0xff222222),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            onSelected: (bool selected) async {
                                              final bounds =
                                                  await _mapController
                                                      .getVisibleRegion();

                                              final centerLat =
                                                  (bounds.southwest.latitude +
                                                      bounds
                                                          .northeast
                                                          .latitude) /
                                                  2;
                                              final centerLng =
                                                  (bounds.southwest.longitude +
                                                      bounds
                                                          .northeast
                                                          .longitude) /
                                                  2;

                                              markerProvider.selectCategory(
                                                selected ? category : null,
                                                centerLat,
                                                centerLng,
                                              );
                                            },
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                ///돌아가기버튼
                // Visibility(
                //   visible: _isListDetailOpened,
                //   child: Positioned(
                //     top: 70,
                //     left: 10,
                //     child: SizedBox(
                //       height: 45,
                //       width: 45,
                //       child: FittedBox(
                //         child: FloatingActionButton(
                //           heroTag: UniqueKey().toString(),
                //           backgroundColor: Colors.white,
                //           child: Padding(
                //             padding: const EdgeInsets.only(right: 2.0),
                //             child: const Icon(
                //               CupertinoIcons.back,
                //               color: Colors.black54,
                //               size: 32,
                //             ),
                //           ),
                //           onPressed: () {
                //             if (_selectedLocation != null) {
                //               // 상세 열려 있을 때
                //               setState(() {
                //                 _selectedLocation = null;
                //                 _selectedVideoId = null;
                //                 if (_selectedCategory == null) {
                //                   // 맵→상세 경로였으면 → 전체 카테고리 리스트로
                //                   _isListDetailOpened = false;
                //                   // _markers    = _allBookmarkMarkers;  /// TODO: 마커 관리 방식 변경
                //                 }
                //                 // (_selectedCategory != null 이면 → 카테고리→상세 경로)
                //                 //    _isListDetailOpened(true)와 필터된 _markers 유지
                //               });
                //
                //             } else if (_isListDetailOpened) {
                //               // 카테고리 리스트 화면에서 뒤로 → 전체 카테고리 뷰로
                //               setState(() {
                //                 _isListDetailOpened = false;
                //                 // _markers    = _allBookmarkMarkers;  /// TODO: 마커 관리 방식 변경
                //                 _selectedCategory   = null;
                //               });
                //             }
                //
                //             _sheetController.animateTo(0.4,
                //                 duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                //           },
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                ///더보기버튼
                Visibility(
                  visible:
                      markerProvider.selectedLocation != null &&
                      markerProvider.selectedVideoId != null,
                  child: Positioned(
                    top: 70,
                    right: 10,
                    child: SizedBox(
                      height: 50,
                      width: 50,
                      child: FittedBox(
                        child: FloatingActionButton(
                          heroTag: UniqueKey().toString(),
                          backgroundColor: Colors.white,
                          child: const Icon(
                            Icons.more_horiz,
                            color: Colors.black54,
                            size: 32,
                          ),
                          onPressed: () {
                            showCancelBookmarkModal(
                              context,
                              markerProvider.selectedVideoId!,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                /// 바텀시트
                Positioned(
                  bottom: 0,
                  top: 0,
                  child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      // 시트 크기 비율(extent)로 FAB 위치와 맵 패딩 실시간 조정
                      // final e = notification.extent;
                      // _fabPosition     = e * _widgetHeight;
                      // _mapBottomPadding = e <= 0.5
                      //     ? e * _widgetHeight
                      //     : 0.5 * _widgetHeight;
                      // setState(() {});
                      _sheetExtent.value = notification.extent;
                      return true;
                    },
                    child: DraggableScrollableSheet(
                      controller: _sheetController,
                      maxChildSize: 0.9,
                      initialChildSize: 0.1,
                      minChildSize: 0.1,
                      expand: false,
                      snap: true,
                      snapSizes: const [0.1, 0.4],
                      builder: (context, scrollController) {
                        return Container(
                          clipBehavior: Clip.hardEdge,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 8,
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            color: Colors.grey[200],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Stack(
                            children: [
                              /// 스크롤 가능한 전체 콘텐츠 영역
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight:
                                      MediaQuery.of(
                                        context,
                                      ).size.height, // 또는 원하는 최소 높이
                                ),
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  physics: const ClampingScrollPhysics(),
                                  child: Column(
                                    children: [
                                      // 헤더 공간만큼의 빈 공간(헤더는 오버레이로 표시됨)
                                      const SizedBox(height: 30),
                                      // 실제 스크롤 되는 콘텐츠
                                      markerProvider.selectedLocation != null
                                          ? FutureBuilder<Map<String, dynamic>>(
                                            future:
                                                markerProvider
                                                    .locationDetailFuture,
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Center(
                                                  child:
                                                      CupertinoActivityIndicator(),
                                                );
                                              }
                                              if (!snapshot.hasData ||
                                                  snapshot.data!.isEmpty) {
                                                print(snapshot.error);
                                                return const Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child: Text(
                                                    'No locations found.',
                                                  ),
                                                );
                                              }

                                              final placeData = snapshot.data!;
                                              final placeId =
                                                  placeData['place_id']
                                                      as String;

                                              return riv.Consumer(
                                                builder: (context, ref, child) {
                                                  // 1) photoFuture 메모이제이션
                                                  _photoFutures[placeId] ??= ref
                                                      .read(
                                                        photoCacheServiceProvider,
                                                      )
                                                      .getPhotoUrlForPlace(
                                                        placeId,
                                                      );
                                                  final photoFuture =
                                                      _photoFutures[placeId]!;

                                                  // 2) photoFuture 로 전체 상세 UI 감싸기
                                                  return FutureBuilder<String>(
                                                    future: photoFuture,
                                                    builder: (
                                                      context,
                                                      photoSnapshot,
                                                    ) {
                                                      final imageUrl =
                                                          photoSnapshot.data;
                                                      final isLoading =
                                                          photoSnapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting;
                                                      final isEmpty =
                                                          photoSnapshot
                                                              .hasData &&
                                                          photoSnapshot
                                                              .data!
                                                              .isEmpty;

                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 14.0,
                                                            ),
                                                        child: Column(
                                                          children: [
                                                            // --- 상단 Row (Avatar + 텍스트 + 공유 버튼) ---
                                                            Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                GestureDetector(
                                                                  onTap: () {
                                                                    FirebaseAnalytics.instance.logEvent(
                                                                      name:
                                                                          "tap_location_image",
                                                                      parameters: {
                                                                        "video_id":
                                                                            placeData['video_id'],
                                                                      },
                                                                    );

                                                                    Navigator.of(
                                                                      context,
                                                                      rootNavigator:
                                                                          true,
                                                                    ).push(
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (
                                                                              context,
                                                                            ) => MapShortsPage(
                                                                              placeName:
                                                                                  placeData['place_name'],
                                                                              placeId:
                                                                                  placeData['place_id'],
                                                                              videoId:
                                                                                  placeData['video_id'],
                                                                              storeCaption:
                                                                                  placeData['description'] ??
                                                                                  'descriptionNull',
                                                                              storeLocation:
                                                                                  placeData['region'],
                                                                              openTime:
                                                                                  placeData['open_time'] ??
                                                                                  '09:00',
                                                                              closeTime:
                                                                                  placeData['close_time'] ??
                                                                                  '20:00',
                                                                              rating:
                                                                                  placeData['rating'] ??
                                                                                  4.0,
                                                                              category:
                                                                                  placeData['category'],
                                                                              averagePrice:
                                                                                  placeData['average_price'] ==
                                                                                          null
                                                                                      ? 3
                                                                                      : placeData['average_price'].toDouble(),
                                                                              imageUrl:
                                                                                  imageUrl,
                                                                              coordinates: {
                                                                                'lat':
                                                                                    placeData['latitude'],
                                                                                'lon':
                                                                                    placeData['longitude'],
                                                                              },
                                                                              phoneNumber:
                                                                                  placeData['phone_number'],
                                                                              website:
                                                                                  placeData['website_link'],
                                                                              address:
                                                                                  placeData['address'],
                                                                              naverMapLink:
                                                                                  placeData['naver_map_link'],
                                                                            ),
                                                                      ),
                                                                    );
                                                                  },
                                                                  child: Container(
                                                                    width: 90,
                                                                    height: 90,
                                                                    decoration: BoxDecoration(
                                                                      shape:
                                                                          BoxShape
                                                                              .circle,
                                                                      border: Border.all(
                                                                        color:
                                                                            Colors.lightBlue,
                                                                        width:
                                                                            2,
                                                                      ),
                                                                    ),
                                                                    child: Padding(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            2.0,
                                                                          ),
                                                                      child: CircleAvatar(
                                                                        radius:
                                                                            90,
                                                                        backgroundImage:
                                                                            imageUrl ==
                                                                                    null
                                                                                ? null
                                                                                : NetworkImage(
                                                                                  imageUrl,
                                                                                ),
                                                                        backgroundColor:
                                                                            Colors.grey[300],
                                                                        child:
                                                                            imageUrl ==
                                                                                    null
                                                                                ? Icon(
                                                                                  Icons.location_on_outlined,
                                                                                  color:
                                                                                      Colors.black,
                                                                                  size:
                                                                                      30,
                                                                                )
                                                                                : null,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      placeData['place_name'],
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            MediaQuery.of(
                                                                              context,
                                                                            ).size.width *
                                                                            0.046,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            Colors.black,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 3,
                                                                    ),
                                                                    Text(
                                                                      placeData['category'],
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            MediaQuery.of(
                                                                              context,
                                                                            ).size.width *
                                                                            0.036,
                                                                        color:
                                                                            Colors.black54,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 3,
                                                                    ),
                                                                    Row(
                                                                      children: [
                                                                        Icon(
                                                                          CupertinoIcons
                                                                              .bus,
                                                                          color:
                                                                              Colors.black26,
                                                                          size:
                                                                              MediaQuery.of(
                                                                                context,
                                                                              ).size.width *
                                                                              0.045,
                                                                        ),
                                                                        Text(
                                                                          (placeData['latitude'] !=
                                                                                      null &&
                                                                                  userLat !=
                                                                                      null &&
                                                                                  placeData['longitude'] !=
                                                                                      null &&
                                                                                  userLon !=
                                                                                      null)
                                                                              ? ' ${calculateTimeRequired(userLat, userLon, placeData['latitude'], placeData['longitude'])}분 · ${placeData['region']}'
                                                                              : ' 30분 · ${placeData['region']}',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                MediaQuery.of(
                                                                                  context,
                                                                                ).size.width *
                                                                                0.036,
                                                                            color:
                                                                                Colors.black54,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 3,
                                                                    ),
                                                                    Row(
                                                                      children: [
                                                                        const Icon(
                                                                          CupertinoIcons
                                                                              .time,
                                                                          color:
                                                                              Colors.black26,
                                                                          size:
                                                                              18,
                                                                        ),
                                                                        Text(
                                                                          ' ${placeData['open_time'] ?? '09:00'} ~ ${placeData['close_time'] ?? '22:00'}',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                MediaQuery.of(
                                                                                  context,
                                                                                ).size.width *
                                                                                0.036,
                                                                            color:
                                                                                Colors.black54,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                                const Spacer(),
                                                                GestureDetector(
                                                                  onTap: () {
                                                                    showShareModal(
                                                                      context,
                                                                      placeData['place_name'],
                                                                      placeData['video_id'],
                                                                      placeData['naver_map_link'],
                                                                    );
                                                                  },
                                                                  child: Container(
                                                                    width: 40,
                                                                    height: 40,
                                                                    decoration: BoxDecoration(
                                                                      shape:
                                                                          BoxShape
                                                                              .circle,
                                                                      color:
                                                                          Colors
                                                                              .black12,
                                                                    ),
                                                                    child: const Icon(
                                                                      CupertinoIcons
                                                                          .share,
                                                                      size: 20,
                                                                      color:
                                                                          Colors
                                                                              .black,
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 8,
                                                                ),
                                                                GestureDetector(
                                                                  onTap: () {
                                                                    markerProvider
                                                                            .setSelectedLocation =
                                                                        null;
                                                                    markerProvider
                                                                            .setSelectedVideoId =
                                                                        null;
                                                                    _sheetController.animateTo(
                                                                      0.4,
                                                                      duration: const Duration(
                                                                        milliseconds:
                                                                            400,
                                                                      ),
                                                                      curve:
                                                                          Curves
                                                                              .easeInOut,
                                                                    );
                                                                  },
                                                                  child: Container(
                                                                    width: 40,
                                                                    height: 40,
                                                                    decoration: BoxDecoration(
                                                                      shape:
                                                                          BoxShape
                                                                              .circle,
                                                                      color:
                                                                          Colors
                                                                              .black12,
                                                                    ),
                                                                    child: const Icon(
                                                                      CupertinoIcons
                                                                          .xmark,
                                                                      size: 20,
                                                                      color:
                                                                          Colors
                                                                              .black,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),

                                                            const SizedBox(
                                                              height: 25,
                                                            ),

                                                            // --- 버튼 Row (Call, Route, Explore) ---
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                // Call
                                                                GestureDetector(
                                                                  onTap: () async {
                                                                    final Uri
                                                                    phoneUri = Uri(
                                                                      scheme:
                                                                          'tel',
                                                                      path:
                                                                          placeData['phone_number'],
                                                                    );

                                                                    FirebaseAnalytics.instance.logEvent(
                                                                      name:
                                                                          "tap_call",
                                                                      parameters: {
                                                                        "video_id":
                                                                            placeData['video_id'],
                                                                      },
                                                                    );

                                                                    if (await canLaunchUrl(
                                                                      phoneUri,
                                                                    )) {
                                                                      await launchUrl(
                                                                        phoneUri,
                                                                      );
                                                                    } else {
                                                                      ScaffoldMessenger.of(
                                                                        context,
                                                                      ).showSnackBar(
                                                                        SnackBar(
                                                                          duration: Duration(
                                                                            milliseconds:
                                                                                1500,
                                                                          ),
                                                                          content: Text(
                                                                            '지정된 전화번호가 없습니다.',
                                                                          ),
                                                                          behavior:
                                                                              SnackBarBehavior.floating,
                                                                          margin: EdgeInsets.only(
                                                                            bottom:
                                                                                MediaQuery.of(
                                                                                  context,
                                                                                ).size.height *
                                                                                0.06,
                                                                            left:
                                                                                20.0,
                                                                            right:
                                                                                20.0,
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                  child: Container(
                                                                    width:
                                                                        MediaQuery.of(
                                                                          context,
                                                                        ).size.width *
                                                                        0.3,
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              6,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color:
                                                                          Colors
                                                                              .black12,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            20,
                                                                          ),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: const [
                                                                        Icon(
                                                                          CupertinoIcons
                                                                              .phone,
                                                                          color:
                                                                              Colors.black,
                                                                          size:
                                                                              22,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              8,
                                                                        ),
                                                                        Text(
                                                                          '전화걸기',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                                // Route
                                                                GestureDetector(
                                                                  onTap: () async {
                                                                    FirebaseAnalytics.instance.logEvent(
                                                                      name:
                                                                          "tap_route",
                                                                      parameters: {
                                                                        "video_id":
                                                                            placeData['video_id'],
                                                                      },
                                                                    );

                                                                    String
                                                                    deepRouteUrl =
                                                                        'nmap://route/public?slat=$userLat&slng=$userLon&sname=내위치&dlat=${placeData['latitude']}&dlng=${placeData['longitude']}&dname=${placeData['place_name']}&appname=com.hwsoft.shortsmap';

                                                                    String
                                                                    webRouteUrl =
                                                                        'http://m.map.naver.com/route.nhn?menu=route&sname=내위치&sx=$userLon&sy=$userLat&ename=${placeData['place_name']}&ex=${placeData['longitude']}&ey=${placeData['latitude']}&pathType=1&showMap=true';

                                                                    if (await canLaunchUrl(
                                                                      Uri.parse(
                                                                        deepRouteUrl,
                                                                      ),
                                                                    )) {
                                                                      await launchUrl(
                                                                        Uri.parse(
                                                                          deepRouteUrl,
                                                                        ),
                                                                        mode:
                                                                            LaunchMode.externalApplication,
                                                                      );
                                                                    } else {
                                                                      await launchUrl(
                                                                        Uri.parse(
                                                                          webRouteUrl,
                                                                        ),
                                                                        mode:
                                                                            LaunchMode.externalApplication,
                                                                      );
                                                                    }
                                                                  },
                                                                  child: Container(
                                                                    width:
                                                                        MediaQuery.of(
                                                                          context,
                                                                        ).size.width *
                                                                        0.3,
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              6,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color:
                                                                          Colors
                                                                              .black12,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            20,
                                                                          ),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: const [
                                                                        Icon(
                                                                          CupertinoIcons
                                                                              .car,
                                                                          color:
                                                                              Colors.black,
                                                                          size:
                                                                              22,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              8,
                                                                        ),
                                                                        Text(
                                                                          '길찾기',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                                // Explore
                                                                GestureDetector(
                                                                  onTap: () {
                                                                    FirebaseAnalytics.instance.logEvent(
                                                                      name:
                                                                          "tap_explore",
                                                                      parameters: {
                                                                        "video_id":
                                                                            placeData['video_id'],
                                                                      },
                                                                    );

                                                                    Navigator.of(
                                                                      context,
                                                                      rootNavigator:
                                                                          true,
                                                                    ).push(
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (
                                                                              _,
                                                                            ) => MapShortsPage(
                                                                              placeName:
                                                                                  placeData['place_name'],
                                                                              placeId:
                                                                                  placeData['place_id'],
                                                                              videoId:
                                                                                  placeData['video_id'],
                                                                              storeCaption:
                                                                                  placeData['description'] ??
                                                                                  'descriptionNull',
                                                                              storeLocation:
                                                                                  placeData['region'],
                                                                              openTime:
                                                                                  placeData['open_time'] ??
                                                                                  '09:00',
                                                                              closeTime:
                                                                                  placeData['close_time'] ??
                                                                                  '20:00',
                                                                              rating:
                                                                                  placeData['rating'] ??
                                                                                  4.0,
                                                                              category:
                                                                                  placeData['category'],
                                                                              averagePrice:
                                                                                  placeData['average_price'] ==
                                                                                          null
                                                                                      ? 3
                                                                                      : placeData['average_price'].toDouble(),
                                                                              imageUrl:
                                                                                  imageUrl,
                                                                              coordinates: {
                                                                                'lat':
                                                                                    placeData['latitude'],
                                                                                'lon':
                                                                                    placeData['longitude'],
                                                                              },
                                                                              phoneNumber:
                                                                                  placeData['phone_number'],
                                                                              website:
                                                                                  placeData['website_link'],
                                                                              address:
                                                                                  placeData['address'],
                                                                              naverMapLink:
                                                                                  placeData['naver_map_link'],
                                                                            ),
                                                                      ),
                                                                    );
                                                                  },
                                                                  child: Container(
                                                                    width:
                                                                        MediaQuery.of(
                                                                          context,
                                                                        ).size.width *
                                                                        0.3,
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              6,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color:
                                                                          Colors
                                                                              .lightBlue,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            20,
                                                                          ),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: const [
                                                                        Icon(
                                                                          CupertinoIcons
                                                                              .play_arrow_solid,
                                                                          color:
                                                                              Colors.white,
                                                                          size:
                                                                              22,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              8,
                                                                        ),
                                                                        Text(
                                                                          '영상보기',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),

                                                            const SizedBox(
                                                              height: 25,
                                                            ),

                                                            // --- 추가 정보 리스트 ---
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical: 6,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    Colors
                                                                        .grey[200],
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                                boxShadow: const [
                                                                  BoxShadow(
                                                                    color:
                                                                        Colors
                                                                            .black12,
                                                                    blurRadius:
                                                                        4,
                                                                    offset:
                                                                        Offset(
                                                                          0,
                                                                          2,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Column(
                                                                children: [
                                                                  _buildListTile(
                                                                    icon:
                                                                        Icons
                                                                            .location_on_outlined,
                                                                    title:
                                                                        '네이버지도에서 보기',
                                                                    subtitle:
                                                                        placeData['address'],
                                                                    onTap: () async {
                                                                      FirebaseAnalytics.instance.logEvent(
                                                                        name:
                                                                            "tap_address",
                                                                        parameters: {
                                                                          "video_id":
                                                                              placeData['video_id'],
                                                                        },
                                                                      );

                                                                      openNaverMap(
                                                                        placeData['naver_map_link'],
                                                                      );
                                                                    },
                                                                  ),
                                                                  Divider(
                                                                    height: 2,
                                                                  ),
                                                                  _buildListTile(
                                                                    icon:
                                                                        Icons
                                                                            .event_available,
                                                                    title:
                                                                        '예약하러 가기',
                                                                    subtitle:
                                                                        '숙소·액티비티 예약',
                                                                    onTap: () async {
                                                                      FirebaseAnalytics.instance.logEvent(
                                                                        name:
                                                                            "tap_reservation",
                                                                        parameters: {
                                                                          "video_id":
                                                                              placeData['video_id'],
                                                                        },
                                                                      );

                                                                      // openNaverMap(widget.naverMapLink);

                                                                      /// 예약하러 가는 링크 열어주는 함수 만들어서 넣기
                                                                    },
                                                                  ),
                                                                  Divider(
                                                                    height: 2,
                                                                  ),
                                                                  _buildListTile(
                                                                    icon:
                                                                        Icons
                                                                            .description_outlined,
                                                                    title:
                                                                        '텍스트후기 보러가기',
                                                                    subtitle:
                                                                        '생생한 텍스트 후기',
                                                                    onTap: () async {
                                                                      FirebaseAnalytics.instance.logEvent(
                                                                        name:
                                                                            "tap_text_review",
                                                                        parameters: {
                                                                          "video_id":
                                                                              placeData['video_id'],
                                                                        },
                                                                      );

                                                                      // openNaverMap(widget.naverMapLink);

                                                                      /// 텍스트후기 보러가는 링크 열어주는 함수 만들어서 넣기
                                                                    },
                                                                  ),
                                                                  if (placeData['phone_number'] !=
                                                                      null)
                                                                    const Divider(
                                                                      height: 2,
                                                                    ),
                                                                  if (placeData['phone_number'] !=
                                                                      null)
                                                                    _buildListTile(
                                                                      icon:
                                                                          Icons
                                                                              .phone,
                                                                      title:
                                                                          '전화걸기',
                                                                      onTap: () async {
                                                                        FirebaseAnalytics.instance.logEvent(
                                                                          name:
                                                                              "tap_call",
                                                                          parameters: {
                                                                            "video_id":
                                                                                placeData['video_id'],
                                                                          },
                                                                        );

                                                                        final Uri
                                                                        phoneUri = Uri(
                                                                          scheme:
                                                                              'tel',
                                                                          path:
                                                                              placeData['phone_number'],
                                                                        );
                                                                        if (await canLaunchUrl(
                                                                          phoneUri,
                                                                        ))
                                                                          await launchUrl(
                                                                            phoneUri,
                                                                          );
                                                                      },
                                                                    ),
                                                                  if (placeData['website_link'] !=
                                                                      null)
                                                                    const Divider(
                                                                      height: 2,
                                                                    ),
                                                                  if (placeData['website_link'] !=
                                                                      null)
                                                                    _buildListTile(
                                                                      icon:
                                                                          Icons
                                                                              .language,
                                                                      title:
                                                                          '웹사이트 방문하기',
                                                                      onTap: () async {
                                                                        FirebaseAnalytics.instance.logEvent(
                                                                          name:
                                                                              "tap_visit_website",
                                                                          parameters: {
                                                                            "video_id":
                                                                                placeData['video_id'],
                                                                          },
                                                                        );

                                                                        await launchUrl(
                                                                          Uri.parse(
                                                                            placeData['website_link'],
                                                                          ),
                                                                          mode:
                                                                              LaunchMode.inAppBrowserView,
                                                                        );
                                                                      },
                                                                    ),
                                                                  const Divider(
                                                                    height: 2,
                                                                  ),
                                                                  _buildListTile(
                                                                    icon:
                                                                        Icons
                                                                            .flag,
                                                                    title:
                                                                        '신고하기',
                                                                    onTap: () {
                                                                      showReportModal(
                                                                        context,
                                                                        placeData['video_id'],
                                                                      );
                                                                    },
                                                                  ),
                                                                  const Divider(
                                                                    height: 2,
                                                                  ),
                                                                  _buildListTile(
                                                                    icon:
                                                                        Icons
                                                                            .verified_outlined,
                                                                    title:
                                                                        '장소 소유자 인증하기',
                                                                    onTap: () async {
                                                                      FirebaseAnalytics.instance.logEvent(
                                                                        name:
                                                                            "tap_place_owner",
                                                                        parameters: {
                                                                          "video_id":
                                                                              placeData['video_id'],
                                                                        },
                                                                      );

                                                                      await launchUrl(
                                                                        Uri.parse(
                                                                          'https://forms.gle/yXcva654ddrWfWwYA',
                                                                        ),
                                                                        mode:
                                                                            LaunchMode.inAppBrowserView,
                                                                      );
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              );
                                            },
                                          )
                                          : FutureBuilder<
                                            List<Map<String, dynamic>>
                                          >(
                                            future:
                                                markerProvider
                                                    .currentLocationsFuture,
                                            builder: (context, snapshot) {
                                              // TODO Skeleton이나 아예 흰화면으로 바꿔주기
                                              if (snapshot.connectionState ==
                                                      ConnectionState.waiting ||
                                                  markerProvider
                                                      .isMarkerLoading ||
                                                  markerProvider
                                                      .isCategoryChanging ||
                                                  snapshot.data == null) {
                                                return const Center(
                                                  child:
                                                      CupertinoActivityIndicator(),
                                                );
                                              }

                                              // TODO 비어있거나 에러일 때 보여줄 내용 넣기 ( 빈 화면일 일은 없을거임근데 )
                                              if (snapshot.hasError) {
                                                print(snapshot.error);
                                                return Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Something went wrong',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                      SizedBox(height: 30),
                                                      Text(
                                                        'Restart App',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }

                                              final places = snapshot.data!;

                                              if (places.isEmpty) {
                                                return Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        '장소가 없음',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                      SizedBox(height: 30),
                                                      Text(
                                                        '다른곳 탐색하세여',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }

                                              return Column(
                                                children: [
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 18,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 25,
                                                          backgroundColor:
                                                              Colors
                                                                  .lightBlueAccent,
                                                          child: Icon(
                                                            Icons.place,
                                                            color: Colors.white,
                                                            size: 30,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 15,
                                                        ),
                                                        Text(
                                                          '${markerProvider.currentLocationLength.toString()}개의 장소들',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.width *
                                                                0.055,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        Spacer(),

                                                        /// 추후에 폴더 공유 기능 생기면 다시 살리기
                                                        // Container(
                                                        //   width: 40,
                                                        //   height: 40,
                                                        //   decoration: BoxDecoration(
                                                        //     shape: BoxShape.circle,
                                                        //     color: Colors.black12,
                                                        //   ),
                                                        //   child: const Icon(
                                                        //     CupertinoIcons.share,
                                                        //     size: 20,
                                                        //     color: Colors.black,
                                                        //   ),
                                                        // ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 10,
                                                        ),
                                                    child: Divider(
                                                      color: Colors.grey[300],
                                                      height: 1.5,
                                                      thickness: 1,
                                                    ),
                                                  ),
                                                  // const SizedBox(
                                                  //   height: 10,
                                                  // ),
                                                  ListView.separated(
                                                    padding: EdgeInsets.zero,
                                                    shrinkWrap: true,
                                                    physics:
                                                        NeverScrollableScrollPhysics(),
                                                    itemCount: places.length,
                                                    separatorBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                            ),
                                                        child: Divider(
                                                          color:
                                                              Colors.grey[300],
                                                          height: 1.5,
                                                          thickness: 1,
                                                        ),
                                                      );
                                                    },
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      final p = places[index];

                                                      final placeId =
                                                          p['place_id'];

                                                      // _photoFutures[placeId] ??= Provider.of<PhotoCacheService>(context, listen: false).getPhotoUrlForPlace(placeId);

                                                      return riv.Consumer(
                                                        builder: (
                                                          context,
                                                          ref,
                                                          child,
                                                        ) {
                                                          _photoFutures[placeId] ??= ref
                                                              .read(
                                                                photoCacheServiceProvider,
                                                              )
                                                              .getPhotoUrlForPlace(
                                                                placeId,
                                                              );

                                                          return FutureBuilder<
                                                            String
                                                          >(
                                                            future:
                                                                _photoFutures[placeId],
                                                            builder: (
                                                              context,
                                                              photoSnapshot,
                                                            ) {
                                                              final imageUrl =
                                                                  photoSnapshot
                                                                      .data;

                                                              if (snapshot
                                                                      .connectionState ==
                                                                  ConnectionState
                                                                      .waiting) {
                                                                return _locationTile(
                                                                  true,
                                                                  placeId,
                                                                  imageUrl,
                                                                  p['place_name'] ??
                                                                      '',
                                                                  p['region'] ??
                                                                      '',
                                                                  p['open_time'] ??
                                                                      '09:00',
                                                                  p['close_time'] ??
                                                                      '22:00',
                                                                  (p['latitude']
                                                                          as num)
                                                                      .toDouble(),
                                                                  (p['longitude']
                                                                          as num)
                                                                      .toDouble(),
                                                                  p['video_id'] ??
                                                                      '',
                                                                  userLat,
                                                                  userLon,
                                                                );
                                                              }

                                                              if (!snapshot
                                                                      .hasData ||
                                                                  snapshot
                                                                      .data!
                                                                      .isEmpty) {
                                                                print(
                                                                  snapshot
                                                                      .error,
                                                                );
                                                              }

                                                              return _locationTile(
                                                                false,
                                                                placeId,
                                                                imageUrl,
                                                                p['place_name'] ??
                                                                    '',
                                                                p['region'] ??
                                                                    '',
                                                                p['open_time'] ??
                                                                    '09:00',
                                                                p['close_time'] ??
                                                                    '22:00',
                                                                (p['latitude']
                                                                        as num)
                                                                    .toDouble(),
                                                                (p['longitude']
                                                                        as num)
                                                                    .toDouble(),
                                                                p['video_id'] ??
                                                                    '',
                                                                userLat,
                                                                userLon,
                                                              );
                                                            },
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                    ],
                                  ),
                                ),
                              ),

                              /// dragHandle
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: IgnorePointer(
                                  child: Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[400],
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                      height: 4,
                                      width: 60,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          BottomNavBar(
            context,
            'map',
            canOpenMap:
                () => ref.read(userSessionProvider).currentUserUID != null,
          ),
        ],
      ),
    );
  }

  /// 장소 간략한 정보 있는 타일
  Widget _locationTile(
    bool isLoading,
    String locationId,
    String? imageUrl,
    String storeName,
    String region,
    String openTime,
    String closeTime,
    double lat,
    double lon,
    String videoId,
    double? userLat,
    double? userLon,
  ) {
    final markerProvider = ref.read(markerDataProvider.notifier);

    return GestureDetector(
      onTap: () {
        markerProvider.setIsProgrammaticMove = true;

        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(lat, lon), zoom: 18),
          ),
        );

        markerProvider.setSelectedLocation = locationId;
        markerProvider.setSelectedVideoId = videoId;

        FirebaseAnalytics.instance.logEvent(
          name: "tap_location_tile",
          parameters: {"video_id": videoId, "region": region},
        );

        _sheetController.animateTo(
          0.55,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 14),
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FutureBuilder를 사용하여 첫 번째 사진을 CircleAvatar 이미지로 설정
            if (imageUrl != null && isLoading != true)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.lightBlue, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: CircleAvatar(
                    radius: 90,
                    backgroundImage: NetworkImage(imageUrl),
                    backgroundColor: Colors.grey[200],
                  ),
                ),
              ),
            if (imageUrl == null && isLoading != true)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.lightBlue, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: CircleAvatar(
                    radius: 90,
                    // backgroundImage: NetworkImage(imageUrl),
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      Icons.location_on_outlined,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),
              ),
            if (isLoading == true)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.lightBlue, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: CircleAvatar(
                    radius: 90,
                    // backgroundImage: NetworkImage(imageUrl),
                    backgroundColor: Colors.grey[300],
                  ),
                ),
              ),
            const SizedBox(width: 15),
            // 텍스트 정보: 매장명, 카테고리, 평균 가격 등
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.046,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
                        (userLat != null && userLon != null)
                            ? ' ${calculateTimeRequired(userLat, userLon, lat, lon)}분 · $region'
                            : ' 30분 · $region',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.036,
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
                        ' $openTime ~ $closeTime',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.036,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                showCancelBookmarkModal(context, videoId);
              },
              child: Icon(Icons.more_horiz),
            ),
          ],
        ),
      ),
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

    return (travelTimeMinutes * 2).toString();
  }

  /// 신고, 위치, 웹사이트 등 옵션 타일
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                ),
              )
              : null,
      trailing: const Icon(Icons.chevron_right, size: 26),
      onTap: onTap,
    );
  }

  ///신고 모달 TODO 실제신고기능추가필요
  void showReportModal(BuildContext context, String videoId) {
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
          maxChildSize: 0.25,
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
                                "video_id": videoId,
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
                                "video_id": videoId,
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
                                "video_id": videoId,
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
                      ],
                    ),
                  ),
                ),
              ),
        );
      },
    );
  }

  ///북마크 삭제 모달
  void showCancelBookmarkModal(BuildContext context, String videoId) {
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
          initialChildSize: 0.1,
          minChildSize: 0.1,
          maxChildSize: 0.1,
          expand: false,
          builder:
              (context, cancelBookmarkScrollController) => SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  // physics: const ClampingScrollPhysics(),
                  controller: cancelBookmarkScrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          /// TODO: 마커 관리 방식 변경
                          // onTap: () async {
                          //   Navigator.pop(context);
                          //   final currentUserUID = Provider.of<UserDataProvider>(context, listen: false).currentUserUID!;
                          //
                          //   try {
                          //     // Supabase DB에서 북마크 삭제
                          //     await Supabase.instance.client.from('bookmarks').delete().match({
                          //       'user_id': currentUserUID,
                          //       'video_id': videoId,
                          //     });
                          //
                          //     await Provider.of<BookmarkProvider>(context, listen: false).loadBookmarks(currentUserUID);
                          //
                          //     // 데이터 새로고침
                          //     await _loadBookmarkMarkers();
                          //
                          //     // 🔥 여기를 추가하면 됩니다!
                          //     if (_selectedCategory != null && _categorizedBookmarks.containsKey(_selectedCategory!)) {
                          //       final items = _categorizedBookmarks[_selectedCategory!]!;
                          //       final sortedItems = List<BookmarkLocationData>.from(items)
                          //         ..sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
                          //       final sortedIds = sortedItems.map((e) => e.placeId).toList();
                          //
                          //       setState(() {
                          //         _categoryLocationFuture = Supabase.instance.client.rpc(
                          //           'get_locations_by_ids',
                          //           params: {'_ids': sortedIds},
                          //         ).then((value) {
                          //           final locations = List<Map<String, dynamic>>.from(value);
                          //           locations.sort((a, b) =>
                          //           sortedIds.indexOf(a['place_id']) - sortedIds.indexOf(b['place_id']));
                          //           return locations;
                          //         });
                          //       });
                          //     }
                          //
                          //     if (_selectedVideoId != null && _selectedVideoId != null){
                          //       setState(() {
                          //         _isListDetailOpened = false;
                          //         _selectedLocation = null;
                          //         _selectedVideoId = null;
                          //       });
                          //     }
                          //
                          //
                          //     FirebaseAnalytics.instance.logEvent(
                          //       name: "delete_bookmark_map_page",
                          //       parameters: {
                          //         "video_id": videoId,
                          //       },
                          //     );
                          //
                          //     // 성공 메시지 표시
                          //     ScaffoldMessenger.of(context).showSnackBar(
                          //       SnackBar(
                          //         duration: Duration(milliseconds: 1500),
                          //         backgroundColor: Colors.lightBlueAccent,
                          //         content: Text('북마크에서 삭제되었어요'),
                          //         behavior: SnackBarBehavior.floating,
                          //         margin: EdgeInsets.only(
                          //           bottom: MediaQuery.of(context).size.height * 0.02,
                          //           left: 20.0,
                          //           right: 20.0,
                          //         ),
                          //       ),
                          //     );
                          //   } catch (e) {
                          //     ScaffoldMessenger.of(context).showSnackBar(
                          //       SnackBar(
                          //         backgroundColor: Colors.redAccent,
                          //         duration: Duration(milliseconds: 1500),
                          //         content: Text('북마크 취소 도중 알 수 없는 에러가 발생했습니다'),
                          //         behavior: SnackBarBehavior.floating,
                          //         margin: EdgeInsets.only(
                          //           bottom: MediaQuery.of(context).size.height * 0.02,
                          //           left: 20.0,
                          //           right: 20.0,
                          //         ),
                          //       ),
                          //     );
                          //     print('Delete 에러: $e');
                          //   }
                          // },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            color: Colors.transparent,
                            padding: EdgeInsets.only(top: 10, bottom: 20),
                            child: Text(
                              '북마크 취소하기',
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

  void showShareModal(
    BuildContext context,
    String placeName,
    String videoId,
    String naverMapLink,
  ) {
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
          source: 'Map',
          naverMapLink: naverMapLink,
        );
      },
    );
  }
}
