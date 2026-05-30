import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/data/database/app_database.dart';

void main() {
  test('hello world: create and read a task in the local database', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.into(database.tasks).insert(
          TasksCompanion.insert(title: 'Cloud Agent Setup Task'),
        );

    final titles = await database.select(database.tasks).map((row) => row.title).get();
    expect(titles, contains('Cloud Agent Setup Task'));
  });
}
