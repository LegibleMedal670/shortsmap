import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shortsmap/Map/page/MapPage.dart';
import 'package:shortsmap/Profile/page/ProfilePage.dart';
import 'package:shortsmap/Provider/UserSessionProvider.dart';
import 'package:shortsmap/Shorts/page/ShortsPage.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _getPermissionAndNavigate();
  }

  /// 스플래시 화면 이후 MainNavigator로 전환하여
  /// 초기 라우트 스택(ShortsPage & PlanPage)을 구성합니다.
  void _getPermissionAndNavigate() async {
    await ref.read(userSessionProvider.notifier).setCurrentLocation(null, null);

    final isLoggedIn = ref.read(userSessionProvider).isLoggedIn;

    // 권한 요청 다 끝나면 스플래시 유지 시간 기다렸다 이동
    await Future.delayed(Duration(milliseconds: 1500));
    Navigator.pushReplacement(context, _buildPageRoute(MainNavigator(isLoggedIn : isLoggedIn)));
  }

  /// 부드러운 전환을 위한 페이지 전환 애니메이션(없도록 설정)
  PageRouteBuilder _buildPageRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation1, animation2) => screen,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  /// 스플래시 화면 UI 예시
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          child: Image.asset('images/logo.png'),
        ),
      ),
    );
  }
}

class MainNavigator extends StatelessWidget {

  final bool isLoggedIn;

  const MainNavigator({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          isLoggedIn
              ? MaterialPageRoute(builder: (_) => MapPage())
              : MaterialPageRoute(builder: (_) => ProfilePage()),
          MaterialPageRoute(builder: (_) => ShortsPage()),
        ];
      },
    );
  }
}
