import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shortsmap/Widgets/BottomNavBar.dart';

class MapPage1 extends StatefulWidget {
  const MapPage1({super.key});

  @override
  State<MapPage1> createState() => _MapPage1State();
}

class _MapPage1State extends State<MapPage1> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  late GoogleMapController _mapController;

  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.793503213905154, -122.39945983265487),
    zoom: 20.0,
  );

  double _widgetHeight = 0;
  double _fabPosition = 0;

  double _mapBottomPadding = 0.0;

  // double _sheetSize = 0;

  bool _isListDetailOpened = false;

  // 현재 위치를 가져와서 지도 카메라를 이동시키는 함수
  Future<void> _getInitialLocation() async {
    try {
      // 원하는 정확도로 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 가져온 위치를 이용해 새 카메라 위치 생성
      CameraPosition newPosition = CameraPosition(
        target: LatLng(37.793503213905154, -122.39945983265487),
        zoom: 20.0, // 원하는 줌 레벨로 설정
      );

      // 맵 컨트롤러가 준비되었으면 카메라 이동
      if (_mapController != null) {
        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(newPosition),
        );
      } else {
        // 맵 컨트롤러가 아직 생성되지 않은 경우, setState로 초기 카메라 위치 변경
        setState(() {
          _initialCameraPosition = newPosition;
        });
      }
    } catch (e) {
      print("현재 위치를 가져오는 중 에러 발생: $e");
    }
  }

  Future<void> _moveToCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _widgetHeight = MediaQuery.of(context).size.height;
        _fabPosition = _sheetController.size * _widgetHeight;
        _mapBottomPadding =
            (_sheetController.size <= 0.5)
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
                        bottom:
                            (_fabPosition < 300)
                                ? _mapBottomPadding
                                : _mapBottomPadding - 20,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                        // 컨트롤러가 생성된 후에도 현재 위치로 카메라 이동
                        _getInitialLocation();
                      },
                      onCameraMoveStarted: () {
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
                    ),
                  ),
                  // 검색창
                  Visibility(
                    visible: (!_isListDetailOpened && _fabPosition < 700),
                    child: Positioned(
                      top: 70,
                      left: 10,
                      right: 10,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          onTap: () {
                            _sheetController.animateTo(
                              0.05,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          focusNode: _focusNode,
                          controller: _textEditingController,
                          onChanged: (text) {
                            setState(() {});
                          },
                          cursorColor: Colors.black38,
                          decoration: InputDecoration(
                            prefixIcon: GestureDetector(
                              child: InkWell(
                                onTap: () => print('asd'),
                                child: Icon(Icons.menu, color: Colors.black54),
                              ),
                              onTap: () {},
                            ),
                            suffixIcon:
                                _textEditingController.text.isEmpty
                                    ? null
                                    : InkWell(
                                      onTap:
                                          () => setState(() {
                                            _textEditingController.clear();
                                          }),
                                      child: Icon(
                                        Icons.clear,
                                        color: Colors.black54,
                                      ),
                                    ),
                            hintText: 'Search Here!',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 내위치버튼
                  Visibility(
                    visible: _fabPosition < 700,
                    child: Positioned(
                      bottom:
                          (_fabPosition < 300)
                              ? _fabPosition + 5
                              : (_fabPosition < 500)
                              ? _fabPosition - 20
                              : _fabPosition - 40,
                      right: 10,
                      child: SizedBox(
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
                              // 스크롤 가능한 전체 콘텐츠 영역
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
                                      const SizedBox(height: 10),
                                      // 실제 스크롤 되는 콘텐츠
                                      _isListDetailOpened
                                          ? Padding(
                                            padding: const EdgeInsets.only(
                                              top: 15,
                                              left: 15,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 20,
                                                      backgroundColor:
                                                          Colors.green,
                                                      child: Icon(
                                                        Icons.star_outline,
                                                        color: Colors.white,
                                                        size: 25,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      'ㅇㅇㅇ',
                                                      style: TextStyle(
                                                        fontSize: 28,
                                                      ),
                                                    ),
                                                    Spacer(),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 20,
                                                          ),
                                                      child: CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor:
                                                            Colors.grey[300],
                                                        child: Icon(
                                                          CupertinoIcons.share,
                                                          color: Colors.black,
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )
                                          : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              // "Add New List" 영역
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 12,
                                                ),
                                                child: Column(
                                                  children: [
                                                    ListTile(
                                                      onTap: () {
                                                        _showAddNewBottomSheet();
                                                      },
                                                      leading: Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            color:
                                                                Colors.black54,
                                                            width: 0.6,
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.add,
                                                          color: Colors.black54,
                                                          size: 28,
                                                        ),
                                                      ),
                                                      title: const Text(
                                                        'Add New List',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                          ),
                                                      child: Divider(
                                                        color: Colors.grey[300],
                                                        height: 1.5,
                                                        thickness: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // 리스트 항목 영역 (ListView.separated 사용)
                                              ListView.separated(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount: 4,
                                                itemBuilder: (context, index) {
                                                  return _folderTile();
                                                },
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
                                                      color: Colors.grey[300],
                                                      height: 1.5,
                                                      thickness: 1,
                                                    ),
                                                  );
                                                },
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
    IconData icon = Icons.star_outline,
    int locations = 0,
    int share = 0,
  }) {
    return ListTile(
      onTap: () {
        _sheetController.animateTo(
          0.5,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _isListDetailOpened = true;
        });
      },
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 25),
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
          const Icon(Icons.location_on, size: 16),
          Text(locations.toString()),
          const Text(
            ' · ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.person, size: 16),
          Text(share.toString()),
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

  void _showAddNewBottomSheet() {
    showModalBottomSheet(
      enableDrag: false,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      context: context,
      builder: (context) {
        IconData selectedIcon = Icons.star;
        Color selectedColor = Colors.red;
        bool isPublic = false;

        List<Color> colorList = [
          Colors.red,
          Colors.orange,
          Colors.lightGreen,
          Colors.green,
          Colors.lightBlue,
          Colors.indigo,
          Colors.indigo[900]!,
          Colors.deepPurple,
          Colors.pink[100]!,
        ];

        final TextEditingController _controller1 = TextEditingController();
        final TextEditingController _controller2 = TextEditingController();

        final FocusNode _focusNode1 = FocusNode();
        final FocusNode _focusNode2 = FocusNode();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter myState) {
            return GestureDetector(
              onTap: () {
                _focusNode1.unfocus();
                _focusNode2.unfocus();
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.93,
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      // Appbar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.black54,
                              size: 25,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'New List',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.all(8),
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      // Visibility
                      Row(
                        children: [
                          const Text(
                            'Visibility',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              myState(() {
                                isPublic = true;
                              });
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.25,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color:
                                      isPublic
                                          ? Colors.blue[500]!
                                          : Colors.black54,
                                  width: 1,
                                ),
                                color:
                                    isPublic ? Colors.blue[500]! : Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                    Icons.lock_open,
                                    color:
                                        isPublic
                                            ? Colors.white
                                            : Colors.black54,
                                  ),
                                  Text(
                                    'Public',
                                    style: TextStyle(
                                      color:
                                          isPublic
                                              ? Colors.white
                                              : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () {
                              myState(() {
                                isPublic = false;
                              });
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.25,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color:
                                      !isPublic
                                          ? Colors.blue[500]!
                                          : Colors.black54,
                                  width: 1,
                                ),
                                color:
                                    !isPublic
                                        ? Colors.blue[500]!
                                        : Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    color:
                                        !isPublic
                                            ? Colors.white
                                            : Colors.black54,
                                  ),
                                  Text(
                                    'Private',
                                    style: TextStyle(
                                      color:
                                          !isPublic
                                              ? Colors.white
                                              : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      // TextField for List Title
                      Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          focusNode: _focusNode1,
                          controller: _controller1,
                          onChanged: (text) {
                            myState(() {});
                          },
                          cursorColor: Colors.black38,
                          decoration: InputDecoration(
                            suffixIcon:
                                _controller1.text.isEmpty
                                    ? null
                                    : InkWell(
                                      onTap: () {
                                        myState(() {
                                          _controller1.clear();
                                        });
                                      },
                                      child: Icon(
                                        Icons.clear,
                                        color: Colors.black54,
                                      ),
                                    ),
                            hintText: 'List Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // TextField for List Description
                      Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          focusNode: _focusNode2,
                          controller: _controller2,
                          onChanged: (text) {
                            myState(() {});
                          },
                          cursorColor: Colors.black38,
                          decoration: InputDecoration(
                            suffixIcon:
                                _controller2.text.isEmpty
                                    ? null
                                    : InkWell(
                                      onTap: () {
                                        myState(() {
                                          _controller2.clear();
                                        });
                                      },
                                      child: Icon(
                                        Icons.clear,
                                        color: Colors.black54,
                                      ),
                                    ),
                            hintText: 'List Description (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      // Icon selection
                      const Text(
                        'Select Icon',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                myState(() {
                                  selectedIcon = Icons.star;
                                });
                              },
                              child: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (selectedIcon == Icons.star)
                                            ? Colors.blue[500]!
                                            : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.star,
                                  size: 35,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                myState(() {
                                  selectedIcon = Icons.favorite;
                                });
                              },
                              child: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (selectedIcon == Icons.favorite)
                                            ? Colors.blue[500]!
                                            : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.favorite,
                                  size: 35,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                myState(() {
                                  selectedIcon = Icons.check;
                                });
                              },
                              child: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (selectedIcon == Icons.check)
                                            ? Colors.blue[500]!
                                            : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 35,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                myState(() {
                                  selectedIcon = Icons.thumb_up;
                                });
                              },
                              child: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (selectedIcon == Icons.thumb_up)
                                            ? Colors.blue[500]!
                                            : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.thumb_up,
                                  size: 35,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                myState(() {
                                  selectedIcon = Icons.mood;
                                });
                              },
                              child: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (selectedIcon == Icons.mood)
                                            ? Colors.blue[500]!
                                            : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.mood,
                                  size: 35,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                myState(() {
                                  selectedIcon = Icons.local_cafe;
                                });
                              },
                              child: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (selectedIcon == Icons.local_cafe)
                                            ? Colors.blue[500]!
                                            : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.local_cafe,
                                  size: 35,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                myState(() {
                                  selectedIcon = Icons.fastfood;
                                });
                              },
                              child: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (selectedIcon == Icons.fastfood)
                                            ? Colors.blue[500]!
                                            : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.fastfood,
                                  size: 35,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                myState(() {
                                  selectedIcon = Icons.icecream;
                                });
                              },
                              child: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (selectedIcon == Icons.icecream)
                                            ? Colors.blue[500]!
                                            : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.icecream,
                                  size: 35,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                myState(() {
                                  selectedIcon = Icons.ramen_dining;
                                });
                              },
                              child: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (selectedIcon == Icons.ramen_dining)
                                            ? Colors.blue[500]!
                                            : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.ramen_dining,
                                  size: 35,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                myState(() {
                                  selectedIcon = Icons.egg_alt;
                                });
                              },
                              child: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (selectedIcon == Icons.egg_alt)
                                            ? Colors.blue[500]!
                                            : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.egg_alt,
                                  size: 35,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      // Color selection
                      const Text(
                        'Select Color',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ListView.builder(
                          itemCount: colorList.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (BuildContext context, index) {
                            return GestureDetector(
                              onTap: () {
                                myState(() {
                                  selectedColor = colorList[index];
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorList[index],
                                  boxShadow:
                                      (selectedColor == colorList[index])
                                          ? [
                                            BoxShadow(
                                              color: colorList[index]
                                                  .withOpacity(0.3),
                                              spreadRadius: 7,
                                            ),
                                          ]
                                          : null,
                                ),
                                child:
                                    (selectedColor == colorList[index])
                                        ? const Icon(
                                          Icons.check,
                                          size: 18,
                                          color: Colors.white,
                                        )
                                        : const SizedBox.shrink(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
