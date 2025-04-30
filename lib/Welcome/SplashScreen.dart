import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shortsmap/Map/page/MapPage.dart';
import 'package:shortsmap/Profile/page/ProfilePage.dart';
import 'package:shortsmap/Shorts/page/ShortsPage.dart';

import '../Provider/UserDataProvider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) async {
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
    });
    _navigateToNextScreen();
  }

  /// 스플래시 화면 이후 MainNavigator로 전환하여
  /// 초기 라우트 스택(ShortsPage & PlanPage)을 구성합니다.
  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    Navigator.pushReplacement(context, _buildPageRoute(MainNavigator()));
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
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          (Provider.of<UserDataProvider>(context, listen: false).isLoggedIn)
              ? MaterialPageRoute(builder: (_) => MapPage())
              : MaterialPageRoute(builder: (_) => ProfilePage()),
          MaterialPageRoute(builder: (_) => ShortsPage()),
        ];
      },
    );
  }
}
