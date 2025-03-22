import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


Widget BottomNavBar(BuildContext context, String page) {
  return Container(
    margin: EdgeInsets.only(bottom: 10),
    height: (Platform.isIOS)
        ? MediaQuery.of(context).size.height * (75 / 812)
        : MediaQuery.of(context).size.height * (60 / 812),
    decoration: BoxDecoration(
        color: (page == 'shorts') ? Colors.black : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),)
    ),
    child: Row(
      children: [
        // explore
        InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (page != 'shorts') {
              // Navigator.pushReplacement(
              //   context,
              //   PageRouteBuilder(
              //     pageBuilder: (context, animation1, animation2) =>
              //     const VideoPage(),
              //     transitionDuration: Duration.zero,
              //     reverseTransitionDuration: Duration.zero,
              //   ),
              // );
            }
          },
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * (16 / 812)),
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width * 0.25,
                child: Icon(
                  Icons.travel_explore,
                  color: (page == 'shorts') ? Colors.white : Colors.grey,
                  size: MediaQuery.of(context).size.height * (25 / 812),
                ),
              ),
              Text(
                'Explore',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // plan
        InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (page != 'search') {
              // Navigator.pushReplacement(
              //   context,
              //   PageRouteBuilder(
              //     pageBuilder: (context, animation1, animation2) =>
              //     const VideoPage(),
              //     transitionDuration: Duration.zero,
              //     reverseTransitionDuration: Duration.zero,
              //   ),
              // );
            }
          },
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * (16 / 812)),
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width * 0.25,
                child: Icon(
                  // Icons.supervisor_account,
                  Icons.calendar_month,
                  color: (page == 'map') ? Colors.black : Colors.grey,
                  size: MediaQuery.of(context).size.height * (25 / 812),
                ),
              ),
              Text(
                'Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // book
        InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (page != 'map') {
              // Navigator.pushReplacement(
              //   context,
              //   PageRouteBuilder(
              //     pageBuilder: (context, animation1, animation2) =>
              //     const VideoPage(),
              //     transitionDuration: Duration.zero,
              //     reverseTransitionDuration: Duration.zero,
              //   ),
              // );
            }
          },
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * (16 / 812)),
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width * 0.25,
                child: Icon(
                  // Icons.supervisor_account,
                  CupertinoIcons.tickets,
                  color: (page == 'map') ? Colors.black : Colors.grey,
                  size: MediaQuery.of(context).size.height * (25 / 812),
                ),
              ),
              Text(
                'Reserve',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // community
        InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (page != 'profile') {
              // Navigator.pushReplacement(
              //   context,
              //   PageRouteBuilder(
              //     pageBuilder: (context, animation1, animation2) =>
              //     const VideoPage(),
              //     transitionDuration: Duration.zero,
              //     reverseTransitionDuration: Duration.zero,
              //   ),
              // );
            }
          },
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * (16 / 812)),
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width * 0.25,
                child: Icon(
                  // Icons.supervisor_account,
                  Icons.forum_outlined,
                  color: (page == 'profile') ? Colors.black : Colors.grey,
                  size: MediaQuery.of(context).size.height * (25 / 812),
                ),
              ),
              Text(
                'Community',
                style: TextStyle(
                  color: Colors.white,
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

