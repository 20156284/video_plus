import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_plus/VideoPlusPlayer.dart';

import 'app_bar.dart';

class ListItemPlayer extends StatefulWidget {
  const ListItemPlayer(
      {super.key, required this.index, required this.notifier});
  final int index;
  final ValueNotifier<double> notifier;

  @override
  _ListItemPlayerState createState() => _ListItemPlayerState();
}

class _ListItemPlayerState extends State<ListItemPlayer> {
  VideoPlusPlayer? _player;
  Timer? _timer;
  bool _start = false;
  bool _expectStart = false;

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(scrollListener);
    final mills = widget.index <= 3 ? 100 : 500;
    _timer = Timer(Duration(milliseconds: mills), () async {
      _player = VideoPlusPlayer();
      await _player?.setDataSource('asset:///assets/butterfly.mp4');
      await _player?.prepareAsync();
      scrollListener();
      if (mounted) {
        setState(() {});
      }
    });
  }

  void scrollListener() {
    if (!mounted) {
      return;
    }

    /// !!important
    /// If items in your list view have different height,
    /// You can't get the first visible item index by
    /// dividing a constant height simply

    final pixels = widget.notifier.value;
    final x = (pixels / 200).ceil();
    final player = _player;
    if (player != null && widget.index == x) {
      _expectStart = true;
      player.removeListener(pauseListener);
      if (_start == false && _player!.isPlayable()) {
        VideoPlusLog.i('start from scroll listener $player');
        player.start();
        _start = true;
      } else if (_start == false) {
        VideoPlusLog.i('add start listener $player');
        player.addListener(startListener);
      }
    } else if (_player != null) {
      _expectStart = false;
      player!.removeListener(startListener);
      if (player.isPlayable() && _start) {
        VideoPlusLog.i('pause from scroll listener $player');
        player.pause();
        _start = false;
      } else if (_start) {
        VideoPlusLog.i('add pause listener $player');
        player.addListener(pauseListener);
      }
    }
  }

  void startListener() {
    final value = _player!.value;
    if (value.prepared && !_start && _expectStart) {
      _start = true;
      VideoPlusLog.i('start from player listener $_player');
      _player!.start();
    }
  }

  void pauseListener() {
    final value = _player!.value;
    if (value.prepared && _start && !_expectStart) {
      _start = false;
      VideoPlusLog.i('pause from player listener $_player');
      _player?.pause();
    }
  }

  void finalizer() {
    _player?.removeListener(startListener);
    _player?.removeListener(pauseListener);
    final player = _player;
    _player = null;
    player?.release();
  }

  @override
  void dispose() {
    super.dispose();
    widget.notifier.removeListener(scrollListener);
    _timer?.cancel();
    finalizer();
  }

  @override
  Widget build(BuildContext context) {
    const fit = VideoPlusFit(
      aspectRatio: 480 / 270,
    );
    return SizedBox(
        height: 200,
        child: Column(
          children: <Widget>[
            Text('${widget.index}', style: const TextStyle(fontSize: 20)),
            Expanded(
              child: _player != null
                  ? VideoPlusView(
                      player: _player!,
                      fit: fit,
                      cover: const AssetImage('assets/cover.png'),
                    )
                  : Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(color: Color(0xFF607D8B)),
                      child: Image.asset('assets/cover.png'),
                    ),
            )
          ],
        ));
  }
}

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final ValueNotifier<double> notifier = ValueNotifier(-1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VideoAppBar(title: 'List View'),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          notifier.value = notification.metrics.pixels;
          return true;
        },
        child: ListView.builder(
          itemBuilder: (context, index) {
            return ListItemPlayer(index: index, notifier: notifier);
          },
          cacheExtent: 1,
        ),
      ),
    );
  }
}
