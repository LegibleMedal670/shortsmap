import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shortsmap/Shorts/provider/FilterProvider.dart';
import 'package:shortsmap/Welcome/SplashScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kfyusrkgzupinsgdotaf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmeXVzcmtnenVwaW5zZ2RvdGFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI4MDY4NDUsImV4cCI6MjA1ODM4Mjg0NX0.QD66jLAoC5bJpJwuPnIfKaxoY3pD56Hui3gSngdXZyA',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FilterProvider()),
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
            dragHandleSize: Size(50, 5)
          ),
          useMaterial3: false,
        ),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: child!),
        home: const SplashScreen(),
      ),
    );
  }
}
