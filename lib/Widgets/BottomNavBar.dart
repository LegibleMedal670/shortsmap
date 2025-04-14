import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shortsmap/Map/pages/MapPage.dart';
import 'package:shortsmap/Plan/screens/plan_page.dart';
import 'package:shortsmap/Shorts/page/ShortsPage.dart';
import 'package:shortsmap/Map/screens/map_page.dart';
import 'package:shortsmap/Setting/screens/setting_page.dart';

Widget BottomNavBar(BuildContext context, String page) {
  return Container(
    margin: EdgeInsets.only(bottom: 10),
    height:
        (Platform.isIOS)
            ? MediaQuery.of(context).size.height * (75 / 812)
            : MediaQuery.of(context).size.height * (60 / 812),
    decoration: BoxDecoration(
      color: (page == 'shorts') ? Color(0xff121212) : Color(0xffF0F2F5),
      border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3))),
    ),
    child: Row(
      children: [
        // Shorts
        _navItem(
          context,
          icon: Icons.play_circle_outlined,
          label: 'Shorts',
          activePage: page,
          currentPage: 'shorts',
          colorActive: Colors.white,
          colorInactive: Colors.grey,
          onTap: () {
            if (page != 'shorts') {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShortsPage()),
              );
            }
          },
        ),
        // Map
        _navItem(
          context,
          icon: Icons.map,
          label: 'Map',
          activePage: page,
          currentPage: 'map',
          colorActive: Color(0xff121212),
          colorInactive: Colors.grey,
          onTap: () {
            if (page != 'map') {
              HapticFeedback.lightImpact();
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, a1, a2) => const MapPage(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          },
        ),
        // Plan
        _navItem(
          context,
          icon: Icons.calendar_month,
          label: 'Plan',
          activePage: page,
          currentPage: 'plan',
          colorActive: Color(0xff121212),
          colorInactive: Colors.grey,
          onTap: () {
            if (page != 'plan') {
              HapticFeedback.lightImpact();
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, a1, a2) => const PlanPage(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          },
        ),
        // Setting
        _navItem(
          context,
          icon: Icons.settings_outlined,
          label: 'Setting',
          activePage: page,
          currentPage: 'setting',
          colorActive: Color(0xff121212),
          colorInactive: Colors.grey,
          onTap: () {
            if (page != 'setting') {
              HapticFeedback.lightImpact();
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, a1, a2) => const MapPage1(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          },
        ),
      ],
    ),
  );
}

Widget _navItem(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String activePage,
  required String currentPage,
  required Color colorActive,
  required Color colorInactive,
  required VoidCallback onTap,
}) {
  final isActive = activePage == currentPage;
  return InkWell(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * (16 / 812),
          ),
          color: Colors.transparent,
          width: MediaQuery.of(context).size.width * 0.25,
          child: Icon(
            icon,
            color: isActive ? colorActive : colorInactive,
            size: MediaQuery.of(context).size.height * (25 / 812),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isActive ? colorActive : colorInactive,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
