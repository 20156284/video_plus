import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'video_plus_method_channel.dart';

abstract class VideoPlusPlatform extends PlatformInterface {
  /// Constructs a VideoPlusPlatform.
  VideoPlusPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoPlusPlatform _instance = MethodChannelVideoPlus();

  /// The default instance of [VideoPlusPlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoPlus].
  static VideoPlusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoPlusPlatform] when
  /// they register themselves.
  static set instance(VideoPlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
