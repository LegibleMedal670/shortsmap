import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shortsmap/Map/model/BookmarkLocation.dart';
import 'package:shortsmap/UserDataProvider.dart';
import 'package:shortsmap/Widgets/BottomNavBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

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

  Future<List<Map<String, dynamic>>>? _categoryLocationFuture;




  // 카테고리별 아이콘 및 컬러
  Map<String, dynamic> categoryStyles = {
    'Food & Dining': {'icon': Icons.restaurant, 'color': Color(0xFFFF7043)},
    'Nature': {'icon': Icons.forest, 'color': Color(0xFF4CAF50)},
    'Exhibitions': {'icon': Icons.palette_outlined, 'color': Color(0xFF9C27B0)},
    'Historical Site': {'icon': Icons.account_balance, 'color': Color(0xFF795548)},
    'Sports': {'icon': Icons.sports_tennis, 'color': Color(0xFF2196F3)},
    'Shopping': {'icon': Icons.shopping_bag_outlined, 'color': Color(0xFFFFC107)},
    'Cafe & Desserts': {'icon': Icons.local_cafe_outlined, 'color': Color(0xFF8D6E63)},
    'Bar & Pub': {'icon': Icons.sports_bar, 'color': Color(0xFFB71C1C)},
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

    getMarkerIcon(
      backgroundColor: Colors.green,
      iconData: Icons.star_outline,
      size: 100,
      iconSize: 60,
    ).then((icon) {
      setState(() {
        _currentMarkerIcon = icon;
      });
      _loadBookmarkMarkers();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _widgetHeight = MediaQuery.of(context).size.height;
        _fabPosition = _sheetController.size * _widgetHeight;
        _mapBottomPadding = (_sheetController.size <= 0.5)
            ? _sheetController.size * _widgetHeight
            : 0.5 * _widgetHeight;
      });
    });
    _sheetController.addListener(() {
      setState(() {
        _fabPosition = _sheetController.size * _widgetHeight;
        // print(_sheetController.size);
        if (_sheetController.size <= 0.5) {
          _mapBottomPadding = _sheetController.size * _widgetHeight;
        } else {
          // 0.5 초과일 경우 원하는 값으로 고정하거나 추가 로직을 적용
          _mapBottomPadding = 0.5 * _widgetHeight;
        }
      });
    });
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

      if (data.isEmpty) return;

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
          markerId: MarkerId(bookmark.locationId.toString()),
          position: LatLng(bookmark.latitude, bookmark.longitude),
          icon: icon,
          onTap: () {
            print('마커 tapped: ${bookmark.name}, lat: ${bookmark.latitude}, lon: ${bookmark.longitude}');
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
                        // _getInitialLocation();
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
                          SizedBox(
                            height: 45,
                            width: 45,
                            child: FittedBox(
                              child: FloatingActionButton(
                                backgroundColor: Colors.white,
                                child: const Icon(
                                  Icons.filter_alt,
                                  color: Colors.black54,
                                  size: 28,
                                ),
                                onPressed: () {
                                  // _moveToCurrentLocation();
                                  // _sheetController.animateTo(
                                  //   0.05,
                                  //   duration: Duration(milliseconds: 300),
                                  //   curve: Curves.easeInOut,
                                  // );
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 15,),
                          SizedBox(
                            height: 45,
                            width: 45,
                            child: FittedBox(
                              child: FloatingActionButton(
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
                              setState(() {
                                _isListDetailOpened = false;
                                _bookmarkMarkers = _allBookmarkMarkers; // 마커 복원
                              });
                              _sheetController.animateTo(
                                0.4,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
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
                              setState(() {
                                _isListDetailOpened = false;
                              });
                              _sheetController.animateTo(
                                0.4,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
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
                    child: DraggableScrollableSheet(
                      controller: _sheetController,
                      maxChildSize: 0.9,
                      initialChildSize: 0.4,
                      minChildSize: 0.09,
                      expand: false,
                      snap: true,
                      snapSizes: const [0.09, 0.4],
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
                            color: Colors.white,
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
                                      _isListDetailOpened
                                          ? FutureBuilder<List<Map<String, dynamic>>>(
                                        future: _categoryLocationFuture,
                                        builder: (context, snapshot) {

                                          // TODO Skeleton이나 아예 흰화면으로 바꿔주기
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(child: CircularProgressIndicator());
                                          }

                                          // TODO 비어있거나 에러일 때 보여줄 내용 넣기 ( 빈 화면일 일은 없을거임근데 )
                                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                            return const Padding(
                                              padding: EdgeInsets.all(20),
                                              child: Text('No locations found.'),
                                            );
                                          }

                                          final places = snapshot.data!;

                                          return ListView.separated(
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

                                              return FutureBuilder<String>(
                                                // future: fetchFirstPhotoUrl(p['location_id'].toString()),
                                                // TODO 실제 장소 아이디 불러와서 해줘야함
                                                // TODO API 사진 한번만 불러오도록 해줘야함
                                                future: fetchFirstPhotoUrl('ChIJg15J_MypfDURtLH0G1suNq8'),
                                                builder: (context, photoSnapshot) {
                                                  String? imageUrl = photoSnapshot.data; // fallback 이미지

                                                  return _locationTile(
                                                    p['location_id'].toString(),
                                                    imageUrl,
                                                    p['name'] ?? '',
                                                    p['region'] ?? '',
                                                    p['open_time'] ?? '00:00',
                                                    p['close_time'] ?? '00:00',
                                                    (p['latitude'] as num).toDouble(),
                                                    (p['longitude'] as num).toDouble(),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                // "Add New List" 영역
                                                // Padding(
                                                //   padding: const EdgeInsets.only(
                                                //       top: 12),
                                                //   child: Column(
                                                //     children: [
                                                //       ListTile(
                                                //         onTap: () {
                                                //           _showAddNewBottomSheet();
                                                //         },
                                                //         leading: Container(
                                                //           width: 40,
                                                //           height: 40,
                                                //           decoration:
                                                //               BoxDecoration(
                                                //             color: Colors.white,
                                                //             shape:
                                                //                 BoxShape.circle,
                                                //             border: Border.all(
                                                //               color:
                                                //                   Colors.black54,
                                                //               width: 0.6,
                                                //             ),
                                                //           ),
                                                //           child: const Icon(
                                                //             Icons.add,
                                                //             color: Colors.black54,
                                                //             size: 28,
                                                //           ),
                                                //         ),
                                                //         title: const Text(
                                                //           'Add New List',
                                                //           style: TextStyle(
                                                //             fontWeight:
                                                //                 FontWeight.bold,
                                                //             fontSize: 18,
                                                //             color: Colors.black54,
                                                //           ),
                                                //         ),
                                                //       ),
                                                //       Padding(
                                                //         padding: const EdgeInsets
                                                //             .symmetric(
                                                //             horizontal: 16),
                                                //         child: Divider(
                                                //           color: Colors.grey[300],
                                                //           height: 1.5,
                                                //           thickness: 1,
                                                //         ),
                                                //       ),
                                                //     ],
                                                //   ),
                                                // ),
                                                // 리스트 항목 영역 (ListView.separated 사용)
                                                ListView.separated(
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

  ListTile _folderTile({
    String title = 'default',
    Color color = Colors.green,
    String owner = 'My List',
    IconData icon = Icons.sports_bar,
    int locations = 0,
  }) {
    return ListTile(
      onTap: () {
        final items = _categorizedBookmarks[title]!;
        final locationIds = items.map((e) => e.locationId).toList();

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
              .where((m) => locationIds.contains(int.parse(m.markerId.value)))
              .toSet();

          _selectedCategory = title;
          _isListDetailOpened = true;

          _categoryLocationFuture = Supabase.instance.client
              .rpc('get_locations_by_ids', params: {
            '_ids': locationIds,
          })
              .then((value) => List<Map<String, dynamic>>.from(value));
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
      trailing: InkWell(
        onTap: () {
          print(title);
        },
        child: const Icon(Icons.more_vert),
      ),
    );
  }

  Widget _locationTile(String locationId, String? imageUrl, String storeName, String region, String openTime, String closeTime, double lat, double lon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FutureBuilder를 사용하여 첫 번째 사진을 CircleAvatar 이미지로 설정
          if (imageUrl != null)
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
          if (imageUrl == null)
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
                          ? ' ${calculateTimeRequired(Provider.of<UserDataProvider>(context, listen: false).currentLat!, Provider.of<UserDataProvider>(context, listen: false).currentLon!, lat, lon)}분 · location'
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
          Icon(Icons.more_horiz)
        ],
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

  // void _showAddNewBottomSheet() {
  //   showModalBottomSheet(
  //     enableDrag: false,
  //     isDismissible: false,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.only(
  //         topLeft: Radius.circular(20.0),
  //         topRight: Radius.circular(20.0),
  //       ),
  //     ),
  //     context: context,
  //     builder: (context) {
  //       IconData selectedIcon = Icons.star;
  //       Color selectedColor = Colors.red;
  //       bool isPublic = false;
  //
  //       List<Color> colorList = [
  //         Colors.red,
  //         Colors.orange,
  //         Colors.lightGreen,
  //         Colors.green,
  //         Colors.lightBlue,
  //         Colors.indigo,
  //         Colors.indigo[900]!,
  //         Colors.deepPurple,
  //         Colors.pink[100]!,
  //       ];
  //
  //       final TextEditingController _controller1 = TextEditingController();
  //       final TextEditingController _controller2 = TextEditingController();
  //
  //       final FocusNode _focusNode1 = FocusNode();
  //       final FocusNode _focusNode2 = FocusNode();
  //
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter myState) {
  //           return GestureDetector(
  //             onTap: () {
  //               _focusNode1.unfocus();
  //               _focusNode2.unfocus();
  //             },
  //             child: Container(
  //               width: MediaQuery.of(context).size.width,
  //               height: MediaQuery.of(context).size.height * 0.93,
  //               color: Colors.transparent,
  //               child: Padding(
  //                 padding: const EdgeInsets.symmetric(horizontal: 16),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     const SizedBox(height: 15),
  //                     // Appbar
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                       children: [
  //                         IconButton(
  //                           onPressed: () {
  //                             Navigator.pop(context);
  //                           },
  //                           icon: const Icon(
  //                             Icons.close,
  //                             color: Colors.black54,
  //                             size: 25,
  //                           ),
  //                         ),
  //                         const Spacer(),
  //                         const Text(
  //                           'New List',
  //                           style: TextStyle(
  //                             color: Colors.black,
  //                             fontSize: 22,
  //                             fontWeight: FontWeight.w700,
  //                           ),
  //                         ),
  //                         const Spacer(),
  //                         GestureDetector(
  //                           onTap: () {
  //                             Navigator.pop(context);
  //                           },
  //                           child: Container(
  //                             color: Colors.transparent,
  //                             padding: const EdgeInsets.all(8),
  //                             child: const Text('Save'),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 25),
  //                     // Visibility
  //                     Row(
  //                       children: [
  //                         const Text(
  //                           'Visibility',
  //                           style: TextStyle(
  //                             fontSize: 18,
  //                             fontWeight: FontWeight.w600,
  //                           ),
  //                         ),
  //                         const Spacer(),
  //                         GestureDetector(
  //                           onTap: () {
  //                             myState(() {
  //                               isPublic = true;
  //                             });
  //                           },
  //                           child: Container(
  //                             width: MediaQuery.of(context).size.width * 0.25,
  //                             height: 40,
  //                             decoration: BoxDecoration(
  //                               borderRadius: BorderRadius.circular(30),
  //                               border: Border.all(
  //                                 color: isPublic
  //                                     ? Colors.blue[500]!
  //                                     : Colors.black54,
  //                                 width: 1,
  //                               ),
  //                               color:
  //                                   isPublic ? Colors.blue[500]! : Colors.white,
  //                             ),
  //                             child: Row(
  //                               mainAxisAlignment:
  //                                   MainAxisAlignment.spaceEvenly,
  //                               children: [
  //                                 Icon(
  //                                   Icons.lock_open,
  //                                   color: isPublic
  //                                       ? Colors.white
  //                                       : Colors.black54,
  //                                 ),
  //                                 Text(
  //                                   'Public',
  //                                   style: TextStyle(
  //                                     color: isPublic
  //                                         ? Colors.white
  //                                         : Colors.black54,
  //                                     fontWeight: FontWeight.w600,
  //                                   ),
  //                                 )
  //                               ],
  //                             ),
  //                           ),
  //                         ),
  //                         const SizedBox(width: 5),
  //                         GestureDetector(
  //                           onTap: () {
  //                             myState(() {
  //                               isPublic = false;
  //                             });
  //                           },
  //                           child: Container(
  //                             width: MediaQuery.of(context).size.width * 0.25,
  //                             height: 40,
  //                             decoration: BoxDecoration(
  //                               borderRadius: BorderRadius.circular(30),
  //                               border: Border.all(
  //                                 color: !isPublic
  //                                     ? Colors.blue[500]!
  //                                     : Colors.black54,
  //                                 width: 1,
  //                               ),
  //                               color: !isPublic
  //                                   ? Colors.blue[500]!
  //                                   : Colors.white,
  //                             ),
  //                             child: Row(
  //                               mainAxisAlignment:
  //                                   MainAxisAlignment.spaceEvenly,
  //                               children: [
  //                                 Icon(
  //                                   Icons.lock_outline,
  //                                   color: !isPublic
  //                                       ? Colors.white
  //                                       : Colors.black54,
  //                                 ),
  //                                 Text(
  //                                   'Private',
  //                                   style: TextStyle(
  //                                     color: !isPublic
  //                                         ? Colors.white
  //                                         : Colors.black54,
  //                                     fontWeight: FontWeight.w600,
  //                                   ),
  //                                 )
  //                               ],
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 25),
  //                     // TextField for List Title
  //                     Container(
  //                       width: MediaQuery.of(context).size.width * 0.9,
  //                       decoration: BoxDecoration(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       child: TextField(
  //                         focusNode: _focusNode1,
  //                         controller: _controller1,
  //                         onChanged: (text) {
  //                           myState(() {});
  //                         },
  //                         cursorColor: Colors.black38,
  //                         decoration: InputDecoration(
  //                           suffixIcon: _controller1.text.isEmpty
  //                               ? null
  //                               : InkWell(
  //                                   onTap: () {
  //                                     myState(() {
  //                                       _controller1.clear();
  //                                     });
  //                                   },
  //                                   child: Icon(
  //                                     Icons.clear,
  //                                     color: Colors.black54,
  //                                   ),
  //                                 ),
  //                           hintText: 'List Title',
  //                           border: OutlineInputBorder(
  //                             borderRadius: BorderRadius.circular(10),
  //                           ),
  //                           filled: true,
  //                           fillColor: Colors.white,
  //                           focusedBorder: OutlineInputBorder(
  //                             borderSide: const BorderSide(color: Colors.blue),
  //                             borderRadius: BorderRadius.circular(10),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 10),
  //                     // TextField for List Description
  //                     Container(
  //                       width: MediaQuery.of(context).size.width * 0.9,
  //                       decoration: BoxDecoration(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       child: TextField(
  //                         focusNode: _focusNode2,
  //                         controller: _controller2,
  //                         onChanged: (text) {
  //                           myState(() {});
  //                         },
  //                         cursorColor: Colors.black38,
  //                         decoration: InputDecoration(
  //                           suffixIcon: _controller2.text.isEmpty
  //                               ? null
  //                               : InkWell(
  //                                   onTap: () {
  //                                     myState(() {
  //                                       _controller2.clear();
  //                                     });
  //                                   },
  //                                   child: Icon(
  //                                     Icons.clear,
  //                                     color: Colors.black54,
  //                                   ),
  //                                 ),
  //                           hintText: 'List Description (optional)',
  //                           border: OutlineInputBorder(
  //                             borderRadius: BorderRadius.circular(10),
  //                           ),
  //                           filled: true,
  //                           fillColor: Colors.white,
  //                           focusedBorder: OutlineInputBorder(
  //                             borderSide: const BorderSide(color: Colors.blue),
  //                             borderRadius: BorderRadius.circular(10),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 25),
  //                     // Icon selection
  //                     const Text(
  //                       'Select Icon',
  //                       style: TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 15),
  //                     Padding(
  //                       padding: const EdgeInsets.symmetric(horizontal: 6),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: [
  //                           GestureDetector(
  //                             onTap: () {
  //                               myState(() {
  //                                 selectedIcon = Icons.star;
  //                               });
  //                             },
  //                             child: Container(
  //                               width: 55,
  //                               height: 55,
  //                               decoration: BoxDecoration(
  //                                 shape: BoxShape.circle,
  //                                 border: Border.all(
  //                                   color: (selectedIcon == Icons.star)
  //                                       ? Colors.blue[500]!
  //                                       : Colors.transparent,
  //                                   width: 4,
  //                                 ),
  //                               ),
  //                               child: Icon(
  //                                 Icons.star,
  //                                 size: 35,
  //                                 color: Colors.blue[900],
  //                               ),
  //                             ),
  //                           ),
  //                           GestureDetector(
  //                             onTap: () {
  //                               myState(() {
  //                                 selectedIcon = Icons.favorite;
  //                               });
  //                             },
  //                             child: Container(
  //                               width: 55,
  //                               height: 55,
  //                               decoration: BoxDecoration(
  //                                 shape: BoxShape.circle,
  //                                 border: Border.all(
  //                                   color: (selectedIcon == Icons.favorite)
  //                                       ? Colors.blue[500]!
  //                                       : Colors.transparent,
  //                                   width: 4,
  //                                 ),
  //                               ),
  //                               child: Icon(
  //                                 Icons.favorite,
  //                                 size: 35,
  //                                 color: Colors.blue[900],
  //                               ),
  //                             ),
  //                           ),
  //                           GestureDetector(
  //                             onTap: () {
  //                               myState(() {
  //                                 selectedIcon = Icons.check;
  //                               });
  //                             },
  //                             child: Container(
  //                               width: 55,
  //                               height: 55,
  //                               decoration: BoxDecoration(
  //                                 shape: BoxShape.circle,
  //                                 border: Border.all(
  //                                   color: (selectedIcon == Icons.check)
  //                                       ? Colors.blue[500]!
  //                                       : Colors.transparent,
  //                                   width: 4,
  //                                 ),
  //                               ),
  //                               child: Icon(
  //                                 Icons.check,
  //                                 size: 35,
  //                                 color: Colors.blue[900],
  //                               ),
  //                             ),
  //                           ),
  //                           GestureDetector(
  //                             onTap: () {
  //                               myState(() {
  //                                 selectedIcon = Icons.thumb_up;
  //                               });
  //                             },
  //                             child: Container(
  //                               width: 55,
  //                               height: 55,
  //                               decoration: BoxDecoration(
  //                                 shape: BoxShape.circle,
  //                                 border: Border.all(
  //                                   color: (selectedIcon == Icons.thumb_up)
  //                                       ? Colors.blue[500]!
  //                                       : Colors.transparent,
  //                                   width: 4,
  //                                 ),
  //                               ),
  //                               child: Icon(
  //                                 Icons.thumb_up,
  //                                 size: 35,
  //                                 color: Colors.blue[900],
  //                               ),
  //                             ),
  //                           ),
  //                           GestureDetector(
  //                             onTap: () {
  //                               myState(() {
  //                                 selectedIcon = Icons.mood;
  //                               });
  //                             },
  //                             child: Container(
  //                               width: 55,
  //                               height: 55,
  //                               decoration: BoxDecoration(
  //                                 shape: BoxShape.circle,
  //                                 border: Border.all(
  //                                   color: (selectedIcon == Icons.mood)
  //                                       ? Colors.blue[500]!
  //                                       : Colors.transparent,
  //                                   width: 4,
  //                                 ),
  //                               ),
  //                               child: Icon(
  //                                 Icons.mood,
  //                                 size: 35,
  //                                 color: Colors.blue[900],
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     const SizedBox(height: 25),
  //                     Padding(
  //                       padding: const EdgeInsets.symmetric(horizontal: 6),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: [
  //                           GestureDetector(
  //                             onTap: () {
  //                               myState(() {
  //                                 selectedIcon = Icons.local_cafe;
  //                               });
  //                             },
  //                             child: Container(
  //                               width: 55,
  //                               height: 55,
  //                               decoration: BoxDecoration(
  //                                 shape: BoxShape.circle,
  //                                 border: Border.all(
  //                                   color: (selectedIcon == Icons.local_cafe)
  //                                       ? Colors.blue[500]!
  //                                       : Colors.transparent,
  //                                   width: 4,
  //                                 ),
  //                               ),
  //                               child: Icon(
  //                                 Icons.local_cafe,
  //                                 size: 35,
  //                                 color: Colors.blue[900],
  //                               ),
  //                             ),
  //                           ),
  //                           GestureDetector(
  //                             onTap: () {
  //                               myState(() {
  //                                 selectedIcon = Icons.fastfood;
  //                               });
  //                             },
  //                             child: Container(
  //                               width: 55,
  //                               height: 55,
  //                               decoration: BoxDecoration(
  //                                 shape: BoxShape.circle,
  //                                 border: Border.all(
  //                                   color: (selectedIcon == Icons.fastfood)
  //                                       ? Colors.blue[500]!
  //                                       : Colors.transparent,
  //                                   width: 4,
  //                                 ),
  //                               ),
  //                               child: Icon(
  //                                 Icons.fastfood,
  //                                 size: 35,
  //                                 color: Colors.blue[900],
  //                               ),
  //                             ),
  //                           ),
  //                           GestureDetector(
  //                             onTap: () {
  //                               myState(() {
  //                                 selectedIcon = Icons.icecream;
  //                               });
  //                             },
  //                             child: Container(
  //                               width: 55,
  //                               height: 55,
  //                               decoration: BoxDecoration(
  //                                 shape: BoxShape.circle,
  //                                 border: Border.all(
  //                                   color: (selectedIcon == Icons.icecream)
  //                                       ? Colors.blue[500]!
  //                                       : Colors.transparent,
  //                                   width: 4,
  //                                 ),
  //                               ),
  //                               child: Icon(
  //                                 Icons.icecream,
  //                                 size: 35,
  //                                 color: Colors.blue[900],
  //                               ),
  //                             ),
  //                           ),
  //                           GestureDetector(
  //                             onTap: () {
  //                               myState(() {
  //                                 selectedIcon = Icons.ramen_dining;
  //                               });
  //                             },
  //                             child: Container(
  //                               width: 55,
  //                               height: 55,
  //                               decoration: BoxDecoration(
  //                                 shape: BoxShape.circle,
  //                                 border: Border.all(
  //                                   color: (selectedIcon == Icons.ramen_dining)
  //                                       ? Colors.blue[500]!
  //                                       : Colors.transparent,
  //                                   width: 4,
  //                                 ),
  //                               ),
  //                               child: Icon(
  //                                 Icons.ramen_dining,
  //                                 size: 35,
  //                                 color: Colors.blue[900],
  //                               ),
  //                             ),
  //                           ),
  //                           GestureDetector(
  //                             onTap: () {
  //                               myState(() {
  //                                 selectedIcon = Icons.egg_alt;
  //                               });
  //                             },
  //                             child: Container(
  //                               width: 55,
  //                               height: 55,
  //                               decoration: BoxDecoration(
  //                                 shape: BoxShape.circle,
  //                                 border: Border.all(
  //                                   color: (selectedIcon == Icons.egg_alt)
  //                                       ? Colors.blue[500]!
  //                                       : Colors.transparent,
  //                                   width: 4,
  //                                 ),
  //                               ),
  //                               child: Icon(
  //                                 Icons.egg_alt,
  //                                 size: 35,
  //                                 color: Colors.blue[900],
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     const SizedBox(height: 25),
  //                     // Color selection
  //                     const Text(
  //                       'Select Color',
  //                       style: TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 15),
  //                     Container(
  //                       height: 40,
  //                       padding: const EdgeInsets.symmetric(horizontal: 6),
  //                       child: ListView.builder(
  //                         itemCount: colorList.length,
  //                         scrollDirection: Axis.horizontal,
  //                         itemBuilder: (BuildContext context, index) {
  //                           return GestureDetector(
  //                             onTap: () {
  //                               myState(() {
  //                                 selectedColor = colorList[index];
  //                               });
  //                             },
  //                             child: Container(
  //                               margin:
  //                                   const EdgeInsets.symmetric(horizontal: 10),
  //                               width: 25,
  //                               height: 25,
  //                               decoration: BoxDecoration(
  //                                 shape: BoxShape.circle,
  //                                 color: colorList[index],
  //                                 boxShadow: (selectedColor == colorList[index])
  //                                     ? [
  //                                         BoxShadow(
  //                                           color: colorList[index]
  //                                               .withOpacity(0.3),
  //                                           spreadRadius: 7,
  //                                         )
  //                                       ]
  //                                     : null,
  //                               ),
  //                               child: (selectedColor == colorList[index])
  //                                   ? const Icon(
  //                                       Icons.check,
  //                                       size: 18,
  //                                       color: Colors.white,
  //                                     )
  //                                   : const SizedBox.shrink(),
  //                             ),
  //                           );
  //                         },
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
}
