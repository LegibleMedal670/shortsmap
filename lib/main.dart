import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shortsmap/Provider/ImageCacheProvider.dart';
import 'package:shortsmap/Shorts/provider/FilterProvider.dart';
import 'package:shortsmap/Provider/UserDataProvider.dart';
import 'package:shortsmap/Welcome/SplashScreen.dart';
import 'package:shortsmap/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseURL,
    anonKey: Env.supabaseAnonKey,
  );

  /// Supabase 초기화 후 현재 로그인 상태 확인
  final currentUser = Supabase.instance.client.auth.currentUser;
  final userDataProvider = UserDataProvider();
  await userDataProvider.setCurrentLocation(null, null);
  if (currentUser != null) {
    // 로그인 상태이면 UID, email, provider를 provider에 설정
    userDataProvider.login(currentUser.id, currentUser.email!, currentUser.appMetadata['provider']!);
  }

  runApp(MyApp(userDataProvider: userDataProvider));
}

class MyApp extends StatefulWidget {

  /// main에서 초기화한 프로바이더를 그대로 이용하기 위해
  final UserDataProvider userDataProvider;

  const MyApp({super.key, required this.userDataProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider.value(value: widget.userDataProvider),
        ChangeNotifierProvider(create: (_) => PhotoCacheProvider(apiKey: Env.googlePlaceAPIKey)), // TODO API KEY 숨기기
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Shorts',
        theme: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          primaryColor: Colors.black,
          bottomSheetTheme: BottomSheetThemeData(
              dragHandleColor: Colors.grey[400],
              dragHandleSize: const Size(50, 5)),
          useMaterial3: false,
        ),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: child!),
        home: const SplashScreen(),
      ),
    );
  }
}
