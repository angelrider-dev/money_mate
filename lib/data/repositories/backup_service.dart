import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import '../local/database.dart';

/// Exports the entire local database to a single JSON file and can restore
/// from one. This is the safety net in place of cloud sync — user manually
/// shares/saves this file (WhatsApp, Drive, email, anywhere).
///
/// SECURITY: since this file can contain a full financial history and may be
/// shared over WhatsApp/email, encryption is optional but strongly recommended.
/// If a password is supplied, the JSON payload is AES-256 encrypted before
/// being written to disk; without a password, it's saved as plain JSON
/// (kept for backwards-compatible/simple cases, e.g. local-only device backup).
class BackupService {
  final AppDatabase db;
  BackupService(this.db);

  static const _formatVersion = 1;
  static const _magicEncrypted = 'MMBAKV1E'; // marks an encrypted backup file
  static const _magicPlain = 'MMBAKV1P'; // marks a plain (unencrypted) backup file

  /// Derives a 256-bit key from the user's password using SHA-256.
  /// Simple and dependency-light; fine for this use case (local file,
  /// not a network-facing auth secret).
  enc.Key _deriveKey(String password) {
    final hash = sha256.convert(utf8.encode(password)).bytes;
    return enc.Key(Uint8List.fromList(hash));
  }

  /// Dumps every table into one JSON structure and writes it to a file
  /// in the app's documents directory. If [password] is provided, the
  /// content is AES-256-CBC encrypted before writing.
  /// Returns the file so the caller can share it (e.g. via share_plus).
  Future<File> exportBackup({String? password}) async {
    final data = <String, dynamic>{
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': await db.select(db.categories).get(),
      'groups': await db.select(db.groups).get(),
      'members': await db.select(db.members).get(),
      'groupMembers': await db.select(db.groupMembers).get(),
      'expenses': await db.select(db.expenses).get(),
      'expenseSplits': await db.select(db.expenseSplits).get(),
      'budgets': await db.select(db.budgets).get(),
      'settlements': await db.select(db.settlements).get(),
      'users': await db.select(db.users).get(),
      'incomeSources': await db.select(db.incomeSources).get(),
      'income': await db.select(db.income).get(),
      'savingsGoals': await db.select(db.savingsGoals).get(),
      'savingsContributions': await db.select(db.savingsContributions).get(),
      'appSettings': await db.select(db.appSettings).get(),
      'accounts': await db.select(db.accounts).get(),
      'accountTransfers': await db.select(db.accountTransfers).get(),
      'recurringRules': await db.select(db.recurringRules).get(),
    };

    final jsonReady = data.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.map((row) => (row as dynamic).toJson()).toList());
      }
      return MapEntry(key, value);
    });

    final plainJson = jsonEncode(jsonReady);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/moneymate_backup_$timestamp.json');

    if (password != null && password.isNotEmpty) {
      final key = _deriveKey(password);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainJson, iv: iv);

      // File layout: MAGIC (8 bytes) + IV (base64) + '\n' + ciphertext (base64)
      final payload = '$_magicEncrypted\n${iv.base64}\n${encrypted.base64}';
      await file.writeAsString(payload);
    } else {
      await file.writeAsString('$_magicPlain\n$plainJson');
    }
    return file;
  }

  /// Restores from a previously exported JSON file.
  /// [password] must be supplied if the file was encrypted (throws a
  /// [FormatException] with a clear "wrong password or corrupted file"
  /// message if decryption fails — never a silent/garbled restore).
  /// WARNING: this wipes existing local data first — always confirm with
  /// the user before calling this (irreversible without another backup).
  Future<void> restoreBackup(File file, {String? password}) async {
    final raw = await file.readAsString();
    final firstNewline = raw.indexOf('\n');
    if (firstNewline == -1) {
      throw const FormatException('Backup file is corrupted or not a MoneyMate backup.');
    }
    final magic = raw.substring(0, firstNewline);
    final rest = raw.substring(firstNewline + 1);

    late final String plainJson;

    if (magic == _magicEncrypted) {
      if (password == null || password.isEmpty) {
        throw const FormatException('This backup is password-protected. Enter the password to restore.');
      }
      final secondNewline = rest.indexOf('\n');
      if (secondNewline == -1) {
        throw const FormatException('Backup file is corrupted.');
      }
      final ivBase64 = rest.substring(0, secondNewline);
      final cipherBase64 = rest.substring(secondNewline + 1);
      try {
        final key = _deriveKey(password);
        final iv = enc.IV.fromBase64(ivBase64);
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        plainJson = encrypter.decrypt64(cipherBase64, iv: iv);
      } catch (_) {
        throw const FormatException('Wrong password or corrupted backup file.');
      }
    } else if (magic == _magicPlain) {
      plainJson = rest;
    } else {
      throw const FormatException('Not a recognized MoneyMate backup file.');
    }

    final Map<String, dynamic> json = jsonDecode(plainJson);
    final version = json['formatVersion'] as int?;
    if (version == null || version > _formatVersion) {
      throw FormatException(
          'Backup file format ($version) is newer than this app supports.');
    }

    await db.transaction(() async {
      // Clear existing data (children before parents to respect FKs)
      await db.delete(db.expenseSplits).go();
      await db.delete(db.settlements).go();
      await db.delete(db.groupMembers).go();
      await db.delete(db.savingsContributions).go();
      await db.delete(db.accountTransfers).go();
      await db.delete(db.expenses).go();
      await db.delete(db.income).go();
      await db.delete(db.budgets).go();
      await db.delete(db.savingsGoals).go();
      await db.delete(db.recurringRules).go();
      await db.delete(db.accounts).go();
      await db.delete(db.groups).go();
      await db.delete(db.members).go();
      await db.delete(db.incomeSources).go();
      await db.delete(db.categories).go();
      await db.delete(db.appSettings).go();
      await db.delete(db.users).go();

      // Re-insert from backup, parents before children
      await _insertAll(db.categories, json['categories']);
      await _insertAll(db.users, json['users']);
      await _insertAll(db.incomeSources, json['incomeSources']);
      await _insertAll(db.groups, json['groups']);
      await _insertAll(db.members, json['members']);
      await _insertAll(db.accounts, json['accounts']);
      await _insertAll(db.groupMembers, json['groupMembers']);
      await _insertAll(db.recurringRules, json['recurringRules']);
      await _insertAll(db.expenses, json['expenses']);
      await _insertAll(db.income, json['income']);
      await _insertAll(db.budgets, json['budgets']);
      await _insertAll(db.savingsGoals, json['savingsGoals']);
      await _insertAll(db.expenseSplits, json['expenseSplits']);
      await _insertAll(db.settlements, json['settlements']);
      await _insertAll(db.savingsContributions, json['savingsContributions']);
      await _insertAll(db.accountTransfers, json['accountTransfers']);
      await _insertAll(db.appSettings, json['appSettings']);
    });
  }

  Future<void> _insertAll<T extends Table, D>(
      TableInfo<T, D> table, dynamic rows) async {
    if (rows == null) return;
    for (final row in (rows as List)) {
      await db.into(table).insert(
            table.map(row as Map<String, dynamic>) as Insertable<D>,
            mode: InsertMode.insertOrReplace,
          );
    }
  }
}
