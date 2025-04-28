import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'GOOGLE_PLACE_API_KEY', obfuscate: true)
  static String googlePlaceAPIKey = _Env.googlePlaceAPIKey;
  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true)
  static String supabaseURL = _Env.supabaseURL;
  @EnviedField(varName: 'SUPABASE_ANON_KEY', obfuscate: true)
  static String supabaseAnonKey = _Env.supabaseAnonKey;
}
