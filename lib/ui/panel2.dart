//MIT License
//
//Copyright (c) [2023] [Will]
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

part of VideoPlusPlayer;

VideoPlusPanelWidgetBuilder fijkPanel2Builder(
    {Key? key,
    final bool fill = false,
    final int duration = 4000,
    final bool doubleTap = true,
    final bool snapShot = false,
    final VoidCallback? onBack}) {
  return (player, data, context, viewSize, texturePos) {
    return _VideoPlusPanel2(
      key: key,
      player: player,
      data: data,
      onBack: onBack,
      viewSize: viewSize,
      texPos: texturePos,
      fill: fill,
      doubleTap: doubleTap,
      snapShot: snapShot,
      hideDuration: duration,
    );
  };
}

class _VideoPlusPanel2 extends StatefulWidget {
  const _VideoPlusPanel2(
      {Key? key,
      required this.player,
      required this.data,
      this.fill = false,
      this.onBack,
      required this.viewSize,
      this.hideDuration = 4000,
      this.doubleTap = false,
      this.snapShot = false,
      required this.texPos})
      : assert(hideDuration > 0 && hideDuration < 10000),
        super(key: key);
  final VideoPlusPlayer player;
  final VideoPlusData data;
  final VoidCallback? onBack;
  final Size viewSize;
  final Rect texPos;
  final bool fill;
  final bool doubleTap;
  final bool snapShot;
  final int hideDuration;

  @override
  _VideoPlusPanel2State createState() => _VideoPlusPanel2State();
}

class _VideoPlusPanel2State extends State<_VideoPlusPanel2> {
  VideoPlusPlayer get player => widget.player;

  Timer? _hideTimer;
  bool _hideStuff = true;

  Timer? _statelessTimer;
  bool _prepared = false;
  bool _playing = false;
  bool _dragLeft = false;
  double? _volume;
  double? _brightness;

  double _seekPos = -1.0;
  Duration _duration = const Duration();
  Duration _currentPos = const Duration();
  Duration _bufferPos = const Duration();

  StreamSubscription? _currentPosSubs;
  StreamSubscription? _bufferPosSubs;

  late StreamController<double> _valController;

  // snapshot
  ImageProvider? _imageProvider;
  Timer? _snapshotTimer;

  // Is it needed to clear seek data in FijkData (widget.data)
  bool _needClearSeekData = true;

  static const FijkSliderColors sliderColors = FijkSliderColors(
      cursorColor: Color.fromARGB(240, 250, 100, 10),
      playedColor: Color.fromARGB(200, 240, 90, 50),
      baselineColor: Color.fromARGB(100, 20, 20, 20),
      bufferedColor: Color.fromARGB(180, 200, 200, 200));

  @override
  void initState() {
    super.initState();

    _valController = StreamController.broadcast();
    _prepared = player.state.index >= VideoPlusState.prepared.index;
    _playing = player.state == VideoPlusState.started;
    _duration = player.value.duration;
    _currentPos = player.currentPos;
    _bufferPos = player.bufferPos;

    _currentPosSubs = player.onCurrentPosUpdate.listen((v) {
      if (_hideStuff == false) {
        setState(() {
          _currentPos = v;
        });
      } else {
        _currentPos = v;
      }
      if (_needClearSeekData) {
        widget.data.clearValue(VideoPlusData._fijkViewPanelSeekto);
      }
      _needClearSeekData = false;
    });

    if (widget.data.contains(VideoPlusData._fijkViewPanelSeekto)) {
      final pos =
          widget.data.getValue(VideoPlusData._fijkViewPanelSeekto) as double;
      _currentPos = Duration(milliseconds: pos.toInt());
    }

    _bufferPosSubs = player.onBufferPosUpdate.listen((v) {
      if (_hideStuff == false) {
        setState(() {
          _bufferPos = v;
        });
      } else {
        _bufferPos = v;
      }
    });

    player.addListener(_playerValueChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _valController.close();
    _hideTimer?.cancel();
    _statelessTimer?.cancel();
    _snapshotTimer?.cancel();
    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
    player.removeListener(_playerValueChanged);
  }

  double dura2double(Duration d) {
    return d.inMilliseconds.toDouble();
  }

  void _playerValueChanged() {
    final value = player.value;

    if (value.duration != _duration) {
      if (_hideStuff == false) {
        setState(() {
          _duration = value.duration;
        });
      } else {
        _duration = value.duration;
      }
    }
    final playing = (value.state == VideoPlusState.started);
    final prepared = value.prepared;
    if (playing != _playing ||
        prepared != _prepared ||
        value.state == VideoPlusState.asyncPreparing) {
      setState(() {
        _playing = playing;
        _prepared = prepared;
      });
    }
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(milliseconds: widget.hideDuration), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void onTapFun() {
    if (_hideStuff == true) {
      _restartHideTimer();
    }
    setState(() {
      _hideStuff = !_hideStuff;
    });
  }

  void playOrPause() {
    if (player.isPlayable() || player.state == VideoPlusState.asyncPreparing) {
      if (player.state == VideoPlusState.started) {
        player.pause();
      } else {
        player.start();
      }
    } else if (player.state == VideoPlusState.initialized) {
      player.start();
    } else {
      VideoPlusLog.w(
          "Invalid state ${player.state} ,can't perform play or pause");
    }
  }

  void onDoubleTapFun() {
    playOrPause();
  }

  void onVerticalDragStartFun(DragStartDetails d) {
    if (d.localPosition.dx > panelWidth() / 2) {
      // right, volume
      _dragLeft = false;
      VideoPlusVolume.getVol().then((v) {
        if (!widget.data.contains(VideoPlusData._fijkViewPanelVolume)) {
          widget.data.setValue(VideoPlusData._fijkViewPanelVolume, v);
        }
        setState(() {
          _volume = v;
          _valController.add(v);
        });
      });
    } else {
      // left, brightness
      _dragLeft = true;
      VideoPlusPlugin.screenBrightness().then((v) {
        if (!widget.data.contains(VideoPlusData._fijkViewPanelBrightness)) {
          widget.data.setValue(VideoPlusData._fijkViewPanelBrightness, v);
        }
        setState(() {
          _brightness = v;
          _valController.add(v);
        });
      });
    }
    _statelessTimer?.cancel();
    _statelessTimer = Timer(const Duration(milliseconds: 2000), () {
      setState(() {});
    });
  }

  void onVerticalDragUpdateFun(DragUpdateDetails d) {
    var delta = d.primaryDelta! / panelHeight();
    delta = -delta.clamp(-1.0, 1.0);
    if (_dragLeft == false) {
      var volume = _volume;
      if (volume != null) {
        volume += delta;
        volume = volume.clamp(0.0, 1.0);
        _volume = volume;
        VideoPlusVolume.setVol(volume);
        setState(() {
          _valController.add(volume!);
        });
      }
    } else if (_dragLeft == true) {
      var brightness = _brightness;
      if (brightness != null) {
        brightness += delta;
        brightness = brightness.clamp(0.0, 1.0);
        _brightness = brightness;
        VideoPlusPlugin.setScreenBrightness(brightness);
        setState(() {
          _valController.add(brightness!);
        });
      }
    }
  }

  void onVerticalDragEndFun(DragEndDetails e) {
    _volume = null;
    _brightness = null;
  }

  Widget buildPlayButton(BuildContext context, double height) {
    final icon = (player.state == VideoPlusState.started)
        ? const Icon(Icons.pause)
        : const Icon(Icons.play_arrow);
    final fullScreen = player.value.fullScreen;
    return IconButton(
      padding: const EdgeInsets.all(0),
      iconSize: fullScreen ? height : height * 0.8,
      color: const Color(0xFFFFFFFF),
      icon: icon,
      onPressed: playOrPause,
    );
  }

  Widget buildFullScreenButton(BuildContext context, double height) {
    final icon = player.value.fullScreen
        ? const Icon(Icons.fullscreen_exit)
        : const Icon(Icons.fullscreen);
    final fullScreen = player.value.fullScreen;
    return IconButton(
      padding: const EdgeInsets.all(0),
      iconSize: fullScreen ? height : height * 0.8,
      color: const Color(0xFFFFFFFF),
      icon: icon,
      onPressed: () {
        player.value.fullScreen
            ? player.exitFullScreen()
            : player.enterFullScreen();
      },
    );
  }

  Widget buildTimeText(BuildContext context, double height) {
    final text =
        '${_duration2String(_currentPos)}/${_duration2String(_duration)}';
    return Text(text,
        style: const TextStyle(fontSize: 12, color: Color(0xFFFFFFFF)));
  }

  Widget buildSlider(BuildContext context) {
    final duration = dura2double(_duration);

    var currentValue = _seekPos > 0 ? _seekPos : dura2double(_currentPos);
    currentValue = currentValue.clamp(0.0, duration);

    var bufferPos = dura2double(_bufferPos);
    bufferPos = bufferPos.clamp(0.0, duration);

    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: VideoPlusSlider(
        colors: sliderColors,
        value: currentValue,
        cacheValue: bufferPos,
        max: duration,
        onChanged: (v) {
          _restartHideTimer();
          setState(() {
            _seekPos = v;
          });
        },
        onChangeEnd: (v) {
          setState(() {
            player.seekTo(v.toInt());
            _currentPos = Duration(milliseconds: _seekPos.toInt());
            widget.data.setValue(VideoPlusData._fijkViewPanelSeekto, _seekPos);
            _needClearSeekData = true;
            _seekPos = -1.0;
          });
        },
      ),
    );
  }

  Widget buildBottom(BuildContext context, double height) {
    if (_duration.inMilliseconds > 0) {
      return Row(
        children: <Widget>[
          buildPlayButton(context, height),
          buildTimeText(context, height),
          Expanded(child: buildSlider(context)),
          buildFullScreenButton(context, height),
        ],
      );
    } else {
      return Row(
        children: <Widget>[
          buildPlayButton(context, height),
          Expanded(child: Container()),
          buildFullScreenButton(context, height),
        ],
      );
    }
  }

  void takeSnapshot() {
    player.takeSnapShot().then((v) {
      final provider = MemoryImage(v);
      precacheImage(provider, context).then((_) {
        setState(() {
          _imageProvider = provider;
        });
      });
      VideoPlusLog.d('get snapshot succeed');
    }).catchError((e) {
      VideoPlusLog.d('get snapshot failed');
    });
  }

  Widget buildPanel(BuildContext context) {
    final height = panelHeight();

    final fullScreen = player.value.fullScreen;
    Widget centerWidget = Container(
      color: const Color(0x00000000),
    );

    final centerChild = Container(
      color: const Color(0x00000000),
    );

    if (fullScreen && widget.snapShot) {
      centerWidget = Row(
        children: <Widget>[
          Expanded(child: centerChild),
          Padding(
            padding:
                const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  padding: const EdgeInsets.all(0),
                  color: const Color(0xFFFFFFFF),
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () {
                    takeSnapshot();
                  },
                ),
              ],
            ),
          )
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: height > 200 ? 80 : height / 5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x88000000), Color(0x00000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Expanded(
          child: centerWidget,
        ),
        Container(
          height: height > 80 ? 80 : height / 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x88000000), Color(0x00000000)],
              end: Alignment.topCenter,
              begin: Alignment.bottomCenter,
            ),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            height: height > 80 ? 45 : height / 2,
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 5),
            child: buildBottom(context, height > 80 ? 40 : height / 2),
          ),
        )
      ],
    );
  }

  GestureDetector buildGestureDetector(BuildContext context) {
    return GestureDetector(
      onTap: onTapFun,
      onDoubleTap: widget.doubleTap ? onDoubleTapFun : null,
      onVerticalDragUpdate: onVerticalDragUpdateFun,
      onVerticalDragStart: onVerticalDragStartFun,
      onVerticalDragEnd: onVerticalDragEndFun,
      onHorizontalDragUpdate: (d) {},
      child: AbsorbPointer(
        absorbing: _hideStuff,
        child: AnimatedOpacity(
          opacity: _hideStuff ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: buildPanel(context),
        ),
      ),
    );
  }

  Rect panelRect() {
    final rect = player.value.fullScreen || (true == widget.fill)
        ? Rect.fromLTWH(0, 0, widget.viewSize.width, widget.viewSize.height)
        : Rect.fromLTRB(
            max(0.0, widget.texPos.left),
            max(0.0, widget.texPos.top),
            min(widget.viewSize.width, widget.texPos.right),
            min(widget.viewSize.height, widget.texPos.bottom));
    return rect;
  }

  double panelHeight() {
    if (player.value.fullScreen || (true == widget.fill)) {
      return widget.viewSize.height;
    } else {
      return min(widget.viewSize.height, widget.texPos.bottom) -
          max(0.0, widget.texPos.top);
    }
  }

  double panelWidth() {
    if (player.value.fullScreen || (true == widget.fill)) {
      return widget.viewSize.width;
    } else {
      return min(widget.viewSize.width, widget.texPos.right) -
          max(0.0, widget.texPos.left);
    }
  }

  Widget buildBack(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.only(left: 5),
      icon: const Icon(
        Icons.arrow_back_ios,
        color: Color(0xDDFFFFFF),
      ),
      onPressed: widget.onBack,
    );
  }

  Widget buildStateless() {
    final volume = _volume;
    final brightness = _brightness;
    if (volume != null || brightness != null) {
      final toast = volume == null
          ? defaultFijkBrightnessToast(brightness!, _valController.stream)
          : defaultFijkVolumeToast(volume, _valController.stream);
      return IgnorePointer(
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 500),
          child: toast,
        ),
      );
    } else if (player.state == VideoPlusState.asyncPreparing) {
      return Container(
        alignment: Alignment.center,
        child: const SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white)),
        ),
      );
    } else if (player.state == VideoPlusState.error) {
      return Container(
        alignment: Alignment.center,
        child: const Icon(
          Icons.error,
          size: 30,
          color: Color(0x99FFFFFF),
        ),
      );
    } else if (_imageProvider != null) {
      _snapshotTimer?.cancel();
      _snapshotTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _imageProvider = null;
          });
        }
      });
      return Center(
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.yellowAccent, width: 3)),
            child:
                Image(height: 200, fit: BoxFit.contain, image: _imageProvider!),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rect = panelRect();

    final ws = <Widget>[];

    if (_statelessTimer != null && _statelessTimer!.isActive) {
      ws.add(buildStateless());
    } else if (player.state == VideoPlusState.asyncPreparing) {
      ws.add(buildStateless());
    } else if (player.state == VideoPlusState.error) {
      ws.add(buildStateless());
    } else if (_imageProvider != null) {
      ws.add(buildStateless());
    }
    ws.add(buildGestureDetector(context));
    if (widget.onBack != null) {
      ws.add(buildBack(context));
    }
    return Positioned.fromRect(
      rect: rect,
      child: Stack(children: ws as List<Widget>),
    );
  }
}
