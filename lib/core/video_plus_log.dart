//MIT License
//
//Copyright (c) [2019-2023] [Will]
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

part of VideoPlusPlayer;

/// Log level for the [FijkLog.log] method.
@immutable
class VideoPlusLogLevel {
  const VideoPlusLogLevel._(int l, String n)
      : assert(l != null),
        level = l,
        name = n;
  final int level;
  final String name;

  /// Priority constant for the [FijkLog.log] method;
  static const VideoPlusLogLevel All = VideoPlusLogLevel._(000, 'all');

  /// Priority constant for the [FijkLog.log] method;
  static const VideoPlusLogLevel Detail = VideoPlusLogLevel._(100, 'det');

  /// Priority constant for the [FijkLog.log] method;
  static const VideoPlusLogLevel Verbose = VideoPlusLogLevel._(200, 'veb');

  /// Priority constant for the [FijkLog.log] method; use [FijkLog.d(msg)]
  static const VideoPlusLogLevel Debug = VideoPlusLogLevel._(300, 'dbg');

  /// Priority constant for the [FijkLog.log] method; use [FijkLog.i(msg)]
  static const VideoPlusLogLevel Info = VideoPlusLogLevel._(400, 'inf');

  /// Priority constant for the [FijkLog.log] method; use [FijkLog.w(msg)]
  static const VideoPlusLogLevel Warn = VideoPlusLogLevel._(500, 'war');

  /// Priority constant for the [FijkLog.log] method; use [FijkLog.e(msg)]
  static const VideoPlusLogLevel Error = VideoPlusLogLevel._(600, 'err');
  static const VideoPlusLogLevel Fatal = VideoPlusLogLevel._(700, 'fal');
  static const VideoPlusLogLevel Silent = VideoPlusLogLevel._(800, 'sil');

  @override
  String toString() {
    return 'VideoPlusLogLevel{level:$level, name:$name}';
  }
}

/// API for sending log output
///
/// Generally, you should use the [FijkLog.d(msg)], [FijkLog.i(msg)],
/// [FijkLog.w(msg)], and [FijkLog.e(msg)] methods to write logs.
/// You can then view the logs in console/logcat.
///
/// The order in terms of verbosity, from least to most is ERROR, WARN, INFO, DEBUG, VERBOSE.
/// Verbose should always be skipped in an application except during development.
/// Debug logs are compiled in but stripped at runtime.
/// Error, warning and info logs are always kept.
class VideoPlusLog {
  /// Make constructor private
  const VideoPlusLog._();
  static VideoPlusLogLevel _level = VideoPlusLogLevel.Info;

  /// Set global whole log level
  ///
  /// Call this method on Android platform will load natvie shared libraries.
  /// If you care about app boot performance,
  /// you should call this method as late as possiable. Call this method before the first time you consturctor new [VideoPlusPlayer]
  static void setLevel(final VideoPlusLogLevel level) {
    assert(level != null);
    _level = level;
    log(VideoPlusLogLevel.Silent, 'set log level $level', 'VideoPlus');
    VideoPlusPlugin._setLogLevel(level.level).then((_) {
      log(VideoPlusLogLevel.Silent, 'native log level ${level.level}',
          'VideoPlus');
    });
  }

  /// log [msg] with [level] and [tag] to console
  static void log(VideoPlusLogLevel level, String msg, String tag) {
    if (level.level >= _level.level) {
      final now = DateTime.now();
      if (kDebugMode) {
        print('[${level.name}] ${now.toLocal()} [$tag] $msg');
      }
    }
  }

  /// log [msg] with [VideoPlusLogLevel.Verbose] level
  static void v(String msg, {String tag = 'VideoPlus'}) {
    log(VideoPlusLogLevel.Verbose, msg, tag);
  }

  /// log [msg] with [VideoPlusLogLevel.Debug] level
  static void d(String msg, {String tag = 'VideoPlus'}) {
    log(VideoPlusLogLevel.Debug, msg, tag);
  }

  /// log [msg] with [VideoPlusLogLevel.Info] level
  static void i(String msg, {String tag = 'VideoPlus'}) {
    log(VideoPlusLogLevel.Info, msg, tag);
  }

  /// log [msg] with [VideoPlusLogLevel.Warn] level
  static void w(String msg, {String tag = 'VideoPlus'}) {
    log(VideoPlusLogLevel.Warn, msg, tag);
  }

  /// log [msg] with [VideoPlusLogLevel.Error] level
  static void e(String msg, {String tag = 'VideoPlus'}) {
    log(VideoPlusLogLevel.Error, msg, tag);
  }
}
