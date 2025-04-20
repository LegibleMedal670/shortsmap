import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PhotoCacheProvider extends ChangeNotifier {
  final String apiKey;
  final Map<String, String> _cache = {};

  PhotoCacheProvider({required this.apiKey});

  // 1) placeId → photoName
  Future<String> _getFirstPhotoName(String placeId) async {
    final res = await http.get(Uri.parse(
      'https://places.googleapis.com/v1/places/$placeId?fields=photos&key=$apiKey',
    ));
    if (res.statusCode != 200) {
      throw Exception('장소 사진 정보를 가져오지 못했습니다.');
    }
    final data = jsonDecode(res.body);
    final photos = data['photos'] as List? ?? [];
    if (photos.isEmpty) {
      throw Exception('해당 장소에 사진이 없습니다.');
    }
    return photos.first['name'] as String;
  }

  // 2) photoName → photoUri
  Future<String> _getPhotoUrlByName(
      String photoName, {
        int maxHeightPx = 400,
        int maxWidthPx = 400,
      }) async {
    final encoded = Uri.encodeFull(photoName);
    final res = await http.get(Uri.parse(
      'https://places.googleapis.com/v1/$encoded/media'
          '?key=$apiKey&maxHeightPx=$maxHeightPx&maxWidthPx=$maxWidthPx&skipHttpRedirect=true',
    ));
    if (res.statusCode != 200) {
      throw Exception('사진 URL을 가져오지 못했습니다.');
    }
    final data = jsonDecode(res.body);
    return data['photoUri'] as String;
  }

  // 3) 캐시 로직 포함: placeId → photoUri
  Future<String> getPhotoUrlForPlace(String placeId) async {
    if (_cache.containsKey(placeId)) {
      print('캐시임');
      return _cache[placeId]!;                // 캐시된 URL 즉시 반환
    }
    final name = await _getFirstPhotoName(placeId);
    final url = await _getPhotoUrlByName(name);
    _cache[placeId] = url;                    // 캐시에 저장
    print('불러옴');
    return url;
  }
}
