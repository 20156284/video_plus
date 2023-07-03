//MIT License
//
//Copyright (c) [2019] [Befovy]
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

/// FijkPlayer present as a playback. It interacts with native object.
///
/// FijkPlayer invoke native method and receive native event.
class VideoPlusPlayer extends ChangeNotifier
    implements ValueListenable<VideoPlusValue> {
  VideoPlusPlayer()
      : _nativeSetup = Completer(),
        _value = const VideoPlusValue.uninitialized(),
        super() {
    VideoPlusLog.d('create new fijkplayer');
    _doNativeSetup();
  }
  static final Map<int, VideoPlusPlayer> _allInstance = HashMap();
  String? _dataSource;

  int _playerId = -1;
  int _callId = -1;
  late MethodChannel _channel;
  StreamSubscription<dynamic>? _nativeEventSubscription;

  final bool _startAfterSetup = false;

  VideoPlusValue _value;

  static Iterable<VideoPlusPlayer> get all => _allInstance.values;

  /// Return the player unique id.
  ///
  /// Each public method in [VideoPlusPlayer] `await` the id value firstly.
  Future<int> get id => _nativeSetup.future;

  /// Get is in sync, if the async [id] is not finished, idSync return -1;
  int get idSync => _playerId;

  /// return the current state
  VideoPlusState get state => _value.state;

  @override
  VideoPlusValue get value => _value;

  void _setValue(VideoPlusValue newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    notifyListeners();
  }

  Duration _bufferPos = const Duration();

  /// return the current buffered position
  Duration get bufferPos => _bufferPos;

  final StreamController<Duration> _bufferPosController =
      StreamController.broadcast();

  /// stream of [bufferPos].
  Stream<Duration> get onBufferPosUpdate => _bufferPosController.stream;

  int _bufferPercent = 0;

  /// return the buffer percent of water mark.
  ///
  /// If player is in [VideoPlusState.started] state and is freezing ([isBuffering] is true),
  /// this value starts from 0, and when reaches or exceeds 100, the player start to play again.
  ///
  /// This is not the quotient of [bufferPos] / [value.duration]
  int get bufferPercent => _bufferPercent;

  final StreamController<int> _bufferPercentController =
      StreamController.broadcast();

  /// stream of [bufferPercent].
  Stream<int> get onBufferPercentUpdate => _bufferPercentController.stream;

  Duration _currentPos = const Duration();

  /// return the current playing position
  Duration get currentPos => _currentPos;

  final StreamController<Duration> _currentPosController =
      StreamController.broadcast();

  /// stream of [currentPos].
  Stream<Duration> get onCurrentPosUpdate => _currentPosController.stream;

  bool _buffering = false;
  bool _seeking = false;

  /// return true if the player is buffering
  bool get isBuffering => _buffering;

  final StreamController<bool> _bufferStateController =
      StreamController.broadcast();

  Stream<bool> get onBufferStateUpdate => _bufferStateController.stream;

  String? get dataSource => _dataSource;

  final Completer<int> _nativeSetup;
  Completer<Uint8List>? _snapShot;

  Future<void> _startFromAnyState() async {
    await _nativeSetup.future;

    if (state == VideoPlusState.error || state == VideoPlusState.stopped) {
      await reset();
    }
    final source = _dataSource;
    if (state == VideoPlusState.idle && source != null) {
      await setDataSource(source);
    }
    if (state == VideoPlusState.initialized) {
      await prepareAsync();
    }
    if (state == VideoPlusState.asyncPreparing ||
        state == VideoPlusState.prepared ||
        state == VideoPlusState.completed ||
        state == VideoPlusState.paused) {
      await start();
    }
  }

  Future<dynamic> _handler(MethodCall call) {
    switch (call.method) {
      case '_onSnapshot':
        final img = call.arguments;
        final snapShot = _snapShot;
        if (snapShot != null) {
          if (img is Map) {
            snapShot.complete(img['data']);
          } else {
            snapShot.completeError(UnsupportedError('snapshot'));
          }
        }
        _snapShot = null;
        break;
      default:
        break;
    }
    return Future.value(0);
  }

  Future<void> _doNativeSetup() async {
    _playerId = -1;
    _callId = 0;
    _playerId = await VideoPlusPlugin._createPlayer();
    if (_playerId < 0) {
      _setValue(value.copyWith(state: VideoPlusState.error));
      return;
    }
    VideoPlusLog.i('create player id:$_playerId');

    _allInstance[_playerId] = this;
    _channel = MethodChannel('befovy.com/fijkplayer/$_playerId');
    _nativeEventSubscription =
        EventChannel('befovy.com/fijkplayer/event/$_playerId')
            .receiveBroadcastStream()
            .listen(_eventListener, onError: _errorListener);
    _nativeSetup.complete(_playerId);

    _channel.setMethodCallHandler(_handler);
    if (_startAfterSetup) {
      VideoPlusLog.i('player id:$_playerId, start after setup');
      await _startFromAnyState();
    }
  }

  /// Check if player is playable
  ///
  /// Only the four state [VideoPlusState.prepared] \ [VideoPlusState.started] \
  /// [VideoPlusState.paused] \ [VideoPlusState.completed] are playable
  bool isPlayable() {
    final current = value.state;
    return VideoPlusState.prepared == current ||
        VideoPlusState.started == current ||
        VideoPlusState.paused == current ||
        VideoPlusState.completed == current;
  }

  /// set option
  /// [value] must be int or String
  Future<void> setOption(int category, String key, dynamic value) async {
    await _nativeSetup.future;
    if (value is String) {
      VideoPlusLog.i('$this setOption k:$key, v:$value');
      return _channel.invokeMethod('setOption',
          <String, dynamic>{'cat': category, 'key': key, 'str': value});
    } else if (value is int) {
      VideoPlusLog.i('$this setOption k:$key, v:$value');
      return _channel.invokeMethod('setOption',
          <String, dynamic>{'cat': category, 'key': key, 'long': value});
    } else {
      VideoPlusLog.e('$this setOption invalid value: $value');
      return Future.error(
          ArgumentError.value(value, 'value', 'Must be int or String'));
    }
  }

  Future<void> applyOptions(VideoPlusOption fijkOption) async {
    await _nativeSetup.future;
    return _channel.invokeMethod('applyOptions', fijkOption.data);
  }

  Future<int?> setupSurface() async {
    await _nativeSetup.future;
    VideoPlusLog.i('$this setupSurface');
    return _channel.invokeMethod('setupSurface');
  }

  /// Take snapshot (screen shot) of current playing video
  ///
  /// If you want to use [takeSnapshot], you must call
  /// `player.setOption(FijkOption.hostCategory, "enable-snapshot", 1);`
  /// after you create a [VideoPlusPlayer].
  /// Or else this method returns error.
  ///
  /// Example:
  /// ```
  /// var imageData = await player.takeSnapShot();
  /// var provider = MemoryImage(v);
  /// Widget image = Image(image: provider)
  /// ```
  Future<Uint8List> takeSnapShot() async {
    await _nativeSetup.future;
    VideoPlusLog.i('$this takeSnapShot');
    var snapShot = _snapShot;
    if (snapShot != null && !snapShot.isCompleted) {
      return Future.error(StateError('last snapShot is not finished'));
    }
    snapShot = Completer<Uint8List>();
    _snapShot = snapShot;
    await _channel.invokeMethod('snapshot');
    return snapShot.future;
  }

  /// Set data source for this player
  ///
  /// [path] must be a valid uri, otherwise this method return ArgumentError
  ///
  /// set assets as data source
  /// first add assets in app's pubspec.yml
  ///   assets:
  ///     - assets/butterfly.mp4
  ///
  /// pass "asset:///assets/butterfly.mp4" to [path]
  /// scheme is `asset`, `://` is scheme's separator， `/` is path's separator.
  ///
  /// If set [autoPlay] true, player will stat to play.
  /// The behavior of [setDataSource(url, autoPlay: true)] is like
  ///    await setDataSource(url);
  ///    await setOption(FijkOption.playerCategory, "start-on-prepared", 1);
  ///    await prepareAsync();
  ///
  /// If set [showCover] true, player will display the first video frame and then enter [VideoPlusState.paused] state.
  /// The behavior of [setDataSource(url, showCover: true)] is like
  ///    await setDataSource(url);
  ///    await setOption(FijkOption.playerCategory, "cover-after-prepared", 1);
  ///    await prepareAsync();
  ///
  /// If both [autoPlay] and [showCover] are true, [showCover] will be ignored.
  Future<void> setDataSource(
    String path, {
    bool autoPlay = false,
    bool showCover = false,
  }) async {
    if (path == null || path.isEmpty || Uri.tryParse(path) == null) {
      VideoPlusLog.e('$this setDataSource invalid path:$path');
      return Future.error(
          ArgumentError.value(path, 'path must be a valid url'));
    }
    if (autoPlay == true && showCover == true) {
      VideoPlusLog.w(
          'call setDataSource with both autoPlay and showCover true, showCover will be ignored');
    }
    await _nativeSetup.future;
    if (state == VideoPlusState.idle || state == VideoPlusState.initialized) {
      try {
        VideoPlusLog.i('$this invoke setDataSource $path');
        _dataSource = path;
        await _channel
            .invokeMethod('setDataSource', <String, dynamic>{'url': path});
      } on PlatformException catch (e) {
        return _errorListener(e);
      }
      if (autoPlay == true) {
        await start();
      } else if (showCover == true) {
        await setOption(
            VideoPlusOption.playerCategory, 'cover-after-prepared', 1);
        await prepareAsync();
      }
    } else {
      VideoPlusLog.e('$this setDataSource invalid state:$state');
      return Future.error(StateError('setDataSource on invalid state $state'));
    }
  }

  /// start the async preparing tasks
  ///
  /// see [fijkstate zh](https://fijkplayer.befovy.com/docs/zh/fijkstate.html) or
  /// [fijkstate en](https://fijkplayer.befovy.com/docs/en/fijkstate.html) for details
  Future<void> prepareAsync() async {
    await _nativeSetup.future;
    if (state == VideoPlusState.initialized) {
      VideoPlusLog.i('$this invoke prepareAsync');
      await _channel.invokeMethod('prepareAsync');
    } else {
      VideoPlusLog.e('$this prepareAsync invalid state:$state');
      return Future.error(StateError('prepareAsync on invalid state $state'));
    }
  }

  /// set volume of this player audio track
  ///
  /// This dose not change system volume.
  /// Default value of audio track is 1.0,
  /// [volume] must be greater or equals to 0.0
  Future<void> setVolume(double volume) async {
    if (volume < 0) {
      VideoPlusLog.e('$this invoke seekTo invalid volume:$volume');
      return Future.error(
          ArgumentError.value(volume, 'setVolume invalid volume'));
    } else {
      await _nativeSetup.future;
      VideoPlusLog.i('$this invoke setVolume $volume');
      return _channel
          .invokeMethod('setVolume', <String, dynamic>{'volume': volume});
    }
  }

  /// enter full screen mode, set [VideoPlusValue.fullScreen] to true
  void enterFullScreen() {
    VideoPlusLog.i('$this enterFullScreen');
    _setValue(value.copyWith(fullScreen: true));
  }

  /// exit full screen mode, set [VideoPlusValue.fullScreen] to false
  void exitFullScreen() {
    VideoPlusLog.i('$this exitFullScreen');
    _setValue(value.copyWith(fullScreen: false));
  }

  /// change player's state to [VideoPlusState.started]
  ///
  /// throw [StateError] if call this method on invalid state.
  /// see [fijkstate zh](https://fijkplayer.befovy.com/docs/zh/fijkstate.html) or
  /// [fijkstate en](https://fijkplayer.befovy.com/docs/en/fijkstate.html) for details
  Future<void> start() async {
    await _nativeSetup.future;
    if (state == VideoPlusState.initialized) {
      _callId += 1;
      final cid = _callId;
      VideoPlusLog.i('$this invoke prepareAsync and start #$cid');
      await setOption(VideoPlusOption.playerCategory, 'start-on-prepared', 1);
      await _channel.invokeMethod('prepareAsync');
      VideoPlusLog.i('$this invoke prepareAsync and start #$cid -> done');
    } else if (state == VideoPlusState.asyncPreparing ||
        state == VideoPlusState.prepared ||
        state == VideoPlusState.paused ||
        state == VideoPlusState.started ||
        value.state == VideoPlusState.completed) {
      VideoPlusLog.i('$this invoke start');
      await _channel.invokeMethod('start');
    } else {
      VideoPlusLog.e('$this invoke start invalid state:$state');
      return Future.error(StateError('call start on invalid state $state'));
    }
  }

  Future<void> pause() async {
    await _nativeSetup.future;
    if (isPlayable()) {
      VideoPlusLog.i('$this invoke pause');
      await _channel.invokeMethod('pause');
    } else {
      VideoPlusLog.e('$this invoke pause invalid state:$state');
      return Future.error(StateError('call pause on invalid state $state'));
    }
  }

  Future<void> stop() async {
    await _nativeSetup.future;
    if (state == VideoPlusState.end ||
        state == VideoPlusState.idle ||
        state == VideoPlusState.initialized) {
      VideoPlusLog.e('$this invoke stop invalid state:$state');
      return Future.error(StateError('call stop on invalid state $state'));
    } else {
      VideoPlusLog.i('$this invoke stop');
      await _channel.invokeMethod('stop');
    }
  }

  Future<void> reset() async {
    await _nativeSetup.future;
    if (state == VideoPlusState.end) {
      VideoPlusLog.e('$this invoke reset invalid state:$state');
      return Future.error(StateError('call reset on invalid state $state'));
    } else {
      _callId += 1;
      final cid = _callId;
      VideoPlusLog.i('$this invoke reset #$cid');
      await _channel.invokeMethod('reset').then((_) {
        VideoPlusLog.i('$this invoke reset #$cid -> done');
      });
      _setValue(const VideoPlusValue.uninitialized()
          .copyWith(fullScreen: value.fullScreen));
    }
  }

  Future<void> seekTo(int msec) async {
    await _nativeSetup.future;
    if (msec < 0) {
      VideoPlusLog.e('$this invoke seekTo invalid msec:$msec');
      return Future.error(
          ArgumentError.value(msec, 'speed must be not null and >= 0'));
    } else if (!isPlayable()) {
      VideoPlusLog.e('$this invoke seekTo invalid state:$state');
      return Future.error(StateError('Non playable state $state'));
    } else {
      VideoPlusLog.i('$this invoke seekTo msec:$msec');
      _seeking = true;
      await _channel.invokeMethod('seekTo', <String, dynamic>{'msec': msec});
    }
  }

  /// Release native player. Release memory and resource
  Future<void> release() async {
    await _nativeSetup.future;
    _callId += 1;
    final cid = _callId;
    VideoPlusLog.i('$this invoke release #$cid');
    if (isPlayable()) {
      await stop();
    }
    _setValue(value.copyWith(state: VideoPlusState.end));
    await _nativeEventSubscription?.cancel();
    _nativeEventSubscription = null;
    _allInstance.remove(_playerId);
    await VideoPlusPlugin._releasePlayer(_playerId).then((_) {
      VideoPlusLog.i('$this invoke release #$cid -> done');
    });
  }

  /// Set player loop count
  ///
  /// [loopCount] must not null and greater than or equal to 0.
  /// Default loopCount of player is 1, which also means no loop.
  /// A positive value of [loopCount] means special repeat times.
  /// If [loopCount] is 0, is means infinite repeat.
  Future<void> setLoop(int loopCount) async {
    await _nativeSetup.future;
    if (loopCount < 0) {
      VideoPlusLog.e('$this invoke setLoop invalid loopCount:$loopCount');
      return Future.error(ArgumentError.value(
          loopCount, 'loopCount must not be null and >= 0'));
    } else {
      VideoPlusLog.i('$this invoke setLoop $loopCount');
      return _channel
          .invokeMethod('setLoop', <String, dynamic>{'loop': loopCount});
    }
  }

  /// Set playback speed
  ///
  /// [speed] must not null and greater than 0.
  /// Default speed is 1
  Future<void> setSpeed(double speed) async {
    await _nativeSetup.future;
    if (speed <= 0) {
      VideoPlusLog.e('$this invoke setSpeed invalid speed:$speed');
      return Future.error(ArgumentError.value(
          speed, 'speed must be not null and greater than 0'));
    } else {
      VideoPlusLog.i('$this invoke setSpeed $speed');
      await _channel
          .invokeMethod('setSpeed', <String, dynamic>{'speed': speed});
    }
  }

  void _eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'prepared':
        final duration = map['duration'] ?? 0;
        final dur = Duration(milliseconds: duration);
        _setValue(value.copyWith(duration: dur, prepared: true));
        VideoPlusLog.i('$this prepared duration $dur');
        break;
      case 'rotate':
        final degree = map['degree'] ?? 0;
        _setValue(value.copyWith(rotate: degree));
        VideoPlusLog.i('$this rotate degree $degree');
        break;
      case 'state_change':
        final newStateId = map['new'] ?? 0;
        final _oldState = map['old'] ?? 0;
        final fpState = VideoPlusState.values[newStateId];
        final oldState =
            (_oldState >= 0 && _oldState < VideoPlusState.values.length)
                ? VideoPlusState.values[_oldState]
                : state;

        if (fpState != oldState) {
          VideoPlusLog.i('$this state changed to $fpState <= $oldState');
          final fijkException = (fpState != VideoPlusState.error)
              ? VideoPlusException.noException
              : null;
          if (newStateId == VideoPlusState.prepared.index) {
            _setValue(value.copyWith(
                prepared: true, state: fpState, exception: fijkException));
          } else if (newStateId < VideoPlusState.prepared.index) {
            _setValue(value.copyWith(
                prepared: false, state: fpState, exception: fijkException));
          } else {
            _setValue(value.copyWith(state: fpState, exception: fijkException));
          }
        }
        break;
      case 'rendering_start':
        final type = map['type'] ?? 'none';
        if (type == 'video') {
          _setValue(value.copyWith(videoRenderStart: true));
          VideoPlusLog.i('$this video rendering started');
        } else if (type == 'audio') {
          _setValue(value.copyWith(audioRenderStart: true));
          VideoPlusLog.i('$this audio rendering started');
        }
        break;
      case 'freeze':
        final value = map['value'] ?? false;
        _buffering = value;
        _bufferStateController.add(value);
        VideoPlusLog.d("$this freeze ${value ? "start" : "end"}");
        break;
      case 'buffering':
        final head = map['head'] ?? 0;
        final percent = map['percent'] ?? 0;
        _bufferPos = Duration(milliseconds: head);
        _bufferPosController.add(_bufferPos);
        _bufferPercent = percent;
        _bufferPercentController.add(percent);
        break;
      case 'pos':
        final pos = map['pos'];
        _currentPos = Duration(milliseconds: pos);
        if (!_seeking) {
          _currentPosController.add(_currentPos);
        }
        break;
      case 'size_changed':
        final width = map['width'].toDouble();
        final height = map['height'].toDouble();
        VideoPlusLog.i('$this size changed ($width, $height)');
        _setValue(value.copyWith(size: Size(width, height)));
        break;
      case 'seek_complete':
        _seeking = false;
        break;
      default:
        break;
    }
  }

  void _errorListener(Object obj) {
    final e = obj as PlatformException;
    final exception = VideoPlusException.fromPlatformException(e);
    VideoPlusLog.e('$this errorListener: $exception');
    _setValue(value.copyWith(exception: exception));
  }

  @override
  String toString() {
    return 'FijkPlayer{id:$_playerId}';
  }
}
