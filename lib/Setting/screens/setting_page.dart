import 'package:flutter/material.dart';
import 'package:shortsmap/Widgets/BottomNavBar.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blueGrey,
      ),
      body: const Center(
        child: Text('This is the Setting Page', style: TextStyle(fontSize: 18)),
      ),
      bottomNavigationBar: BottomNavBar(context, 'setting'),
    );
  }
}
