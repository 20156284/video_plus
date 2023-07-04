library video_plus;

import 'dart:async';
import 'dart:collection';
import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'video_plus_platform_interface.dart';

part 'core/video_plus_log.dart';
part 'core/video_plus_option.dart';
part 'core/video_plus_player.dart';
part 'core/video_plus_plugin.dart';
part 'core/video_plus_value.dart';
part 'core/video_plus_view.dart';
part 'core/video_plus_vol.dart';
part 'ui/panel.dart';
part 'ui/panel2.dart';
part 'ui/slider.dart';
part 'ui/volume.dart';

class VideoPlus {
  Future<String?> getPlatformVersion() {
    return VideoPlusPlatform.instance.getPlatformVersion();
  }
}
