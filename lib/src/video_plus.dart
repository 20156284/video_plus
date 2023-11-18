// ===============================================
// video_plus
//
// Create by Will on 2023/11/17 21:07
// Copyright Will All rights reserved.
// ===============================================

import 'package:fijkplayer/fijkplayer.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_plus/src/utils/platform_utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'utils/url_utils.dart';

class VideoPlus extends StatefulWidget {
  const VideoPlus({
    super.key,
    required this.url,
    this.useCache = false,
    this.fit = BoxFit.cover,
    this.autoPlay = true,
  });

  //video url include assets
  final String url;

  //don't support web
  final bool useCache;

  /// Property passed to [FlickVideoPlayer]
  final BoxFit fit;

  final bool autoPlay;

  @override
  State<VideoPlus> createState() => _VideoPlusState();
}

class _VideoPlusState extends State<VideoPlus> {
  late FijkPlayer player;
  late FijkFit fit;
  late FlickManager flickManager;
  late VideoPlayerController videoPlayerController;
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
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

      player = FijkPlayer();
      await player.setOption(FijkOption.hostCategory, 'enable-snapshot', 1);
      await player.setOption(
          FijkOption.playerCategory, 'mediacodec-all-videos', 1);

      await player.setOption(FijkOption.hostCategory, 'request-screen-on', 1);
      await player.setOption(FijkOption.hostCategory, 'request-audio-focus', 1);
      await player
          .setDataSource(
        widget.url,
        autoPlay: widget.autoPlay,
      )
          .catchError((e) {
        // print('setDataSource error: $e');
      });
    } else {
      if (UrlUtils.isAssets(widget.url)) {
        videoPlayerController = VideoPlayerController.asset(widget.url);
      } else {
        videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(widget.url));
      }

      flickManager = FlickManager(
        videoPlayerController: videoPlayerController,
        autoPlay: widget.autoPlay,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformUtils.isMobile ? _buildMobile() : _buildOther();
  }

  Widget _buildMobile() {
    return FijkView(
      player: player,
      fsFit: fit,
    );
  }

  Widget _buildOther() {
    return VisibilityDetector(
      key: ObjectKey(flickManager),
      onVisibilityChanged: (visibility) {
        if (visibility.visibleFraction == 0 && mounted) {
          flickManager.flickControlManager?.autoPause();
        } else if (visibility.visibleFraction == 1) {
          flickManager.flickControlManager?.autoResume();
        }
      },
      child: FlickVideoPlayer(
        flickManager: flickManager,
        flickVideoWithControls: const FlickVideoWithControls(
          closedCaptionTextStyle: TextStyle(fontSize: 8),
          controls: FlickPortraitControls(),
        ),
        flickVideoWithControlsFullscreen: const FlickVideoWithControls(
          controls: FlickLandscapeControls(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (PlatformUtils.isMobile) {
    } else {
      videoPlayerController.dispose();
      flickManager.dispose();
    }

    super.dispose();
  }
}
