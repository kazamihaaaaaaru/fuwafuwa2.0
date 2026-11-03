import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/image_storage_service.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/accessory.dart';

/// 录入搭配小物抽屉组件
/// 支持现货全款与定金尾款制，默认停在“现货全款”
class AddAccessorySheet extends StatefulWidget {
  final VoidCallback? onAdded;

  const AddAccessorySheet({super.key, this.onAdded});

  static Future<void> show(BuildContext context, {VoidCallback? onAdded}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAccessorySheet(onAdded: onAdded),
    );
  }

  @override
  State<AddAccessorySheet> createState() => _AddAccessorySheetState();
}

class _AddAccessorySheetState extends State<AddAccessorySheet> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImageStorageService _imageService = ImageStorageService.instance;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _fullPriceCtrl = TextEditingController();
  final TextEditingController _depositPriceCtrl = TextEditingController();
  final TextEditingController _balancePriceCtrl = TextEditingController();

  String _selectedType = AppConstants.accessoryTypes.first; // 默认 KC
  String _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _expectedDate;
  String? _balanceDate;
  String? _imagePath;

  bool _isDepositType = false; // 智能默认项：小物默认为现货全款
  bool _hasPaidBalance = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fullPriceCtrl.dispose();
    _depositPriceCtrl.dispose();
    _balancePriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
                const Text(
                  '添置新饰品 ୨୧',
                  style: TextStyle(
                    color: FuwaColors.chocolateDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: FuwaColors.mutedRosyBrown),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 照片选择
            Center(
              child: GestureDetector(
                onTap: () async {
                  final path = await _imageService.pickAndSaveImage(source: ImageSource.gallery);
                  if (path != null && mounted) {
                    setState(() => _imagePath = path);
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: FuwaColors.creamWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FuwaColors.subtleBorder),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 24)),
                            Text('配饰图', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 10)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 名称
            const Text('小物名称 *', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: '如：琥珀心发带 / 蕾丝手袖',
                filled: true,
                fillColor: FuwaColors.creamWhite,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // 类型
            const Text('小物分类', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: AppConstants.accessoryTypes.map((t) {
                final isSel = _selectedType == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: isSel,
                  onSelected: (sel) {
                    if (sel) setState(() => _selectedType = t);
                  },
                  selectedColor: FuwaColors.balletPink,
                  backgroundColor: FuwaColors.creamWhite,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : FuwaColors.chocolateDark,
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: isSel ? FuwaColors.balletPink : FuwaColors.subtleBorder),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // 购买模式：现货全款 vs 定金尾款
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('付款模式', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    _buildModeOption('现货全款', !_isDepositType, () => setState(() => _isDepositType = false)),
                    const SizedBox(width: 8),
                    _buildModeOption('定金尾款制', _isDepositType, () => setState(() => _isDepositType = true)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!_isDepositType) ...[
              // 现货全款
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('全款金额 (元)', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _fullPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: '如 128',
                            filled: true,
                            fillColor: FuwaColors.creamWhite,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('购买日期', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12)),
                        const SizedBox(height: 6),
                        _buildDatePickerButton(_date, (d) => setState(() => _date = d)),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // 定金尾款制
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('定金 (元)', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _depositPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: '如 50',
                            filled: true,
                            fillColor: FuwaColors.creamWhite,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('定金日期', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12)),
                        const SizedBox(height: 6),
                        _buildDatePickerButton(_date, (d) => setState(() => _date = d)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 预计补款时间
              const Text('预计出货月份（可选）', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12)),
              const SizedBox(height: 6),
              _buildDatePickerButton(_expectedDate ?? '点击选择预计出货日', (d) => setState(() => _expectedDate = d)),
              const SizedBox(height: 10),
              // 尾款结清开关
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: FuwaColors.creamWhite, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('尾款已结清出货', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w600)),
                    Switch(
                      value: _hasPaidBalance,
                      activeColor: Colors.white,
                      activeTrackColor: FuwaColors.balletPink,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: FuwaColors.apricotCream,
                      onChanged: (val) {
                        setState(() {
                          _hasPaidBalance = val;
                          if (val && _balanceDate == null) {
                            _balanceDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (_hasPaidBalance) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _balancePriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '实付尾款如 80',
                          filled: true,
                          fillColor: FuwaColors.creamWhite,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDatePickerButton(_balanceDate ?? _date, (d) => setState(() => _balanceDate = d)),
                    ),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 20),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveAccessory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FuwaColors.balletPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: const Text('收入小物箱 ୨୧', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? FuwaColors.balletPink : FuwaColors.creamWhite,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : FuwaColors.chocolateDark,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerButton(String label, ValueChanged<String> onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onPicked(DateFormat('yyyy-MM-dd').format(picked));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: FuwaColors.creamWhite, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 12)),
            const Icon(Icons.calendar_month_rounded, size: 16, color: FuwaColors.balletPink),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAccessory() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final fullPrice = double.tryParse(_fullPriceCtrl.text.trim()) ?? 0.0;
    final depositPrice = double.tryParse(_depositPriceCtrl.text.trim()) ?? 0.0;
    final balancePrice = double.tryParse(_balancePriceCtrl.text.trim()) ?? 0.0;

    final acc = Accessory(
      name: _nameCtrl.text.trim(),
      imagePath: _imagePath,
      accessoryType: _selectedType,
      isDepositType: _isDepositType,
      fullPrice: _isDepositType ? 0.0 : fullPrice,
      depositPrice: _isDepositType ? depositPrice : 0.0,
      depositDate: _date,
      balancePrice: (_isDepositType && _hasPaidBalance) ? balancePrice : 0.0,
      balanceDate: (_isDepositType && _hasPaidBalance) ? _balanceDate : null,
      expectedDate: _isDepositType ? _expectedDate : null,
    );

    await _dbHelper.insertAccessory(acc);
    if (mounted) {
      Navigator.pop(context);
      widget.onAdded?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: FuwaColors.balletPink,
          content: Text('饰品已收入小物箱 ୨୧'),
        ),
      );
    }
  }
}
