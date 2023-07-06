// ===============================================
// video_play
//
// Create by Will on 6/7/2023 15:01
// Copyright @video_plus.All rights reserved.
// ===============================================

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:video_plus/video_plus.dart';

class VideoPlayer {
  VideoPlayer({required this.url})
      : player = kIsWeb ? null : VideoPlusPlayer() {
    VideoPlusLog.d('create new VideoPlayer');
    if (kIsWeb) {
      if (url!.contains('assets')) {
        player = VideoPlayerController.asset(url!);
      }
      if (url!.contains('http')) {
        player = VideoPlayerController.networkUrl(
          Uri.parse(url!),
        );
      }

      player.addListener(() {
        // setState(() {});
      });
      player.setLooping(true);
      player.initialize();
      player.play();
    }
  }
  final String? url;

  static final Map<int, VideoPlusPlayer> _allInstance = HashMap();
  var player;

  static Iterable<VideoPlusPlayer> get all => _allInstance.values;

  Future<int> get id => player.id;

  int get idSync => player.idSync;

  VideoPlusState get state => player.state;

  VideoPlusValue get value => player.value;

  Duration get bufferPos => player.bufferPos;

  Stream<Duration> get onBufferPosUpdate => player.onBufferPosUpdate;

  int get bufferPercent => player.bufferPercent;

  Stream<int> get onBufferPercentUpdate => player.onBufferPercentUpdate;

  Duration get currentPos => player.currentPos;

  Stream<Duration> get onCurrentPosUpdate => player.onCurrentPosUpdate;

  bool get isBuffering => player.isBuffering;

  Stream<bool> get onBufferStateUpdate => player.onBufferStateUpdate;

  String? get dataSource => player.dataSource;

  bool isPlayable() {
    return player.isPlayable();
  }

  Future<void> setOption(int category, String key, dynamic value) async {
    if (kIsWeb) {
      return;
    } else {
      return player.setOption(category, key, value);
    }
  }

  Future<void> applyOptions(VideoPlusOption option) async {
    return player.applyOptions(option);
  }

  Future<int?> setupSurface() async {
    return player.setupSurface();
  }

  Future<Uint8List> takeSnapShot() async {
    return player.takeSnapShot();
  }

  Future<void> setDataSource(
    String path, {
    bool autoPlay = false,
    bool showCover = false,
  }) async {
    if (!kIsWeb) {
      player.setDataSource(path, autoPlay: autoPlay, showCover: showCover);
    }
  }

  Future<void> prepareAsync() async {
    return player.prepareAsync();
  }

  Future<void> setVolume(double volume) async {
    return player.setVolume(volume);
  }

  void enterFullScreen() {
    VideoPlusLog.i('$this enterFullScreen');
    player.enterFullScreen();
  }

  void exitFullScreen() {
    player.exitFullScreen();
  }

  Future<void> start() async {
    return player.start();
  }

  Future<void> pause() async {
    return player.pause();
  }

  Future<void> stop() async {
    return player.stop();
  }

  Future<void> reset() async {
    return player.reset();
  }

  Future<void> seekTo(int msec) async {
    return player.seekTo(msec);
  }

  /// Release native player. Release memory and resource
  Future<void> release() async {
    if (kIsWeb) {
    } else {
      return player.release();
    }
  }

  Future<void> setLoop(int loopCount) async {
    return player.setLoop(loopCount);
  }

  Future<void> setSpeed(double speed) async {
    return player.setSpeed(speed);
  }

  @override
  String toString() {
    return player.toString();
  }
}
