import 'package:flutter/material.dart';
import 'package:shortsmap/Widgets/BottomNavBar.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('plan'),
      ),
      body: Column(
        children: [
          Expanded(child: Container()),
          BottomNavBar(context, 'plan'),
        ],
      ),
    );
  }
}
