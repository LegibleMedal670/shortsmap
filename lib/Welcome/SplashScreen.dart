import 'package:flutter/material.dart';
import 'package:shortsmap/Shorts/page/ShortsPage.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  ///스플래시스크린에서 로그인 여부 등 확인하고 다음 페이지로 이동
  ///이후 소셜 로그인 관련 추가한 뒤에 업데이트 필요
  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    Navigator.pushReplacement(
      context,
      _buildPageRoute( ShortsPage()),
    );
  }

  ///부드러운전환을위한??? 설명필요
  PageRouteBuilder _buildPageRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation1, animation2) => screen,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  ///현재는 단순한 텍스트만 있음 추후 애니메이션 혹은 아이콘 추가 업데이트
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      body: Center(
        child: Container(
          // height: 210,
          width: MediaQuery.of(context).size.width * 0.7,
          child: Image.asset('images/logo.png'),
        ),
      ),
    );
  }
}
