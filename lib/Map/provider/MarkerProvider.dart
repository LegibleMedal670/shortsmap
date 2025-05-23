import 'package:flutter/material.dart';
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

  Set<MarkerLocationData> _viewPortLocations = {};
  Set<MarkerLocationData> _bookmarkLocations = {};

  bool _isBookmarkMode = false;
  String? _selectedCategory;

  /// 현재 소스(Set)에 포함된 고유 카테고리 목록을 반환
  List<String> get availableCategories {
    final source = _isBookmarkMode ? _bookmarkLocations : _viewPortLocations;
    // map으로 category만 뽑아서 Set으로 중복 제거, 다시 List로 변환
    final categories = source
        .map((loc) => loc.category)
        .toSet()
        .toList();

    return categories;
  }

  Set<MarkerLocationData> get currentLocations {
    final source = _isBookmarkMode ? _bookmarkLocations : _viewPortLocations;
    if (_selectedCategory == null) {
      return source;
    }
    return source.where((loc) => loc.category == _selectedCategory).toSet();
  }

  set selectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  set isBookmarkMode(bool val) {
    _isBookmarkMode = val;
    notifyListeners();
  }

  /// ✅ Supabase를 통해 현재 지도 뷰포트 영역의 장소 데이터를 로드하는 메서드
  Future<void> loadLocationsInViewport({
    required BuildContext context,
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
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

      for (MarkerLocationData data in _viewPortLocations){
        print(data.placeId);
      }

      notifyListeners();
    } catch (e) {
      print('로드 실패: $e');
    }
  }



  /// 북마크 데이터 업데이트 (기존 로직 유지)
  void _updateBookmarks() {
    _bookmarkLocations = bookmarkProvider.bookmarks
        .map((b) => MarkerLocationData.fromBookmark(b))
        .toSet();
    notifyListeners();
  }

  @override
  void dispose() {
    bookmarkProvider.removeListener(_updateBookmarks);
    super.dispose();
  }
}
