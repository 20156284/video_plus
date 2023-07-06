import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_plus/video_play.dart';
import 'package:video_plus/video_plus.dart';
import 'package:video_plus/video_view.dart';

import 'app_bar.dart';
// import 'custom_ui.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key, required this.url});
  final String url;

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  _VideoScreenState();
  late VideoPlayer player;

  @override
  void initState() {
    super.initState();
    player = VideoPlayer(url: widget.url)
      ..setOption(VideoPlusOption.hostCategory, 'enable-snapshot', 1)
      ..setOption(VideoPlusOption.playerCategory, 'mediacodec-all-videos', 1);
    startPlay();
  }

  Future<void> startPlay() async {
    await player.setOption(
        VideoPlusOption.hostCategory, 'request-screen-on', 1);
    await player.setOption(
        VideoPlusOption.hostCategory, 'request-audio-focus', 1);
    await player.setDataSource(widget.url, autoPlay: true).catchError((e) {
      if (kDebugMode) {
        print('setDataSource error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VideoAppBar(title: 'Video'),
      body: Center(
        child: VideoView(
          player: player,
          panelBuilder: videoPanel2Builder(snapShot: true),
          fsFit: VideoPlusFit.fill,
          // panelBuilder: simplestUI,
          // panelBuilder: (VideoPlusPlayer player, BuildContext context,
          //     Size viewSize, Rect texturePos) {
          //   return CustomVideoPlusPanel(
          //       player: player,
          //       buildContext: context,
          //       viewSize: viewSize,
          //       texturePos: texturePos);
          // },
          // panelBuilder: (player, data, context, viewSize, texturePos) {
          //   return CustomVideoPlusPanel(
          //       player: player,
          //       buildContext: context,
          //       viewSize: viewSize,
          //       texturePos: texturePos);
          // },
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    player.release();
  }
}
