// ===============================================
// plus_control
//
// Create by Will on 2023/11/20 09:41
// Copyright Will All rights reserved.
// ===============================================

import 'package:fijkplayer/fijkplayer.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:video_plus/src/utils/platform_utils.dart';
import 'package:video_plus/src/utils/url_utils.dart';

class PlusControl with ChangeNotifier {
  PlusControl({
    required this.url,
    this.autoPlay = true,
    this.useCache = false,
  }) {
    initPlay();
  }

  //video url include assets
  final String url;

  //don't support web
  final bool useCache;

  final bool autoPlay;

  FijkPlayer? _player;
  FlickManager? _flickManager;
  VideoPlayerController? _videoPlayerController;

  FijkPlayer? get player => _player;

  FlickManager? get flickManager => _flickManager;

  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  Future<void> initPlay() async {
    if (PlatformUtils.isMobile) {
      _player = FijkPlayer();
      await _player!.setOption(FijkOption.hostCategory, 'enable-snapshot', 1);
      await _player!
          .setOption(FijkOption.playerCategory, 'mediacodec-all-videos', 1);

      await _player!.setOption(FijkOption.hostCategory, 'request-screen-on', 1);
      await _player!
          .setOption(FijkOption.hostCategory, 'request-audio-focus', 1);
      await _player!
          .setDataSource(
        url,
        autoPlay: autoPlay,
      )
          .catchError((e) {
        // print('setDataSource error: $e');
      });
    } else {
      if (UrlUtils.isAssets(url)) {
        _videoPlayerController = VideoPlayerController.asset(url);
      } else {
        _videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(url));
      }

      _flickManager = FlickManager(
        videoPlayerController: _videoPlayerController!,
        autoPlay: autoPlay,
      );
    }
  }

  //播放
  void onPlay() {
    if (PlatformUtils.isMobile) {
      _player!.start();
    } else {
      _flickManager!.flickControlManager?.autoResume();
    }
  }

  //暂停
  void onPause() {
    if (PlatformUtils.isMobile) {
      _player!.pause();
    } else {
      _flickManager!.flickControlManager?.autoPause();
    }
  }

  @override
  void dispose() {
    if (PlatformUtils.isMobile) {
      _player!.release();
      player!.release();
    } else {
      _videoPlayerController!.dispose();
      videoPlayerController!.dispose();
      _flickManager!.dispose();
      flickManager!.dispose();
    }
    super.dispose();
  }
}
