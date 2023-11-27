// ===============================================
// video_plus
//
// Create by Will on 2023/11/17 21:07
// Copyright Will All rights reserved.
// ===============================================

import 'package:fijkplayer/fijkplayer.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:video_plus/src/utils/platform_utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'controls/plus_control.dart';

class VideoPlus {
  static Future<void> initFlutter([String? subDir]) async {
    await Hive.initFlutter(subDir);
  }
}

class VideoPlusView extends StatefulWidget {
  const VideoPlusView({
    super.key,
    required this.control,
    this.fit = BoxFit.contain,
  });

  /// Property passed to [FlickVideoPlayer]
  final BoxFit fit;

  final PlusControl control;

  @override
  State<VideoPlusView> createState() => _VideoPlusViewState();
}

class _VideoPlusViewState extends State<VideoPlusView> {
  late FijkFit fit;

  @override
  void initState() {
    super.initState();
    initPlay();
  }

  Future<void> initPlay() async {
    if (PlatformUtils.isMobile) {
      switch (widget.fit) {
        case BoxFit.fill:
          fit = FijkFit.fill;
          break;
        case BoxFit.contain:
          fit = FijkFit.contain;
          break;
        case BoxFit.cover:
          fit = FijkFit.cover;
          break;
        case BoxFit.fitWidth:
          fit = FijkFit.fitWidth;
          break;
        case BoxFit.fitHeight:
          fit = FijkFit.fitHeight;
          break;
        case BoxFit.none:
          fit = FijkFit.fill;
          break;
        case BoxFit.scaleDown:
          fit = FijkFit.fill;
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformUtils.isMobile ? _buildMobile() : _buildOther();
  }

  Widget _buildMobile() {
    return VisibilityDetector(
      key: ObjectKey(widget.control.player),
      onVisibilityChanged: (visibility) {
        final visiblePercentage = visibility.visibleFraction * 100;
        if (visiblePercentage == 0) {
          widget.control.onPause();
        } else if (visiblePercentage == 100) {
          widget.control.onPlay();
        }
      },
      child: FijkView(
        player: widget.control.player!,
        fsFit: fit,
      ),
    );
  }

  Widget _buildOther() {
    return VisibilityDetector(
      key: ObjectKey(widget.control.flickManager),
      onVisibilityChanged: (visibility) {
        final visiblePercentage = visibility.visibleFraction * 100;
        if (visiblePercentage == 0) {
          widget.control.onPause();
        } else if (visiblePercentage == 100) {
          widget.control.onPlay();
        }
      },
      child: FlickVideoPlayer(
        flickManager: widget.control.flickManager!,
        flickVideoWithControls: FlickVideoWithControls(
          closedCaptionTextStyle: const TextStyle(fontSize: 8),
          controls: const FlickPortraitControls(),
          videoFit: widget.fit,
        ),
        flickVideoWithControlsFullscreen: const FlickVideoWithControls(
          controls: FlickLandscapeControls(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.control.dispose();
    super.dispose();
  }
}
