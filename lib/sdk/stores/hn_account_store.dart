import 'dart:async';
import 'dart:convert' show JSON;

import 'package:flutter_flux/flutter_flux.dart';

import 'package:hn_flutter/injection/di.dart';
import 'package:hn_flutter/sdk/actions/hn_account_actions.dart';
import 'package:hn_flutter/sdk/models/hn_account.dart';
import 'package:hn_flutter/sdk/sqflite_vals.dart';
import 'package:hn_flutter/sdk/services/local_storage_service.dart';

class HNAccountStore extends Store {
  static final HNAccountStore _singleton = new HNAccountStore._internal();

  final LocalStorageService _localStorage = new Injector().localStorageService;

  String _primaryAccountId;
  final Map<String, HNAccount> _accounts = new Map();

  HNAccountStore._internal () {
    new Future(() async {
      final primaryUserIdKeys = await this._localStorage.databases[KEYS_DB].query(
        KEYS_TABLE,
        columns: [KEYS_ID, KEYS_VALUE],
        where: '$KEYS_ID = ?',
        whereArgs: [KEY_PRIMARY_ACCOUNT_ID],
        limit: 1,
      );

      final accounts = await this._localStorage.databases[ACCOUNTS_DB].query(
        ACCOUNTS_TABLE,
        columns: [ACCOUNTS_ID, ACCOUNTS_EMAIL, ACCOUNTS_PASSWORD, ACCOUNTS_ACCESS_COOKIE],
      );

      accounts
        .map((accountMap) => new HNAccount.fromMap(accountMap))
        .forEach((account) {
          print(account);
          // this._accounts[account.id] = account;
          // TODO: this causes the DB to get rewritten every launch
          addHNAccount(account);
        });

      if (primaryUserIdKeys.length > 0) {
        print('primary account was ${primaryUserIdKeys.first[KEYS_VALUE]}');
        setPrimaryHNAccount(primaryUserIdKeys.first[KEYS_VALUE]);

        // final primaryUser = accounts.firstWhere((account) => account[''] == this._primaryAccountId);
        // this._primaryUserPassword = primaryUser[ACCOUNTS_PASSWORD];
      }
    }).then((a) {});

    triggerOnAction(addHNAccount, (HNAccount user) async {
      _accounts[user.id] = user;

      print('Adding ${user.id} to SQLite');

      final cookieJson = JSON.encode({
        'name': user.accessCookie.name,
        'value': user.accessCookie.value,
        'expires': user.accessCookie.expires.millisecondsSinceEpoch,
        'domain': user.accessCookie.domain,
        'httpOnly': user.accessCookie.httpOnly,
        'secure': user.accessCookie.secure,
      });

      await this._localStorage.databases[ACCOUNTS_DB].rawInsert(
        '''
        INSERT OR REPLACE INTO $ACCOUNTS_TABLE ($ACCOUNTS_ID, $ACCOUNTS_EMAIL, $ACCOUNTS_PASSWORD, $ACCOUNTS_ACCESS_COOKIE)
          VALUES (?, ?, ?, ?);
        ''',
        [user.id, user.email, user.password, cookieJson]
      );

      print('Added ${user.id} to SQLite');
    });

    triggerOnAction(removeHNAccount, (String userId) async {
      _accounts.remove(userId);

      print('Removing $userId from SQLite');

      await this._localStorage.databases[ACCOUNTS_DB].delete(
        ACCOUNTS_TABLE,
        where: '$ACCOUNTS_ID = ?',
        whereArgs: [userId],
      );

      print('Removed $userId from SQLite');

      if (this._accounts.length == 0) {
        await this._localStorage.databases[KEYS_DB].delete(
          KEYS_TABLE,
          where: '$KEYS_ID = ?',
          whereArgs: [KEY_PRIMARY_ACCOUNT_ID],
        );
        this._primaryAccountId = null;
      } else {
        final newPrimaryUserId = this._accounts.values.first.id;
        setPrimaryHNAccount(newPrimaryUserId);
      }
    });

    triggerOnAction(setPrimaryHNAccount, (String userId) async {
      this._primaryAccountId = userId;

      this._localStorage.databases[KEYS_DB].rawInsert(
        '''
        INSERT OR REPLACE INTO $KEYS_TABLE ($KEYS_ID, $KEYS_VALUE)
          VALUES (?, ?);
        ''',
        [KEY_PRIMARY_ACCOUNT_ID, userId],
      );
    });
  }

  factory HNAccountStore () {
    return _singleton;
  }

  String get primaryAccountId => this._primaryAccountId;
  HNAccount get primaryAccount => this._accounts[this._primaryAccountId];
  Map<String, HNAccount> get accounts => new Map.unmodifiable(this._accounts);
}

final StoreToken accountStoreToken = new StoreToken(new HNAccountStore());
