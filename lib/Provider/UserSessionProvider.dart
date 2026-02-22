import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'UserSessionProvider.g.dart';

class UserState {
  final bool isLoggedIn;
  final String? loginId;
  final String? loginProvider;
  final String? currentUserUID;
  final double? currentLat;
  final double? currentLon;

  const UserState({
    this.isLoggedIn = false,
    this.loginId,
    this.loginProvider,
    this.currentUserUID,
    this.currentLat,
    this.currentLon,
  });

  UserState copyWith({
    bool? isLoggedIn,
    String? loginId,
    String? loginProvider,
    String? currentUserUID,
    double? currentLat,
    double? currentLon,
  }) {
    return UserState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      loginId: loginId,
      loginProvider: loginProvider,
      currentUserUID: currentUserUID,
      currentLat: currentLat,
      currentLon: currentLon,
    );
  }
}

@Riverpod(keepAlive: true)
class UserSession extends _$UserSession {
  @override
  UserState build() => const UserState();

  void login(String uid, String loginId, String loginProvider) {
    state = state.copyWith(
      isLoggedIn: true,
      currentUserUID: uid,
      loginId: loginId,
      loginProvider: loginProvider,
      currentLat: state.currentLat,   // 유지
      currentLon: state.currentLon,   // 유지
    );

    FirebaseAnalytics.instance.setUserId(id: uid);
  }

  void logout() {
    state = UserState(
      isLoggedIn: false,
      loginId: null,
      loginProvider: null,
      currentUserUID: null,
      currentLat: state.currentLat,   // 유지
      currentLon: state.currentLon,   // 유지
    );

    FirebaseAnalytics.instance.setUserId(id: null);
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          forceLocationManager: true,
          accuracy: LocationAccuracy.lowest,
        ),
      );

      state = UserState(
        isLoggedIn: state.isLoggedIn,
        loginId: state.loginId,
        loginProvider: state.loginProvider,
        currentUserUID: state.currentUserUID,
        currentLat: position.latitude,
        currentLon: position.longitude,
      );
    } else {
      state = UserState(
        isLoggedIn: state.isLoggedIn,
        loginId: state.loginId,
        loginProvider: state.loginProvider,
        currentUserUID: state.currentUserUID,
        currentLat: currentLat,
        currentLon: currentLon,
      );
    }
  }
}
