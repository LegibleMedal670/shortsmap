import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// 유저 로그인 여부, 유저 정보 등 모든 페이지에서 쓰이는 데이터를 관리하기 위한 프로바이더
class UserDataProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _loginId;
  String? _loginProvider;
  String? _currentUserUID;
  double? _currentLat;
  double? _currentLon;

  bool get isLoggedIn => _isLoggedIn;

  String? get currentUserUID => _currentUserUID;

  String? get loginId => _loginId;

  String? get loginProvider => _loginProvider;

  double? get currentLat => _currentLat;

  double? get currentLon => _currentLon;

  void login(String uid, String loginId, String loginProvider) {
    _isLoggedIn = true;
    _currentUserUID = uid;
    _loginId = loginId;
    _loginProvider = loginProvider;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _currentUserUID = null;
    _loginId = null;
    _loginProvider = null;
    notifyListeners();
  }

  Future<void> setCurrentLocation(
    double? currentLat,
    double? currentLon,
  ) async {
    if (currentLat == null && currentLon == null) {
      final permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      _currentLat = position.latitude;
      _currentLon = position.longitude;
      notifyListeners();
    } else {
      _currentLat = currentLat;
      _currentLon = currentLon;
      notifyListeners();
    }
  }
}
