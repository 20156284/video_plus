import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Dio dio = Dio();

class DownloadUtil {
  static List downloadTasks = []; // 下载任务队列
  static bool downloading = false; // 是否存在下载任务
  static int finishCount = 0; // 当前下载完成的分片数量
  static bool creating = false; // 防止连点
  static bool currentRemove = false; // 当前下载任务是否被删除

  static void removeTask(String delId) {
    if (downloadTasks.isEmpty) {
      return;
    }
    final haveCurrent = delId == downloadTasks[0]['taskInfo']['id'];
    downloadTasks.removeWhere((e) => e['taskInfo']['id'] == delId);
    if (haveCurrent) {
      downloading = false;
      currentRemove = true;
      startNext();
    }
  }

  // 获取地址
  static Future<String> getPath(String folderName) async {
    Directory? documents;
    if (Platform.isAndroid) {
      documents = await getExternalStorageDirectory();
    } else {
      documents = await getApplicationDocumentsDirectory();
    }
    final _getApplicationDocumentsDirectory = documents!.path;
    final _cachePath = '$_getApplicationDocumentsDirectory/$folderName/';
    final directory = Directory(_cachePath);
    final isExists = await directory.exists();
    if (!isExists) {
      await directory.create(recursive: true);
    }
    return _cachePath;
  }

  // 获取地址
  static Future<String> getEnvironmentPath(String folderName) async {
    String _getApplicationDocumentsDirectory;
    if (Platform.isAndroid) {
      final osp = await getExternalStorageDirectory();
      final packageInfo = await PackageInfo.fromPlatform();
      _getApplicationDocumentsDirectory =
          osp!.path.replaceAll('/${packageInfo.packageName}/files', '');
    } else {
      final osp = await getApplicationDocumentsDirectory();
      _getApplicationDocumentsDirectory = osp.path;
    }

    final _cachePath = '$_getApplicationDocumentsDirectory/$folderName/';
    final directory = Directory(_getApplicationDocumentsDirectory);
    final isExists = await directory.exists();
    if (!isExists) {
      await directory.create(recursive: true);
    }
    return _cachePath;
  }

  // 视频解密，返回ts队列
  static Future<Map> getTsList({
    required String urlPath,
    bool encrypt = true,
    Function? decryptM3U8,
  }) async {
    // 视频地址解密
    String decrypted;
    final res = await Dio().get(urlPath);
    if (encrypt && decryptM3U8 != null) {
      decrypted = decryptM3U8(res.data);
    } else {
      decrypted = res.data;
    }
    var localM3u8 = decrypted;
    // 整理key和ts链接
    final lists = decrypted.split('#EXTINF:');
    final tsLists = <String>[];
    for (final e in lists) {
      // 提取key
      if (e.contains('URI=') && e.contains('.key')) {
        final keyUri =
            e.substring(e.indexOf('URI=') + 5, e.indexOf('.key') + 4);
        tsLists.add(keyUri);
        // 替换key为本地链接
        localM3u8 = localM3u8.replaceAll(
            keyUri,
            keyUri.substring(
                keyUri.lastIndexOf('/') + 1, keyUri.indexOf('.key') + 4));
      }
      // 提取ts链接
      if (e.contains('http') && e.contains('.ts')) {
        final tsItem = e.substring(e.indexOf('http'), e.indexOf('.ts') + 3);
        tsLists.add(tsItem);
        // 替换ts为本地链接
        localM3u8 = localM3u8.replaceAll(
            tsItem,
            tsItem.substring(
                tsItem.lastIndexOf('/') + 1, tsItem.indexOf('.ts') + 3));
      }
    }
    return {'localM3u8': localM3u8, 'tsLists': tsLists};
  }

  // 初始化下载状态
  static void initStatus(int finishNum) {
    downloading = true;
    currentRemove = false;
    finishCount = finishNum;
  }

  // 开始下个任务
  static Future<void> startNext() async {
    if (downloadTasks.isNotEmpty) {
      // LogUtil.d("${downloadTasks[0]["taskInfo"]["title"]}");
      final box = await Hive.openBox('guqibox');
      final List tasks = box.get('download_video_tasks') ?? [];
      downloadTasks[0]['taskInfo']['downloading'] = true;
      final taskNum = tasks
          .indexWhere((e) => e['id'] == downloadTasks[0]['taskInfo']['id']);
      // LogUtil.d("${tasks[taskNum]["title"]}");
      tasks[taskNum]['downloading'] = true;
      tasks[taskNum]['isWaiting'] = false;
      await box.put('download_video_tasks', tasks);
      await downloadContent(tasks[taskNum], box);
    } else {
      downloading = false;
    }
  }

  // 请求权限
  static Future<bool> getPermission() async {
    var storageStatus = await Permission.storage.status;
    if (storageStatus == PermissionStatus.denied) {
      storageStatus = await Permission.storage.request();
      if (storageStatus == PermissionStatus.denied ||
          storageStatus == PermissionStatus.permanentlyDenied) {
        return false;
      }
      return true;
    } else if (storageStatus == PermissionStatus.permanentlyDenied) {
      return false;
    }
    return true;
  }

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
  static Future<void> createDownloadTask({
    required Map taskInfo,
    bool encrypt = true,
    Function? decryptM3U8,
  }) async {
    if (creating) {
      // CommonUtils.showText(CommonUtils.txt('dtk'));
      return;
    }
    final havePermission = await getPermission();
    if (havePermission) {
      creating = true;
    } else {
      return;
    }
    try {
      final box = await Hive.openBox('guqibox');
      final List tasks = box.get('download_video_tasks') ?? [];
      final existTaskIndex = tasks.indexWhere((e) => e['id'] == taskInfo['id']);
      final existDownloadTaskIndex = downloadTasks
          .indexWhere((e) => e['taskInfo']['id'] == taskInfo['id']);
      // 存在下载任务
      if (tasks.isNotEmpty && existTaskIndex != -1) {
        if (tasks[existTaskIndex]['downloading'] ||
            tasks[existTaskIndex]['progress'] == 1 ||
            existDownloadTaskIndex != -1) {
          // CommonUtils.showText(CommonUtils.txt('yczxz'));
        } else if (downloading) {
          // CommonUtils.showText(CommonUtils.txt('ztjdl'));
          downloadTasks.add({'taskInfo': tasks[existTaskIndex]});
          tasks[existTaskIndex]['isWaiting'] = true;
          await box.put('download_video_tasks', tasks);
        } else {
          // CommonUtils.showText(CommonUtils.txt('jxxz'));
          downloadTasks.add({'taskInfo': tasks[existTaskIndex]});
          await downloadContent(tasks[existTaskIndex], box);
          tasks[existTaskIndex]['downloading'] = true;
          tasks[existTaskIndex]['isWaiting'] = false;
          await box.put('download_video_tasks', tasks);
        }
        creating = false;
        return;
      }
      // CommonUtils.showText(CommonUtils.txt('ytjzwck'));
      // 生成本地m3u8和ts下载列表
      final tsData = await getTsList(
        urlPath: taskInfo['urlPath'],
        encrypt: encrypt,
        decryptM3U8: decryptM3U8,
      );
      final String localM3u8 = tsData['localM3u8'];
      final List<String> tsLists = tsData['tsLists'];
      taskInfo['tsLists'] = tsLists;
      taskInfo['localM3u8'] = localM3u8;
      taskInfo['tsListsFinished'] = [];
      // 添加下载队列
      downloadTasks.add({'taskInfo': taskInfo});
      // 获取储存地址
      final saveDirectory =
          await getPath('${DateTime.now().millisecondsSinceEpoch}');
      // 存储本地m3u8文件
      final String m3u8Name = taskInfo['urlPath'].substring(
          taskInfo['urlPath'].lastIndexOf('/') + 1,
          taskInfo['urlPath'].indexOf('m3u8') + 4);
      await File('$saveDirectory$m3u8Name').writeAsString(localM3u8);
      taskInfo['url'] = '$saveDirectory$m3u8Name';
      if (!downloading) {
        taskInfo['downloading'] = true;
        taskInfo['isWaiting'] = false;
        await downloadContent(taskInfo, box);
      }
      // 储存下载任务信息
      taskInfo['progress'] = 0;
      tasks.insert(0, taskInfo);
      await box.put('download_video_tasks', tasks);
      creating = false;
    } catch (e) {
      // CommonUtils.debugPrint(CommonUtils.txt('xzcjsb'));
      creating = false;
    }
  }

  static Future<void> downloadContent(Map taskInfo, Box box) async {
    final List tsListsFinished = taskInfo['tsListsFinished'];
    initStatus(tsListsFinished.length);
    final tsLists = <String>[taskInfo['tsLists']];
    final String saveDirectory =
        taskInfo['url'].substring(0, taskInfo['url'].lastIndexOf('/'));
    // 提取未完成的下载任务队列
    // LogUtil.d("下载任务id---------${taskInfo["id"]}");
    if (tsListsFinished.isNotEmpty) {
      tsLists.removeWhere((e) {
        for (var i = 0; i < tsListsFinished.length; i++) {
          if (tsListsFinished[i] == e) {
            return true;
          }
        }
        return false;
      });
    }

    var _index = 0;
    int taskNum;
    List tasks;
    Future start() async {
      // 删除任务中断下载
      if (currentRemove) {
        return;
      }
      try {
        final savePath =
            "$saveDirectory/${tsLists[_index].substring(tsLists[_index].lastIndexOf("/") + 1, tsLists[_index].contains(".ts") ? (tsLists[_index].indexOf(".ts") + 3) : (tsLists[_index].indexOf(".key") + 4))}";
        _index = await downloadItem(tsLists[_index], savePath, _index,
            taskInfo['id'], taskInfo['tsLists'].length, box);
        if (currentRemove) {
          return;
        }
        if (_index >= tsLists.length - 1) {
          // 完成
          // 存储完成后的下载任务信息
          tasks = box.get('download_video_tasks') ?? [];
          taskNum = tasks.indexWhere((e) => e['id'] == taskInfo['id']);
          tasks[taskNum]['progress'] = 1;
          tasks[taskNum]['downloading'] = false;
          await box.put('download_video_tasks', tasks);
          // 下载完成，开始下一个任务
          downloadTasks.removeAt(0);
          await startNext();
        } else {
          _index++;
          await start();
        }
      } catch (e) {
        // 下载失败，开始下个任务
        tasks = box.get('download_video_tasks') ?? [];
        taskNum = tasks.indexWhere((e) => e['id'] == taskInfo['id']);
        tasks[taskNum]['downloading'] = false;
        await box.put('download_video_tasks', tasks);
        downloadTasks.removeAt(0);
        await startNext();
        // EventBus().emit('DOWNLOADVIDEO_PROGRESS_${taskInfo["id"]}', {
        //   'id': taskInfo['id'],
        //   'downloading': false,
        //   'downloadError': true
        // });
      }
    }

    await start();
  }

// 单个下载方法
  static Future<int> downloadItem(String urlPath, String savePath, int index,
      String id, int tsTotal, Box box) async {
    Future<int> start() async {
      if (currentRemove) {
        return index;
      }
      try {
        await dio.download(urlPath, savePath,
            onReceiveProgress: (count, total) {
          if (count >= total) {
            // 储存下载进度
            finishCount++;
            final List tasks = box.get('download_video_tasks') ?? [];
            final taskNum = tasks.indexWhere((e) => e['id'] == id);
            tasks[taskNum]['progress'] = finishCount / tsTotal;
            tasks[taskNum]['downloading'] = true;
            tasks[taskNum]['tsListsFinished'].add(urlPath);
            box.put('download_video_tasks', tasks);
            // LogUtil.d("完成单个任务id---------${id}");
            // 发送进度数据
            // EventBus().emit('DOWNLOADVIDEO_PROGRESS_$id',
            //     {'id': id, 'progress': finishCount / tsTotal});
          }
        });
        return index;
      } catch (e) {
        return start();
      }
    }

    final a = await start();
    return a;
  }

  //获取本地唯一标识
  static Future<String> getUniqueId() async {
    final saveDirectory = await getEnvironmentPath('guqiuni'); // 获取储存地址
    // CommonUtils.debugPrint(saveDirectory);
    try {
      final data = await File('${saveDirectory}unis.json').readAsString();
      final Map json = jsonDecode(data);
      final cx = json['uni'].toString();
      final uits = base64Decode(PlatformAwareCrypto.decry(cx));
      final txt = String.fromCharCodes(uits);
      // CommonUtils.debugPrint('parsing--$txt--$cx');
      // AppGlobal.isSave = true;
      return txt;
    } on FileSystemException catch (e) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      // CommonUtils.debugPrint('custom id--${androidInfo.androidId}--$e');
      await setUniqueId(androidInfo.androidId); //存储
      return androidInfo.androidId;
    }
  }

  //保存本地唯一标识
  static Future<void> setUniqueId(String uni) async {
    if (uni.isEmpty) return;
    try {
      final saveDirectory = await getEnvironmentPath('guqiuni'); // 获取储存地址
      final json = {};
      final bytes = Uint8List.fromList(uni.codeUnits);
      final String txt = PlatformAwareCrypto.encry(base64Encode(bytes));
      json['uni'] = txt;
      final pathf = await File('${saveDirectory}unis.json')
          .writeAsBytes(utf8.encode(jsonEncode(json)));
      if (pathf.path.isNotEmpty) {
        // CommonUtils.debugPrint('save success');
      } else {
        // CommonUtils.debugPrint('failed success');
      }
    } on FileSystemException catch (e) {
      // CommonUtils.debugPrint(e);
    }
  }
}
