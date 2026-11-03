import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/backup_service.dart';
import '../../core/theme/fuwa_colors.dart';

/// 数据备份与换机迁移弹窗 (`BackupDialog`)
/// 严格遵循纯本地离线原则：
/// - 一键导出包含全部洋装、常服、配饰、心愿单与相片的一体化备份数据
/// - 支持复制到剪贴板、支持通过粘贴数据或读取文件一键恢复入库
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

class _BackupDialogState extends State<BackupDialog> {
  final BackupService _backupService = BackupService.instance;
  final TextEditingController _importController = TextEditingController();

  bool _isExporting = false;
  bool _isImporting = false;
  String? _exportedFilePath;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  /// 导出备份并自动复制到剪贴板
  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final jsonStr = await _backupService.exportBackupJson();
      final filePath = await _backupService.exportBackupToFile();

      // 复制到系统剪贴板，方便通过微信或记事本直接发送给新设备
      await Clipboard.setData(ClipboardData(text: jsonStr));

      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportedFilePath = filePath;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: FuwaColors.balletPink,
            content: Text('备份数据已成功复制到剪贴板，可直接在微信/QQ发给新手机 ୨୧'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('导出失败: $e')),
        );
      }
    }
  }

  /// 从输入内容执行数据恢复
  Future<void> _importData() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: FuwaColors.sugarCandyGold, content: Text('请先粘贴备份数据内容 ୨୧')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuwaColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认恢复备份？', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('即将从备份数据中恢复所有衣物、饰品、心愿单与相片记录，确认继续吗？', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: FuwaColors.mutedRosyBrown))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: FuwaColors.balletPink, elevation: 0),
            child: const Text('立即恢复', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isImporting = true);
    try {
      final count = await _backupService.importBackupFromJson(text);
      if (mounted) {
        setState(() => _isImporting = false);
        widget.onRestored?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: FuwaColors.balletPink,
            content: Text('数据迁移成功！已恢复 $count 条记录及相片 ୨୧'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('恢复失败: $e')),
        );
      }
    }
  }

  /// 从系统剪贴板自动粘贴
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _importController.text = data.text!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: FuwaColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 18)),
                    SizedBox(width: 6),
                    Text(
                      '数据备份与换机迁移 ୨୧',
                      style: TextStyle(
                        color: FuwaColors.chocolateDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: FuwaColors.mutedRosyBrown),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '纯本地离线储存，更换手机时可一键打包导出并无损迁移数据',
              style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // 卡片 1：导出数据
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FuwaColors.creamWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FuwaColors.subtleBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('一键导出当前衣柜', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                    '打包全部洋装、常服、配饰、心愿单及本地相册照片为单个备份文件，并自动复制到剪贴板。',
                    style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportData,
                      icon: _isExporting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.copy_all_rounded, size: 18, color: Colors.white),
                      label: Text(_isExporting ? '正在打包备份数据...' : '导出备份并复制数据 ୨୧'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FuwaColors.balletPink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  if (_exportedFilePath != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '本地备份路径已生成在应用沙盒',
                      style: TextStyle(color: FuwaColors.mutedRosyBrown.withOpacity(0.8), fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 卡片 2：恢复数据
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FuwaColors.creamWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FuwaColors.subtleBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('从备份一键恢复', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
                      TextButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(Icons.paste_rounded, size: 14, color: FuwaColors.balletPink),
                        label: const Text('粘贴剪贴板内容', style: TextStyle(color: FuwaColors.balletPink, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: FuwaColors.pureWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FuwaColors.subtleBorder),
                    ),
                    child: TextField(
                      controller: _importController,
                      maxLines: null,
                      style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 11),
                      decoration: const InputDecoration(
                        hintText: '在此粘贴之前导出的备份 JSON 文本数据...',
                        hintStyle: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _isImporting ? null : _importData,
                      icon: _isImporting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: FuwaColors.balletPink))
                          : const Icon(Icons.restore_page_rounded, size: 18, color: FuwaColors.balletPink),
                      label: Text(_isImporting ? '正在恢复数据中...' : '确认导入并恢复衣柜 ୨୧', style: const TextStyle(color: FuwaColors.chocolateDark, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: FuwaColors.balletPink),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
