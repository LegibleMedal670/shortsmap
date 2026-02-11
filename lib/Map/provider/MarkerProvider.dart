import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shortsmap/Map/model/LocationData.dart';
import 'package:shortsmap/Provider/BookmarkProvider.dart';

class MarkerDataProvider extends ChangeNotifier {
  final BookmarkProvider bookmarkProvider;

  MarkerDataProvider({
    required this.bookmarkProvider,
  }) {
    bookmarkProvider.addListener(_updateBookmarks);
    _updateBookmarks();
  }



  /// ✅ 변수 영역 시작

  // 화면 내의 장소들의 데이터를 저장하기 위한 변수
  Set<MarkerLocationData> _viewPortLocations = {};
  // 북마크 장소들의 데이터를 저장하기 위한 변수
  Set<MarkerLocationData> _bookmarkLocations = {};
  // 장소 마커들을 저장하기 위한 변수
  Set<Marker> _locationMarkers = {};

  // 마커 아이콘 캐싱을 위한 변수
  final Map<String, BitmapDescriptor> _markerIconCache = {};
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

  // 북마크 여부 확인용 변수
  bool _isBookmarkMode = false;

  // 카테고리 확인용 변수
  String? _selectedCategory;

  // 마커 탭 시 화면 이동할 때 바텀시트 내려가는걸 방지하기 위한 변수
  bool _isProgrammaticMove = false;
  // 탭한 마커의 장소 정보를 저장하기 위한 변수들
  String? _selectedLocation;
  String? _selectedVideoId;
  // 탭한 마커의 디테일한 정보Future를 저장하기 위한 변수
  Future<Map<String, dynamic>>? _locationDetailFuture;

  // 바텀시트에 표시할 대략적인 장소들의 정보Future를 저장하기 위한 변수
  Future<List<Map<String, dynamic>>>? _currentLocationsFuture;

  // 마커 로딩 확인용 변수
  bool _isMarkerLoading = false;
  // 카테고리 로딩 확인용 변수
  bool _isCategoryChanging = false;

  // 최근 불러온 컨트롤러와 좌표 저장용 변수
  // DraggableScrollableController? _lastSheetController;
  // double? _lastCenterLat, _lastCenterLng;


  /// ❌ 변수 영역 끝



  /// ✅ Getter, Setter 영역 시작

  // 현재 소스(Set)에 포함된 고유 카테고리 목록을 반환하는 Getter
  List<String> get availableCategories {
    final source = _isBookmarkMode ? _bookmarkLocations : _viewPortLocations;
    // map으로 category만 뽑아서 Set으로 중복 제거, 다시 List로 변환
    final categories = source
        .map((loc) => loc.category)
        .toSet()
        .toList();

    return categories;
  }

  // 필터링된 장소 데이터를 반환하는 Getter
  Set<MarkerLocationData> get currentLocations {
    final source = _isBookmarkMode ? _bookmarkLocations : _viewPortLocations;
    if (_selectedCategory == null) {
      return source;
    }
    return source.where((loc) => loc.category == _selectedCategory).toSet();
  }

  // 필터링된 장소 개수 반환하는 Getter
  int get currentLocationLength {
    final source = _isBookmarkMode ? _bookmarkLocations : _viewPortLocations;
    if (_selectedCategory == null) {
      return source.length;
    }
    return source.where((loc) => loc.category == _selectedCategory).length;
  }

  // 마커들을 반환하는 Getter
  Set<Marker> get locationMarkers => _locationMarkers;

  // 마커 로딩 여부 반환하는 Getter
  bool get isMarkerLoading => _isMarkerLoading;

  // 카테고리 로딩 여부 반환하는 Getter
  bool get isCategoryChanging => _isCategoryChanging;

  // 버튼 눌러서 이동하는지 여부 변수를 리턴하는 Getter
  bool get isProgrammaticMove => _isProgrammaticMove;

  // 탭한 마커의 장소 정보를 리턴하는 Getter
  String? get selectedLocation => _selectedLocation;
  String? get selectedVideoId => _selectedVideoId;

  // 탭한 마커의 디테일한 정보Future를 리턴하는 Getter
  Future<Map<String, dynamic>>? get locationDetailFuture => _locationDetailFuture;

  // 현재 장소들의 데이터Future를 리턴하는 Getter
  Future<List<Map<String, dynamic>>>? get currentLocationsFuture => _currentLocationsFuture;

  // 선택한 카테고리를 리턴하는 Getter
  String? get selectedCategory => _selectedCategory;

  // 카테고리 선택을 위한 Setter
  // set selectCategory(String? category) {
  //   _selectedCategory = category;
  //   _selectedLocation = null;
  //   _selectedVideoId = null;
  //   _isCategoryChanging = true;
  //   if (_lastSheetController != null && _lastCenterLat != null) {
  //     _buildLocationMarkers(_lastSheetController!, _lastCenterLat!, _lastCenterLng!);
  //   }
  //   notifyListeners();
  // }

  // 북마크 모드 선택을 위한 Setter
  set setBookmarkMode(bool val) {
    _isBookmarkMode = val;
    notifyListeners();
  }

  // 장소 선택을 위한 Setter
  set setSelectedLocation(String? placeId){
    _selectedLocation = placeId;
    if (placeId != null) _locationDetailFuture = _fetchLocationDetail(placeId);
    notifyListeners();
  }

  // 장소 비디오 아이디 선택을 위한 Setter
  set setSelectedVideoId(String? videoId){
    _selectedVideoId = videoId;
    notifyListeners();
  }

  // 프로그램으로 인한 움직임을 조정하기 위한 Setter
  set setIsProgrammaticMove(bool val){
    _isProgrammaticMove = val;
    notifyListeners();
  }


  /// ❌ Getter, Setter 영역 끝



  /// ✅ 함수 영역 시작

  // Supabase를 통해 현재 지도 뷰포트 영역의 장소 데이터를 로드하는 함수
  Future<void> loadLocationsInViewport({
    required BuildContext context,
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    required DraggableScrollableController sheetController,
  }) async {
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;

    print('latSpan: $latSpan, lngSpan: $lngSpan');

    // 🔥 너무 넓은 영역 제한
    if (latSpan > 0.06 || lngSpan > 0.06) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('지도를 더 확대해 주세요. 현재 범위가 너무 넓습니다.')),
      );
      return;
    }

    try {

      _isMarkerLoading = true;

      notifyListeners();

      _viewPortLocations = {};

      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final halfLatSpan = latSpan / 2;
      final halfLngSpan = lngSpan / 2;

      const expandFactor = 1.2;
      final expandedMinLat = centerLat - halfLatSpan * expandFactor;
      final expandedMaxLat = centerLat + halfLatSpan * expandFactor;
      final expandedMinLng = centerLng - halfLngSpan * expandFactor;
      final expandedMaxLng = centerLng + halfLngSpan * expandFactor;

      final response = await Supabase.instance.client.rpc(
        'get_locations_in_viewport',
        params: {
          'min_lat': expandedMinLat,
          'max_lat': expandedMaxLat,
          'min_lng': expandedMinLng,
          'max_lng': expandedMaxLng,
        },
      );

      print('expandedMinLat: $expandedMinLat  expandedMaxLat: $expandedMaxLat  expandedMinLng: $expandedMinLng  expandedMaxLng: $expandedMaxLng');

      _viewPortLocations = (response as List)
          .map((e) => MarkerLocationData.fromMap(e))
          .toSet();

      // for (MarkerLocationData data in _viewPortLocations){
      //   print(data.placeId);
      // }

      // _lastSheetController = sheetController;
      // _lastCenterLat = centerLat;
      // _lastCenterLng = centerLng;

      await _buildLocationMarkers(sheetController, centerLat, centerLng);

      notifyListeners();
    } catch (e) {
      print('로드 실패: $e');
    }
  }

  // 북마크 데이터 업데이트 (기존 로직 유지)
  void _updateBookmarks() {


    _bookmarkLocations = bookmarkProvider.bookmarks
        .map((b) => MarkerLocationData.fromBookmark(b))
        .toSet();

    notifyListeners();
  }

  // 마커의 아이콘을 그리는 함수
  Future<BitmapDescriptor> _getMarkerIcon({
    required Color backgroundColor,
    required IconData iconData,
    double size = 80,     // 논리적 크기 (예: 80x80)
    double iconSize = 40, // 논리적 내부 아이콘 크기
  }) async {
    // 1) 캐시 key 생성 (컬러·아이콘·크기 조합)
    final cacheKey = '${backgroundColor.toARGB32()}_${iconData.codePoint}_${size.toInt()}_${iconSize.toInt()}';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    // --- 기존 그리기 로직 그대로 유지 ---
    final double scale = PlatformDispatcher.instance.views.first.devicePixelRatio;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    canvas.scale(scale);

    final double borderWidth = 4.0;
    final Paint borderPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

    final Paint innerPaint = Paint()..color = backgroundColor;
    canvas.drawCircle(Offset(size / 2, size / 2), (size / 2) - borderWidth, innerPaint);

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        fontSize: iconSize,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    final double xCenter = (size - textPainter.width) / 2;
    final double yCenter = (size - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(xCenter, yCenter));

    final ui.Image hiResImage = await pictureRecorder.endRecording().toImage(
      (size * scale).toInt(),
      (size * scale).toInt(),
    );
    final ByteData? hiResByteData = await hiResImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List hiResPngBytes = hiResByteData!.buffer.asUint8List();

    final ui.Codec codec = await ui.instantiateImageCodec(
      hiResPngBytes,
      targetWidth: size.toInt(),
      targetHeight: size.toInt(),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image resizedImage = frameInfo.image;
    final ByteData? resizedByteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedPngBytes = resizedByteData!.buffer.asUint8List();
    // --- 그리기 로직 끝 ---

    // 2) 캐시에 저장하고 반환
    final descriptor = BitmapDescriptor.fromBytes(resizedPngBytes);
    _markerIconCache[cacheKey] = descriptor;
    return descriptor;
  }

  // 마커를 그리는 함수
  Future<void> _buildLocationMarkers(DraggableScrollableController sheetController, double calcLat, double calcLng) async {

    // 마커를 그릴 장소 데이터들을 저장할 변수
    Set<MarkerLocationData> locationData;

    // 북마크 여부에 따른 소스 선택
    final source = _isBookmarkMode ? _bookmarkLocations : _viewPortLocations;

    // 소스가 비어있다면 빈 세트 리턴
    if (source.isEmpty) {
      _locationMarkers = {};
    }

    // 카테고리 선택이 되어있지 않으면 소스를 그대로 이용
    if (_selectedCategory == null) {
      locationData = source;
    } else {
      // 카테고리가 선택되어 있으면 필터링해서 이용
      locationData = source.where((loc) => loc.category == _selectedCategory).toSet();
    }

    // 그린 마커를 저장할 변수
    Set<Marker> markers = {};

    for (final data in locationData) {
      final style = categoryStyles[data.category] ?? {
        'icon': Icons.place,
        'color': Colors.blue,
      };

      final icon = await _getMarkerIcon(
        backgroundColor: style['color'],
        iconData: style['icon'],
        size: 100,
        iconSize: 60,
      );

      markers.add(Marker(
        markerId: MarkerId(data.placeId),
        position: LatLng(data.latitude, data.longitude),
        icon: icon,
        onTap: () {

          FirebaseAnalytics.instance.logEvent(name: "tap_marker", parameters: {
            "video_id": data.videoId,
            "category": data.category,
          });


          _isProgrammaticMove = true;
          _selectedLocation = data.placeId;
          _selectedVideoId = data.videoId;
          _locationDetailFuture =  _fetchLocationDetail(data.placeId);

          notifyListeners();

          sheetController.animateTo(0.55, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ));
    }

    await _fetchCurrentLocations(locationData, calcLat, calcLng);

    await Future.delayed(Duration(milliseconds: 1000));


    _isMarkerLoading = false;
    _isCategoryChanging = false;


    _locationMarkers = markers;



    notifyListeners();

  }

  // 특정 장소의 디테일한 정보를 가져오는 함수
  Future<Map<String, dynamic>> _fetchLocationDetail(String placeId) async {


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

  Future<void> _fetchCurrentLocations(Set<MarkerLocationData> source, double calcLat, double calcLng) async {

    // 중앙 지점과의 거리순으로 장소 데이터 정렬 ( 머로할지정하기 )
    final list = source.toList();
    list.sort((a, b) {
      final da = Geolocator.distanceBetween(
          calcLat, calcLng, a.latitude, a.longitude);
      final db = Geolocator.distanceBetween(
          calcLat, calcLng, b.latitude, b.longitude);
      return da.compareTo(db);
    });

    final sortedIds = list.map((e) => e.placeId).toList();

    // 정렬된 순서에 따라 장소 정보 불러오기
    _currentLocationsFuture = Supabase.instance.client
        .rpc('get_locations_by_ids', params: {
          '_ids': sortedIds,
        }).then((value) {
          final locations = List<Map<String, dynamic>>.from(value);

          // 정렬된 place_id 순서에 맞게 다시 재정렬
          locations.sort((a, b) =>
          sortedIds.indexOf(a['place_id']) - sortedIds.indexOf(b['place_id']));

          return locations;
        });

  }

  void selectCategory(String? category, DraggableScrollableController sheetController, double? centerLat, double? centerLng){
    _selectedCategory = category;
    _selectedLocation = null;
    _selectedVideoId = null;
    _isCategoryChanging = true;
    if (centerLat != null && centerLng != null) {
      _buildLocationMarkers(sheetController, centerLat, centerLng);
    }
    notifyListeners();
  }

  /// ❌ 함수 영역 끝



  /// 기타

  @override
  void dispose() {
    bookmarkProvider.removeListener(_updateBookmarks);
    super.dispose();
  }
}
