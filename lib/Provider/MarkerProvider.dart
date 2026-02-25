import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shortsmap/Map/model/BookmarkLocationData.dart';
import 'package:shortsmap/Map/model/LocationData.dart';
import 'package:shortsmap/Provider/BookmarkProvider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'MarkerProvider.g.dart';

enum MarkerLoadResult { ok, viewportTooWide, fail }

class MarkerState {
  final Set<MarkerLocationData> viewPortLocations;
  final Set<MarkerLocationData> bookmarkLocations;
  final Set<Marker> locationMarkers;
  final bool isBookmarkMode;
  final String? selectedCategory;
  final bool isProgrammaticMove;
  final String? selectedLocation;
  final String? selectedVideoId;
  final Future<Map<String, dynamic>>? locationDetailFuture;
  final Future<List<Map<String, dynamic>>>? currentLocationsFuture;
  final bool isMarkerLoading;
  final bool isCategoryChanging;

  const MarkerState({
    this.viewPortLocations = const {},
    this.bookmarkLocations = const {},
    this.locationMarkers = const {},
    this.isBookmarkMode = false,
    this.selectedCategory,
    this.isProgrammaticMove = false,
    this.selectedLocation,
    this.selectedVideoId,
    this.locationDetailFuture,
    this.currentLocationsFuture,
    this.isMarkerLoading = false,
    this.isCategoryChanging = false,
  });

  MarkerState copyWith({
    Set<MarkerLocationData>? viewPortLocations,
    Set<MarkerLocationData>? bookmarkLocations,
    Set<Marker>? locationMarkers,
    bool? isBookmarkMode,
    String? selectedCategory,
    bool? isProgrammaticMove,
    String? selectedLocation,
    String? selectedVideoId,
    Future<Map<String, dynamic>>? locationDetailFuture,
    Future<List<Map<String, dynamic>>>? currentLocationsFuture,
    bool? isMarkerLoading,
    bool? isCategoryChanging,
  }) {
    return MarkerState(
      viewPortLocations: viewPortLocations ?? this.viewPortLocations,
      bookmarkLocations: bookmarkLocations ?? this.bookmarkLocations,
      locationMarkers: locationMarkers ?? this.locationMarkers,
      isBookmarkMode: isBookmarkMode ?? this.isBookmarkMode,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isProgrammaticMove: isProgrammaticMove ?? this.isProgrammaticMove,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedVideoId: selectedVideoId ?? this.selectedVideoId,
      locationDetailFuture: locationDetailFuture ?? this.locationDetailFuture,
      currentLocationsFuture:
          currentLocationsFuture ?? this.currentLocationsFuture,
      isMarkerLoading: isMarkerLoading ?? this.isMarkerLoading,
      isCategoryChanging: isCategoryChanging ?? this.isCategoryChanging,
    );
  }
}

@Riverpod(keepAlive: true)
class MarkerData extends _$MarkerData {
  // 마커 아이콘 캐싱
  final Map<String, BitmapDescriptor> _markerIconCache = {};

  // 카테고리별 아이콘/컬러
  final Map<String, dynamic> categoryStyles = {
    'Restaurant': {'icon': Icons.restaurant, 'color': Color(0xFFFF7043)},
    'Nature': {'icon': Icons.forest, 'color': Color(0xFF4CAF50)},
    'Exhibitions': {'icon': Icons.palette_outlined, 'color': Color(0xFF9C27B0)},
    'Historical Site': {
      'icon': Icons.account_balance,
      'color': Color(0xFF795548),
    },
    'Sports': {'icon': Icons.sports_tennis, 'color': Color(0xFF2196F3)},
    'Shopping': {
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFFFFC107),
    },
    'Cafe': {'icon': Icons.local_cafe_outlined, 'color': Color(0xFF8D6E63)},
    'Bar': {'icon': Icons.sports_bar, 'color': Color(0xFFB71C1C)},
  };

  @override
  MarkerState build() {
    final initialBookmarks = ref.read(bookmarkProvider).bookmarks;

    ref.listen<List<BookmarkLocationData>>(
      bookmarkProvider.select((b) => b.bookmarks),
      (prev, next) {
        if (identical(prev, next)) return;
        _updateBookmarks(next);
      },
    );

    return MarkerState(
      bookmarkLocations:
          initialBookmarks
              .map((b) => MarkerLocationData.fromBookmark(b))
              .toSet(),
    );
  }

  // 현재 소스(Set)에 포함된 고유 카테고리 목록
  List<String> get availableCategories {
    final source =
        state.isBookmarkMode
            ? state.bookmarkLocations
            : state.viewPortLocations;
    return source.map((loc) => loc.category).toSet().toList();
  }

  // 필터링된 장소 데이터
  Set<MarkerLocationData> get currentLocations {
    final source =
        state.isBookmarkMode
            ? state.bookmarkLocations
            : state.viewPortLocations;
    if (state.selectedCategory == null) return source;
    return source
        .where((loc) => loc.category == state.selectedCategory)
        .toSet();
  }

  // 필터링된 장소 개수
  int get currentLocationLength {
    final source =
        state.isBookmarkMode
            ? state.bookmarkLocations
            : state.viewPortLocations;
    if (state.selectedCategory == null) return source.length;
    return source.where((loc) => loc.category == state.selectedCategory).length;
  }

  Set<Marker> get locationMarkers => state.locationMarkers;
  bool get isMarkerLoading => state.isMarkerLoading;
  bool get isCategoryChanging => state.isCategoryChanging;
  bool get isProgrammaticMove => state.isProgrammaticMove;
  String? get selectedLocation => state.selectedLocation;
  String? get selectedVideoId => state.selectedVideoId;
  Future<Map<String, dynamic>>? get locationDetailFuture =>
      state.locationDetailFuture;
  Future<List<Map<String, dynamic>>>? get currentLocationsFuture =>
      state.currentLocationsFuture;
  String? get selectedCategory => state.selectedCategory;

  // 북마크 모드 여부
  set setBookmarkMode(bool val) {
    state = state.copyWith(isBookmarkMode: val);
  }

  // 선택 장소 변경
  set setSelectedLocation(String? placeId) {
    if (placeId == null) {
      state = MarkerState(
        viewPortLocations: state.viewPortLocations,
        bookmarkLocations: state.bookmarkLocations,
        locationMarkers: state.locationMarkers,
        isBookmarkMode: state.isBookmarkMode,
        selectedCategory: state.selectedCategory,
        isProgrammaticMove: state.isProgrammaticMove,
        selectedLocation: null,
        selectedVideoId: state.selectedVideoId,
        locationDetailFuture: state.locationDetailFuture,
        currentLocationsFuture: state.currentLocationsFuture,
        isMarkerLoading: state.isMarkerLoading,
        isCategoryChanging: state.isCategoryChanging,
      );
      return;
    }

    state = state.copyWith(
      selectedLocation: placeId,
      locationDetailFuture: _fetchLocationDetail(placeId),
    );
  }

  // 선택 비디오 변경
  set setSelectedVideoId(String? videoId) {
    if (videoId == null) {
      state = MarkerState(
        viewPortLocations: state.viewPortLocations,
        bookmarkLocations: state.bookmarkLocations,
        locationMarkers: state.locationMarkers,
        isBookmarkMode: state.isBookmarkMode,
        selectedCategory: state.selectedCategory,
        isProgrammaticMove: state.isProgrammaticMove,
        selectedLocation: state.selectedLocation,
        selectedVideoId: null,
        locationDetailFuture: state.locationDetailFuture,
        currentLocationsFuture: state.currentLocationsFuture,
        isMarkerLoading: state.isMarkerLoading,
        isCategoryChanging: state.isCategoryChanging,
      );
      return;
    }

    state = state.copyWith(selectedVideoId: videoId);
  }

  // 프로그램 이동 여부
  set setIsProgrammaticMove(bool val) {
    state = state.copyWith(isProgrammaticMove: val);
  }

  // 지도 뷰포트의 장소 데이터 로드
  Future<MarkerLoadResult> loadLocationsInViewport({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;

    print('latSpan: $latSpan, lngSpan: $lngSpan');

    if (latSpan > 0.06 || lngSpan > 0.06) {
      return MarkerLoadResult.viewportTooWide;
    }

    try {
      state = state.copyWith(isMarkerLoading: true, viewPortLocations: {});

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

      print(
        'expandedMinLat: $expandedMinLat  expandedMaxLat: $expandedMaxLat  expandedMinLng: $expandedMinLng  expandedMaxLng: $expandedMaxLng',
      );

      final viewPortLocations =
          (response as List).map((e) => MarkerLocationData.fromMap(e)).toSet();

      state = state.copyWith(viewPortLocations: viewPortLocations);

      await _buildLocationMarkers(centerLat, centerLng);
      return MarkerLoadResult.ok;
    } catch (e) {
      print('로드 실패: $e');
      return MarkerLoadResult.fail;
    }
  }

  // 북마크 데이터 업데이트
  void _updateBookmarks(List<BookmarkLocationData> bookmarks) {
    final bookmarkLocations =
        bookmarks.map((b) => MarkerLocationData.fromBookmark(b)).toSet();

    state = state.copyWith(bookmarkLocations: bookmarkLocations);
  }

  // 마커 아이콘 생성
  Future<BitmapDescriptor> _getMarkerIcon({
    required Color backgroundColor,
    required IconData iconData,
    double size = 80,
    double iconSize = 40,
  }) async {
    final cacheKey =
        '${backgroundColor.toARGB32()}_${iconData.codePoint}_${size.toInt()}_${iconSize.toInt()}';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    final double scale =
        PlatformDispatcher.instance.views.first.devicePixelRatio;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    canvas.scale(scale);

    const double borderWidth = 4.0;
    final Paint borderPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

    final Paint innerPaint = Paint()..color = backgroundColor;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      (size / 2) - borderWidth,
      innerPaint,
    );

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
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
    final ByteData? hiResByteData = await hiResImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List hiResPngBytes = hiResByteData!.buffer.asUint8List();

    final ui.Codec codec = await ui.instantiateImageCodec(
      hiResPngBytes,
      targetWidth: size.toInt(),
      targetHeight: size.toInt(),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image resizedImage = frameInfo.image;
    final ByteData? resizedByteData = await resizedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List resizedPngBytes = resizedByteData!.buffer.asUint8List();

    final descriptor = BitmapDescriptor.fromBytes(resizedPngBytes);
    _markerIconCache[cacheKey] = descriptor;
    return descriptor;
  }

  // 마커 생성
  Future<void> _buildLocationMarkers(double calcLat, double calcLng) async {
    Set<MarkerLocationData> locationData;
    final source =
        state.isBookmarkMode
            ? state.bookmarkLocations
            : state.viewPortLocations;

    if (source.isEmpty) {
      state = state.copyWith(locationMarkers: {});
    }

    if (state.selectedCategory == null) {
      locationData = source;
    } else {
      locationData =
          source.where((loc) => loc.category == state.selectedCategory).toSet();
    }

    final Set<Marker> markers = {};

    for (final data in locationData) {
      final style =
          categoryStyles[data.category] ??
          {'icon': Icons.place, 'color': Colors.blue};

      final icon = await _getMarkerIcon(
        backgroundColor: style['color'],
        iconData: style['icon'],
        size: 100,
        iconSize: 60,
      );

      markers.add(
        Marker(
          markerId: MarkerId(data.placeId),
          position: LatLng(data.latitude, data.longitude),
          icon: icon,
          onTap: () {
            FirebaseAnalytics.instance.logEvent(
              name: "tap_marker",
              parameters: {"video_id": data.videoId, "category": data.category},
            );

            state = state.copyWith(
              isProgrammaticMove: true,
              selectedLocation: data.placeId,
              selectedVideoId: data.videoId,
              locationDetailFuture: _fetchLocationDetail(data.placeId),
            );
          },
        ),
      );
    }

    await _fetchCurrentLocations(locationData, calcLat, calcLng);

    await Future.delayed(const Duration(milliseconds: 1000));

    state = state.copyWith(
      isMarkerLoading: false,
      isCategoryChanging: false,
      locationMarkers: markers,
    );
  }

  // 장소 상세 데이터 조회
  Future<Map<String, dynamic>> _fetchLocationDetail(String placeId) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_location_detail_by_id',
        params: {'_place_id': placeId},
      );

      final data = response as List<dynamic>;

      if (data.isEmpty) print('empty');

      return data[0] as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception("Error fetching posts: ${e.code}, ${e.message}");
    }
  }

  // 바텀시트용 장소 리스트 조회
  Future<void> _fetchCurrentLocations(
    Set<MarkerLocationData> source,
    double calcLat,
    double calcLng,
  ) async {
    final list = source.toList();
    list.sort((a, b) {
      final da = Geolocator.distanceBetween(
        calcLat,
        calcLng,
        a.latitude,
        a.longitude,
      );
      final db = Geolocator.distanceBetween(
        calcLat,
        calcLng,
        b.latitude,
        b.longitude,
      );
      return da.compareTo(db);
    });

    final sortedIds = list.map((e) => e.placeId).toList();

    final future = Supabase.instance.client
        .rpc('get_locations_by_ids', params: {'_ids': sortedIds})
        .then((value) {
          final locations = List<Map<String, dynamic>>.from(value);
          locations.sort(
            (a, b) =>
                sortedIds.indexOf(a['place_id']) -
                sortedIds.indexOf(b['place_id']),
          );
          return locations;
        });

    state = state.copyWith(currentLocationsFuture: future);
  }

  // 카테고리 선택
  void selectCategory(String? category, double? centerLat, double? centerLng) {
    state = MarkerState(
      viewPortLocations: state.viewPortLocations,
      bookmarkLocations: state.bookmarkLocations,
      locationMarkers: state.locationMarkers,
      isBookmarkMode: state.isBookmarkMode,
      selectedCategory: category,
      isProgrammaticMove: state.isProgrammaticMove,
      selectedLocation: null,
      selectedVideoId: null,
      locationDetailFuture: state.locationDetailFuture,
      currentLocationsFuture: state.currentLocationsFuture,
      isMarkerLoading: state.isMarkerLoading,
      isCategoryChanging: true,
    );

    if (centerLat != null && centerLng != null) {
      unawaited(_buildLocationMarkers(centerLat, centerLng));
    }
  }
}
