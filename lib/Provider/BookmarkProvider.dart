import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:shortsmap/Map/model/BookmarkLocationData.dart';
import 'package:shortsmap/Map/page/MapPage.dart';
import 'package:shortsmap/Welcome/LoginPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookmarkProvider with ChangeNotifier {
  List<BookmarkLocationData> _bookmarks = [];
  bool _isLoggedIn = false;
  String? _userId;

  List<BookmarkLocationData> get bookmarks => _bookmarks;

  String? get userId => _userId;

  void updateLoginStatus(bool isLoggedIn, [String? userId]) {
    _isLoggedIn = isLoggedIn;
    if (_isLoggedIn && userId != null) {
      loadBookmarks(userId);
      _userId = userId;
    } else {
      _bookmarks.clear();
      _userId = null;
      notifyListeners();
    }
  }

  Future<void> loadBookmarks(String userId) async {
    if (!_isLoggedIn) return;
    final response = await Supabase.instance.client.rpc('get_user_bookmarks', params: {'_user_id': userId});
    _bookmarks = (response as List).map((e) => BookmarkLocationData.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addBookmark(BuildContext context, String videoId, String category, String placeId, int watchDuration) async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(milliseconds: 1500),
          backgroundColor: Colors.lightBlueAccent,
          content: Text('북마크하기 위해 로그인 해주세요'),
          action: SnackBarAction(
            label: '로그인',
            textColor: Color(0xff121212),
            onPressed: () async {


              FirebaseAnalytics.instance.logEvent(
                name: "login_to_bookmark",
                parameters: {
                  "video_id": videoId,
                  "watch_duration": watchDuration,
                },
              );

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.02,
            left: 20.0,
            right: 20.0,
          ),
        ),
      );
    } else {
      try{
        await Supabase.instance.client.from('bookmarks').insert({
          'user_id': userId,
          'video_id': videoId,
          'category': category,
          'bookmarked_at': DateTime.now().toIso8601String(),
          'place_id': placeId,
        });

        await loadBookmarks(userId!);

        FirebaseAnalytics.instance.logEvent(
          name: "bookmark_save",
          parameters: {
            "video_id": videoId,
            "watch_duration": watchDuration,
          },
        );

        // 저장 되었음을 표시해주는 스낵바 TODO ( UI 조정 필요 )
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(milliseconds: 1500),
            backgroundColor: Colors.lightBlueAccent,
            content: Text('북마크에 저장되었어요'),
            action: SnackBarAction(
              label: '보러 가기',
              textColor: Color(0xff121212),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPage(placeId: placeId, videoId: videoId,),
                  ),
                      (route) => false,
                );
              },
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.02,
              left: 20.0,
              right: 20.0,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(milliseconds: 1500),
            backgroundColor: Colors.redAccent,
            content: Text('북마크 도중 알 수 없는 에러가 발생했습니다'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.02,
              left: 20.0,
              right: 20.0,
            ),
          ),
        );
        print('Insert 에러: $e');
      }
    }
  }

  Future<void> removeBookmark(BuildContext context, String videoId, String placeId, int watchDuration) async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(milliseconds: 1500),
          backgroundColor: Colors.lightBlueAccent,
          content: Text('북마크하기 위해 로그인 해주세요'),
          action: SnackBarAction(
            label: '로그인',
            textColor: Color(0xff121212),
            onPressed: () async {


              FirebaseAnalytics.instance.logEvent(
                name: "login_to_bookmark",
                parameters: {
                  "video_id": videoId,
                  "watch_duration": watchDuration,
                },
              );

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.02,
            left: 20.0,
            right: 20.0,
          ),
        ),
      );
    } else {

      try{
        await Supabase.instance.client.from('bookmarks').delete().match({
          'user_id': userId!,
          'video_id': videoId,
        });

        FirebaseAnalytics.instance.logEvent(
          name: "bookmark_delete",
          parameters: {
            "video_id": videoId,
            "watch_duration": watchDuration,
          },
        );

        await loadBookmarks(userId!);

        // 삭제 되었음을 알려주는 스낵바 TODO ( UI 조정 필요 )
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(milliseconds: 1500),
            backgroundColor: Colors.lightBlueAccent,
            content: Text('북마크에서 삭제되었어요'),
            action: SnackBarAction(
              label: '보러 가기',
              textColor: Color(0xff121212),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPage(),
                  ),
                      (route) => false,
                );
              },
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.02,
              left: 20.0,
              right: 20.0,
            ),
          ),
        );
      } catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            duration: Duration(milliseconds: 1500),
            content: Text('북마크 취소 도중 알 수 없는 에러가 발생했습니다'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.02,
              left: 20.0,
              right: 20.0,
            ),
          ),
        );
        print('Delete 에러: $e');
      }
    }
  }

  bool isBookmarked(String videoId) {
    if (!_isLoggedIn) return false;
    return _bookmarks.any((bookmark) => bookmark.videoId == videoId);
  }
}
