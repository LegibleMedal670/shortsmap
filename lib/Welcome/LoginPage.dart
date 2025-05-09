import 'dart:convert';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shortsmap/Provider/BookmarkProvider.dart';
import 'package:shortsmap/Provider/UserDataProvider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final _supabase = Supabase.instance.client;

  /// 구글로그인 함수
  Future<void> _googleSignIn() async {
    // 로딩 다이얼로그 표시
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return Center(
          child: SizedBox(
            width: MediaQuery.of(dialogContext).size.width * (50 / 375),
            height: MediaQuery.of(dialogContext).size.height * (50 / 812),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              strokeWidth: 4.0,
            ),
          ),
        );
      },
    );

    try {

      const iosClientId = '916848326581-8ksg7a187hji9v2ak727f3mm6n0c39jr.apps.googleusercontent.com';
      const serverClientId = '916848326581-tgrq4r69qhcgb9vfr7ojmj5tbudcvl96.apps.googleusercontent.com';

      GoogleSignIn _googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: serverClientId,
      );
      GoogleSignInAccount? _account = await _googleSignIn.signIn();
      if (_account != null) {
        GoogleSignInAuthentication _authentication =
        await _account.authentication;

        final accessToken = _authentication.accessToken;
        final idToken = _authentication.idToken;

        if (accessToken == null) throw 'No Access Token found.';
        if (idToken == null) throw 'No ID Token found.';

        await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        if (_supabase.auth.currentUser != null) {
          final uid = _supabase.auth.currentUser!.id;
          final String loginId = _supabase.auth.currentUser!.email!;
          final String loginProvider = _supabase.auth.currentUser!.appMetadata['provider']!;
          Provider.of<UserDataProvider>(context, listen: false).login(uid, loginId, loginProvider);

          Provider.of<BookmarkProvider>(context, listen: false).updateLoginStatus(true, uid);

          FirebaseAnalytics.instance.logLogin(loginMethod: 'Google');

          Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 제거
          Navigator.pop(context); // 이전 화면으로 이동
        } else {
          Navigator.of(context, rootNavigator: true).pop(); // 다이얼로그 제거
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Something went wrong. Try again later.')),
          );
        }
      } else {
        Navigator.of(context, rootNavigator: true).pop(); // 다이얼로그 제거
      }
    } catch (e) {
      print(e);
      Navigator.of(context, rootNavigator: true).pop(); // 에러 발생 시 다이얼로그 제거
    }
  }

  /// 애플로그인 함수
  Future<void> _appleSignIn(BuildContext context) async {
    // 로딩 다이얼로그 표시
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return Center(
          child: SizedBox(
            width: MediaQuery.of(dialogContext).size.width * (50 / 375),
            height: MediaQuery.of(dialogContext).size.height * (50 / 812),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              strokeWidth: 4.0,
            ),
          ),
        );
      },
    );

    try {
      final rawNonce = _supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Could not find ID Token from generated credential.');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      // 로그인 성공 후 사용자 정보 확인
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final uid = user.id;
        final String loginId = user.email ?? 'unknown@email.com';
        final String loginProvider = user.appMetadata['provider'] ?? 'apple';

        Provider.of<UserDataProvider>(context, listen: false)
            .login(uid, loginId, loginProvider);

        Provider.of<BookmarkProvider>(context, listen: false).updateLoginStatus(true, uid);

        FirebaseAnalytics.instance.logLogin(loginMethod: 'Apple');

        Navigator.of(context, rootNavigator: true).pop(); // 로딩 다이얼로그 제거
        Navigator.pop(context); // 이전 화면으로 이동
      } else {
        Navigator.of(context, rootNavigator: true).pop(); // 다이얼로그 제거
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again later.')),
        );
      }
    } catch (e) {
      print(e);
      Navigator.of(context, rootNavigator: true).pop(); // 에러 발생 시 다이얼로그 제거
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 중 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;

          return Center(
            child: Column(
              children: [
                SizedBox(height: maxHeight * 0.38), // 상단 여백

                // 로고
                Container(
                  width: maxWidth * 0.8,
                  child: Image.asset('images/logo.png'),
                ),

                const Spacer(),

                // 구글 로그인 버튼
                _loginButton(
                  icon: FontAwesomeIcons.google,
                  text: 'Continue with Google',
                  onTap: _googleSignIn,
                ),

                const SizedBox(height: 20),

                // 애플 로그인 버튼 (iOS만)
                if (Platform.isIOS)
                  _loginButton(
                    icon: FontAwesomeIcons.apple,
                    text: 'Continue with Apple',
                    onTap: () => _appleSignIn(context),
                  ),

                if (Platform.isIOS)
                  SizedBox(height: maxHeight * 0.08), // iOS 하단 여백
                if (!Platform.isIOS)
                  SizedBox(height: maxHeight * 0.04), // Android 여백
              ],
            ),
          );
        },
      ),
    );
  }

// 커스텀 로그인 버튼 위젯
  Widget _loginButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 1.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: Colors.black87, size: 22),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
