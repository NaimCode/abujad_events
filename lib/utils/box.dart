import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Box {
  static Future<void> setToken(String token) async {
    // await FlutterSecureStorage
    await Hive.box('auth').put('token', token);
  }

  static String? getToken() {
    // return await FlutterSecureStorage
    return Hive.box('auth').get('token');
  }

  static Future<void> clearToken() async {
    // await FlutterSecureStorage
    await Hive.box('auth').delete('token');
  }

  static Listenable listenToken() {
    return Hive.box('auth').listenable(keys: ['token']);
  }
}
