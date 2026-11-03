import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 本地沙盒图片存储与压缩服务
/// 遵循原则：纯本地离线运行、上限 1080p、写入 App 私有沙盒存储
class ImageStorageService {
  ImageStorageService._();
  static final ImageStorageService instance = ImageStorageService._();

  final ImagePicker _picker = ImagePicker();

  /// 从相册或相机选取单张照片，自动执行 1080p 压缩并转存至 App 私有沙盒
  Future<String?> pickAndSaveImage({required ImageSource source}) async {
    try {
      // image_picker 原生直接支持 1080p 硬件加速压缩，无需庞大 C++ NDK 依赖
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // 准备私有沙盒存储目录
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'fuwa_wardrobe_images'));
      if (!imagesDir.existsSync()) {
        imagesDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetFileName = 'fuwa_$timestamp.jpg';
      final targetPath = p.join(imagesDir.path, targetFileName);

      final copiedFile = await File(pickedFile.path).copy(targetPath);
      return copiedFile.path;
    } catch (_) {
      return null;
    }
  }

  /// 删除沙盒中的本地图片
  Future<void> deleteImage(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
