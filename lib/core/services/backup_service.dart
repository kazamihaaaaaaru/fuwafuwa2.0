import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/database/database_helper.dart';

/// 衣柜本地数据备份与迁移恢复服务
/// 遵循纯本地离线原则：支持将所有衣物、饰品、心愿单与本地 1080p 相片打包导出与一键恢复
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 导出完整备份数据（包含数据库全部记录与本地相片 Base64 编码）
  Future<String> exportBackupJson() async {
    final rawData = await _dbHelper.exportRawData();

    // 提取并编码本地沙盒相片
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'fuwa_wardrobe_images'));

    final Map<String, String> encodedImages = {};
    if (imagesDir.existsSync()) {
      final files = imagesDir.listSync();
      for (final f in files) {
        if (f is File) {
          try {
            final bytes = await f.readAsBytes();
            final b64 = base64Encode(bytes);
            encodedImages[p.basename(f.path)] = b64;
          } catch (_) {}
        }
      }
    }

    final fullBackup = {
      'app': 'FuwaFuwa',
      'version': 4,
      'exportTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'data': rawData,
      'images': encodedImages,
    };

    return const JsonEncoder.withIndent('  ').convert(fullBackup);
  }

  /// 导出并保存到本地沙盒文件
  Future<String> exportBackupToFile() async {
    final jsonStr = await exportBackupJson();
    final appDir = await getApplicationDocumentsDirectory();
    final timeTag = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFile = File(p.join(appDir.path, 'fuwafuwa_backup_$timeTag.json'));
    await backupFile.writeAsString(jsonStr);
    return backupFile.path;
  }

  /// 从备份 JSON 内容恢复数据
  Future<int> importBackupFromJson(String jsonContent) async {
    final dynamic decoded = jsonDecode(jsonContent);
    if (decoded is! Map<String, dynamic> || decoded['app'] != 'FuwaFuwa') {
      throw Exception('格式错误：不是有效的「ふわふわ」衣柜备份文件');
    }

    // 1. 恢复本地沙盒相片并修正路径映射
    final imagesMap = decoded['images'] as Map<String, dynamic>? ?? {};
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'fuwa_wardrobe_images'));
    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }

    for (final entry in imagesMap.entries) {
      try {
        final filename = entry.key;
        final b64 = entry.value as String;
        final bytes = base64Decode(b64);
        final file = File(p.join(imagesDir.path, filename));
        await file.writeAsBytes(bytes);
      } catch (_) {}
    }

    // 2. 恢复 SQLite 数据库记录并映射为新设备绝对路径
    final dataMap = decoded['data'] as Map<String, dynamic>? ?? {};

    // 遍历修正单品与饰品的相片本地路径
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

    return await _dbHelper.importRawData(dataMap);
  }
}
