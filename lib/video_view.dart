// ===============================================
// video_view
//
// Create by Will on 5/7/2023 20:53
// Copyright @video_plus.All rights reserved.
// ===============================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:video_plus/video_play.dart';
import 'package:video_plus/video_plus.dart';

class VideoView extends StatefulWidget {
  const VideoView({
    super.key,
    required this.player,
    this.width,
    this.height,
    this.fit = VideoPlusFit.contain,
    this.fsFit = VideoPlusFit.contain,
    this.panelBuilder = defaultVideoPanelBuilder,
    this.color = const Color(0xFF607D8B),
    this.cover,
    this.fs = true,
    this.onDispose,
  });

  /// The player that need display video by this [VideoView].
  /// Will be passed to [panelBuilder].
  final VideoPlayer player;

  /// builder to build panel Widget
  final VideoPlusPanelWidgetBuilder panelBuilder;

  /// This method will be called when VideoView dispose.
  /// VideoData is managed inner VideoView. User can change VideoData in custom panel.
  /// See [panelBuilder]'s second argument.
  /// And check if some value need to be recover on VideoView dispose.
  final void Function(VideoPlusData)? onDispose;

  /// background color
  final Color color;

  /// cover image provider
  final ImageProvider? cover;

  /// How a video should be inscribed into this [VideoView].
  final VideoPlusFit fit;

  /// How a video should be inscribed into this [VideoView] at fullScreen mode.
  final VideoPlusFit fsFit;

  /// Nullable, width of [VideoView]
  /// If null, the weight will be as big as possible.
  final double? width;

  /// Nullable, height of [VideoView].
  /// If null, the height will be as big as possible.
  final double? height;

  /// Enable or disable the full screen
  ///
  /// If [fs] is true, VideoView make response to the [VideoPlusValue.fullScreen] value changed,
  /// and push o new full screen mode page when [VideoPlusValue.fullScreen] is true, pop full screen page when [VideoPlusValue.fullScreen]  become false.
  ///
  /// If [fs] is false, VideoView never make response to the change of [VideoPlusValue.fullScreen].
  /// But you can still call [VideoPlusPlayer.enterFullScreen] and [VideoPlusPlayer.exitFullScreen] and make your own full screen pages.
  final bool fs;

  @override
  _VideoViewState createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  @override
  Widget build(BuildContext context) {
    debugPrint('create new VideoPlayer');
    debugPrint('create new web === $kIsWeb');

    return kIsWeb == true
        ? Container(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: widget.player.player!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  vp.VideoPlayer(widget.player.player!),
                  vp.ClosedCaption(
                      text: widget.player.player!.value.caption.text),
                  // _ControlsOverlay(controller: widget.player.player!),
                  vp.VideoProgressIndicator(widget.player.player!,
                      allowScrubbing: true),
                ],
              ),
            ),
          )
        : VideoPlusView(
            player: widget.player.player!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            fsFit: widget.fsFit,
            panelBuilder: widget.panelBuilder,
            color: widget.color,
            cover: widget.cover,
            fs: widget.fs,
            onDispose: widget.onDispose,
          );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});

  static const List<Duration> _exampleCaptionOffsets = <Duration>[
    Duration(seconds: -10),
    Duration(seconds: -3),
    Duration(seconds: -1, milliseconds: -500),
    Duration(milliseconds: -250),
    Duration.zero,
    Duration(milliseconds: 250),
    Duration(seconds: 1, milliseconds: 500),
    Duration(seconds: 3),
    Duration(seconds: 10),
  ];
  static const List<double> _examplePlaybackRates = <double>[
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  final vp.VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        Align(
          alignment: Alignment.topLeft,
          child: PopupMenuButton<Duration>(
            initialValue: controller.value.captionOffset,
            tooltip: 'Caption Offset',
            onSelected: (Duration delay) {
              controller.setCaptionOffset(delay);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<Duration>>[
                for (final Duration offsetDuration in _exampleCaptionOffsets)
                  PopupMenuItem<Duration>(
                    value: offsetDuration,
                    child: Text('${offsetDuration.inMilliseconds}ms'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.captionOffset.inMilliseconds}ms'),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (double speed) {
              controller.setPlaybackSpeed(speed);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in _examplePlaybackRates)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}
