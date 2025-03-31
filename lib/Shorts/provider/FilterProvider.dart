import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// 동영상을 필터링하는데 쓰이는 요소들을 관리하기 위한 프로바이더
class FilterProvider extends ChangeNotifier {
  String? _filterRegion;
  String? _filterCategory;
  double? _filterLat;
  double? _filterLon;
  bool _orderNear = false;

  String? get filterRegion => _filterRegion;
  String? get filterCategory => _filterCategory;
  double? get filterLat => _filterLat;
  double? get filterLon => _filterLon;
  bool get orderNear => _orderNear;

  void setBasicVideoCategory(String? region, String? category) {

    _filterRegion = region;
    _filterCategory = category;
    _orderNear = false;

    notifyListeners();
  }

  Future<void> setAroundVideoCategory(BuildContext context, String? category) async {

    // 바로 시스템 권한 요청
    final permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location Permission Denied.")),
      );
      return;
    }

    // 권한이 허용된 경우 현재 위치 가져오기
    final position = await Geolocator.getCurrentPosition();
    _filterLat = position.latitude;
    _filterLon = position.longitude;
    _filterRegion = null;
    _filterCategory = category;
    _orderNear = true;

    notifyListeners();
  }

}
