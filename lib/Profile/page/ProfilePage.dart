import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shortsmap/Profile/page/AccountPage.dart';
import 'package:shortsmap/Profile/page/WithdrawPage.dart';
import 'package:shortsmap/Provider/UserDataProvider.dart';
import 'package:shortsmap/Welcome/LoginPage.dart';
import 'package:shortsmap/Widgets/BottomNavBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// 공통으로 사용하는 기본 텍스트/아이콘 색상
const Color primaryTextColor = Color(0xFF121212);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
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
                    title: Text(
                      '계정',
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  /// 개발자와 소통
                  ListTile(
                    onTap: () async {
                      await launchUrl(
                        Uri.parse('https://slashpage.com/shortsmap'),
                        mode: LaunchMode.inAppBrowserView,
                      );
                    },
                    leading: Icon(CupertinoIcons.chat_bubble, color: primaryTextColor),
                    title: Text(
                      '개발자와 소통하기',
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  /// 이용 약관
                  ListTile(
                    onTap: () async {
                      await launchUrl(
                        Uri.parse('https://hwsoft.notion.site/1427ab93f29a80c89a77de807a75c160'),
                        mode: LaunchMode.inAppBrowserView,
                      );
                    },
                    leading: Icon(Icons.article_outlined, color: primaryTextColor),
                    title: Text(
                      '이용 약관',
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  /// 로그아웃
                  Consumer<UserDataProvider>(
                    builder: (context, userDataProvider, _) {
                      return ListTile(
                        onTap: userDataProvider.isLoggedIn
                            ? () {
                          _showLogoutDialog(context);
                        }
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        leading: Icon(userDataProvider.isLoggedIn ? Icons.logout : Icons.login, color: primaryTextColor),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.05,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * (38 / 812),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        enableFeedback: false,
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '예',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: MediaQuery.of(context).size.height * (20 / 812),
                        ),
                      ),
                      onPressed: () async {
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
