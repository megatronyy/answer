import 'dart:async';
import 'dart:io';

import 'package:answer/app/data/db/prompt_dao.dart';
import 'package:answer/app/data/db/request_parameters_dao.dart';
import 'package:answer/app/data/db/service_providers_dao.dart';
import 'package:answer/app/data/db/service_tokens_dao.dart';
import 'package:answer/app/data/db/service_vendors_dao.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'conversations_dao.dart';
import 'messages_dao.dart';

class AppDatabase {
  static const defaultLimit = 16;

  static final AppDatabase instance = AppDatabase._internal();

  AppDatabase._internal();

  late final Database database;

  late final ConversationsDao conversationsDao = ConversationsDao(database);
  late final MessagesDao messagesDao = MessagesDao(database);
  late final ServiceProvidersDao serviceProvidersDao =
      ServiceProvidersDao(database);
  late final ServiceVendorsDao serviceVendorsDao = ServiceVendorsDao(database);
  late final ServiceTokensDao serviceTokensDao = ServiceTokensDao(database);
  late final PromptDao promptDao = PromptDao(database);
  late final RequestParametersDao requestParametersDao =
      RequestParametersDao(database);

  static Future<void> initialize({
    required String dbName,
  }) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    var databasesPath = appDocDir.path; //await getDatabasesPath();
    var path = join(databasesPath, dbName);

    if (kDebugMode) {
      print(path);
    }

    instance.database = await _openDatabase(path);
  }

  static Future<Database> _openDatabase(String path) async {
    if (kIsWeb) {
      DatabaseFactory _databaseFactory = databaseFactoryFfiWeb;
      return await _databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          onCreate: instance._onCreate,
          onUpgrade: instance._onUpgrade,
          version: 4,
        ),
      );
    } else if (Platform.isWindows || Platform.isLinux) {
      DatabaseFactory _databaseFactory = databaseFactoryFfi;
      return await _databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          onCreate: instance._onCreate,
          onUpgrade: instance._onUpgrade,
          version: 4,
        ),
      );
    } else {
      return await openDatabase(
        path,
        onCreate: instance._onCreate,
        onUpgrade: instance._onUpgrade,
        version: 4,
      );
    }
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await PromptDao.onCreate(db);
    await ServiceTokensDao.onCreate(db);
    await ServiceVendorsDao.onCreate(db);
    await ServiceProvidersDao.onCreate(db);
    await ConversationsDao.onCreate(db);
    await RequestParametersDao.onCreate(db);
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await ServiceVendorsDao.onCreate(db);
      await PromptDao.onCreate(db);
    }
    if (oldVersion < 4) {
      await RequestParametersDao.onCreate(db);
    } else {
      await RequestParametersDao.onUpgrade(db, oldVersion, newVersion);
    }
    await ServiceTokensDao.onUpgrade(db, oldVersion, newVersion);
    await ServiceVendorsDao.onUpgrade(db, oldVersion, newVersion);
    await PromptDao.onUpgrade(db, oldVersion, newVersion);
    await ServiceProvidersDao.onUpgrade(db, oldVersion, newVersion);
    await MessagesDao.onUpgrade(db, oldVersion, newVersion);
    await ConversationsDao.onUpgrade(db, oldVersion, newVersion);
  }
}
