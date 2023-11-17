// ===============================================
// url_utils
//
// Create by Will on 2023/11/17 21:23
// Copyright Will All rights reserved.
// ===============================================

class UrlUtils {
  static bool isAssets(String url) {
    if (url.contains('assets/') && !url.contains('http')) {
      return true;
    }
    return false;
  }
}
