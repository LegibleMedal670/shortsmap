import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shortsmap/Map/model/BookmarkLocationData.dart';
import 'package:shortsmap/Provider/UserSessionProvider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


part 'BookmarkProvider.g.dart';

enum BookmarkMutationResult {
  ok,
  loginRequired,
  fail,
}

class BookmarkState {
  final List<BookmarkLocationData> bookmarks;
  final String? errorMessage;

  const BookmarkState({
    this.bookmarks = const [],
    this.errorMessage,
  });

  BookmarkState copyWith({
    List<BookmarkLocationData>? bookmarks,
    String? errorMessage,
  }) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      errorMessage: errorMessage,
    );
  }
}

@Riverpod(keepAlive: true)
class Bookmark extends _$Bookmark {
  @override
  BookmarkState build() {

    //빌드시에 초기화
    final uid = ref.read(userSessionProvider).currentUserUID;

    if (uid != null) {
      //로그인된 유저가 있으면 비동기로 북마크 불러옴
      unawaited(_loadBookmarks(uid));
    }

    //uid 변화 리스닝 -> 바뀌면 북마크 정보 수정
    ref.listen<String?>(
      userSessionProvider.select((u) => u.currentUserUID),
          (prev, next) {
        if (prev == next) return;

        if (next == null) {
          state = const BookmarkState(); // 로그아웃: 즉시 초기화
          return;
        }

        unawaited(_loadBookmarks(next)); // 로그인/세션복구: 자동 로드
      },
    );

    return const BookmarkState();
  }

  // 북마크 여부 확인용 bool. state에 있는 리스트에 있는지 여부
  bool isBookmarked(String videoId) {
    return state.bookmarks.any((b) => b.videoId == videoId);
  }

  // 북마크를 서버에서 불러옴. 에러가 있으면 에러메시지를 업데이트
  Future<void> _loadBookmarks(String uid) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_user_bookmarks',
        params: {'_user_id': uid},
      );

      final bookmarks = (response as List)
          .map((e) => BookmarkLocationData.fromMap(e))
          .toList();

      state = state.copyWith(bookmarks: bookmarks, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // 북마크를 추가함. 원래는 context, lat, lng를 받아와서 UI를 띄워주고 '바로가기'를 누르면 MapPage로 이동 + 해당 좌표로 카메라 이동했었는데 이제는 UI작업을 분리할거라서 해당 인자 삭제
  Future<BookmarkMutationResult> addBookmark(String videoId, String category, String placeId, int watchDuration) async {
    final uid = ref.read(userSessionProvider).currentUserUID;
    if (uid == null) return BookmarkMutationResult.loginRequired;

    try {
      await Supabase.instance.client.from('bookmarks').insert({
        'user_id': uid,
        'video_id': videoId,
        'category': category,
        'bookmarked_at': DateTime.now().toIso8601String(),
        'place_id': placeId,
      });

      await _loadBookmarks(uid);

      await FirebaseAnalytics.instance.logEvent(
        name: 'bookmark_save',
        parameters: {
          'video_id': videoId,
          'watch_duration': watchDuration,
        },
      );

      return BookmarkMutationResult.ok;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return BookmarkMutationResult.fail;
    }
  }

  //북마크를 삭제해줌. 원래는 context를 받아 스낵바를 띄워줬는데, 이제 분리할거라 해당 인자 삭제
  Future<BookmarkMutationResult> removeBookmark(String videoId, int watchDuration) async {
    final uid = ref.read(userSessionProvider).currentUserUID;
    if (uid == null) return BookmarkMutationResult.loginRequired;

    try {
      await Supabase.instance.client.from('bookmarks').delete().match({
          'user_id': uid,
          'video_id': videoId,
        });

      FirebaseAnalytics.instance.logEvent(
        name: "bookmark_delete",
        parameters: {
          "video_id": videoId,
          "watch_duration": watchDuration,
        }
      );

      await _loadBookmarks(uid);

      return BookmarkMutationResult.ok;
    } catch (e){
      state = state.copyWith(errorMessage: e.toString());
      return BookmarkMutationResult.fail;
    }
  }

}
