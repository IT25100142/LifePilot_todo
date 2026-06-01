library sqlite3_flutter_libs;

import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

Future<void> applyWorkaroundToOpenSqlite3OnOldAndroidVersions() async {
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
}
