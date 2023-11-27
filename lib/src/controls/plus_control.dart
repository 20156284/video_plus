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
import 'package:video_plus/src/utils/video_download_utils.dart';

class PlusControl with ChangeNotifier {
  PlusControl({
    required this.url,
    this.autoPlay = true,
    this.useCache = false,
    this.decryptM3U8,
    this.encry,
    this.encrypt = false,
  }) {
    initPlay();
  }

  //video url include assets
  final String url;

  //don't support web
  final bool useCache;

  final bool autoPlay;

  final Function? decryptM3U8;
  final Function? encry;
  final bool encrypt;

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

      if (useCache) {
        // 创建下载任务
        /*
   * taskInfo数据结构:
   * id              视频id
   * urlPath         下载地址（需解密）
   * title           视频标题
   * thumbCover      视频封面
   * tags            视频标签
   * contentType     视频类型
   * downloading     视频下载状态 bool
   * isWaiting       是否在下载队列中 bool
   * url             视频m3u8储存地址
   * tsLists         视频ts链接队列
   * localM3u8       本地m3u8文件 string
   * tsListsFinished 已下载完成的ts队列
   * progress        视频下载进度
   */

        final taskInfo = {
          'id': 123,
          'urlPath': url,
          'title': 'videoInfo.title',
          'thumbCover': '',
          'tags': [],
          'contentType': 1,
          'downloading': false,
          'isWaiting': true
        };

        VideoDownloadUtil.createDownloadTask(
          taskInfo: taskInfo,
          encrypt: true,
          decryptM3U8: decryptM3U8,
        );
      }
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
