import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/image_storage_service.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/accessory.dart';
import '../../data/models/item.dart';
import '../../data/models/wishlist_item.dart';

/// 模态页: 录入/编辑页面 (`AddScreen`)
/// 严格遵循甘系（Sweet Lolita）视觉设计规范：
/// - 支持单品录入与已有单品修改编辑（itemToEdit）
/// - 支持服装尺码选择（XS/S/M/L/均码/手写其他）
/// - 地球人与 Lolita 均支持记录【店铺/品牌】
/// - 洋装子类目拆分裙撑与内搭，并包含 JK
/// - 开关滑块纯白圆点配色，彻底去除生硬黑色
class AddScreen extends StatefulWidget {
  final String? initialCategory; // 'lolita' | 'earth'
  final Item? itemToEdit; // 传入已有单品则为编辑模式
  final WishlistItem? prefilledWishlistItem;
  final VoidCallback? onItemAdded;

  const AddScreen({
    super.key,
    this.initialCategory,
    this.itemToEdit,
    this.prefilledWishlistItem,
    this.onItemAdded,
  });

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImageStorageService _imageService = ImageStorageService.instance;

  String? _imagePath;
  bool _isProcessingImage = false;

  late String _category;
  String _subCategory = 'JSK';
  String _season = '四季通用';
  String _size = '均码';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _customSizeController = TextEditingController();
  final TextEditingController _fullPriceController = TextEditingController();
  final TextEditingController _depositPriceController = TextEditingController();
  final TextEditingController _balancePriceController = TextEditingController();

  String _purchaseDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _depositDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _balanceDate;
  String? _expectedDate;

  bool _isDepositType = true;
  bool _hasPaidBalance = false;

  List<Accessory> _allAccessories = [];
  final Set<int> _selectedAccessoryIds = {};

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? (widget.itemToEdit?.category ?? AppConstants.categoryLolita);
    _initDefaults();
    _loadAccessories();
  }

  void _initDefaults() {
    // 1. 如果是编辑已有单品模式
    if (widget.itemToEdit != null) {
      final it = widget.itemToEdit!;
      _category = it.category;
      _subCategory = it.subCategory;
      _nameController.text = it.name;
      _shopNameController.text = it.shopName ?? '';
      _colorController.text = it.color ?? '';
      _imagePath = it.imagePath;

      // 尺码
      if (it.size != null && it.size!.isNotEmpty) {
        if (AppConstants.clothingSizes.contains(it.size)) {
          _size = it.size!;
        } else {
          _size = '其他';
          _customSizeController.text = it.size!;
        }
      }

      // 季节
      if (it.season != null && it.season!.isNotEmpty) {
        _season = it.season!;
      }

      // 付款模式
      _isDepositType = it.isDepositType;
      if (it.isDepositType) {
        _depositPriceController.text = it.depositPrice > 0 ? it.depositPrice.toStringAsFixed(0) : '';
        _depositDate = it.depositDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
        _expectedDate = it.expectedDate;
        _hasPaidBalance = it.isCompletedBalance;
        if (it.isCompletedBalance) {
          _balancePriceController.text = it.balancePrice > 0 ? it.balancePrice.toStringAsFixed(0) : '';
          _balanceDate = it.balanceDate;
        }
      } else {
        _fullPriceController.text = it.fullPrice > 0 ? it.fullPrice.toStringAsFixed(0) : '';
        _purchaseDate = it.depositDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      }

      // 已绑定的饰品
      for (final a in it.associatedAccessories) {
        if (a.id != null) _selectedAccessoryIds.add(a.id!);
      }
      return;
    }

    // 2. 新增模式智能默认项
    if (_category == AppConstants.categoryLolita) {
      _subCategory = AppConstants.lolitaSubCategories.first;
      _isDepositType = true;
    } else {
      _subCategory = AppConstants.earthSubCategories.first;
      _isDepositType = false;
    }

    // 3. 若从心愿单预填带入
    if (widget.prefilledWishlistItem != null) {
      final wish = widget.prefilledWishlistItem!;
      _nameController.text = wish.name;
      if (wish.shopName != null) _shopNameController.text = wish.shopName!;
      if (wish.budgetPrice > 0) {
        _fullPriceController.text = wish.budgetPrice.toStringAsFixed(0);
        _depositPriceController.text = (wish.budgetPrice * 0.4).toStringAsFixed(0);
      }
      _imagePath = wish.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _colorController.dispose();
    _customSizeController.dispose();
    _fullPriceController.dispose();
    _depositPriceController.dispose();
    _balancePriceController.dispose();
    super.dispose();
  }

  Future<void> _loadAccessories() async {
    final list = await _dbHelper.getAllAccessories();
    if (mounted) {
      setState(() => _allAccessories = list);
    }
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

  void _onCategoryChanged(String newCat) {
    setState(() {
      _category = newCat;
      if (newCat == AppConstants.categoryLolita) {
        _subCategory = AppConstants.lolitaSubCategories.first;
        _isDepositType = true;
      } else {
        _subCategory = AppConstants.earthSubCategories.first;
        _isDepositType = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLolita = _category == AppConstants.categoryLolita;
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
          isEditMode
              ? '修改单品档案 ୨୧'
              : (widget.prefilledWishlistItem != null ? '心愿单入库 · 录入衣物 ୨୧' : '录入新衣物 ୨୧'),
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
              _buildCategorySwitcher(),
              const SizedBox(height: 16),
              _buildGeneralInfoCard(isLolita),
              const SizedBox(height: 16),
              if (isLolita) _buildLolitaPricingCard() else _buildEarthPricingCard(),
              const SizedBox(height: 16),
              _buildAccessoryPickerSection(),
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
          width: 220,
          height: 270,
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
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(File(_imagePath!), fit: BoxFit.cover),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 36)),
                                  SizedBox(height: 8),
                                  Text('点击拍摄或上传照片', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
                                  SizedBox(height: 4),
                                  Text('自动本地 1080p 优化归档', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 10)),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'FUWAFUWA POLAROID ୨୧',
                style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
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
              const Text('选取单品相片 ୨୧', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _buildCategorySwitcher() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: FuwaColors.apricotCream, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          _buildCategorySwitchTab(title: 'Lolita 洋装 ୨୧', categoryKey: AppConstants.categoryLolita),
          _buildCategorySwitchTab(title: '地球人常服', categoryKey: AppConstants.categoryEarth),
        ],
      ),
    );
  }

  Widget _buildCategorySwitchTab({required String title, required String categoryKey}) {
    final isSelected = _category == categoryKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onCategoryChanged(categoryKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? FuwaColors.pureWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected ? [BoxShadow(color: FuwaColors.softGlowPink.withOpacity(0.5), blurRadius: 6, offset: const Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? FuwaColors.balletPink : FuwaColors.mutedRosyBrown,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard(bool isLolita) {
    final subCategories = isLolita ? AppConstants.lolitaSubCategories : AppConstants.earthSubCategories;

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
          const Text('基本档案', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _buildTextInput(
            label: '单品名称 *',
            hint: isLolita ? '如：原版琥珀心 OP' : '如：法式碎花裙 / 针织开衫',
            controller: _nameController,
            validator: (v) => (v == null || v.trim().isEmpty) ? '请输入单品名称' : null,
          ),
          const SizedBox(height: 14),

          _buildTextInput(
            label: '购买店铺 / 品牌',
            hint: isLolita ? '如：玻璃花信 / Baby / AP' : '如：Snidel / Zara / 淘宝原创店',
            controller: _shopNameController,
          ),
          const SizedBox(height: 14),

          const Text('颜色标签', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ['生成色', '黑色', '绀色', '蓝色', '绿色', '紫色'].map((c) {
              final isSel = _colorController.text == c;
              return ChoiceChip(
                label: Text(c),
                selected: isSel,
                onSelected: (selected) {
                  setState(() {
                    _colorController.text = selected ? c : '';
                  });
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
          const SizedBox(height: 8),
          _buildTextInput(
            label: '手写或修改具体颜色',
            hint: '如：生成色 / 绀色 / 薄荷绿 / 薰衣草紫 等',
            controller: _colorController,
          ),

          const SizedBox(height: 14),
          const Text('服装子类目', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subCategories.map((subCat) {
              final isSel = _subCategory == subCat;
              return ChoiceChip(
                label: Text(subCat),
                selected: isSel,
                onSelected: (selected) {
                  if (selected) setState(() => _subCategory = subCat);
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

          const SizedBox(height: 16),

          // 服装尺码选择（XS/S/M/L/均码/手写其他）
          const Text('服装尺码', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.clothingSizes.map((s) {
              final isSel = _size == s;
              return ChoiceChip(
                label: Text(s),
                selected: isSel,
                onSelected: (selected) {
                  if (selected) setState(() => _size = s);
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

          if (_size == '其他') ...[
            const SizedBox(height: 10),
            _buildTextInput(
              label: '手写填入具体尺码',
              hint: '如：XL / 定制量体尺码 / 38码 等',
              controller: _customSizeController,
            ),
          ],

          if (!isLolita) ...[
            const SizedBox(height: 14),
            const Text('适用季节', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.seasons.map((s) {
                final isSel = _season == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: isSel,
                  onSelected: (selected) {
                    if (selected) setState(() => _season = s);
                  },
                  selectedColor: FuwaColors.balletPink,
                  backgroundColor: FuwaColors.creamWhite,
                  labelStyle: TextStyle(color: isSel ? Colors.white : FuwaColors.chocolateDark, fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isSel ? FuwaColors.balletPink : FuwaColors.subtleBorder),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLolitaPricingCard() {
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
              const Text('付款与工期模式 ୨୧', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  _buildMiniTypeOption(title: '定金尾款制', isSelected: _isDepositType, onTap: () => setState(() => _isDepositType = true)),
                  const SizedBox(width: 8),
                  _buildMiniTypeOption(title: '现货全款', isSelected: !_isDepositType, onTap: () => setState(() => _isDepositType = false)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isDepositType) ...[
            Row(
              children: [
                Expanded(
                  child: _buildNumberInput(
                    label: '定金金额 (元) *',
                    hint: '如 300',
                    controller: _depositPriceController,
                    validator: (v) => (_isDepositType && (v == null || v.trim().isEmpty)) ? '请输入定金' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePickerField(
                    label: '定金支付日期',
                    currentDate: _depositDate,
                    onDatePicked: (dt) => setState(() => _depositDate = dt),
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('尾款已结清出货', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('未开启则自动记入【待补款】与工期等待天数', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 10)),
                    ],
                  ),
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
                      hint: '如 450',
                      controller: _balancePriceController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePickerField(
                      label: '尾款支付日期',
                      currentDate: _balanceDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      onDatePicked: (dt) => setState(() => _balanceDate = dt),
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildNumberInput(
                    label: '全款金额 (元) *',
                    hint: '如 780',
                    controller: _fullPriceController,
                    validator: (v) => (!_isDepositType && (v == null || v.trim().isEmpty)) ? '请输入金额' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePickerField(
                    label: '购买支付日期',
                    currentDate: _purchaseDate,
                    onDatePicked: (dt) => setState(() => _purchaseDate = dt),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarthPricingCard() {
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
          const Text('价格与购买信息', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  label: '购买金额 (元) *',
                  hint: '如 299',
                  controller: _fullPriceController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? '请输入金额' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerField(
                  label: '购买日期',
                  currentDate: _purchaseDate,
                  onDatePicked: (dt) => setState(() => _purchaseDate = dt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessoryPickerSection() {
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
              const Text('预选搭配饰品 ୨୧', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('已勾选 ${_selectedAccessoryIds.length} 件', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          if (_allAccessories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('小物库暂无饰品，录入后可随时在单品详情补配 ୨୧', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allAccessories.map((acc) {
                final isSelected = _selectedAccessoryIds.contains(acc.id);
                return FilterChip(
                  label: Text('${acc.name} (${acc.accessoryType})'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAccessoryIds.add(acc.id!);
                      } else {
                        _selectedAccessoryIds.remove(acc.id!);
                      }
                    });
                  },
                  selectedColor: FuwaColors.apricotCream,
                  checkmarkColor: FuwaColors.balletPink,
                  backgroundColor: FuwaColors.creamWhite,
                  labelStyle: TextStyle(
                    color: isSelected ? FuwaColors.chocolateDark : FuwaColors.mutedRosyBrown,
                    fontSize: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isSelected ? FuwaColors.balletPink : FuwaColors.subtleBorder),
                  ),
                );
              }).toList(),
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
          onPressed: _saveItem,
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
                isEditMode ? '保存修改档案 ୨୧' : '保存至我的衣柜 ୨୧',
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

  Widget _buildMiniTypeOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
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

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final isLolita = _category == AppConstants.categoryLolita;
    final fullPrice = double.tryParse(_fullPriceController.text.trim()) ?? 0.0;
    final depositPrice = double.tryParse(_depositPriceController.text.trim()) ?? 0.0;
    final balancePrice = double.tryParse(_balancePriceController.text.trim()) ?? 0.0;
    final shopNameText = _shopNameController.text.trim();
    final colorText = _colorController.text.trim();

    final sizeVal = _size == '其他'
        ? (_customSizeController.text.trim().isNotEmpty ? _customSizeController.text.trim() : '其他')
        : _size;

    final itemData = Item(
      id: widget.itemToEdit?.id, // 若为编辑模式保留原有 id
      category: _category,
      subCategory: _subCategory,
      name: _nameController.text.trim(),
      imagePath: _imagePath,
      color: colorText.isNotEmpty ? colorText : null,
      size: sizeVal,
      season: isLolita ? null : _season,
      shopName: shopNameText.isNotEmpty ? shopNameText : null,
      isDepositType: isLolita && _isDepositType,
      fullPrice: (!isLolita || !_isDepositType) ? fullPrice : 0.0,
      depositPrice: (isLolita && _isDepositType) ? depositPrice : 0.0,
      depositDate: (isLolita && _isDepositType) ? _depositDate : _purchaseDate,
      balancePrice: (isLolita && _isDepositType && _hasPaidBalance) ? balancePrice : 0.0,
      balanceDate: (isLolita && _isDepositType && _hasPaidBalance) ? _balanceDate : null,
      expectedDate: (isLolita && _isDepositType) ? _expectedDate : null,
    );

    if (widget.itemToEdit != null) {
      // 执行修改更新
      await _dbHelper.updateItem(
        itemData,
        accessoryIds: _selectedAccessoryIds.toList(),
      );
    } else {
      // 执行新增录入
      await _dbHelper.insertItem(
        itemData,
        accessoryIds: _selectedAccessoryIds.toList(),
      );
    }

    if (mounted) {
      widget.onItemAdded?.call();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: FuwaColors.balletPink,
          content: Text(widget.itemToEdit != null ? '单品档案已成功修改 ୨୧' : '轻飘飘的单品已收入衣柜 ୨୧'),
        ),
      );
    }
  }
}
