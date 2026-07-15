import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens (or creates) the local SQLite file used by Drift.
/// Call: AppDatabase(openConnection())
LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bill_splitter.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
