import 'dart:io';
import 'dart:ui';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riv;
import 'package:provider/provider.dart';
import 'package:shortsmap/Provider/BookmarkProvider.dart';
import 'package:shortsmap/Provider/UserDataProvider.dart';
import 'package:shortsmap/Welcome/SplashScreen.dart';
import 'package:shortsmap/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shortsmap/Map/provider/MarkerProvider.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS) {
    final status = await AppTrackingTransparency
        .requestTrackingAuthorization();
  }

  await Supabase.initialize(
    url: Env.supabaseURL,
    anonKey: Env.supabaseAnonKey,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FacebookAppEvents facebookAppEvents = FacebookAppEvents();

  await facebookAppEvents.setAdvertiserTracking(enabled: true);
  await facebookAppEvents.setAutoLogAppEventsEnabled(true);

  /// Supabase 초기화 후 현재 로그인 상태 확인
  final currentUser = Supabase.instance.client.auth.currentUser;
  final userDataProvider = UserDataProvider();
  final bookmarkProvider = BookmarkProvider();

  if (currentUser != null) {
    // 로그인 상태이면 UID, email, provider를 provider에 설정
    userDataProvider.login(currentUser.id, currentUser.email!, currentUser.appMetadata['provider']!);
    bookmarkProvider.updateLoginStatus(true, currentUser.id);
  }

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(riv.ProviderScope(child: MyApp(userDataProvider: userDataProvider, bookmarkProvider: bookmarkProvider,)));
}

class MyApp extends StatefulWidget {

  /// main에서 초기화한 프로바이더를 그대로 이용하기 위해
  final UserDataProvider userDataProvider;

  final BookmarkProvider bookmarkProvider;

  const MyApp({super.key, required this.userDataProvider, required this.bookmarkProvider,});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider.value(value: widget.userDataProvider),
        // ChangeNotifierProvider(create: (_) => PhotoCacheProvider(apiKey: Env.googlePlaceAPIKey)),
        ChangeNotifierProvider.value(value: widget.bookmarkProvider),
        ChangeNotifierProvider(create: (_) => MarkerDataProvider(bookmarkProvider: widget.bookmarkProvider)),
      ],
      child: MaterialApp(
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: analytics),
        ],
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
