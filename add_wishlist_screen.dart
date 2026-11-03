import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/image_storage_service.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/wishlist_item.dart';

/// 全屏录入/修改心愿单页面 (`AddWishlistScreen`)
/// 统一规范全屏从容排版，去除突兀黑边，纯白微粉柔光卡片与深棕文字
class AddWishlistScreen extends StatefulWidget {
  final WishlistItem? itemToEdit; // 传入已有心愿单单品则为修改编辑模式
  final VoidCallback? onAdded;

  const AddWishlistScreen({
    super.key,
    this.itemToEdit,
    this.onAdded,
  });

  @override
  State<AddWishlistScreen> createState() => _AddWishlistScreenState();
}

class _AddWishlistScreenState extends State<AddWishlistScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImageStorageService _imageService = ImageStorageService.instance;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _shopCtrl = TextEditingController();
  final TextEditingController _budgetCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  String _desireLevel = AppConstants.desireLevels.first;
  String _releaseDate = DateFormat('yyyy-MM').format(DateTime.now());
  String? _imagePath;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    _initDefaults();
  }

  void _initDefaults() {
    if (widget.itemToEdit != null) {
      final it = widget.itemToEdit!;
      _nameCtrl.text = it.name;
      _shopCtrl.text = it.shopName ?? '';
      _budgetCtrl.text = it.budgetPrice > 0 ? it.budgetPrice.toStringAsFixed(0) : '';
      _noteCtrl.text = it.note ?? '';
      _desireLevel = it.desireLevel;
      _releaseDate = it.releaseDate ?? DateFormat('yyyy-MM').format(DateTime.now());
      _imagePath = it.imagePath;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shopCtrl.dispose();
    _budgetCtrl.dispose();
    _noteCtrl.dispose();
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
    final isEditMode = widget.itemToEdit != null;

    return Scaffold(
      backgroundColor: FuwaColors.creamWhite,
      appBar: AppBar(
        backgroundColor: FuwaColors.creamWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: FuwaColors.chocolateDark),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          isEditMode ? '修改心愿档案 ୨୧' : '许愿新单品 ୨୧',
          style: const TextStyle(
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
              _buildDesireCard(),
            ],
          ),
        ),
      ),
      bottomSheet: _buildBottomSaveBar(isEditMode),
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
                                  Text('点击上传心愿相片', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
                                  SizedBox(height: 4),
                                  Text('自动本地 1080p 优化归档', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 10)),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'WISHLIST POLAROID ୨୧',
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
              const Text('选取心愿图 ୨୧', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700)),
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
          const Text('单品心愿信息', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _buildTextInput(
            label: '心愿单品名称 *',
            hint: '如：白雪姬 JSK / 珍珠发带',
            controller: _nameCtrl,
            validator: (v) => (v == null || v.trim().isEmpty) ? '请输入单品名称' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTextInput(
                  label: '店家 / 品牌',
                  hint: '如：Baby / AP',
                  controller: _shopCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberInput(
                  label: '预算金额 (元)',
                  hint: '如 2500',
                  controller: _budgetCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextInput(
            label: '心愿便签 / 备注',
            hint: '如：预计初版再贩、想配红色KC等',
            controller: _noteCtrl,
          ),
        ],
      ),
    );
  }

  Widget _buildDesireCard() {
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
          const Text('心动等级与预计时间', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('心动等级', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.desireLevels.map((lvl) {
              final isSel = _desireLevel == lvl;
              Color activeColor;
              switch (lvl) {
                case '非入不可 ♡':
                  activeColor = FuwaColors.balletPink;
                  break;
                case '很心动 ୨୧':
                  activeColor = FuwaColors.sugarCandyGold;
                  break;
                default:
                  activeColor = const Color(0xFFC798A6);
                  break;
              }

              return ChoiceChip(
                label: Text(lvl),
                selected: isSel,
                onSelected: (sel) {
                  if (sel) setState(() => _desireLevel = lvl);
                },
                selectedColor: activeColor,
                backgroundColor: FuwaColors.creamWhite,
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : FuwaColors.chocolateDark,
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isSel ? activeColor : FuwaColors.subtleBorder),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('预计贩售时间（年-月）', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _releaseDate = DateFormat('yyyy-MM').format(picked));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: FuwaColors.creamWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FuwaColors.subtleBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_releaseDate, style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w600)),
                  const Icon(Icons.calendar_month_rounded, size: 16, color: FuwaColors.balletPink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSaveBar(bool isEditMode) {
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
          onPressed: _saveWishlist,
          style: ElevatedButton.styleFrom(
            backgroundColor: FuwaColors.balletPink,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(FuwaColors.ribbonSymbol, style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                isEditMode ? '保存修改心愿 ୨୧' : '许愿收藏 ୨୧',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
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
          ),
        ),
      ],
    );
  }

  Future<void> _saveWishlist() async {
    if (!_formKey.currentState!.validate()) return;
    final budget = double.tryParse(_budgetCtrl.text.trim()) ?? 0.0;

    final item = WishlistItem(
      id: widget.itemToEdit?.id, // 保留原有 id
      name: _nameCtrl.text.trim(),
      shopName: _shopCtrl.text.trim(),
      budgetPrice: budget,
      imagePath: _imagePath,
      releaseDate: _releaseDate,
      desireLevel: _desireLevel,
      note: _noteCtrl.text.trim(),
      createdDate: widget.itemToEdit?.createdDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    if (widget.itemToEdit != null) {
      await _dbHelper.updateWishlistItem(item);
    } else {
      await _dbHelper.insertWishlistItem(item);
    }

    if (mounted) {
      widget.onAdded?.call();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: FuwaColors.balletPink,
          content: Text(widget.itemToEdit != null ? '心愿单档案已成功修改 ୨୧' : '心愿单已收藏 ୨୧'),
        ),
      );
    }
  }
}
