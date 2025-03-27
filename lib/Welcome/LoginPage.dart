import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final _supabase = Supabase.instance.client;

  Future<void> _googleSignIn() async {

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * (50 / 375),
              height: MediaQuery.of(context).size.height * (50 / 812),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                strokeWidth: 4.0, // 선 두께 설정 (기본값: 4.0)
              ),
            ),
          );
        });

    try {
      GoogleSignIn _googleSignIn = GoogleSignIn();
      GoogleSignInAccount? _account = await _googleSignIn.signIn();
      if (_account != null) {
        GoogleSignInAuthentication _authentication = await _account.authentication;

        final accessToken = _authentication.accessToken;
        final idToken = _authentication.idToken;

        if (accessToken == null) {
          throw 'No Access Token found.';
        }
        if (idToken == null) {
          throw 'No ID Token found.';
        }
        await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        if (_supabase.auth.currentUser != null) {
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Something went wrong. Try again later.'),
          ));
        }
      } else{
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
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
                child: Image.asset(
                  'images/google.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.02,
            ),
            GestureDetector(
              onTap: () {
                // _googleSignIn();
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Image.asset(
                  'images/apple.png',
                  fit: BoxFit.cover,
                ),
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
