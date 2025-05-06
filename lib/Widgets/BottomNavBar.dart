import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shortsmap/Map/page/MapPage.dart';
import 'package:shortsmap/Profile/page/ProfilePage.dart';
import 'package:shortsmap/Shorts/page/ShortsPage.dart';
import 'package:shortsmap/Provider/UserDataProvider.dart';
import 'package:shortsmap/Welcome/LoginPage.dart';

class NoPushCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  NoPushCupertinoPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(builder: builder, settings: settings);

  // 푸시 애니메이션 즉시 완료
  @override
  Duration get transitionDuration => Duration.zero;

  // 팝(뒤로가기) 애니메이션은 기본(≈400ms) 유지
  @override
  Duration get reverseTransitionDuration =>
      const Duration(milliseconds: 400);
}


Widget BottomNavBar(BuildContext context, String page) {
  return Container(
    height: (Platform.isIOS)
        ? MediaQuery.of(context).size.height * (75 / 812)
        : MediaQuery.of(context).size.height * (60 / 812),
    decoration: BoxDecoration(
        color: (page == 'shorts') ? Color(0xff121212) : Color(0xffF0F2F5),
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),)
    ),
    child: Row(
      children: [
        /// explore
        InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (page != 'shorts') {
              Navigator.push(
                  context,
                  NoPushCupertinoPageRoute(
                      builder: (context) => ShortsPage()));
            }
          },
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * (10 / 812)),
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width * 0.33,
                child: Icon(
                  Icons.travel_explore,
                  color: (page == 'shorts') ? Colors.white : Colors.grey,
                  size: MediaQuery.of(context).size.height * (25 / 812),
                ),
              ),
              Text(
                'Explore',
                style: TextStyle(
                  color: (page == 'shorts') ? Colors.white : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // // plan
        // InkWell(
        //   onTap: () async {
        //     HapticFeedback.lightImpact();
        //     if (page != 'plan') {
        //       Navigator.pushReplacement(
        //         context,
        //         PageRouteBuilder(
        //           pageBuilder: (context, animation1, animation2) =>
        //           const PlanPage(),
        //           transitionDuration: Duration.zero,
        //           reverseTransitionDuration: Duration.zero,
        //         ),
        //       );
        //     }
        //   },
        //   child: Column(
        //     children: [
        //       Container(
        //         padding: EdgeInsets.only(
        //             top: MediaQuery.of(context).size.height * (16 / 812)),
        //         color: Colors.transparent,
        //         width: MediaQuery.of(context).size.width * 0.25,
        //         child: Icon(
        //           // Icons.supervisor_account,
        //           Icons.calendar_month,
        //           color: (page == 'plan') ? Color(0xff121212) : Colors.grey,
        //           size: MediaQuery.of(context).size.height * (25 / 812),
        //         ),
        //       ),
        //       Text(
        //         'Plan',
        //         style: TextStyle(
        //           color: (page == 'plan') ? Color(0xff121212) : Colors.grey,
        //           fontSize: 12,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // // book
        // InkWell(
        //   onTap: () async {
        //     HapticFeedback.lightImpact();
        //     if (page != 'reserve') {
        //       // Navigator.pushReplacement(
        //       //   context,
        //       //   PageRouteBuilder(
        //       //     pageBuilder: (context, animation1, animation2) =>
        //       //     const VideoPage(),
        //       //     transitionDuration: Duration.zero,
        //       //     reverseTransitionDuration: Duration.zero,
        //       //   ),
        //       // );
        //     }
        //   },
        //   child: Column(
        //     children: [
        //       Container(
        //         padding: EdgeInsets.only(
        //             top: MediaQuery.of(context).size.height * (16 / 812)),
        //         color: Colors.transparent,
        //         width: MediaQuery.of(context).size.width * 0.25,
        //         child: Icon(
        //           // Icons.supervisor_account,
        //           CupertinoIcons.tickets,
        //           color: (page == 'reserve') ? Color(0xff121212) : Colors.grey,
        //           size: MediaQuery.of(context).size.height * (25 / 812),
        //         ),
        //       ),
        //       Text(
        //         'Reserve',
        //         style: TextStyle(
        //           color: (page == 'reserve') ? Color(0xff121212) : Colors.grey,
        //           fontSize: 12,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        /// map
        InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (page != 'map') {
              if (Provider.of<UserDataProvider>(context, listen: false).currentUserUID != null) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) =>
                    const MapPage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              }

            }
          },
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * (10 / 812)),
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width * 0.33,
                child: Icon(
                  // Icons.supervisor_account,
                  Icons.map_outlined,
                  color: (page == 'map') ? Color(0xff121212) : Colors.grey,
                  size: MediaQuery.of(context).size.height * (25 / 812),
                ),
              ),
              Text(
                'map',
                style: TextStyle(
                  color: (page == 'map') ? Color(0xff121212) : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        /// profile
        InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (page != 'profile') {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                  const ProfilePage(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          },
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * (10 / 812)),
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width * 0.33,
                child: Icon(
                  // Icons.supervisor_account,
                  Icons.account_circle_outlined,
                  color: (page == 'profile') ? Color(0xff121212) : Colors.grey,
                  size: MediaQuery.of(context).size.height * (25 / 812),
                ),
              ),
              Text(
                'profile',
                style: TextStyle(
                  color: (page == 'profile') ? Color(0xff121212) : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

