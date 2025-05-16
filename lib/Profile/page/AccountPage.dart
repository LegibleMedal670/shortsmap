import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shortsmap/Profile/page/ProfilePage.dart';
import 'package:shortsmap/Profile/page/WithdrawPage.dart';
import 'package:shortsmap/Provider/BookmarkProvider.dart';
import 'package:shortsmap/Provider/UserDataProvider.dart';
import 'package:shortsmap/Welcome/LoginPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

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
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Text(
                          '계정',
                          style: const TextStyle(
                            color: Color(0xff121212),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Text(
                          Provider.of<UserDataProvider>(
                                context,
                                listen: false,
                              ).loginId ??
                              '로그인하지 않음',
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Text(
                          '로그인 방식',
                          style: const TextStyle(
                            color: Color(0xff121212),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        if (Provider.of<UserDataProvider>(context, listen: false,).isLoggedIn)
                          Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: FaIcon(
                            (Provider.of<UserDataProvider>(context, listen: false,).loginProvider == 'google')
                              ? FontAwesomeIcons.google // 구글 아이콘
                              : (Provider.of<UserDataProvider>(context, listen: false,).loginProvider == 'apple')
                                ? FontAwesomeIcons.apple // 애플 아이콘
                                : FontAwesomeIcons.envelope // 이메일 아이콘
                            ,
                            color: Colors.black87, // 검정색으로 설정
                            size: 24, // 크기 지정 (필요시)
                          ),
                        ),
                        if (!Provider.of<UserDataProvider>(context, listen: false,).isLoggedIn)
                          Padding(
                            padding: const EdgeInsets.only(right: 5.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(builder: (context) => const LoginPage()), // 로그인 페이지로 push
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black87),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: Provider.of<UserDataProvider>(
                      context,
                      listen: false,
                    ).isLoggedIn ? () {
                      _showLogoutDialog(context);
                    } : () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (context) => const LoginPage()), // 로그인 페이지로 push
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Text(
                            '로그아웃',
                            style: const TextStyle(
                              color: Color(0xff121212),
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: Provider.of<UserDataProvider>(
                      context,
                      listen: false,
                    ).isLoggedIn ? () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (context) => WithdrawPage()),
                      );
                    } : (){
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (context) => const LoginPage()), // 로그인 페이지로 push
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Text(
                            '회원 탈퇴',
                            style: const TextStyle(
                              color: Color(0xff121212),
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      // 자동으로 뒤로가기 버튼 생성 비활성화
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        '계정',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
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
                color: Color(0xFF121212),
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
                          color: Color(0xFF121212),
                          fontSize:
                              MediaQuery.of(context).size.height * (20 / 812),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '예',
                        style: TextStyle(
                          color: Color(0xFF121212),
                          fontSize:
                              MediaQuery.of(context).size.height * (20 / 812),
                        ),
                      ),
                      onPressed: () {
                        Supabase.instance.client.auth.signOut();
                        Provider.of<UserDataProvider>(
                          context,
                          listen: false,
                        ).logout();
                        Provider.of<BookmarkProvider>(context, listen: false).updateLoginStatus(false, null);
                        Navigator.of(context).pop();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                          (route) => false,
                        );
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
