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
import 'item_detail_screen.dart';

/// Tab 2: 小物箱 (`AccessoriesScreen`)
/// 严格遵循甘系（Sweet Lolita）视觉设计规范：
/// - 独立网格展示所有小物（KC/BNT/手袖/鞋/袜/包等）
/// - 横向胶囊类型过滤
/// - 单击查看详情与已绑定的裙子单品列表
/// - 优雅半屏快速录入新小物
class AccessoriesScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const AccessoriesScreen({super.key, this.onDataChanged});

  @override
  State<AccessoriesScreen> createState() => _AccessoriesScreenState();
}

class _AccessoriesScreenState extends State<AccessoriesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImageStorageService _imageService = ImageStorageService.instance;

  String _selectedType = '全部';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Accessory> _accessories = [];
  Map<int, int> _boundCounts = {}; // accessoryId -> bound items count
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccessories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 从 SQLite 本地数据库加载所有小物及绑定数量
  Future<void> _loadAccessories() async {
    setState(() => _isLoading = true);

    try {
      final list = await _dbHelper.getAllAccessories(
        accessoryType: _selectedType == '全部' ? null : _selectedType,
        searchQuery: _searchQuery,
      );

      // 查询每个小物的绑定单品数量
      final Map<int, int> counts = {};
      for (final acc in list) {
        if (acc.id != null) {
          final items = await _dbHelper.getItemsForAccessory(acc.id!);
          counts[acc.id!] = items.length;
        }
      }

      if (mounted) {
        setState(() {
          _accessories = list;
          _boundCounts = counts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FuwaColors.creamWhite,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. 顶部标题栏与搜索
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '小物箱 ୨୧',
                                style: TextStyle(
                                  color: FuwaColors.chocolateDark,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'KC、BNT、手袖与搭配小物件',
                                style: TextStyle(
                                  color: FuwaColors.mutedRosyBrown,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          // 录入新小物快捷按钮
                          GestureDetector(
                            onTap: () => _showAddAccessorySheet(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: FuwaColors.balletPink,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: FuwaColors.balletPink.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    FuwaColors.ribbonSymbol,
                                    style: TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '添置小物',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 搜索框
                      _buildSearchField(),
                    ],
                  ),
                ),
              ),

              // 2. 小物分类胶囊横向滚动栏
              SliverToBoxAdapter(
                child: _buildTypeFilterBar(),
              ),
            ];
          },
          body: RefreshIndicator(
            color: FuwaColors.balletPink,
            backgroundColor: FuwaColors.pureWhite,
            onRefresh: _loadAccessories,
            child: _buildGridContent(),
          ),
        ),
      ),
    );
  }

  /// 搜索框
  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: FuwaColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: FuwaColors.softCardShadow,
        border: Border.all(color: FuwaColors.subtleBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: FuwaColors.mutedRosyBrown,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              cursorColor: FuwaColors.balletPink,
              style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 13),
              decoration: const InputDecoration(
                hintText: '搜索小物名称...',
                hintStyle: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                _searchQuery = val;
                _loadAccessories();
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _searchQuery = '';
                _loadAccessories();
              },
              child: const Icon(
                Icons.cancel_rounded,
                size: 18,
                color: FuwaColors.mutedRosyBrown,
              ),
            ),
        ],
      ),
    );
  }

  /// 类型过滤胶囊栏
  Widget _buildTypeFilterBar() {
    final types = ['全部', ...AppConstants.accessoryTypes];

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final t = types[index];
          final isSelected = _selectedType == t;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedType = t);
              _loadAccessories();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? FuwaColors.balletPink : FuwaColors.pureWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? FuwaColors.balletPink : FuwaColors.subtleBorder,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: FuwaColors.balletPink.withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                t,
                style: TextStyle(
                  color: isSelected ? Colors.white : FuwaColors.chocolateDark,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 核心网格内容
  Widget _buildGridContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: FuwaColors.balletPink),
      );
    }

    if (_accessories.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: _accessories.length,
      itemBuilder: (context, index) {
        final acc = _accessories[index];
        final boundCount = _boundCounts[acc.id] ?? 0;

        return _buildAccessoryItemCard(acc, boundCount);
      },
    );
  }

  /// 单个小物拍立得质感卡片
  Widget _buildAccessoryItemCard(Accessory acc, int boundCount) {
    return GestureDetector(
      onTap: () => _showAccessoryDetailModal(acc),
      child: Container(
        decoration: BoxDecoration(
          color: FuwaColors.pureWhite,
          borderRadius: FuwaColors.roundedCardRadius,
          boxShadow: FuwaColors.softCardShadow,
          border: Border.all(color: FuwaColors.subtleBorder),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片与类型标签
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: FuwaColors.creamWhite,
                      child: acc.imagePath != null && File(acc.imagePath!).existsSync()
                          ? Image.file(File(acc.imagePath!), fit: BoxFit.cover)
                          : const Center(
                              child: Text(
                                FuwaColors.ribbonSymbol,
                                style: TextStyle(
                                  color: FuwaColors.balletPink,
                                  fontSize: 30,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // 类型浮标
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: FuwaColors.pureWhite.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        acc.accessoryType,
                        style: const TextStyle(
                          color: FuwaColors.chocolateDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 名称
            Text(
              acc.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FuwaColors.chocolateDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 4),

            // 价格与搭配裙子数
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '¥',
                        style: TextStyle(
                          color: FuwaColors.chocolateDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: acc.price.toStringAsFixed(0),
                        style: const TextStyle(
                          color: FuwaColors.chocolateDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: boundCount > 0 ? FuwaColors.apricotCream : FuwaColors.creamWhite,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    boundCount > 0 ? '配 $boundCount 条' : '未搭配',
                    style: TextStyle(
                      color: boundCount > 0 ? FuwaColors.chocolateDark : FuwaColors.mutedRosyBrown,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 小物箱空状态
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: FuwaColors.pureWhite,
              borderRadius: FuwaColors.roundedCardRadius,
              boxShadow: FuwaColors.softCardShadow,
              border: Border.all(color: FuwaColors.subtleBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  FuwaColors.ribbonSymbol,
                  style: TextStyle(
                    color: FuwaColors.balletPink,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '小物箱空空如也 ୨୧',
                  style: TextStyle(
                    color: FuwaColors.chocolateDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '快来收纳第一顶 KC、手袖或优雅的 BNT 吧～',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FuwaColors.mutedRosyBrown,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showAddAccessorySheet(),
                  icon: const Text(
                    FuwaColors.ribbonSymbol,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  label: const Text(
                    '录入新小物',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FuwaColors.balletPink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 小物详情与已绑定裙子弹窗
  // ==========================================

  /// 单击查看小物详情与已绑定的裙子列表
  Future<void> _showAccessoryDetailModal(Accessory acc) async {
    final boundItems = await _dbHelper.getItemsForAccessory(acc.id!);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: FuwaColors.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部操作栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FuwaColors.apricotCream,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          acc.accessoryType,
                          style: const TextStyle(
                            color: FuwaColors.chocolateDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        acc.name,
                        style: const TextStyle(
                          color: FuwaColors.chocolateDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // 删除小物按钮
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: FuwaColors.balletPink),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _deleteAccessory(acc);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: FuwaColors.mutedRosyBrown),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 小物主要属性信息卡片
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: FuwaColors.creamWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FuwaColors.subtleBorder),
                ),
                child: Row(
                  children: [
                    // 照片预览
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 70,
                        height: 70,
                        color: FuwaColors.pureWhite,
                        child: acc.imagePath != null && File(acc.imagePath!).existsSync()
                            ? Image.file(File(acc.imagePath!), fit: BoxFit.cover)
                            : const Center(
                                child: Text(
                                  FuwaColors.ribbonSymbol,
                                  style: TextStyle(color: FuwaColors.balletPink, fontSize: 24),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '购入金额：¥${acc.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: FuwaColors.chocolateDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '购入日期：${acc.purchaseDate ?? '未记录'}',
                            style: const TextStyle(
                              color: FuwaColors.mutedRosyBrown,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '已用于搭配 ${boundItems.length} 条裙装',
                            style: const TextStyle(
                              color: FuwaColors.balletPink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 已绑定的裙子列表标题
              const Text(
                '已绑定的搭配裙装 ୨୧',
                style: TextStyle(
                  color: FuwaColors.chocolateDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              if (boundItems.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      '该小物尚未绑定任何单品裙装\n可在衣服详情页点击【搭配管理】进行一键绑定 ୨୧',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12, height: 1.5),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: boundItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = boundItems[index];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailScreen(
                                itemId: item.id!,
                                onDataChanged: _loadAccessories,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: FuwaColors.creamWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: FuwaColors.subtleBorder),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  color: FuwaColors.pureWhite,
                                  child: item.imagePath != null && File(item.imagePath!).existsSync()
                                      ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                                      : const Center(
                                          child: Text(
                                            FuwaColors.ribbonSymbol,
                                            style: TextStyle(color: FuwaColors.balletPink, fontSize: 16),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: FuwaColors.chocolateDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${item.isLolita ? 'Lolita' : '地球人'} · ${item.subCategory}',
                                      style: const TextStyle(
                                        color: FuwaColors.mutedRosyBrown,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: FuwaColors.mutedRosyBrown,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 快速录入新小物抽屉
  // ==========================================

  Future<void> _showAddAccessorySheet() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String selectedType = AppConstants.accessoryTypes.first;
    String purchaseDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String? imagePath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
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
                          '添置新小物 ୨୧',
                          style: TextStyle(
                            color: FuwaColors.chocolateDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: FuwaColors.mutedRosyBrown),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 图片选取
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final path = await _imageService.pickAndSaveImage(source: ImageSource.gallery);
                          if (path != null) {
                            setSheetState(() => imagePath = path);
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
                          child: imagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(File(imagePath!), fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      FuwaColors.ribbonSymbol,
                                      style: TextStyle(color: FuwaColors.balletPink, fontSize: 24),
                                    ),
                                    Text(
                                      '选照片',
                                      style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 10),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 小物名称
                    const Text(
                      '小物名称 *',
                      style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: FuwaColors.creamWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: FuwaColors.subtleBorder),
                      ),
                      child: TextField(
                        controller: nameCtrl,
                        cursorColor: FuwaColors.balletPink,
                        style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: '如：草莓蕾丝 KC / 珍珠手袖',
                          hintStyle: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 小物类型单选
                    const Text(
                      '小物类型',
                      style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: AppConstants.accessoryTypes.map((t) {
                        final isSel = selectedType == t;
                        return ChoiceChip(
                          label: Text(t),
                          selected: isSel,
                          onSelected: (sel) {
                            if (sel) setSheetState(() => selectedType = t);
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
                            side: BorderSide(
                              color: isSel ? FuwaColors.balletPink : FuwaColors.subtleBorder,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    // 价格与日期
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '价格 (元)',
                                style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: FuwaColors.creamWhite,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: FuwaColors.subtleBorder),
                                ),
                                child: TextField(
                                  controller: priceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  cursorColor: FuwaColors.balletPink,
                                  style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 14),
                                  decoration: const InputDecoration(
                                    hintText: '如 128',
                                    hintStyle: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13),
                                    border: InputBorder.none,
                                  ),
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
                              const Text(
                                '购买日期',
                                style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
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
                                    setSheetState(() {
                                      purchaseDate = DateFormat('yyyy-MM-dd').format(picked);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: FuwaColors.creamWhite,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: FuwaColors.subtleBorder),
                                  ),
                                  child: Text(
                                    purchaseDate,
                                    style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 保存按钮
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                          final newAcc = Accessory(
                            name: nameCtrl.text.trim(),
                            imagePath: imagePath,
                            accessoryType: selectedType,
                            price: price,
                            purchaseDate: purchaseDate,
                          );
                          await _dbHelper.insertAccessory(newAcc);
                          if (mounted) {
                            Navigator.pop(ctx);
                            _loadAccessories();
                            widget.onDataChanged?.call();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: FuwaColors.balletPink,
                                content: Text('新小物已收入小物箱 ୨୧'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FuwaColors.balletPink,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text(
                          '收入小物箱 ୨୧',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 删除小物确认
  Future<void> _deleteAccessory(Accessory acc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuwaColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '移除小物？',
          style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '确定要从衣柜中删除「${acc.name}」吗？与单品的搭配关联将自动解除。',
          style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('保留', style: TextStyle(color: FuwaColors.mutedRosyBrown)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FuwaColors.balletPink,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('确认删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _dbHelper.deleteAccessory(acc.id!);
      _loadAccessories();
      widget.onDataChanged?.call();
    }
  }
}
