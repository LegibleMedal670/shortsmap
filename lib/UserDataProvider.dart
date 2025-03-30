import 'package:flutter/material.dart';


/// 유저 로그인 여부, 유저 정보 등 모든 페이지에서 쓰이는 데이터를 관리하기 위한 프로바이더
class UserDataProvider extends ChangeNotifier {

  bool _isLoggedIn = false;
  String? _currentUserUID;

  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserUID => _currentUserUID;

  void login(String uid) {
    _isLoggedIn = true;
    _currentUserUID = uid;
    notifyListeners();
  }

}