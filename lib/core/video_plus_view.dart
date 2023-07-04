//
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
//

part of video_plus;

/// The signature of the [LayoutBuilder] builder function.
///
/// Must not return null.
/// The return widget is placed as one of [Stack]'s children.
/// If change FijkView between normal mode and full screen mode, the panel would
/// be rebuild. [data] can be used to pass value from different panel.
typedef VideoPlusPanelWidgetBuilder = Widget Function(VideoPlusPlayer player,
    VideoPlusData data, BuildContext context, Size viewSize, Rect texturePos);

/// How a video should be inscribed into [VideoPlusView].
///
/// See also [BoxFit]
class VideoPlusFit {
  const VideoPlusFit(
      {this.alignment = Alignment.center,
      this.aspectRatio = -1,
      this.sizeFactor = 1.0});

  /// [Alignment] for this [VideoPlusView] Container.
  /// alignment is applied to Texture inner FijkView
  final Alignment alignment;

  /// [aspectRatio] controls inner video texture widget's aspect ratio.
  ///
  /// A [VideoPlusView] has an important child widget which display the video frame.
  /// This important inner widget is a [Texture] in this version.
  /// Normally, we want the aspectRatio of [Texture] to be same
  /// as playback's real video frame's aspectRatio.
  /// It's also the default behaviour of [VideoPlusView]
  /// or if aspectRatio is assigned null or negative value.
  ///
  /// If you want to change this default behaviour,
  /// just pass the aspectRatio you want.
  ///
  /// Addition: double.infinate is a special value.
  /// The aspect ratio of inner Texture will be same as FijkView's aspect ratio
  /// if you set double.infinate to attribute aspectRatio.
  final double aspectRatio;

  /// The size of [Texture] is multiplied by this factor.
  ///
  /// Some spacial values:
  ///  * (-1.0, -0.0) scaling up to max of [VideoPlusView]'s width and height
  ///  * (-2.0, -1.0) scaling up to [VideoPlusView]'s width
  ///  * (-3.0, -2.0) scaling up to [VideoPlusView]'s height
  final double sizeFactor;

  /// Fill the target FijkView box by distorting the video's aspect ratio.
  static const VideoPlusFit fill = VideoPlusFit(
    aspectRatio: double.infinity,
  );

  /// As large as possible while still containing the video entirely within the
  /// target FijkView box.
  static const VideoPlusFit contain = VideoPlusFit();

  /// As small as possible while still covering the entire target FijkView box.
  static const VideoPlusFit cover = VideoPlusFit(
    sizeFactor: -0.5,
  );

  /// Make sure the full width of the source is shown, regardless of
  /// whether this means the source overflows the target box vertically.
  static const VideoPlusFit fitWidth = VideoPlusFit(sizeFactor: -1.5);

  /// Make sure the full height of the source is shown, regardless of
  /// whether this means the source overflows the target box horizontally.
  static const VideoPlusFit fitHeight = VideoPlusFit(sizeFactor: -2.5);

  /// As large as possible while still containing the video entirely within the
  /// target FijkView box. But change video's aspect ratio to 4:3.
  static const VideoPlusFit ar4_3 = VideoPlusFit(aspectRatio: 4.0 / 3.0);

  /// As large as possible while still containing the video entirely within the
  /// target FijkView box. But change video's aspect ratio to 16:9.
  static const VideoPlusFit ar16_9 = VideoPlusFit(aspectRatio: 16.0 / 9.0);
}

/// [VideoPlusView] is a widget that can display the video frame of [VideoPlusPlayer].
///
/// Actually, it is a Container widget contains many children.
/// The most important is a Texture which display the read video frame.
class VideoPlusView extends StatefulWidget {
  const VideoPlusView({
    super.key,
    required this.player,
    this.width,
    this.height,
    this.fit = VideoPlusFit.contain,
    this.fsFit = VideoPlusFit.contain,
    this.panelBuilder = defaultFijkPanelBuilder,
    this.color = const Color(0xFF607D8B),
    this.cover,
    this.fs = true,
    this.onDispose,
  });

  /// The player that need display video by this [VideoPlusView].
  /// Will be passed to [panelBuilder].
  final VideoPlusPlayer player;

  /// builder to build panel Widget
  final VideoPlusPanelWidgetBuilder panelBuilder;

  /// This method will be called when fijkView dispose.
  /// FijkData is managed inner FijkView. User can change fijkData in custom panel.
  /// See [panelBuilder]'s second argument.
  /// And check if some value need to be recover on FijkView dispose.
  final void Function(VideoPlusData)? onDispose;

  /// background color
  final Color color;

  /// cover image provider
  final ImageProvider? cover;

  /// How a video should be inscribed into this [VideoPlusView].
  final VideoPlusFit fit;

  /// How a video should be inscribed into this [VideoPlusView] at fullScreen mode.
  final VideoPlusFit fsFit;

  /// Nullable, width of [VideoPlusView]
  /// If null, the weight will be as big as possible.
  final double? width;

  /// Nullable, height of [VideoPlusView].
  /// If null, the height will be as big as possible.
  final double? height;

  /// Enable or disable the full screen
  ///
  /// If [fs] is true, FijkView make response to the [VideoPlusValue.fullScreen] value changed,
  /// and push o new full screen mode page when [VideoPlusValue.fullScreen] is true, pop full screen page when [VideoPlusValue.fullScreen]  become false.
  ///
  /// If [fs] is false, FijkView never make response to the change of [VideoPlusValue.fullScreen].
  /// But you can still call [VideoPlusPlayer.enterFullScreen] and [VideoPlusPlayer.exitFullScreen] and make your own full screen pages.
  final bool fs;

  @override
  _VideoPlusViewState createState() => _VideoPlusViewState();
}

class _VideoPlusViewState extends State<VideoPlusView> {
  int _textureId = -1;
  double _vWidth = -1;
  double _vHeight = -1;
  bool _fullScreen = false;

  final _fijkData = VideoPlusData();
  ValueNotifier<int> paramNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    final s = widget.player.value.size;
    if (s != null) {
      _vWidth = s.width;
      _vHeight = s.height;
    }
    widget.player.addListener(_fijkValueListener);
    _nativeSetup();
  }

  Future<void> _nativeSetup() async {
    if (widget.player.value.prepared) {
      await _setupTexture();
    }
    paramNotifier.value = paramNotifier.value + 1;
  }

  Future<void> _setupTexture() async {
    final vid = await widget.player.setupSurface();
    if (vid == null) {
      VideoPlusLog.e('failed to set surface');
      return;
    }
    VideoPlusLog.i('view setup, vid:$vid');
    if (mounted) {
      setState(() {
        _textureId = vid;
      });
    }
  }

  Future<void> _fijkValueListener() async {
    final value = widget.player.value;
    if (value.prepared && _textureId < 0) {
      await _setupTexture();
    }

    if (widget.fs) {
      if (value.fullScreen && !_fullScreen) {
        _fullScreen = true;
        await _pushFullScreenWidget(context);
      } else if (_fullScreen && !value.fullScreen) {
        Navigator.of(context).pop();
        _fullScreen = false;
      }

      // save width and height to make judgement about whether to
      // request landscape when enter full screen mode
      final size = value.size;
      if (size != null && value.prepared) {
        _vWidth = size.width;
        _vHeight = size.height;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.player.removeListener(_fijkValueListener);

    final brightness = _fijkData.getValue(VideoPlusData._viewPanelBrightness);
    if (brightness != null && brightness is double) {
      VideoPlusPlugin.setScreenBrightness(brightness);
      _fijkData.clearValue(VideoPlusData._viewPanelBrightness);
    }

    final volume = _fijkData.getValue(VideoPlusData._viewPanelVolume);
    if (volume != null && volume is double) {
      VideoPlusVolume.setVol(volume);
      _fijkData.clearValue(VideoPlusData._viewPanelVolume);
    }

    widget.onDispose?.call(_fijkData);
  }

  AnimatedWidget _defaultRoutePageBuilder(
      BuildContext context, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: _InnerFijkView(
            fijkViewState: this,
            fullScreen: true,
            cover: widget.cover,
            data: _fijkData,
          ),
        );
      },
    );
  }

  Widget _fullScreenRoutePageBuilder(BuildContext context,
      Animation<double> animation, Animation<double> secondaryAnimation) {
    return _defaultRoutePageBuilder(context, animation);
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      settings: const RouteSettings(),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: []);
    var changed = false;
    final orientation = MediaQuery.of(context).orientation;
    VideoPlusLog.d('start enter fullscreen. orientation:$orientation');
    if (_vWidth >= _vHeight) {
      if (MediaQuery.of(context).orientation == Orientation.portrait)
        changed = await VideoPlusPlugin.setOrientationLandscape();
    } else {
      if (MediaQuery.of(context).orientation == Orientation.landscape)
        changed = await VideoPlusPlugin.setOrientationPortrait();
    }
    VideoPlusLog.d('screen orientation changed:$changed');

    await Navigator.of(context).push(route);
    _fullScreen = false;
    widget.player.exitFullScreen();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    if (changed) {
      if (_vWidth >= _vHeight) {
        await VideoPlusPlugin.setOrientationPortrait();
      } else {
        await VideoPlusPlugin.setOrientationLandscape();
      }
    }
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget as VideoPlusView);
    paramNotifier.value = paramNotifier.value + 1;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _fullScreen
          ? Container()
          : _InnerFijkView(
              fijkViewState: this,
              fullScreen: false,
              cover: widget.cover,
              data: _fijkData,
            ),
    );
  }
}

class _InnerFijkView extends StatefulWidget {
  const _InnerFijkView({
    required this.fijkViewState,
    required this.fullScreen,
    required this.cover,
    required this.data,
  });

  final _VideoPlusViewState fijkViewState;
  final bool fullScreen;
  final ImageProvider? cover;
  final VideoPlusData data;

  @override
  __InnerFijkViewState createState() => __InnerFijkViewState();
}

class __InnerFijkViewState extends State<_InnerFijkView> {
  late VideoPlusPlayer _player;
  VideoPlusPanelWidgetBuilder? _panelBuilder;
  Color? _color;
  VideoPlusFit _fit = VideoPlusFit.contain;
  int _textureId = -1;
  double _vWidth = -1;
  double _vHeight = -1;
  final bool _vFullScreen = false;
  int _degree = 0;
  bool _videoRender = false;

  @override
  void initState() {
    super.initState();
    _player = fView.player;
    _fijkValueListener();
    fView.player.addListener(_fijkValueListener);
    if (widget.fullScreen) {
      widget.fijkViewState.paramNotifier.addListener(_voidValueListener);
    }
  }

  VideoPlusView get fView => widget.fijkViewState.widget;

  void _voidValueListener() {
    final binding = WidgetsBinding.instance;
    if (binding != null)
      binding.addPostFrameCallback((_) => _fijkValueListener());
  }

  void _fijkValueListener() {
    if (!mounted) {
      return;
    }

    final panelBuilder = fView.panelBuilder;
    final color = fView.color;
    final fit = widget.fullScreen ? fView.fsFit : fView.fit;
    final textureId = widget.fijkViewState._textureId;

    final value = _player.value;

    _degree = value.rotate;
    var width = _vWidth;
    var height = _vHeight;
    final fullScreen = value.fullScreen;
    final videoRender = value.videoRenderStart;

    final size = value.size;
    if (size != null && value.prepared) {
      width = size.width;
      height = size.height;
    }

    if (width != _vWidth ||
        height != _vHeight ||
        fullScreen != _vFullScreen ||
        panelBuilder != _panelBuilder ||
        color != _color ||
        fit != _fit ||
        textureId != _textureId ||
        _videoRender != videoRender) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Size applyAspectRatio(BoxConstraints constraints, double aspectRatio) {
    assert(constraints.hasBoundedHeight && constraints.hasBoundedWidth);

    constraints = constraints.loosen();

    var width = constraints.maxWidth;
    var height = width;

    if (width.isFinite) {
      height = width / aspectRatio;
    } else {
      height = constraints.maxHeight;
      width = height * aspectRatio;
    }

    if (width > constraints.maxWidth) {
      width = constraints.maxWidth;
      height = width / aspectRatio;
    }

    if (height > constraints.maxHeight) {
      height = constraints.maxHeight;
      width = height * aspectRatio;
    }

    if (width < constraints.minWidth) {
      width = constraints.minWidth;
      height = width / aspectRatio;
    }

    if (height < constraints.minHeight) {
      height = constraints.minHeight;
      width = height * aspectRatio;
    }

    return constraints.constrain(Size(width, height));
  }

  double getAspectRatio(BoxConstraints constraints, double ar) {
    if (ar < 0) {
      ar = _vWidth / _vHeight;
    } else if (ar.isInfinite) {
      ar = constraints.maxWidth / constraints.maxHeight;
    }
    return ar;
  }

  /// calculate Texture size
  Size getTxSize(BoxConstraints constraints, VideoPlusFit fit) {
    var childSize = applyAspectRatio(
        constraints, getAspectRatio(constraints, fit.aspectRatio));
    var sizeFactor = fit.sizeFactor;
    if (-1.0 < sizeFactor && sizeFactor < -0.0) {
      sizeFactor = max(constraints.maxWidth / childSize.width,
          constraints.maxHeight / childSize.height);
    } else if (-2.0 < sizeFactor && sizeFactor < -1.0) {
      sizeFactor = constraints.maxWidth / childSize.width;
    } else if (-3.0 < sizeFactor && sizeFactor < -2.0) {
      sizeFactor = constraints.maxHeight / childSize.height;
    } else if (sizeFactor < 0) {
      sizeFactor = 1.0;
    }
    childSize = childSize * sizeFactor;
    return childSize;
  }

  /// calculate Texture offset
  Offset getTxOffset(
      BoxConstraints constraints, Size childSize, VideoPlusFit fit) {
    final resolvedAlignment = fit.alignment;
    final diff = (constraints.biggest - childSize) as Offset;
    return resolvedAlignment.alongOffset(diff);
  }

  Widget buildTexture() {
    final tex = _textureId > 0 ? Texture(textureId: _textureId) : Container();
    if (_degree != 0 && _textureId > 0) {
      return RotatedBox(
        quarterTurns: _degree ~/ 90,
        child: tex,
      );
    }
    return tex;
  }

  @override
  void dispose() {
    super.dispose();
    fView.player.removeListener(_fijkValueListener);
    widget.fijkViewState.paramNotifier.removeListener(_fijkValueListener);
  }

  @override
  Widget build(BuildContext context) {
    _panelBuilder = fView.panelBuilder;
    _color = fView.color;
    _fit = widget.fullScreen ? fView.fsFit : fView.fit;
    _textureId = widget.fijkViewState._textureId;

    final value = _player.value;
    final data = widget.data;
    final size = value.size;
    if (size != null && value.prepared) {
      _vWidth = size.width;
      _vHeight = size.height;
    }
    _videoRender = value.videoRenderStart;

    return LayoutBuilder(builder: (ctx, constraints) {
      // get child size
      final childSize = getTxSize(constraints, _fit);
      final offset = getTxOffset(constraints, childSize, _fit);
      final pos = Rect.fromLTWH(
          offset.dx, offset.dy, childSize.width, childSize.height);

      final List ws = <Widget>[
        Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          color: _color,
        ),
        Positioned.fromRect(
            rect: pos,
            child: Container(
              color: const Color(0xFF000000),
              child: buildTexture(),
            )),
      ];

      if (widget.cover != null && !value.videoRenderStart) {
        ws.add(Positioned.fromRect(
          rect: pos,
          child: Image(
            image: widget.cover!,
            fit: BoxFit.fill,
          ),
        ));
      }

      if (_panelBuilder != null) {
        ws.add(_panelBuilder!(_player, data, ctx, constraints.biggest, pos));
      }
      return Stack(
        children: ws as List<Widget>,
      );
    });
  }
}
