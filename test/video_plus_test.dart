import 'package:flutter_test/flutter_test.dart';
import 'package:video_plus/video_plus.dart';
import 'package:video_plus/video_plus_platform_interface.dart';
import 'package:video_plus/video_plus_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVideoPlusPlatform
    with MockPlatformInterfaceMixin
    implements VideoPlusPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final VideoPlusPlatform initialPlatform = VideoPlusPlatform.instance;

  test('$MethodChannelVideoPlus is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVideoPlus>());
  });

  test('getPlatformVersion', () async {
    VideoPlus videoPlusPlugin = VideoPlus();
    MockVideoPlusPlatform fakePlatform = MockVideoPlusPlatform();
    VideoPlusPlatform.instance = fakePlatform;

    expect(await videoPlusPlugin.getPlatformVersion(), '42');
  });
}
