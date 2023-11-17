// ===============================================
// platform_utils
//
// Create by Will on 2023/10/10 16:21
// Copyright Will All rights reserved.
// ===============================================

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtils {
  static bool get isMobile {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isIOS || Platform.isAndroid;
    }
  }

  static bool get isDesktop {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isLinux ||
          Platform.isFuchsia ||
          Platform.isWindows ||
          Platform.isMacOS;
    }
  }
}
