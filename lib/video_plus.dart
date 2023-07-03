
import 'video_plus_platform_interface.dart';

class VideoPlus {
  Future<String?> getPlatformVersion() {
    return VideoPlusPlatform.instance.getPlatformVersion();
  }
}
