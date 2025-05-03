import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortsmap/Map/model/BookmarkLocation.dart';
import 'package:shortsmap/Map/page/MapShortsPage.dart';
import 'package:shortsmap/Provider/ImageCacheProvider.dart';
import 'package:shortsmap/Provider/UserDataProvider.dart';
import 'package:shortsmap/Welcome/LoginPage.dart';
import 'package:shortsmap/Widgets/BottomNavBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatefulWidget {
  final String? placeId;

  const MapPage({super.key, this.placeId});


  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  late GoogleMapController _mapController;

  CameraPosition _initialCameraPosition =
      CameraPosition(target: LatLng(600.793503213905154, -600.39945983265487), zoom: 20.0);

  double _widgetHeight = 0;
  double _fabPosition = 0;

  double _mapBottomPadding = 0.0;

  // double _sheetSize = 0;

  bool _isListDetailOpened = false;

  BitmapDescriptor? _currentMarkerIcon;

  Set<Marker> _bookmarkMarkers = {};

  Set<Marker> _allBookmarkMarkers = {}; // 전체 마커 저장용


  Map<String, List<BookmarkLocation>> _categorizedBookmarks = {};

  String? _selectedCategory;

  bool _isProgrammaticMove = false;

  bool _isMarkerTapped = false;

  Future<List<Map<String, dynamic>>>? _categoryLocationFuture;

  Future<Map<String, dynamic>>? _locationDetailFuture;

  // Map<String, Future<String>> _photoUrlCache = {};

  final Map<String, Future<String>> _photoFutures = {};

  String? _selectedLocation;

  // 카테고리별 아이콘 및 컬러
  Map<String, dynamic> categoryStyles = {
    'Restaurant': {'icon': Icons.restaurant, 'color': Color(0xFFFF7043)},
    'Nature': {'icon': Icons.forest, 'color': Color(0xFF4CAF50)},
    'Exhibitions': {'icon': Icons.palette_outlined, 'color': Color(0xFF9C27B0)},
    'Historical Site': {'icon': Icons.account_balance, 'color': Color(0xFF795548)},
    'Sports': {'icon': Icons.sports_tennis, 'color': Color(0xFF2196F3)},
    'Shopping': {'icon': Icons.shopping_bag_outlined, 'color': Color(0xFFFFC107)},
    'Cafe': {'icon': Icons.local_cafe_outlined, 'color': Color(0xFF8D6E63)},
    'Bar': {'icon': Icons.sports_bar, 'color': Color(0xFFB71C1C)},
  };


// 현재 위치를 가져와서 지도 카메라를 이동시키는 함수
//   Future<void> _getInitialLocation() async {
//     try {
//       // 원하는 정확도로 현재 위치 가져오기
//       Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);
//
//       // 가져온 위치를 이용해 새 카메라 위치 생성
//       // CameraPosition newPosition = CameraPosition(
//       //   target: LatLng(37.793503213905154, -122.39945983265487),
//       //   zoom: 20.0, // 원하는 줌 레벨로 설정
//       // );
//
//       CameraPosition cameraPosition = CameraPosition(target: LatLng(position.latitude, position.longitude));
//
//       // 맵 컨트롤러가 준비되었으면 카메라 이동
//       if (_mapController != null) {
//         _mapController
//             .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
//       } else {
//         // 맵 컨트롤러가 아직 생성되지 않은 경우, setState로 초기 카메라 위치 변경
//         setState(() {
//           _initialCameraPosition = cameraPosition;
//         });
//       }
//     } catch (e) {
//       print("현재 위치를 가져오는 중 에러 발생: $e");
//     }
//   }

  Future<void> _moveToCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    final cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 18,
    );
    _mapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  Future<BitmapDescriptor> getMarkerIcon({
    required Color backgroundColor,
    required IconData iconData,
    double size = 80,     // 논리적 크기 (예: 80x80)
    double iconSize = 40, // 논리적 내부 아이콘 크기
  }) async {
    // 최신 방법으로 devicePixelRatio 가져오기
    final double scale = PlatformDispatcher.instance.views.first.devicePixelRatio;

    // 1. PictureRecorder와 Canvas 생성, canvas에 scale 적용하여 고해상도 출력 준비
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    canvas.scale(scale);

    // border 두께 (논리 단위)
    final double borderWidth = 4.0;

    // 2. 흰색 외곽 원 (border) 그리기
    final Paint borderPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      borderPaint,
    );

    // 3. 내부 원 그리기 (border 두께 만큼 작게)
    final Paint innerPaint = Paint()..color = backgroundColor;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      (size / 2) - borderWidth,
      innerPaint,
    );

    // 4. 텍스트 페인터로 아이콘 글리프를 중앙에 그림
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage, // Material Icons인 경우 보통 null
        fontSize: iconSize,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    final double xCenter = (size - textPainter.width) / 2;
    final double yCenter = (size - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(xCenter, yCenter));

    // 5. 캔버스에 그린 내용을 고해상도 이미지로 생성 (실제 픽셀 크기는 size * scale)
    final ui.Image hiResImage = await pictureRecorder.endRecording().toImage(
      (size * scale).toInt(),
      (size * scale).toInt(),
    );
    final ByteData? hiResByteData = await hiResImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List hiResPngBytes = hiResByteData!.buffer.asUint8List();

    // 6. 고해상도 이미지를 논리적 크기(size x size)로 다운스케일링
    final ui.Codec codec = await ui.instantiateImageCodec(
      hiResPngBytes,
      targetWidth: size.toInt(),
      targetHeight: size.toInt(),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image resizedImage = frameInfo.image;
    final ByteData? resizedByteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedPngBytes = resizedByteData!.buffer.asUint8List();

    // 7. BitmapDescriptor 생성 (BitmapDescriptor.fromBytes는 여전히 사용 가능한 최신 방식입니다)
    return BitmapDescriptor.fromBytes(resizedPngBytes);
  }



  @override
  void initState() {
    super.initState();

    // 1) 마커 아이콘 로드
    getMarkerIcon(
      backgroundColor: Colors.green,
      iconData: Icons.star_outline,
      size: 100,
      iconSize: 60,
    ).then((icon) {
      setState(() {
        _currentMarkerIcon = icon;
      });

    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _widgetHeight = MediaQuery.of(context).size.height;

      // 1-2) initialChildSize(0.4) 기준으로 FAB 위치와 맵 패딩 설정
      _fabPosition     = 0.4 * _widgetHeight;
      _mapBottomPadding = 0.4 <= 0.5
          ? 0.4 * _widgetHeight
          : 0.5 * _widgetHeight;

      setState(() {});
    });

    // 4) placeId가 전달된 경우 바로 상세 뷰 열기
    if (widget.placeId != null) {
      setState(() {
        _isListDetailOpened    = true;
        _selectedLocation      = widget.placeId;
        _locationDetailFuture  = _fetchLocationDetail(widget.placeId!);
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // RPC 함수를 호출하여 특정 유저의 북마크 데이터를 가져오고 Marker로 변환하는 함수
  Future<void> _loadBookmarkMarkers() async {
    try {
      final response = await Supabase.instance.client.rpc('get_user_bookmarks', params: {
        '_user_id': Provider.of<UserDataProvider>(context, listen: false).currentUserUID!
      });

      final List<dynamic> data = response;

      if (data.isEmpty) {
        _isProgrammaticMove = true;
        // 북마크가 없으면 내 현재 위치로 이동
        await _moveToCurrentLocation();
        return;
      }

      List<BookmarkLocation> bookmarks = data.map((raw) => BookmarkLocation.fromMap(raw)).toList();

      // 가장 최신 위치를 초기 카메라 위치로 설정 (이미 SQL에서 정렬됨)
      final latestBookmark = bookmarks.first;

      CameraPosition newPosition = CameraPosition(
        target: LatLng(latestBookmark.latitude, latestBookmark.longitude),
        zoom: 18,
      );

      if (_mapController != null) {
        _mapController.animateCamera(CameraUpdate.newCameraPosition(newPosition));
      } else {
        setState(() {
          _initialCameraPosition = newPosition;
        });
      }

      Set<Marker> markers = {};

      for (var bookmark in bookmarks) {
        final style = categoryStyles[bookmark.category] ?? {'icon': Icons.place, 'color': Colors.blue};

        final icon = await getMarkerIcon(
          backgroundColor: style['color'],
          iconData: style['icon'],
          size: 100,
          iconSize: 60,
        );

        markers.add(Marker(
          markerId: MarkerId(bookmark.placeId),
          position: LatLng(bookmark.latitude, bookmark.longitude),
          icon: icon,
          onTap: () {
            print('마커 tapped: ${bookmark.placeName}, lat: ${bookmark.latitude}, lon: ${bookmark.longitude}');

            setState(() {
              _isProgrammaticMove = true;
              _isMarkerTapped = true;
              _selectedCategory = null;
              _isListDetailOpened    = true;
              _selectedLocation      = bookmark.placeId;
              _locationDetailFuture  = _fetchLocationDetail(bookmark.placeId);
            });

            _sheetController.animateTo(
              0.55,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );

          },
        ));
      }

      // 카테고리별로 분류
      Map<String, List<BookmarkLocation>> categorized = {};

      for (final bookmark in bookmarks) {
        categorized.putIfAbsent(bookmark.category, () => []).add(bookmark);
      }

      setState(() {
        _bookmarkMarkers = markers;
        _allBookmarkMarkers = markers; // 전체 마커 백업
        _categorizedBookmarks = categorized;
      });


    } on PostgrestException catch (e) {
      print('북마크 Marker 로드 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey[200],
        // appBar: PreferredSize(
        //   preferredSize: Size.fromHeight(48),
        //   child: SafeArea(
        //     child: AnimatedCrossFade(
        //       firstChild: AppBar(
        //         backgroundColor: Colors.transparent,
        //         automaticallyImplyLeading: false,
        //         elevation: 0,
        //         titleSpacing: 0,
        //         centerTitle: true,
        //         leading: Container(
        //           margin: const EdgeInsets.only(left: 5),
        //           child: IconButton(
        //             enableFeedback: false,
        //             onPressed: () {
        //               Navigator.pop(context);
        //             },
        //             icon: Icon(
        //               CupertinoIcons.back,
        //               color: Colors.black54,
        //               size: MediaQuery.of(context).size.height * (30 / 812),
        //             ),
        //           ),
        //         ),
        //         title: Text(
        //           'dadas',
        //           overflow: TextOverflow.ellipsis,
        //           style: TextStyle(
        //             color: Colors.black87,
        //             fontSize: MediaQuery.of(context).size.height * (18 / 812),
        //             fontWeight: FontWeight.w900,
        //           ),
        //         ),
        //         actions: [
        //           IconButton(
        //               enableFeedback: false,
        //               onPressed: () {},
        //               icon: Icon(
        //                 Icons.ios_share,
        //                 color: Colors.black,
        //                 size: MediaQuery.of(context).size.height * (25 / 812),
        //               )),
        //           IconButton(
        //               enableFeedback: false,
        //               onPressed: () {},
        //               icon: Icon(
        //                 Icons.more_horiz,
        //                 color: Colors.black,
        //                 size: MediaQuery.of(context).size.height * (25 / 812),
        //               )),
        //           SizedBox(
        //             width: MediaQuery.of(context).size.height * (5 / 812),
        //           ),
        //         ],
        //       ),
        //       secondChild: SizedBox.shrink(),
        //       crossFadeState: true
        //           ? CrossFadeState.showFirst
        //           : CrossFadeState.showSecond,
        //       duration: const Duration(milliseconds: 200),
        //     ),
        //   ),
        // ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // 지도
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.white,
                    child: GoogleMap(
                      padding: EdgeInsets.only(
                          bottom: (_fabPosition < 300)
                              ? _mapBottomPadding
                              : _mapBottomPadding - 20),
                      onMapCreated: (controller) {
                        _mapController = controller;
                        // 컨트롤러가 생성된 후에도 현재 위치로 카메라 이동
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _loadBookmarkMarkers();
                        });
                      },
                      onCameraMoveStarted: () {
                        if (_isProgrammaticMove) {
                          _isProgrammaticMove = false;
                          return; // 바텀시트 안 내림
                        }

                        _focusNode.unfocus();
                        _sheetController.animateTo(
                          0.05,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      onTap: (LatLng) {
                        _focusNode.unfocus();
                        _sheetController.animateTo(
                          0.05,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      initialCameraPosition: _initialCameraPosition,
                      markers: _bookmarkMarkers,
                    ),
                  ),
                  // 검색창
                  // Visibility(
                  //   visible: (!_isListDetailOpened && _fabPosition < 700),
                  //   child: Positioned(
                  //     top: 70,
                  //     left: 10,
                  //     right: 10,
                  //     child: Container(
                  //       width: MediaQuery.of(context).size.width * 0.9,
                  //       decoration: BoxDecoration(
                  //         borderRadius: BorderRadius.circular(8),
                  //       ),
                  //       child: TextField(
                  //         onTap: () {
                  //           _sheetController.animateTo(
                  //             0.05,
                  //             duration: Duration(milliseconds: 300),
                  //             curve: Curves.easeInOut,
                  //           );
                  //         },
                  //         focusNode: _focusNode,
                  //         controller: _textEditingController,
                  //         onChanged: (text) {
                  //           setState(() {});
                  //         },
                  //         cursorColor: Colors.black38,
                  //         decoration: InputDecoration(
                  //           prefixIcon: GestureDetector(
                  //             child: InkWell(
                  //               onTap: () => print('asd'),
                  //               child: Icon(
                  //                 Icons.menu,
                  //                 color: Colors.black54,
                  //               ),
                  //             ),
                  //             onTap: () {},
                  //           ),
                  //           suffixIcon: _textEditingController.text.isEmpty
                  //               ? null
                  //               : InkWell(
                  //                   onTap: () => setState(() {
                  //                     _textEditingController.clear();
                  //                   }),
                  //                   child: Icon(
                  //                     Icons.clear,
                  //                     color: Colors.black54,
                  //                   ),
                  //                 ),
                  //           hintText: 'Search Here!',
                  //           border: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(10),
                  //             borderSide: BorderSide.none,
                  //           ),
                  //           filled: true,
                  //           fillColor: Colors.white,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // 내위치버튼
                  Visibility(
                    visible: _fabPosition < 700,
                    child: Positioned(
                      bottom: (_fabPosition < 300)
                          ? _fabPosition + 5
                          : (_fabPosition < 500)
                              ? _fabPosition - 20
                              : _fabPosition - 40,
                      right: 10,
                      child: Row(
                        children: [
                          // SizedBox(
                          //   height: 45,
                          //   width: 95,
                          //   child: FittedBox(
                          //     child: FloatingActionButton.extended(
                          //       label: const Text(
                          //         '화장실',
                          //         style: TextStyle(
                          //           color: Colors.black,
                          //           fontSize: 16,
                          //           fontWeight: FontWeight.bold,
                          //         ),
                          //       ),
                          //       backgroundColor: Colors.white,
                          //       // child: const Text(
                          //       //   '화장실',
                          //       //   style: TextStyle(
                          //       //     color: Colors.black,
                          //       //   ),
                          //       // ),
                          //       onPressed: () {
                          //         // _moveToCurrentLocation();
                          //         // _sheetController.animateTo(
                          //         //   0.05,
                          //         //   duration: Duration(milliseconds: 300),
                          //         //   curve: Curves.easeInOut,
                          //         // );
                          //       },
                          //     ),
                          //   ),
                          // ),
                          // SizedBox(
                          //   height: 45,
                          //   width: 45,
                          //   child: FittedBox(
                          //     child: FloatingActionButton(
                          //       backgroundColor: Colors.white,
                          //       child: Padding(
                          //         padding: const EdgeInsets.only(right: 6.0),
                          //         child: const Icon(
                          //           FontAwesomeIcons.restroom,
                          //           color: Colors.black54,
                          //           size: 24,
                          //         ),
                          //       ),
                          //       onPressed: () {
                          //         // _moveToCurrentLocation();
                          //         // _sheetController.animateTo(
                          //         //   0.05,
                          //         //   duration: Duration(milliseconds: 300),
                          //         //   curve: Curves.easeInOut,
                          //         // );
                          //       },
                          //     ),
                          //   ),
                          // ),
                          // SizedBox(width: 15,),
                          /// 나중에 필터기능 추가할예정
                          // SizedBox(
                          //   height: 45,
                          //   width: 45,
                          //   child: FittedBox(
                          //     child: FloatingActionButton(
                          //       heroTag: UniqueKey().toString(),
                          //       backgroundColor: Colors.white,
                          //       child: const Icon(
                          //         Icons.filter_alt,
                          //         color: Colors.black54,
                          //         size: 28,
                          //       ),
                          //       onPressed: () {
                          //         // _moveToCurrentLocation();
                          //         // _sheetController.animateTo(
                          //         //   0.05,
                          //         //   duration: Duration(milliseconds: 300),
                          //         //   curve: Curves.easeInOut,
                          //         // );
                          //       },
                          //     ),
                          //   ),
                          // ),
                          // SizedBox(width: 15,),
                          SizedBox(
                            height: 45,
                            width: 45,
                            child: FittedBox(
                              child: FloatingActionButton(
                                heroTag: UniqueKey().toString(),
                                backgroundColor: Colors.white,
                                child: const Icon(
                                  CupertinoIcons.paperplane_fill,
                                  color: Colors.black54,
                                  size: 28,
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
                        ],
                      ),
                    ),
                  ),
                  //돌아가기버튼
                  Visibility(
                    visible: _isListDetailOpened,
                    child: Positioned(
                      top: 70,
                      left: 10,
                      child: SizedBox(
                        height: 50,
                        width: 50,
                        child: FittedBox(
                          child: FloatingActionButton(
                            backgroundColor: Colors.white,
                            child: const Icon(
                              CupertinoIcons.back,
                              color: Colors.black54,
                              size: 32,
                            ),
                            onPressed: () {
                              if (_selectedLocation != null) {
                                // 상세 열려 있을 때
                                setState(() {
                                  _selectedLocation = null;               // 상세만 닫음
                                  if (_selectedCategory == null) {
                                    // 맵→상세 경로였으면 → 전체 카테고리 리스트로
                                    _isListDetailOpened = false;
                                    _bookmarkMarkers    = _allBookmarkMarkers;
                                  }
                                  // (_selectedCategory != null 이면 → 카테고리→상세 경로)
                                  //    _isListDetailOpened(true)와 필터된 _bookmarkMarkers 유지
                                });

                              } else if (_isListDetailOpened) {
                                // 카테고리 리스트 화면에서 뒤로 → 전체 카테고리 뷰로
                                setState(() {
                                  _isListDetailOpened = false;
                                  _bookmarkMarkers    = _allBookmarkMarkers;
                                  _selectedCategory   = null;
                                });
                              }

                              _sheetController.animateTo(0.4,
                                  duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  //더보기버튼
                  Visibility(
                    visible: _isListDetailOpened,
                    child: Positioned(
                      top: 70,
                      right: 10,
                      child: SizedBox(
                        height: 50,
                        width: 50,
                        child: FittedBox(
                          child: FloatingActionButton(
                            backgroundColor: Colors.white,
                            child: const Icon(
                              Icons.more_horiz,
                              color: Colors.black54,
                              size: 32,
                            ),
                            onPressed: () {
                              showReportModal(context);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 바텀시트
                  Positioned(
                    bottom: 0,
                    top: 0,
                    child: NotificationListener<DraggableScrollableNotification>(
                      onNotification: (notification) {
                        // 시트 크기 비율(extent)로 FAB 위치와 맵 패딩 실시간 조정
                        final e = notification.extent;
                        _fabPosition     = e * _widgetHeight;
                        _mapBottomPadding = e <= 0.5
                            ? e * _widgetHeight
                            : 0.5 * _widgetHeight;
                        setState(() {});
                        return true;
                      },
                      child: DraggableScrollableSheet(
                        controller: _sheetController,
                        maxChildSize:   0.9,
                        initialChildSize: 0.4,
                        minChildSize:   0.1,
                        expand:         false,
                        snap:           true,
                        snapSizes:      const [0.1, 0.4],
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
                                    minHeight: MediaQuery.of(context).size.height, // 또는 원하는 최소 높이
                                  ),
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    physics: const ClampingScrollPhysics(),
                                    child: Column(
                                      children: [
                                        // 헤더 공간만큼의 빈 공간(헤더는 오버레이로 표시됨)
                                        const SizedBox(height: 30),
                                        // 실제 스크롤 되는 콘텐츠
                                        _selectedLocation != null
                                            ? FutureBuilder<Map<String, dynamic>>(
                                          future: _locationDetailFuture,
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const Center(child: CircularProgressIndicator());
                                            }
                                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                              print(snapshot.error);
                                              return const Padding(
                                                padding: EdgeInsets.all(20),
                                                child: Text('No locations found.'),
                                              );
                                            }

                                            final placeData = snapshot.data!;
                                            final placeId = placeData['place_id'] as String;

                                            // 1) photoFuture 메모이제이션
                                            _photoFutures[placeId] ??=
                                                Provider.of<PhotoCacheProvider>(context, listen: false)
                                                    .getPhotoUrlForPlace(placeId);
                                            final photoFuture = _photoFutures[placeId]!;

                                            final userLat = Provider.of<UserDataProvider>(context, listen: false).currentLat;
                                            final userLon = Provider.of<UserDataProvider>(context, listen: false).currentLon;

                                            // 2) photoFuture 로 전체 상세 UI 감싸기
                                            return FutureBuilder<String>(
                                              future: photoFuture,
                                              builder: (context, photoSnapshot) {
                                                final imageUrl = photoSnapshot.data;
                                                final isLoading = photoSnapshot.connectionState == ConnectionState.waiting;
                                                final isEmpty = photoSnapshot.hasData && photoSnapshot.data!.isEmpty;

                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                                                  child: Column(
                                                    children: [
                                                      // --- 상단 Row (Avatar + 텍스트 + 공유 버튼) ---
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          GestureDetector(
                                                            onTap: (){
                                                              print('123');
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) => MapShortsPage(
                                                                        storeName: placeData['place_name'],
                                                                        placeId: placeData['place_id'],
                                                                        videoId: placeData['video_id'],
                                                                        storeCaption: placeData['description'] ?? 'descriptionNull',
                                                                        storeLocation: placeData['region'],
                                                                        openTime: placeData['open_time'] ?? '09:00',
                                                                        closeTime: placeData['close_time'] ?? '20:00',
                                                                        rating: placeData['rating'] ?? 4.0,
                                                                        category: placeData['category'],
                                                                        averagePrice: placeData['average_price'] == null ? 3 : placeData['average_price'].toDouble(),
                                                                        imageUrl: imageUrl,
                                                                        coordinates: {
                                                                          'lat': placeData['latitude'],
                                                                          'lon': placeData['longitude'],
                                                                        },
                                                                        phoneNumber: placeData['phone_number'],
                                                                        website: placeData['website_link'],
                                                                        address: placeData['address'],
                                                                      )));
                                                            },
                                                            child: Container(
                                                              width: 90,
                                                              height: 90,
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                border: Border.all(color: Colors.lightBlue, width: 2),
                                                              ),
                                                              child: Padding(
                                                                padding: const EdgeInsets.all(2.0),
                                                                child: CircleAvatar(
                                                                  radius: 90,
                                                                  backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
                                                                  backgroundColor: Colors.grey[300],
                                                                  child: imageUrl == null ? Icon(
                                                                    Icons.location_on_outlined,
                                                                    color: Colors.black,
                                                                    size: 30,
                                                                  ) : null,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                placeData['place_name'],
                                                                style: const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.black,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 3),
                                                              Text(
                                                                '${placeData['category']} · \$${placeData['average_price'] == null ? '3' : placeData['average_price'].round()}~',
                                                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                                                              ),
                                                              const SizedBox(height: 3),
                                                              Row(
                                                                children: [
                                                                  const Icon(CupertinoIcons.bus, color: Colors.black26, size: 18),
                                                                  Text(
                                                                    (placeData['latitude'] != null &&
                                                                        userLat != null &&
                                                                        placeData['longitude'] != null &&
                                                                        userLon != null)
                                                                        ? ' ${calculateTimeRequired(userLat, userLon, placeData['latitude'], placeData['longitude'])}분 · ${placeData['region']}'
                                                                        : ' 30분 · ${placeData['region']}',
                                                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(height: 3),
                                                              Row(
                                                                children: [
                                                                  const Icon(CupertinoIcons.time, color: Colors.black26, size: 18),
                                                                  Text(
                                                                    ' ${placeData['open_time'] ?? '09:00'} ~ ${placeData['close_time'] ?? '22:00'}',
                                                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          const Spacer(),
                                                          GestureDetector(
                                                            onTap: () {
                                                              Share.share(
                                                                'https://www.youtube.com/shorts/${placeData['video_id']}',
                                                                subject: placeData['place_name']!,
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
                                                              child: const Icon(CupertinoIcons.share, size: 20, color: Colors.black),
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      const SizedBox(height: 25),

                                                      // --- 버튼 Row (Call, Route, Explore) ---
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: [
                                                          // Call
                                                          GestureDetector(
                                                            onTap: () async {
                                                              final Uri phoneUri = Uri(scheme: 'tel', path: placeData['phone_number']);
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
                                                                  Icon(CupertinoIcons.phone, color: Colors.black, size: 22),
                                                                  SizedBox(width: 8),
                                                                  Text('전화걸기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          // Route
                                                          GestureDetector(
                                                            onTap: () async {
                                                              await launchUrl(
                                                                Uri.parse(
                                                                  'https://www.google.com/maps/dir/?api=1'
                                                                      '&origin=$userLat,$userLon'
                                                                      '&destination=${Uri.encodeComponent(placeData['place_name'])}'
                                                                      '&destination_place_id=${placeData['place_id']}'
                                                                      '&travelmode=transit',
                                                                ),
                                                                mode: LaunchMode.externalApplication,
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
                                                                  Icon(Icons.directions_car, color: Colors.black, size: 22),
                                                                  SizedBox(width: 8),
                                                                  Text('길찾기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          // Explore
                                                          GestureDetector(
                                                            onTap: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (_) => MapShortsPage(
                                                                    storeName: placeData['place_name'],
                                                                    placeId: placeData['place_id'],
                                                                    videoId: placeData['video_id'],
                                                                    storeCaption: placeData['description'] ?? 'descriptionNull',
                                                                    storeLocation: placeData['region'],
                                                                    openTime: placeData['open_time'] ?? '09:00',
                                                                    closeTime: placeData['close_time'] ?? '20:00',
                                                                    rating: placeData['rating'] ?? 4.0,
                                                                    category: placeData['category'],
                                                                    averagePrice: placeData['average_price'] == null
                                                                        ? 3
                                                                        : placeData['average_price'].toDouble(),
                                                                    imageUrl: imageUrl, // ← 여기!
                                                                    coordinates: {
                                                                      'lat': placeData['latitude'],
                                                                      'lon': placeData['longitude'],
                                                                    },
                                                                    phoneNumber: placeData['phone_number'],
                                                                    website: placeData['website_link'],
                                                                    address: placeData['address'],
                                                                  ),
                                                                ),
                                                              );
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
                                                                  Icon(CupertinoIcons.play_arrow_solid, color: Colors.white, size: 22),
                                                                  SizedBox(width: 8),
                                                                  Text(
                                                                    '영상보기',
                                                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      const SizedBox(height: 25),

                                                      // --- 추가 정보 리스트 ---
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[200],
                                                          borderRadius: BorderRadius.circular(8),
                                                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            _buildListTile(
                                                              icon: Icons.location_on_outlined,
                                                              title: 'Address',
                                                              subtitle: placeData['address'],
                                                              onTap: () async {
                                                                await launchUrl(
                                                                  Uri.parse(
                                                                    'https://www.google.com/maps/search/?api=1'
                                                                        '&query=${Uri.encodeComponent(placeData['place_name'])}'
                                                                        '&query_place_id=${placeData['place_id']}',
                                                                  ),
                                                                  mode: LaunchMode.externalApplication,
                                                                );
                                                              },
                                                            ),
                                                            if (placeData['phone_number'] != null)
                                                              const Divider(height: 2),
                                                            if (placeData['phone_number'] != null)
                                                              _buildListTile(
                                                                icon: Icons.phone,
                                                                title: 'Call',
                                                                subtitle: '눌러서 전화걸기',
                                                                onTap: () async {
                                                                  final Uri phoneUri = Uri(scheme: 'tel', path: placeData['phone_number']);
                                                                  if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
                                                                },
                                                              ),
                                                            if (placeData['website_link'] != null)
                                                              const Divider(height: 2),
                                                            if (placeData['website_link'] != null)
                                                              _buildListTile(
                                                                icon: Icons.language,
                                                                title: 'Visit Website',
                                                                subtitle: '웹사이트 방문하기',
                                                                onTap: () async {
                                                                  await launchUrl(Uri.parse(placeData['website_link']),
                                                                      mode: LaunchMode.inAppBrowserView);
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
                                                                await launchUrl(
                                                                  Uri.parse('https://forms.gle/yXcva654ddrWfWwYA'),
                                                                  mode: LaunchMode.inAppBrowserView,
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
                                        )
                                            : _isListDetailOpened
                                            ? FutureBuilder<List<Map<String, dynamic>>>(
                                          future: _categoryLocationFuture,
                                          builder: (context, snapshot) {

                                            // TODO Skeleton이나 아예 흰화면으로 바꿔주기
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const Center(child: CircularProgressIndicator());
                                            }

                                            // TODO 비어있거나 에러일 때 보여줄 내용 넣기 ( 빈 화면일 일은 없을거임근데 )
                                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                              print(snapshot.error);
                                              return Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Something went wrong',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.bold,
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

                                            final style = categoryStyles[_selectedCategory] ?? {
                                              'icon': Icons.place,
                                              'color': Colors.blue,
                                            };

                                            return Column(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 18),
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 25,
                                                        backgroundColor: style['color'],
                                                        child: Icon(
                                                          style['icon'],
                                                          color: Colors.white,
                                                          size: 30,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 15,),
                                                      Text(
                                                        _selectedCategory!,
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      Spacer(),
                                                      Container(
                                                        width: 40,
                                                        height: 40,
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
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                                  physics: NeverScrollableScrollPhysics(),
                                                  itemCount: places.length,
                                                  separatorBuilder:
                                                      (context, index) {
                                                    return Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16),
                                                      child: Divider(
                                                        color: Colors.grey[300],
                                                        height: 1.5,
                                                        thickness: 1,
                                                      ),
                                                    );
                                                  },
                                                  itemBuilder: (context, index) {
                                                    final p = places[index];

                                                    final placeId = p['place_id'];

                                                    _photoFutures[placeId] ??= Provider.of<PhotoCacheProvider>(context, listen: false).getPhotoUrlForPlace(placeId);

                                                    return FutureBuilder<String>(
                                                      future: _photoFutures[placeId],
                                                      builder: (context, photoSnapshot) {
                                                        final imageUrl = photoSnapshot.data;

                                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                                          return _locationTile(
                                                            true,
                                                            placeId,
                                                            imageUrl,
                                                            p['place_name'] ?? '',
                                                            p['region'] ?? '',
                                                            p['open_time'] ?? '09:00',
                                                            p['close_time'] ?? '22:00',
                                                            (p['latitude'] as num).toDouble(),
                                                            (p['longitude'] as num).toDouble(),
                                                            p['video_id'] ?? '',
                                                          );
                                                        }

                                                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                                          print(snapshot.error);
                                                        }

                                                        return _locationTile(
                                                          false,
                                                          placeId,
                                                          imageUrl,
                                                          p['place_name'] ?? '',
                                                          p['region'] ?? '',
                                                          p['open_time'] ?? '09:00',
                                                          p['close_time'] ?? '22:00',
                                                          (p['latitude'] as num).toDouble(),
                                                          (p['longitude'] as num).toDouble(),
                                                          p['video_id'] ?? '',
                                                        );
                                                      },
                                                    );

                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        )
                                            : Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                          children: [
                                            _categorizedBookmarks.isEmpty
                                                ? Padding(
                                              padding: const EdgeInsets.all(24.0),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.folder_open, size: 48, color: Colors.grey),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    '저장된 장소가 없습니다',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                                : ListView.separated(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: _categorizedBookmarks.length,
                                              itemBuilder: (context, index) {
                                                final category = _categorizedBookmarks.keys.elementAt(index);
                                                final items = _categorizedBookmarks[category]!;

                                                final style = categoryStyles[category] ?? {
                                                  'icon': Icons.place,
                                                  'color': Colors.blue,
                                                };

                                                return _folderTile(
                                                  title: category,
                                                  color: style['color'],
                                                  icon: style['icon'],
                                                  locations: items.length,
                                                );
                                              },
                                              separatorBuilder: (context, index) => Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                child: Divider(
                                                  color: Colors.grey[300],
                                                  height: 1.5,
                                                  thickness: 1,
                                                ),
                                              ),
                                            ),
                                            // ListView(
                                            //   shrinkWrap: true,
                                            //   padding: EdgeInsets.zero,
                                            //     physics:
                                            //           const NeverScrollableScrollPhysics(),
                                            //   children: [
                                            //     _folderTile(title: 'LA', color: Colors.purpleAccent, locations: 32, share: 3),
                                            //     Padding(
                                            //             padding: const EdgeInsets
                                            //                 .symmetric(
                                            //                 horizontal: 16),
                                            //             child: Divider(
                                            //               color: Colors.grey[300],
                                            //               height: 1.5,
                                            //               thickness: 1,
                                            //             ),
                                            //           ),
                                            //     _folderTile(title: 'Burgers', color: Colors.orangeAccent, icon: Icons.lunch_dining, locations: 12, share: 1),
                                            //     Padding(
                                            //       padding: const EdgeInsets
                                            //           .symmetric(
                                            //           horizontal: 16),
                                            //       child: Divider(
                                            //         color: Colors.grey[300],
                                            //         height: 1.5,
                                            //         thickness: 1,
                                            //       ),
                                            //     ),
                                            //     _folderTile(title: 'Pizza', color: Colors.redAccent, icon: Icons.local_pizza, locations: 9, share: 12),
                                            //     Padding(
                                            //       padding: const EdgeInsets
                                            //           .symmetric(
                                            //           horizontal: 16),
                                            //       child: Divider(
                                            //         color: Colors.grey[300],
                                            //         height: 1.5,
                                            //         thickness: 1,
                                            //       ),
                                            //     ),
                                            //     _folderTile(title: 'Japanese', color: Colors.pinkAccent, icon: Icons.favorite, locations: 19, share: 3),
                                            //   ],
                                            // )
                                          ],
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
                                              Radius.circular(10)),
                                        ),
                                        height: 4,
                                        width: 60,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 10),
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
                  // AnimatedCrossFade(
                  //   firstChild: Container(
                  //     width: MediaQuery.of(context).size.width,
                  //     height: 130,
                  //     color: Colors.white,
                  //     child: Padding(
                  //       padding: const EdgeInsets.only(top: 60,),
                  //       child: Row(
                  //         children: [
                  //           Container(
                  //             margin: const EdgeInsets.only(left: 5),
                  //             child: IconButton(
                  //               enableFeedback: false,
                  //               onPressed: () {
                  //                 Navigator.pop(context);
                  //               },
                  //               icon: Icon(
                  //                 CupertinoIcons.back,
                  //                 color: Colors.black54,
                  //                 size: MediaQuery.of(context).size.height * (30 / 812),
                  //               ),
                  //             ),
                  //           ),
                  //           Center(
                  //             child: Text(
                  //               'adasddas',
                  //               overflow: TextOverflow.ellipsis,
                  //               style: TextStyle(
                  //                 color: Colors.black87,
                  //                 fontSize: MediaQuery.of(context).size.height * (18 / 812),
                  //                 fontWeight: FontWeight.w900,
                  //               ),
                  //             ),
                  //           ),
                  //           Spacer(),
                  //           IconButton(
                  //               enableFeedback: false,
                  //               onPressed: () {},
                  //               icon: Icon(
                  //                 Icons.ios_share,
                  //                 color: Colors.black,
                  //                 size: MediaQuery.of(context).size.height * (25 / 812),
                  //               )),
                  //           IconButton(
                  //               enableFeedback: false,
                  //               onPressed: () {},
                  //               icon: Icon(
                  //                 Icons.more_horiz,
                  //                 color: Colors.black,
                  //                 size: MediaQuery.of(context).size.height * (25 / 812),
                  //               )),
                  //           SizedBox(
                  //             width: MediaQuery.of(context).size.height * (5 / 812),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  //   secondChild: SizedBox.shrink(),
                  //   crossFadeState:
                  //   true ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  //   duration: const Duration(milliseconds: 200),
                  // ),
                ],
              ),
            ),
            BottomNavBar(context, 'map'),
          ],
        ),
      ),
    );
  }

  /// 카테고리 목록 타일
  ListTile _folderTile({
    String title = 'default',
    Color color = Colors.green,
    String owner = 'My List',
    IconData icon = Icons.star_border,
    int locations = 0,
  }) {
    return ListTile(
      onTap: () {
        final items = _categorizedBookmarks[title]!;
        final locationIds = items.map((e) => e.placeId).toList();

        _isProgrammaticMove = true;

        final latest = items.first;

        _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(latest.latitude, latest.longitude),
            zoom: 18,
          ),
        ));

        setState(() {
          _bookmarkMarkers = _allBookmarkMarkers
              .where((m) => locationIds.contains(m.markerId.value))
              .toSet();

          _selectedCategory = title;
          _isListDetailOpened = true;

          final items = _categorizedBookmarks[title]!;

          /// TODO 최신순으로할지 거리순으로할지 설정
          // 1. 최신순으로 BookmarkLocation 정렬
          final sortedItems = List<BookmarkLocation>.from(items)
            ..sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));

          final sortedIds = sortedItems.map((e) => e.placeId).toList();

          // 2. 정렬된 순서에 따라 장소 정보 불러오기
          _categoryLocationFuture = Supabase.instance.client
              .rpc('get_locations_by_ids', params: {
            '_ids': sortedIds,
          }).then((value) {
            final locations = List<Map<String, dynamic>>.from(value);

            // 3. 정렬된 location_id 순서에 맞게 다시 재정렬
            locations.sort((a, b) =>
            sortedIds.indexOf(a['place_id']) - sortedIds.indexOf(b['place_id']));

            return locations;
          });

        });

        _sheetController.animateTo(
          0.5,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: color,
        child: Icon(
          icon,
          color: Colors.white,
          size: 25,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Row(
        children: [
          Text(owner),
          const Text(
            ' · ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Icon(
            Icons.location_on,
            size: 16,
          ),
          Text(locations.toString()),
        ],
      ),
      // trailing: InkWell(
      //   onTap: () {
      //     print(title);
      //   },
      //   child: const Icon(Icons.more_vert),
      // ),
    );
  }

  /// 장소 목록 타일
  Widget _locationTile(bool isLoading, String locationId, String? imageUrl, String storeName, String region, String openTime, String closeTime, double lat, double lon, String videoId) {
    return GestureDetector(
      onTap: (){
        _isProgrammaticMove = true;

        _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, lon),
            zoom: 18,
          ),
        ));

        setState(() {
          _selectedLocation = locationId;
          _locationDetailFuture = _fetchLocationDetail(locationId);
        });

        _sheetController.animateTo(
          0.55,
          duration: Duration(milliseconds: 300),
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
                  border: Border.all(
                    color: Colors.lightBlue,
                    width: 2,
                  ),
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
                  border: Border.all(
                    color: Colors.lightBlue,
                    width: 2,
                  ),
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
                    style: const TextStyle(
                      fontSize: 18,
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
                        (lat != null && Provider.of<UserDataProvider>(context, listen: false).currentLat != null && lon != null && Provider.of<UserDataProvider>(context, listen: false).currentLon != null)
                            ? ' ${calculateTimeRequired(Provider.of<UserDataProvider>(context, listen: false).currentLat!, Provider.of<UserDataProvider>(context, listen: false).currentLon!, lat, lon)}분 · $region'
                            : ' 30분 · $region',
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
                        ' $openTime ~ $closeTime',
                        style: const TextStyle(
                          fontSize: 14,
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
              onTap: (){
                showCancelBookmarkModal(context, videoId);
              },
              child: Icon(Icons.more_horiz)
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

    return travelTimeMinutes.toString();
  }

  /// 특정 장소의 정보를 가져오는 함수
  Future<Map<String, dynamic>> _fetchLocationDetail(String placeId) async {

    print(placeId);

    try{
      final response = await Supabase.instance.client
          .rpc('get_location_detail_by_id', params: {
        '_place_id': placeId,
      });

      List<dynamic> data = response;

      if (data.isEmpty) print('empty'); // TODO 비었을 때 처리 ( 빌일은 없을거긴함 )

      Map<String, dynamic> locationData = data[0];

      return locationData;
    } on PostgrestException catch (e) {
      throw Exception("Error fetching posts: ${e.code}, ${e.message}");
    }

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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle:
      subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 15))
          : null,
      trailing: const Icon(Icons.chevron_right, size: 26),
      onTap: onTap,
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
                          '현재 운영하지 않는 장소에요',
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
                          '정보가 부정확해요',
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
                          '컨텐츠가 부적절해요',
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

  ///북마크 삭제 모달 TODO 실제신고기능추가필요
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
                      onTap: () async {
                        Navigator.pop(context);
                        final currentUserUID = Provider.of<UserDataProvider>(context, listen: false).currentUserUID!;

                        try {
                          // Supabase DB에서 북마크 삭제
                          await Supabase.instance.client.from('bookmarks').delete().match({
                            'user_id': currentUserUID,
                            'video_id': videoId,
                          });

                          // 데이터 새로고침
                          await _loadBookmarkMarkers();

                          // 🔥 여기를 추가하면 됩니다!
                          if (_selectedCategory != null && _categorizedBookmarks.containsKey(_selectedCategory!)) {
                            final items = _categorizedBookmarks[_selectedCategory!]!;
                            final sortedItems = List<BookmarkLocation>.from(items)
                              ..sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
                            final sortedIds = sortedItems.map((e) => e.placeId).toList();

                            setState(() {
                              _categoryLocationFuture = Supabase.instance.client.rpc(
                                'get_locations_by_ids',
                                params: {'_ids': sortedIds},
                              ).then((value) {
                                final locations = List<Map<String, dynamic>>.from(value);
                                locations.sort((a, b) =>
                                sortedIds.indexOf(a['place_id']) - sortedIds.indexOf(b['place_id']));
                                return locations;
                              });
                            });
                          }

                          // 성공 메시지 표시
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.lightBlueAccent,
                              content: Text('북마크가 삭제되었어요'),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.only(
                                bottom: MediaQuery.of(context).size.height * 0.06,
                                left: 20.0,
                                right: 20.0,
                              ),
                            ),
                          );
                        } catch (e) {
                          print('Delete 에러: $e');
                        }
                      },
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
}
