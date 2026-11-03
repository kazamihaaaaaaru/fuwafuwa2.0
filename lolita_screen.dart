import 'wardrobe_statistics_screen.dart';
import 'add_accessory_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/accessory.dart';
import '../../data/models/item.dart';
import '../widgets/fuwa_animations.dart';
import '../widgets/polaroid_card.dart';
import 'item_detail_screen.dart';

/// Tab 1: 【Lolita 衣柜】(`LolitaScreen`)
/// 严格遵循甘系（Sweet Lolita）视觉设计规范：
/// - 顶部标题【Lolita 衣柜 ୨୧】与经典标语【在廉价的生活里做着轻飘飘的少女梦】
/// - 标题下方居中大书签横栏【洋装裙装】与【搭配小物】（舒展宽敞，告别局促）
/// - 洋装展示拍立得双列照片墙与子类目胶囊（含 JK、裙撑与内搭独立分类）
/// - 待补尾款单品自动置顶
class LolitaScreen extends StatefulWidget {
  final VoidCallback? onAddDressTap;
  final VoidCallback? onAddAccessoryTap;
  final ValueChanged<Item>? onItemTap;

  const LolitaScreen({
    super.key,
    this.onAddDressTap,
    this.onAddAccessoryTap,
    this.onItemTap,
  });

  @override
  State<LolitaScreen> createState() => _LolitaScreenState();
}




class _LolitaScreenState extends State<LolitaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Future<void> _confirmDeleteAccessory(Accessory acc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuwaColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('移除饰品？', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('确定要将「${acc.name}」从小物箱中删除吗？与裙装的搭配关联将自动解除。', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('保留', style: TextStyle(color: FuwaColors.mutedRosyBrown))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: FuwaColors.balletPink, elevation: 0),
            child: const Text('确认删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _dbHelper.deleteAccessory(acc.id!);
      _loadAccessories();
    }
  }

  // 洋装状态
  List<Item> _dresses = [];
  String _selectedDressSubCat = '全部';
  String _dressSearch = '';
  bool _isLoadingDresses = true;

  // 小物状态
  List<Accessory> _accessories = [];
  Map<int, int> _boundCounts = {};
  String _selectedAccType = '全部';
  String _accSearch = '';
  bool _isLoadingAccessories = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadDresses();
    _loadAccessories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDresses() async {
    setState(() => _isLoadingDresses = true);
    final subCat = _selectedDressSubCat == '全部' ? null : _selectedDressSubCat;
    final list = await _dbHelper.getAllItems(
      category: AppConstants.categoryLolita,
      subCategory: subCat,
      searchQuery: _dressSearch,
    );
    if (mounted) {
      setState(() {
        _dresses = list;
        _isLoadingDresses = false;
      });
    }
  }

  Future<void> _loadAccessories() async {
    setState(() => _isLoadingAccessories = true);
    final list = await _dbHelper.getAllAccessories(
      accessoryType: _selectedAccType == '全部' ? null : _selectedAccType,
      searchQuery: _accSearch,
    );

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
        _isLoadingAccessories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCount = _tabController.index == 0 ? _dresses.length : _accessories.length;

    return Scaffold(
      backgroundColor: FuwaColors.creamWhite,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 顶部艺术标题区与永恒经典名句
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Lolita 衣柜 ୨୧',
                        style: TextStyle(
                          color: FuwaColors.chocolateDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '在廉价的生活里做着轻飘飘的少女梦',
                        style: TextStyle(
                          color: FuwaColors.mutedRosyBrown,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final isDress = _tabController.index == 0;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WardrobeStatisticsScreen(
                                category: isDress ? 'lolita' : 'accessory',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: FuwaColors.pureWhite,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: FuwaColors.softCardShadow,
                            border: Border.all(color: FuwaColors.subtleBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.pie_chart_outline_rounded, size: 14, color: FuwaColors.balletPink),
                              const SizedBox(width: 4),
                              Text(
                                _tabController.index == 0 ? '洋装统计 ୨୧' : '小物统计 ୨୧',
                                style: const TextStyle(
                                  color: FuwaColors.chocolateDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: FuwaColors.pureWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: FuwaColors.softCardShadow,
                          border: Border.all(color: FuwaColors.subtleBorder),
                        ),
                        child: Text(
                          '$currentCount 件',
                          style: const TextStyle(
                            color: FuwaColors.chocolateDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. 居中横置大书签分栏：【洋装裙装】与【搭配小物】（舒展宽敞，告别局促）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: FuwaColors.apricotCream,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    _buildWideBookmarkTab(0, '洋装裙装 ୨୧'),
                    _buildWideBookmarkTab(1, '搭配小物 ୨୧'),
                  ],
                ),
              ),
            ),

            // 3. 双页内容区（洋装裙装 vs 搭配小物）
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDressPageView(),
                  _buildAccessoryPageView(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildWideBookmarkTab(int index, String title) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? FuwaColors.pureWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: FuwaColors.softGlowPink.withOpacity(0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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

  // ==========================================
  // 第一页：洋装裙装（含 JK、裙撑与内搭独立分类）
  // ==========================================

  Widget _buildDressPageView() {
    final subCats = ['全部', ...AppConstants.lolitaSubCategories];

    return RefreshIndicator(
      color: FuwaColors.balletPink,
      backgroundColor: FuwaColors.pureWhite,
      onRefresh: _loadDresses,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: subCats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = subCats[index];
                    final isSel = _selectedDressSubCat == item;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedDressSubCat = item);
                        _loadDresses();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? FuwaColors.balletPink : FuwaColors.pureWhite,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSel ? FuwaColors.balletPink : FuwaColors.subtleBorder,
                          ),
                          boxShadow: isSel
                              ? [BoxShadow(color: FuwaColors.balletPink.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSel ? Colors.white : FuwaColors.chocolateDark,
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          if (_isLoadingDresses)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: FuwaColors.balletPink)),
            )
          else if (_dresses.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 36)),
                    SizedBox(height: 8),
                    Text('还没有收藏 Lolita 洋装 ୨୧', style: TextStyle(color: FuwaColors.chocolateDark, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('点击右下角小缎带开始录入', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.60,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dress = _dresses[index];
                    return PolaroidCard(
                      item: dress,
                      onTap: () {
                        if (widget.onItemTap != null) {
                          widget.onItemTap!(dress);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailScreen(
                                itemId: dress.id!,
                                onDataChanged: _loadDresses,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                  childCount: _dresses.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // 第二页：搭配小物
  // ==========================================

  Widget _buildAccessoryPageView() {
    final accTypes = ['全部', ...AppConstants.accessoryTypes];

    return RefreshIndicator(
      color: FuwaColors.balletPink,
      backgroundColor: FuwaColors.pureWhite,
      onRefresh: _loadAccessories,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: accTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = accTypes[index];
                    final isSel = _selectedAccType == item;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedAccType = item);
                        _loadAccessories();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? FuwaColors.balletPink : FuwaColors.pureWhite,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSel ? FuwaColors.balletPink : FuwaColors.subtleBorder,
                          ),
                          boxShadow: isSel
                              ? [BoxShadow(color: FuwaColors.balletPink.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSel ? Colors.white : FuwaColors.chocolateDark,
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          if (_isLoadingAccessories)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: FuwaColors.balletPink)),
            )
          else if (_accessories.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 36)),
                    SizedBox(height: 8),
                    Text('小物箱里还没有饰品 ୨୧', style: TextStyle(color: FuwaColors.chocolateDark, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('KC、发带、BNT、手袖等待收纳', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final acc = _accessories[index];
                    final count = _boundCounts[acc.id] ?? 0;
                    return _buildAccessoryCard(acc, count);
                  },
                  childCount: _accessories.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccessoryCard(Accessory acc, int boundCount) {
    return FuwaBounceCard(
      onTap: () => _showAccessoryDetail(acc),
      child: Container(
        decoration: BoxDecoration(
          color: FuwaColors.pureWhite,
          borderRadius: FuwaColors.roundedCardRadius,
          boxShadow: FuwaColors.softCardShadow,
          border: Border.all(color: FuwaColors.subtleBorder),
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                                style: TextStyle(color: FuwaColors.balletPink, fontSize: 28),
                              ),
                            ),
                    ),
                  ),
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
                  if (acc.isDepositType && acc.durationBadgeText != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: acc.isPendingBalance ? FuwaColors.sugarCandyGold : FuwaColors.balletPink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          acc.durationBadgeText!,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
            if (acc.shopName != null && acc.shopName!.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                acc.shopName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FuwaColors.mutedRosyBrown,
                  fontSize: 10,
                ),
              ),
            ],
            const SizedBox(height: 4),
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
                        text: acc.totalCost.toStringAsFixed(0),
                        style: const TextStyle(
                          color: FuwaColors.chocolateDark,
                          fontSize: 15,
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

  Future<void> _showAccessoryDetail(Accessory acc) async {
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
                          style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        acc.name,
                        style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: FuwaColors.chocolateDark, size: 20),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => AddAccessoryScreen(accessoryToEdit: acc),
                            ),
                          );
                          if (updated == true && mounted) {
                            _loadAccessories();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: FuwaColors.balletPink, size: 20),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          _confirmDeleteAccessory(acc);
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: FuwaColors.creamWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FuwaColors.subtleBorder),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 70,
                        height: 70,
                        color: FuwaColors.pureWhite,
                        child: acc.imagePath != null && File(acc.imagePath!).existsSync()
                            ? Image.file(File(acc.imagePath!), fit: BoxFit.cover)
                            : const Center(
                                child: Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 24)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '总金额：¥${acc.totalCost.toStringAsFixed(0)}',
                            style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            acc.isDepositType
                                ? (acc.isPendingBalance ? '待补款 · 定金 ¥${acc.depositPrice.toStringAsFixed(0)}' : '已补款 · 工期 ${acc.waitingDays ?? 0} 天')
                                : '现货全款 · ${acc.depositDate ?? ''}',
                            style: TextStyle(
                              color: acc.isPendingBalance ? FuwaColors.sugarCandyGold : FuwaColors.mutedRosyBrown,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (acc.shopName != null && acc.shopName!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('店铺品牌：${acc.shopName!}', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11)),
                          ],
                          const SizedBox(height: 4),
                          Text('已搭配 ${boundItems.length} 条裙装', style: const TextStyle(color: FuwaColors.balletPink, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text('已绑定的搭配裙装 ୨୧', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              if (boundItems.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('该小物尚未绑定任何裙装\n在洋装详情页点击【搭配管理】即可绑定 ୨୧', textAlign: TextAlign.center, style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12)),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: boundItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dress = boundItems[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: FuwaColors.creamWhite,
                        title: Text(dress.name, style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w700)),
                        subtitle: Text('${dress.subCategory} · ¥${dress.totalCost.toStringAsFixed(0)}', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: FuwaColors.mutedRosyBrown),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: dress.id!)),
                          );
                        },
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

  Widget _buildFab() {
    return FuwaBreathingRibbon(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: FuwaColors.balletPink.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddChoiceModal,
          backgroundColor: FuwaColors.balletPink,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: const Text(
            FuwaColors.ribbonSymbol,
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddChoiceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: FuwaColors.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '添置新单品 ୨୧',
                style: TextStyle(
                  color: FuwaColors.chocolateDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '你想为衣柜记录一件新裙子还是精巧饰品？',
                style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceCard(
                      icon: Icons.checkroom_rounded,
                      title: '录入洋装 ୨୧',
                      desc: 'JSK / OP / SK / JK',
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onAddDressTap?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildChoiceCard(
                      icon: Icons.diamond_outlined,
                      title: '录入小物 ୨୧',
                      desc: 'KC / 发带 / BNT / 手袖',
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onAddAccessoryTap?.call();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: FuwaColors.creamWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FuwaColors.subtleBorder),
          boxShadow: FuwaColors.softCardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: FuwaColors.pureWhite,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: FuwaColors.balletPink, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: FuwaColors.chocolateDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(
                color: FuwaColors.mutedRosyBrown,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
