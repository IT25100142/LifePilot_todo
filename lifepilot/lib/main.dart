import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }

  runApp(const ProviderScope(child: LifePilotApp()));
}
