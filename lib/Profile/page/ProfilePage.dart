import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortsmap/Profile/page/AccountPage.dart';
import 'package:shortsmap/Profile/page/WithdrawPage.dart';
import 'package:shortsmap/Provider/UserDataProvider.dart';
import 'package:shortsmap/Welcome/LoginPage.dart';
import 'package:shortsmap/Widgets/BottomNavBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// 공통으로 사용하는 기본 텍스트/아이콘 색상
const Color primaryTextColor = Color(0xFF121212);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  int _step = 0;
  bool _hasRated = false;

  final _inAppReview = InAppReview.instance;

  // 1) 가장 불만족 부분
  String? _selectedIssue;
  final List<String> _issues = [
    '콘텐츠 탐색 불편',
    '일정 추천 정확도',
    'UI/UX 디자인',
    '앱 성능 혹은 버그',
    '고객 지원/소통',
  ];

  // 2) 가장 만족 부분
  String? _selectedSatisfaction;
  final List<String> _satisfactions = [
    '콘텐츠 탐색 편리',
    '일정 추천 유용',
    'UI/UX 직관적',
    '앱 속도 및 안정성',
    '개발자 소통 경험',
  ];

  // 3) 별점
  int? _starRating;

  @override
  void initState() {
    super.initState();
    _loadHasRated();
  }

  Future<void> _loadHasRated() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _hasRated = prefs.getBool('hasRated') ?? false);
  }

  Future<void> _submitFeedback() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1) Supabase에 삽입
      await Supabase.instance.client
          .from('feedback_issues')
          .insert({
        'issue': _selectedIssue,
        'satisfaction': _selectedSatisfaction,
        'star_rating': _starRating,
      });

      // 3) 별점이 5점일 때 인앱리뷰 요청
      if (_starRating == 5 && await _inAppReview.isAvailable()) {
        _inAppReview.requestReview();
      }

      // 4) 캐시에 제출 완료 저장
      await prefs.setBool('hasRated', true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.lightBlueAccent,
            content: Text('소중한 피드백 감사합니다!'),
        ),
      );

      setState(() => _hasRated = true);

    } catch (err) {

      print(err);

      // 네트워크 오류나 Supabase 에러 핸들링
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피드백 전송 중 오류가 발생했습니다: $err')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // 기존 프로필 메뉴
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  /// 계정
                  ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AccountPage()),
                      );
                    },
                    leading: Icon(Icons.account_circle_outlined, color: primaryTextColor),
                    title: const Text(
                      '계정',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  /// 개발자와 소통
                  ListTile(
                    onTap: () async {
                      await FirebaseAnalytics.instance.logEvent(name: "tap_communicate_with_dev");
                      await launchUrl(
                        Uri.parse('https://slashpage.com/shortsmap'),
                        mode: LaunchMode.inAppBrowserView,
                      );
                    },
                    leading: Icon(CupertinoIcons.chat_bubble, color: primaryTextColor),
                    title: const Text(
                      '개발자와 소통하기',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  /// 이용 약관
                  ListTile(
                    onTap: () async {
                      await FirebaseAnalytics.instance.logEvent(name: "tap_term");
                      await launchUrl(
                        Uri.parse('https://hwsoft.notion.site/1e57ab93f29a80c88d37fb10f41f8bcf'),
                        mode: LaunchMode.inAppBrowserView,
                      );
                    },
                    leading: Icon(Icons.article_outlined, color: primaryTextColor),
                    title: const Text(
                      '이용 약관',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  /// 로그인/로그아웃
                  Consumer<UserDataProvider>(
                    builder: (context, userDataProvider, _) {
                      return ListTile(
                        onTap: userDataProvider.isLoggedIn
                            ? () => _showLogoutDialog(context)
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        leading: Icon(
                          userDataProvider.isLoggedIn ? Icons.logout : Icons.login,
                          color: primaryTextColor,
                        ),
                        title: Text(
                          userDataProvider.isLoggedIn ? '로그아웃' : '로그인',
                          style: const TextStyle(
                            color: primaryTextColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                  /// 회원 탈퇴
                  Consumer<UserDataProvider>(
                    builder: (context, userDataProvider, _) {
                      if (!userDataProvider.isLoggedIn) return const SizedBox.shrink();
                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => WithdrawPage()),
                          );
                        },
                        leading: Icon(Icons.person_off_outlined, color: primaryTextColor),
                        title: const Text(
                          '회원 탈퇴',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          if (!_hasRated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 단계별 제목
                  if (_step == 0)
                    const Text(
                      '앱 사용 중 가장 불만족스러운 부분을 선택해주세요',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  if (_step == 1)
                    const Text(
                      '앱 사용 중 가장 만족스러웠던 부분을 선택해주세요',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  if (_step == 2)
                    const Text(
                      '앱 전반적인 만족도를 별점으로 평가해주세요',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 8),

                  // 단계별 입력 UI
                  if (_step == 0)
                    ..._issues.map((issue) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: issue,
                      groupValue: _selectedIssue,
                      title: Text(issue, style: TextStyle(

                      ),),
                      onChanged: (val) =>
                          setState(() => _selectedIssue = val),
                    )),

                  if (_step == 1)
                    ..._satisfactions
                        .map((sat) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: sat,
                      groupValue: _selectedSatisfaction,
                      title: Text(sat),
                      onChanged: (val) => setState(
                              () => _selectedSatisfaction = val),
                    ))
                        .toList(),

                  if (_step == 2)
                    for (int i = 1; i <= 5; i++)
                      RadioListTile<int>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: i,
                        groupValue: _starRating,
                        title: Text('$i점'),
                        onChanged: (val) =>
                            setState(() => _starRating = val),
                      ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      // 다음 / 제출 활성화 로직
                      onPressed: () {
                        if (_step == 0 && _selectedIssue != null) {
                          setState(() => _step = 1);
                        } else if (_step == 1 &&
                            _selectedSatisfaction != null) {
                          setState(() => _step = 2);
                        } else if (_step == 2 && _starRating != null) {
                          _submitFeedback();
                        }
                      },
                      child: Text(
                        _step < 2
                            ? '다음'
                            : '제출',
                      ),
                    ),
                  ),
                ],
              ),
            ),


          // 기존 BottomNavBar
          BottomNavBar(context, 'profile'),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: Text(
        'Profile',
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.height * (20 / 812),
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.all(10),
          title: Center(
            child: Text(
              "로그아웃 하시겠습니까?",
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.w400,
                fontFamily: 'Jua',
                fontSize: MediaQuery.of(context).size.height * (20 / 812),
              ),
            ),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * (38 / 812),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        enableFeedback: false,
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        '아니요',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: MediaQuery.of(context).size.height * (20 / 812),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * (38 / 812),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        enableFeedback: false,
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        '예',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: MediaQuery.of(context).size.height * (20 / 812),
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseAnalytics.instance.logEvent(
                          name: "logout",
                          parameters: {
                            'uid': Provider.of<UserDataProvider>(context, listen: false).loginProvider!
                          },
                        );
                        await Supabase.instance.client.auth.signOut();
                        Navigator.of(context).pop();
                        Provider.of<UserDataProvider>(context, listen: false).logout();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
