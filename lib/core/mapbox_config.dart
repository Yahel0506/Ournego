import 'package:ournego/core/app_env.dart';

class MapboxConfig {
  MapboxConfig._();

  static String get accessToken => AppEnv.getString('MAPBOX_ACCESS_TOKEN');
  static String get username => AppEnv.getString('MAPBOX_USERNAME');
  static String get styleIdDark => AppEnv.getString('MAPBOX_STYLE_ID_DARK');
  static String get styleIdLight => AppEnv.getString('MAPBOX_STYLE_ID_LIGHT');
}
