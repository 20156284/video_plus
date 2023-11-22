// ===============================================
// crypto
//
// Create by Will on 22/5/2023 11:42
// Copyright Will rights reserved.
// ===============================================

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

final key = Key.fromUtf8('1e78032909bf48f6');
final iv = IV.fromUtf8('ba1ed9cb6fe4b77f');
const appKey = '7205a6c3883caf95b52db5b534e12ec3';

final mediaKey = Key.fromUtf8('f5d965df75336270');
final mediaIv = IV.fromUtf8('97b60394abc2fbe1');

String getSign(Map obj) {
  String md5Text;
  final keyValues = [
    "client=${obj['client']}",
    "data=${obj['data']}",
    "timestamp=${obj['timestamp']}"
  ];
  final text = '${keyValues.join('&')}$appKey';
  final _digest = sha256.convert(utf8.encode(text));
  md5Text = md5.convert(utf8.encode(_digest.toString())).toString();
  return md5Text;
}

class PlatformAwareCrypto {
  //IM加密专用
  static Future<String> encryptReqParamsWithKey(
      String word, String key, String iv) async {
    final encrypt = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
    final encrypted =
        encrypt.encryptBytes(utf8.encode(word), iv: IV.fromUtf8(iv));
    final data = utf8.decode(encrypted.base64.codeUnits);
    return data;
  }

  //IM解密专用
  static Future<String> decryptResDataWithKey(
    dynamic data,
    String key,
    String iv,
  ) async {
    final encrypt = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
    final encrypted = Encrypted.fromBase64(data['data']);
    final decrypted = encrypt.decrypt(encrypted, iv: IV.fromUtf8(iv));
    return decrypted;
  }

  static Future<dynamic> encryptReqParams(String word) async {
    final encrypt = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypt.encryptBytes(utf8.encode(word), iv: iv);
    final data = utf8.decode(encrypted.base64.codeUnits);
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sign =
        getSign({'client': 'pwa', 'data': data, 'timestamp': timestamp});
    return 'client=pwa&timestamp=$timestamp&data=$data&sign=$sign';
  }

  static Future<String> decryptResData(dynamic data) async {
    final encrypt = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = Encrypted.fromBase64(data['data']);
    final decrypted = encrypt.decrypt(encrypted, iv: iv);
    return decrypted;
  }

  // //获取小说
  // static Future<String> decryptNovel(String url) async {
  //   final base64 = await PlatformAwareHttp.getNovel(url);
  //   dynamic decrypted = decryptImage(base64);
  //   if (decrypted != '' && decrypted != null) {
  //     decrypted = base64Decode(decrypted);
  //     final data = utf8.decode(decrypted);
  //     return data;
  //   }
  //   return '';
  // }

  // static String decryptImage(dynamic data) {
  //   try {
  //     final encrypt = Encrypter(AES(mediaKey, mode: AESMode.cbc));
  //     final encrypted = Encrypted.fromBase64(data);
  //     final stopwatch = Stopwatch()..start();
  //     final decrypted = encrypt.decryptBytes(encrypted, iv: mediaIv);
  //     CoreKitLogger().d('decode() executed in ${stopwatch.elapsed}');
  //     return base64Encode(decrypted);
  //   } catch (err) {
  //     CoreKitLogger().e(err);
  //     return '';
  //   }
  // }

  static dynamic decryptM3U8(String data) {
    try {
      final encrypt = Encrypter(AES(mediaKey, mode: AESMode.cbc));
      final encrypted = Encrypted.fromBase64(data);
      final stopwatch = Stopwatch()..start();
      final decrypted = encrypt.decrypt(encrypted, iv: mediaIv);
      // CoreKitLogger().d('decode() executed in ${stopwatch.elapsed}');
      return decrypted;
    } catch (err) {
      return null;
    }
  }

  static String encry(String input) {
    try {
      final encrypt = Encrypter(AES(mediaKey, mode: AESMode.cbc));
      final encrypted = encrypt.encrypt(input, iv: mediaIv);
      return encrypted.base16;
    } catch (err) {
      // CoreKitLogger().e('aes encode error:$err');
      return input;
    }
  }

  static String decry(String encoded) {
    try {
      final encrypt = Encrypter(AES(mediaKey, mode: AESMode.cbc));
      final decrypted = encrypt.decrypt16(encoded, iv: mediaIv);
      return decrypted;
    } catch (err) {
      // CoreKitLogger().e('aes decode error:$err');
      return encoded;
    }
  }
}
