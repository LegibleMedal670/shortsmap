import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
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
      GoogleSignIn _googleSignIn = GoogleSignIn();
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
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
            ),
            Container(
              // height: 210,
              width: MediaQuery.of(context).size.width * 0.5,
              child: Image.asset('images/logo.png'),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                _googleSignIn();
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 1.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.google,
                      color: Colors.black87,
                      size: 24,
                    ),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 24
                      ),
                    )
                  ],
                )
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.02,
            ),
            GestureDetector(
              onTap: () {
                _appleSignIn(context);
              },
              child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.apple,
                        color: Colors.black87,
                        size: 24,
                      ),
                      Text(
                        'Continue with Apple',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 24
                        ),
                      )
                    ],
                  )
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.1,
            ),
          ],
        ),
      ),
    );
  }
}
