import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/database/database_helper.dart';

/// 衣柜本地数据真·ZIP 压缩包备份与迁移恢复服务
/// 遵循纯本地离线原则：支持将所有衣物、饰品、心愿单与本地 1080p 相片打包导出为 ZIP 文件，并支持一键从 ZIP 文件完整还原
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 导出为真正的 ZIP 压缩包 (包含 SQLite 完整数据 JSON 与全部 1080P 本地原图)
  Future<String> exportBackupZip() async {
    final rawData = await _dbHelper.exportRawData();
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'fuwa_wardrobe_images'));

    final archive = Archive();

    // 1. 打包数据库数据 JSON (UTF-8 字节)
    final backupMeta = {
      'app': 'FuwaFuwa',
      'version': 5,
      'exportTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'data': rawData,
    };
    final jsonBytes = utf8.encode(jsonEncode(backupMeta));
    archive.addFile(ArchiveFile('fuwa_database.json', jsonBytes.length, jsonBytes));

    // 2. 打包相片目录下的所有原图
    if (imagesDir.existsSync()) {
      final imageFiles = imagesDir.listSync();
      for (final f in imageFiles) {
        if (f is File) {
          try {
            final bytes = await f.readAsBytes();
            archive.addFile(ArchiveFile('images/${p.basename(f.path)}', bytes.length, bytes));
          } catch (_) {}
        }
      }
    }

    // 3. 使用 ZipEncoder 进行真正的 ZIP 二进制打包
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    if (zipBytes == null) {
      throw Exception('ZIP 压缩打包失败');
    }

    final timeTag = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'fuwafuwa_wardrobe_backup_$timeTag.zip';

    // 优先保存至手机公开的 Download 目录，方便在文件管理器中找到并发送
    String savedPath;
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (downloadDir.existsSync()) {
        final targetFile = File(p.join(downloadDir.path, fileName));
        await targetFile.writeAsBytes(zipBytes);
        savedPath = targetFile.path;
      } else {
        final targetFile = File(p.join(appDir.path, fileName));
        await targetFile.writeAsBytes(zipBytes);
        savedPath = targetFile.path;
      }
    } catch (_) {
      final targetFile = File(p.join(appDir.path, fileName));
      await targetFile.writeAsBytes(zipBytes);
      savedPath = targetFile.path;
    }

    return savedPath;
  }

  /// 从 ZIP 压缩包还原全部数据与高清相片
  Future<int> importBackupFromZipFile(String filePath) async {
    final zipFile = File(filePath);
    if (!zipFile.existsSync()) {
      throw Exception('未找到备份压缩包文件：$filePath');
    }

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. 查找 fuwa_database.json
    final dbFile = archive.findFile('fuwa_database.json');
    if (dbFile == null) {
      throw Exception('格式错误：压缩包内未包含「fuwa_database.json」数据文件');
    }

    final jsonStr = utf8.decode(dbFile.content as List<int>);
    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic> || decoded['app'] != 'FuwaFuwa') {
      throw Exception('格式错误：不是有效的「ふわふわ」衣柜备份文件');
    }

    // 2. 解压恢复图片至本地 fuwa_wardrobe_images 目录
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'fuwa_wardrobe_images'));
    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }

    for (final file in archive.files) {
      if (file.name.startsWith('images/') && !file.isDirectory) {
        final basename = p.basename(file.name);
        final imgFile = File(p.join(imagesDir.path, basename));
        await imgFile.writeAsBytes(file.content as List<int>);
      }
    }

    // 3. 恢复 SQLite 数据并更新图片本地绝对路径
    final dataMap = decoded['data'] as Map<String, dynamic>? ?? {};

    // 修正单品路径
    if (dataMap.containsKey('items')) {
      final items = (dataMap['items'] as List<dynamic>).map((it) {
        if (it is Map<String, dynamic>) {
          final copy = Map<String, dynamic>.from(it);
          if (copy['imagePath'] != null && copy['imagePath'].toString().isNotEmpty) {
            final basename = p.basename(copy['imagePath']);
            copy['imagePath'] = p.join(imagesDir.path, basename);
          }
          return copy;
        }
        return it;
      }).toList();
      dataMap['items'] = items;
    }

    // 修正饰品路径
    if (dataMap.containsKey('accessories')) {
      final accessories = (dataMap['accessories'] as List<dynamic>).map((acc) {
        if (acc is Map<String, dynamic>) {
          final copy = Map<String, dynamic>.from(acc);
          if (copy['imagePath'] != null && copy['imagePath'].toString().isNotEmpty) {
            final basename = p.basename(copy['imagePath']);
            copy['imagePath'] = p.join(imagesDir.path, basename);
          }
          return copy;
        }
        return acc;
      }).toList();
      dataMap['accessories'] = accessories;
    }

    // 修正心愿单路径
    if (dataMap.containsKey('wishlist')) {
      final wishlist = (dataMap['wishlist'] as List<dynamic>).map((w) {
        if (w is Map<String, dynamic>) {
          final copy = Map<String, dynamic>.from(w);
          if (copy['imagePath'] != null && copy['imagePath'].toString().isNotEmpty) {
            final basename = p.basename(copy['imagePath']);
            copy['imagePath'] = p.join(imagesDir.path, basename);
          }
          return copy;
        }
        return w;
      }).toList();
      dataMap['wishlist'] = wishlist;
    }

    return await _dbHelper.importRawData(dataMap);
  }

  /// 扫描手机本地 Download 目录和应用沙盒目录中已有的备份压缩包
  Future<List<String>> scanExistingBackupFiles() async {
    final List<String> paths = [];
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (downloadDir.existsSync()) {
        for (final f in downloadDir.listSync()) {
          if (f is File && f.path.endsWith('.zip') && f.path.contains('fuwafuwa')) {
            paths.add(f.path);
          }
        }
      }
    } catch (_) {}

    try {
      final appDir = await getApplicationDocumentsDirectory();
      for (final f in appDir.listSync()) {
        if (f is File && f.path.endsWith('.zip') && f.path.contains('fuwafuwa')) {
          if (!paths.contains(f.path)) paths.add(f.path);
        }
      }
    } catch (_) {}

    paths.sort((a, b) => b.compareTo(a)); // 最新文件排在最前
    return paths;
  }
}
