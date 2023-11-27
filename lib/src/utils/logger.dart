// ===============================================
// logger
//
// Create by Will on 2020/10/5 4:37 PM
// Copyright @flutter_core_kit.All rights reserved.
// ===============================================

import 'package:flutter/foundation.dart';
import 'package:loggy/loggy.dart';

class CoreKitLogger {
  /// http://www.dartdoc.cn/guides/language/language-tour#factory-constructors
  /// 使用 factory 关键字标识类的构造函数将会令该构造函数变为工厂构造函数，这将意味着使用该构造函数构造类的实例时并非总是会返回新的实例对象。
  /// 例如，工厂构造函数可能会从缓存中返回一个实例，或者返回一个子类型的实例。
  factory CoreKitLogger() {
    return _shared;
  }

  CoreKitLogger._internal() {
    // if (kDebugMode) {
    //   Logger.level = Level.debug;
    // } else if (kProfileMode) {
    //   Logger.level = Level.error;
    // } else {
    //   Logger.level = Level.nothing;
    // }

    Loggy.initLoggy(
      logPrinter: const PrettyPrinter(),
      logOptions: const LogOptions(
        LogLevel.all,
        stackTraceLevel: LogLevel.error,
      ),
    );

    // Loggy.initLoggy(logPrinter: const PrettyPrinter());
  }

  static final _shared = CoreKitLogger._internal();
  final _logger = GlobalLoggy().loggy.log;

  void d(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger(LogLevel.debug, message, error, stackTrace);
    }
  }

  void i(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger(LogLevel.info, message, error, stackTrace);
    }
  }

  void w(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger(LogLevel.warning, message, error, stackTrace);
    }
  }

  void e(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger(LogLevel.error, message, error, stackTrace);
}
