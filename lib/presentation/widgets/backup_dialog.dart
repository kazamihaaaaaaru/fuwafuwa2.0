import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/backup_service.dart';
import '../../core/theme/fuwa_colors.dart';

/// 真实 ZIP 压缩包数据备份与换机迁移弹窗 (`BackupDialog`)
/// 严格遵循纯本地离线原则：
/// - 一键将衣柜所有单品、饰品、心愿单与 1080P 高清原图打包为真正的 .zip 压缩包
/// - 自动保存至手机公开的【下载 / Download】文件夹，支持微信/QQ直接发送给新手机
/// - 新手机直接点选本地 .zip 文件一键完整解压入库，杜绝任何剪贴板截断报错！
class BackupDialog extends StatefulWidget {
  final VoidCallback? onRestored;

  const BackupDialog({super.key, this.onRestored});

  static Future<void> show(BuildContext context, {VoidCallback? onRestored}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackupDialog(onRestored: onRestored),
    );
  }

  @override
  State<BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<BackupDialog> with SingleTickerProviderStateMixin {
  final BackupService _backupService = BackupService.instance;
  final TextEditingController _filePathController = TextEditingController();

  late TabController _tabController;
  bool _isExporting = false;
  bool _isImporting = false;
  String? _exportedZipPath;
  List<String> _detectedBackupFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scanBackups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filePathController.dispose();
    super.dispose();
  }

  Future<void> _scanBackups() async {
    final list = await _backupService.scanExistingBackupFiles();
    if (mounted) {
      setState(() {
        _detectedBackupFiles = list;
        if (list.isNotEmpty && _filePathController.text.isEmpty) {
          _filePathController.text = list.first;
        }
      });
    }
  }

  /// 导出为 ZIP 压缩包
  Future<void> _exportZip() async {
    setState(() => _isExporting = true);
    try {
      final zipPath = await _backupService.exportBackupZip();
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportedZipPath = zipPath;
          _filePathController.text = zipPath;
        });
        _scanBackups();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: FuwaColors.balletPink,
            content: Text('已成功生成 ZIP 备份包，并保存至手机【下载 / Download】文件夹！'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('打包失败: $e')),
        );
      }
    }
  }

  /// 从 ZIP 文件执行完整数据恢复
  Future<void> _importZip() async {
    final path = _filePathController.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: FuwaColors.sugarCandyGold, content: Text('请输入或选择备份压缩包文件路径')),
      );
      return;
    }

    if (!File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text('指定的文件不存在：\n$path')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuwaColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认解压并恢复备份？', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('即将从该 ZIP 压缩包中解压并完整还原所有衣物、饰品、心愿单与高清相片。确认继续吗？', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: FuwaColors.mutedRosyBrown))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: FuwaColors.balletPink, elevation: 0),
            child: const Text('立即解压恢复', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isImporting = true);
    try {
      final count = await _backupService.importBackupFromZipFile(path);
      if (mounted) {
        setState(() => _isImporting = false);
        Navigator.pop(context); // 关闭弹窗
        widget.onRestored?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: FuwaColors.balletPink,
            content: Text('已成功解压并还原全部高清图片与 $count 条衣柜档案！'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('解压恢复失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: FuwaColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部小横条
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: FuwaColors.subtleBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),

          // 弹窗标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.swap_horiz_rounded, size: 20, color: FuwaColors.balletPink),
                  SizedBox(width: 8),
                  Text('数据备份与迁移', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: FuwaColors.mutedRosyBrown),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 双段 Tab 切换
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: FuwaColors.creamWhite,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: FuwaColors.balletPink,
                borderRadius: BorderRadius.circular(20),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: FuwaColors.chocolateDark,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '导出 ZIP 压缩包'),
                Tab(text: '从 ZIP 压缩包恢复'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExportTab(),
                _buildImportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 导出选项卡
  Widget _buildExportTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FuwaColors.creamWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FuwaColors.subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '📦 真·ZIP 压缩包完整迁移方案',
                  style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  '• 自动将全衣柜单品记录、心愿单与全部 1080P 高清原图打包压缩为单一 .zip 文件。\n• 导出的压缩包直接写入手机公开的【下载 / Download】文件夹中，绝无任何字符截断风险。\n• 可直接通过微信文件传输助手、QQ 发给新手机，或使用电脑拷贝。',
                  style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportZip,
              icon: _isExporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.archive_outlined, color: Colors.white, size: 18),
              label: Text(
                _isExporting ? '正在打包高清原图与数据库...' : '一键打包导出 ZIP 备份包',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: FuwaColors.balletPink,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              '「ふわふわ」衣柜管理 · v1.1.0 (Build 2)',
              style: TextStyle(
                color: FuwaColors.mutedRosyBrown.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          if (_exportedZipPath != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FuwaColors.paleRose,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FuwaColors.balletPink.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '备份包已生成成功！',
                        style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _exportedZipPath!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(backgroundColor: FuwaColors.balletPink, content: Text('文件路径已复制到剪贴板！')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: FuwaColors.pureWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: FuwaColors.subtleBorder),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, size: 12, color: FuwaColors.balletPink),
                              SizedBox(width: 3),
                              Text('复制路径', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _exportedZipPath!,
                    style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '提示：打开手机自带的「文件管理」->「下载 (Download)」，就能直接找到并发送这个压缩包给新手机！',
                    style: TextStyle(color: FuwaColors.strawberryPink, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 导入选项卡
  Widget _buildImportTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FuwaColors.creamWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FuwaColors.subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '📥 从 ZIP 压缩包还原',
                  style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  '• 将新手机上收到的 .zip 压缩包放入手机的 Download 文件夹中。\n• 点击下方检测到的备份包，或手动输入完整文件路径。\n• 点击解压按钮，程序将流式完整还原所有图片与数据库记录！',
                  style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_detectedBackupFiles.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('检测到手机上的备份压缩包：', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: FuwaColors.balletPink),
                  onPressed: _scanBackups,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Column(
              children: _detectedBackupFiles.map((fpath) {
                final fname = fpath.split('/').last;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _filePathController.text = fpath;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _filePathController.text == fpath ? FuwaColors.apricotCream : FuwaColors.creamWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _filePathController.text == fpath ? FuwaColors.balletPink : FuwaColors.subtleBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_zip_outlined, size: 16, color: FuwaColors.balletPink),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          const Text('备份文件完整绝对路径：', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: FuwaColors.creamWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FuwaColors.subtleBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _filePathController,
              cursorColor: FuwaColors.balletPink,
              style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 12),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '如 /storage/emulated/0/Download/fuwafuwa_backup.zip',
                hintStyle: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isImporting ? null : _importZip,
              icon: _isImporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.unarchive_outlined, color: Colors.white, size: 18),
              label: Text(
                _isImporting ? '正在解压还原所有图片与数据...' : '一键解压并恢复数据',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: FuwaColors.balletPink,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              '「ふわふわ」衣柜管理 · v1.1.0 (Build 2)',
              style: TextStyle(
                color: FuwaColors.mutedRosyBrown.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
