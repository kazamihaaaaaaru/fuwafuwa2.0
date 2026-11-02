import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/image_storage_service.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/accessory.dart';

/// 全屏录入搭配饰品页面 (`AddAccessoryScreen`)
/// 统一规范全屏从容排版，去除突兀黑边，纯白微粉柔光卡片与深棕文字
class AddAccessoryScreen extends StatefulWidget {
  final VoidCallback? onAdded;

  const AddAccessoryScreen({super.key, this.onAdded});

  @override
  State<AddAccessoryScreen> createState() => _AddAccessoryScreenState();
}

class _AddAccessoryScreenState extends State<AddAccessoryScreen> {
  final _formKey = GlobalKey<FormState>();
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
  bool _isProcessingImage = false;

  bool _isDepositType = false; // 智能默认项：饰品默认为现货全款
  bool _hasPaidBalance = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fullPriceCtrl.dispose();
    _depositPriceCtrl.dispose();
    _balancePriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isProcessingImage = true);
    final savedPath = await _imageService.pickAndSaveImage(source: source);
    if (mounted) {
      setState(() {
        _imagePath = savedPath;
        _isProcessingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FuwaColors.creamWhite,
      appBar: AppBar(
        backgroundColor: FuwaColors.creamWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: FuwaColors.chocolateDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '添置新饰品 ୨୧',
          style: TextStyle(
            color: FuwaColors.chocolateDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            children: [
              _buildPhotoPickerSection(),
              const SizedBox(height: 18),
              _buildGeneralInfoCard(),
              const SizedBox(height: 16),
              _buildPricingCard(),
            ],
          ),
        ),
      ),
      bottomSheet: _buildBottomSaveBar(),
    );
  }

  Widget _buildPhotoPickerSection() {
    return Center(
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          width: 200,
          height: 240,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          decoration: BoxDecoration(
            color: FuwaColors.pureWhite,
            borderRadius: FuwaColors.roundedCardRadius,
            boxShadow: FuwaColors.softCardShadow,
            border: Border.all(color: FuwaColors.subtleBorder),
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: FuwaColors.creamWhite,
                    width: double.infinity,
                    child: _isProcessingImage
                        ? const Center(child: CircularProgressIndicator(color: FuwaColors.balletPink))
                        : _imagePath != null
                            ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 36)),
                                  SizedBox(height: 8),
                                  Text('点击上传饰品相片', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
                                  SizedBox(height: 4),
                                  Text('自动本地 1080p 优化归档', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 10)),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ACCESSORY POLAROID ୨୧',
                style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: FuwaColors.pureWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('选取饰品相片 ୨୧', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: FuwaColors.balletPink),
                title: const Text('从手机相册选取', style: TextStyle(color: FuwaColors.chocolateDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: FuwaColors.balletPink),
                title: const Text('拍摄新照片', style: TextStyle(color: FuwaColors.chocolateDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FuwaColors.pureWhite,
        borderRadius: FuwaColors.roundedCardRadius,
        boxShadow: FuwaColors.softCardShadow,
        border: Border.all(color: FuwaColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('饰品档案', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _buildTextInput(
            label: '小物名称 *',
            hint: '如：琥珀心发带 / 珍珠手袖 / 优雅KC',
            controller: _nameCtrl,
            validator: (v) => (v == null || v.trim().isEmpty) ? '请输入小物名称' : null,
          ),
          const SizedBox(height: 14),
          const Text('饰品类型', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.accessoryTypes.map((t) {
              final isSel = _selectedType == t;
              return ChoiceChip(
                label: Text(t),
                selected: isSel,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedType = t);
                },
                selectedColor: FuwaColors.balletPink,
                backgroundColor: FuwaColors.creamWhite,
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : FuwaColors.chocolateDark,
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isSel ? FuwaColors.balletPink : FuwaColors.subtleBorder),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FuwaColors.pureWhite,
        borderRadius: FuwaColors.roundedCardRadius,
        boxShadow: FuwaColors.softCardShadow,
        border: Border.all(color: FuwaColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('付款与购买模式', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  _buildMiniTypeOption('现货全款', !_isDepositType, () => setState(() => _isDepositType = false)),
                  const SizedBox(width: 8),
                  _buildMiniTypeOption('定金尾款制', _isDepositType, () => setState(() => _isDepositType = true)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isDepositType) ...[
            Row(
              children: [
                Expanded(
                  child: _buildNumberInput(
                    label: '全款金额 (元) *',
                    hint: '如 128',
                    controller: _fullPriceCtrl,
                    validator: (v) => (!_isDepositType && (v == null || v.trim().isEmpty)) ? '请输入金额' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePickerField(
                    label: '购买支付日期',
                    currentDate: _date,
                    onDatePicked: (dt) => setState(() => _date = dt),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildNumberInput(
                    label: '定金金额 (元) *',
                    hint: '如 50',
                    controller: _depositPriceCtrl,
                    validator: (v) => (_isDepositType && (v == null || v.trim().isEmpty)) ? '请输入定金' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePickerField(
                    label: '定金支付日期',
                    currentDate: _date,
                    onDatePicked: (dt) => setState(() => _date = dt),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDatePickerField(
              label: '预计出货/补款日期（可选）',
              currentDate: _expectedDate ?? '点击设置预计出货日',
              onDatePicked: (dt) => setState(() => _expectedDate = dt),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: FuwaColors.creamWhite, borderRadius: BorderRadius.circular(16)),
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
                    trackOutlineColor: MaterialStateProperty.all(FuwaColors.subtleBorder),
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberInput(
                      label: '实付尾款金额 (元)',
                      hint: '如 78',
                      controller: _balancePriceCtrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePickerField(
                      label: '尾款支付日期',
                      currentDate: _balanceDate ?? _date,
                      onDatePicked: (dt) => setState(() => _balanceDate = dt),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBottomSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: FuwaColors.pureWhite,
        boxShadow: FuwaColors.softCardShadow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _saveAccessory,
          style: ElevatedButton.styleFrom(
            backgroundColor: FuwaColors.balletPink,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(FuwaColors.ribbonSymbol, style: TextStyle(color: Colors.white, fontSize: 16)),
              SizedBox(width: 8),
              Text('收入小物箱 ୨୧', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: FuwaColors.creamWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FuwaColors.subtleBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextFormField(
            controller: controller,
            cursorColor: FuwaColors.balletPink,
            style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: FuwaColors.creamWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FuwaColors.subtleBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            cursorColor: FuwaColors.balletPink,
            style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required String currentDate,
    required ValueChanged<String> onDatePicked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              onDatePicked(DateFormat('yyyy-MM-dd').format(picked));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: FuwaColors.creamWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: FuwaColors.subtleBorder)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currentDate, style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 13)),
                const Icon(Icons.calendar_month_rounded, size: 16, color: FuwaColors.balletPink),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniTypeOption(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? FuwaColors.balletPink : FuwaColors.creamWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? FuwaColors.balletPink : FuwaColors.subtleBorder),
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

  Future<void> _saveAccessory() async {
    if (!_formKey.currentState!.validate()) return;

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
      widget.onAdded?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: FuwaColors.balletPink,
          content: Text('饰品已收入小物箱 ୨୧'),
        ),
      );
    }
  }
}
