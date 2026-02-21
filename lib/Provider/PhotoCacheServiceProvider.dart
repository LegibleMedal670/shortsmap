import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shortsmap/Service/PhotoCacheService.dart';
import 'package:shortsmap/env.dart';

/// PhotoCacheService는 listening하는게 아닌 요청에 맞는 url을 리턴해주는 방식이기 때문에 ref.read를 통해 접근하도록 한다..
/// 상태관리 패키지를 적용하지 않아도 사용할 수 있지만, apiKey를 인자로 전달해줘야 하는데 매번 호출때마다 넣으면은 뭔가 번거로워지고 그러니까 Riverpod을 통해 넣고 사용하도록 해보았다
final photoCacheServiceProvider = Provider<PhotoCacheService>((ref) {
  return PhotoCacheService(apiKey: Env.googlePlaceAPIKey);
});
