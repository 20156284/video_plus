//MIT License
//
//Copyright (c) [2019] [Befovy]
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

class VideoPlusPlugin {
  /// Make constructor private
  const VideoPlusPlugin._();

  static const MethodChannel _channel = MethodChannel('befovy.com/fijk');

  static Future<int> _createPlayer() async {
    final pid = await _channel.invokeMethod('createPlayer');
    if (pid != null) {
      return Future.value(pid);
    }
    VideoPlusLog.e('failed to create native player');
    return Future.value(-1);
  }

  static Future<void> _releasePlayer(int pid) {
    return _channel
        .invokeMethod('releasePlayer', <String, dynamic>{'pid': pid});
  }

  static bool isDesktop() {
    return Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux ||
        Platform.isFuchsia;
  }

  /// Only works on Android and iOS
  static Future<bool> setOrientationPortrait() async {
    if (isDesktop()) {
      return Future.value();
    }
    // ios crash Supported orientations has no common orientation with the application
    final changed = await _channel.invokeMethod('setOrientationPortrait');
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return Future.value(changed);
  }

  /// Only works on Android and iOS
  /// return false if current orientation is landscape
  /// return true if current orientation is portrait and after this API
  /// call finished, the orientation becomes landscape.
  /// return false if can't change orientation.
  static Future<bool> setOrientationLandscape() async {
    if (isDesktop()) {
      return Future.value(false);
    }
    final changed = await _channel.invokeMethod('setOrientationLandscape');
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    return Future.value(changed);
  }

  static Future<void> setOrientationAuto() {
    if (Platform.isAndroid) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    return _channel.invokeMethod('setOrientationAuto');
  }

  /// Works on Android and iOS
  /// Keep screen on or not
  static Future<void> keepScreenOn(bool on) {
    if (Platform.isAndroid || Platform.isIOS) {
      VideoPlusLog.i('keepScreenOn :$on');
      return _channel.invokeMethod('setScreenOn', <String, dynamic>{'on': on});
    }
    return Future.value();
  }

  /// Check if screen is kept on
  static Future<bool> isScreenKeptOn() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final keptOn = await _channel.invokeMethod('isScreenKeptOn');
      if (keptOn != null) {
        return Future.value(keptOn);
      }
    }
    return Future.value(false);
  }

  /// Set screen brightness.
  /// The range of [value] is [0.0, 1.0]
  static Future<void> setScreenBrightness(double value) {
    if (value < 0.0 || value > 1.0) {
      return Future.error(ArgumentError.value(
          value, 'brightness value must be not null and in range [0.0, 1.0]'));
    } else if (Platform.isAndroid || Platform.isIOS) {
      return _channel.invokeMethod(
          'setBrightness', <String, dynamic>{'brightness': value});
    }
    return Future.value();
  }

  /// Get the screen brightness.
  /// The range of returned value is [0.0, 1.0]
  static Future<double> screenBrightness() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final brightness = await _channel.invokeMethod('brightness');
      if (brightness != null) {
        return Future.value(brightness);
      }
    }
    return Future.value(0);
  }

  /// Only works on Android
  /// request audio focus for media usage
  static Future<void> requestAudioFocus() {
    if (Platform.isAndroid) {
      return _channel.invokeMethod('requestAudioFocus');
    }
    return Future.value();
  }

  /// Only works on Android
  /// release audio focus
  static Future<void> releaseAudioFocus() {
    if (Platform.isAndroid) {
      return _channel.invokeMethod('releaseAudioFocus');
    }
    return Future.value();
  }

  static Future<void> _setLogLevel(int level) {
    return _channel.invokeMethod('logLevel', <String, dynamic>{'level': level});
  }

  static StreamSubscription? _eventSubs;

  static void _onLoad(String type) {
    if (_eventSubs == null) {
      VideoPlusLog.i('_onLoad $type');
      _eventSubs = const EventChannel('befovy.com/fijk/event')
          .receiveBroadcastStream()
          .listen(VideoPlusPlugin._eventListener,
              onError: VideoPlusPlugin._errorListener);
    }
    _channel.invokeMethod('onLoad');
  }

  // ignore: unused_element
  static void _onUnload() {
    VideoPlusLog.i('_onUnload');
    _channel.invokeMethod('onUnload');
    _eventSubs?.cancel();
  }

  static void _eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    VideoPlusLog.d('plugin listener: $map');
    switch (map['event']) {
      case 'volume':
        final bool sui = map['sui'] ?? false;
        final double vol = map['vol'] ?? 0.0;
        VideoPlusVolume._instance._onVolCallback(vol, sui);
        break;
      default:
        break;
    }
  }

  static void _errorListener(Object obj) {
    VideoPlusLog.e('plugin errorListerner: $obj');
  }
}
