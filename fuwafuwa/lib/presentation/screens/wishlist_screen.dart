import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/wishlist_item.dart';
import '../widgets/fuwa_animations.dart';
import 'add_screen.dart';
import 'add_wishlist_screen.dart';
import 'add_accessory_screen.dart';

/// Tab 3: 【少女心愿单】(`WishlistScreen`)
/// 严格遵循甘系（Sweet Lolita）视觉设计规范与定制榜单模式：
/// - 采用「心动心愿榜单模式」，支持用户长按/拖拽自由调节榜单排行顺序
/// - 顶部保留【心动 X 件】计数徽章，主标题字号严格与衣柜各专区统一 (24px)
/// - 榜单前三名赋予专属马卡龙金粉奖牌标识（#1 金平糖金、#2 芭蕾粉、#3 杏色）
/// - 支持【转入洋装 / 常服衣柜】与【转入搭配小物箱】双向无缝归档
/// - 支持【拔草】一键清爽移出
class WishlistScreen extends StatefulWidget {
  final VoidCallback? onWardrobeUpdated;

  const WishlistScreen({super.key, this.onWardrobeUpdated});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<WishlistItem> _wishlist = [];
  String _selectedDesireLevel = '全部';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);
    final level = _selectedDesireLevel == '全部' ? null : _selectedDesireLevel;
    final list = await _dbHelper.getAllWishlistItems(desireLevel: level);
    if (mounted) {
      setState(() {
        _wishlist = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final levels = ['全部', ...AppConstants.desireLevels];

    return Scaffold(
      backgroundColor: FuwaColors.creamWhite,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 顶部标题栏（字号、留白与各主页严格统一）
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '少女心愿单 ୨୧',
                        style: TextStyle(
                          color: FuwaColors.chocolateDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '世界和光辉都据为己有好了',
                        style: TextStyle(
                          color: FuwaColors.mutedRosyBrown,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: FuwaColors.pureWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: FuwaColors.softCardShadow,
                      border: Border.all(color: FuwaColors.subtleBorder),
                    ),
                    child: Text(
                      '心动 ${_wishlist.length} 件',
                      style: const TextStyle(
                        color: FuwaColors.chocolateDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 心动等级胶囊筛选栏（高度统一 36px）
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: levels.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final lvl = levels[index];
                  final isSel = _selectedDesireLevel == lvl;
                  Color activeColor;
                  switch (lvl) {
                    case '非入不可 ♡':
                      activeColor = FuwaColors.balletPink;
                      break;
                    case '很心动 ୨୧':
                      activeColor = FuwaColors.sugarCandyGold;
                      break;
                    case '还在观望 ~':
                      activeColor = const Color(0xFFC798A6);
                      break;
                    default:
                      activeColor = FuwaColors.balletPink;
                      break;
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDesireLevel = lvl);
                      _loadWishlist();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? activeColor : FuwaColors.pureWhite,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSel ? activeColor : FuwaColors.subtleBorder,
                        ),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: activeColor.withOpacity(0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        lvl,
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

            const SizedBox(height: 8),

            // 3. 榜单模式（用户可自由拖拽调节排行顺序）
            Expanded(
              child: RefreshIndicator(
                color: FuwaColors.balletPink,
                backgroundColor: FuwaColors.pureWhite,
                onRefresh: _loadWishlist,
                child: _buildWishlistLeaderboard(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  /// 榜单列表视图
  Widget _buildWishlistLeaderboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: FuwaColors.balletPink));
    }

    if (_wishlist.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FuwaBreathingRibbon(
              child: Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 36)),
            ),
            SizedBox(height: 8),
            Text('心愿榜单还是空的呢', style: TextStyle(color: FuwaColors.chocolateDark, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('点击右下角小缎带种草第一件心动单品', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12)),
          ],
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
        itemCount: _wishlist.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _wishlist.removeAt(oldIndex);
            _wishlist.insert(newIndex, item);
          });
          _dbHelper.updateWishlistOrder(_wishlist);
        },
        itemBuilder: (context, index) {
          final item = _wishlist[index];
          return Container(
            key: ValueKey(item.id ?? index),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: FuwaColors.pureWhite,
              borderRadius: FuwaColors.roundedCardRadius,
              boxShadow: FuwaColors.softCardShadow,
              border: Border.all(color: FuwaColors.subtleBorder),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: FuwaColors.roundedCardRadius,
              child: InkWell(
                borderRadius: FuwaColors.roundedCardRadius,
                onTap: () => _showWishlistDetailModal(item),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // 1. 榜单排名徽章
                      _buildRankBadge(index),
                      const SizedBox(width: 10),

                      // 2. 单品方形圆角相片
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 66,
                          height: 66,
                          color: FuwaColors.creamWhite,
                          child: item.imagePath != null && File(item.imagePath!).existsSync()
                              ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                              : const Center(
                                  child: Text(
                                    FuwaColors.ribbonSymbol,
                                    style: TextStyle(color: FuwaColors.balletPink, fontSize: 22),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 3. 单品信息区
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FuwaColors.chocolateDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getDesireBgColor(item.desireLevel),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.desireLevel,
                                    style: TextStyle(
                                      color: _getDesireTextColor(item.desireLevel),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (item.shopName != null && item.shopName!.trim().isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.shopName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  item.budgetPrice > 0 ? '¥${AppConstants.formatPrice(item.budgetPrice)}' : '未定预算',
                                  style: const TextStyle(
                                    color: FuwaColors.chocolateDark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (item.releaseDate != null && item.releaseDate!.trim().isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '· 预计 ${item.releaseDate}',
                                    style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 10),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 4. 右侧拖拽重排手柄
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.drag_indicator_rounded,
                            color: FuwaColors.mutedRosyBrown,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 榜单排名徽章渲染
  Widget _buildRankBadge(int index) {
    if (index == 0) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: FuwaColors.sugarCandyGold,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
      );
    } else if (index == 1) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: FuwaColors.balletPink,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
      );
    } else if (index == 2) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: FuwaColors.seasonAutumn,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
      );
    } else {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: FuwaColors.creamWhite,
          shape: BoxShape.circle,
          border: Border.all(color: FuwaColors.subtleBorder),
        ),
        alignment: Alignment.center,
        child: Text('${index + 1}', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontWeight: FontWeight.w700, fontSize: 11)),
      );
    }
  }

  Color _getDesireBgColor(String level) {
    switch (level) {
      case '非入不可 ♡':
        return FuwaColors.paleRose;
      case '很心动 ୨୧':
        return FuwaColors.apricotCream;
      default:
        return FuwaColors.creamWhite;
    }
  }

  Color _getDesireTextColor(String level) {
    switch (level) {
      case '非入不可 ♡':
        return FuwaColors.strawberryPink;
      case '很心动 ୨୧':
        return FuwaColors.chocolateDark;
      default:
        return FuwaColors.mutedRosyBrown;
    }
  }

  Future<void> _showWishlistDetailModal(WishlistItem item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.70,
        padding: const EdgeInsets.all(22),
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
                        color: _getDesireBgColor(item.desireLevel),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.desireLevel,
                        style: TextStyle(color: _getDesireTextColor(item.desireLevel), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.name,
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
                            builder: (_) => AddWishlistScreen(itemToEdit: item),
                          ),
                        );
                        if (updated == true && mounted) {
                          _loadWishlist();
                        }
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
                      width: 72,
                      height: 72,
                      color: FuwaColors.pureWhite,
                      child: item.imagePath != null && File(item.imagePath!).existsSync()
                          ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                          : const Center(child: Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 26))),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('店家品牌：${item.shopName ?? '未填写'}', style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text('预算金额：¥${AppConstants.formatPrice(item.budgetPrice)}', style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text('预计贩售时间：${item.releaseDate ?? '待定'}', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (item.note != null && item.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FuwaColors.creamWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('心愿便签：${item.note}', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12)),
              ),
            ],

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      _confirmRemoveWishlist(item);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: FuwaColors.subtleBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    child: const Text(
                      '拔草',
                      style: TextStyle(color: FuwaColors.mutedRosyBrown, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      _transferToWardrobe(item);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FuwaColors.balletPink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    child: const Text('转入衣柜 / 小物箱', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _transferToWardrobe(WishlistItem item) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: FuwaColors.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.checkroom_rounded, color: FuwaColors.balletPink, size: 20),
                  SizedBox(width: 8),
                  Text('请选择转入目标', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              Text('准备将心愿单「${item.name}」收纳至何处？', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: FuwaColors.creamWhite,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: FuwaColors.pureWhite, shape: BoxShape.circle, boxShadow: FuwaColors.softCardShadow),
                  child: const Icon(Icons.checkroom_rounded, color: FuwaColors.balletPink, size: 20),
                ),
                title: const Text('转入洋装 / 常服衣柜', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: const Text('归入洋装裙装或日常常服档案', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: FuwaColors.mutedRosyBrown),
                onTap: () => Navigator.pop(ctx, 'wardrobe'),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: FuwaColors.creamWhite,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: FuwaColors.pureWhite, shape: BoxShape.circle, boxShadow: FuwaColors.softCardShadow),
                  child: const Icon(Icons.auto_awesome_rounded, color: FuwaColors.balletPink, size: 20),
                ),
                title: const Text('转入搭配小物箱', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: const Text('归入KC、发带、帽子、手袖等饰品库', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: FuwaColors.mutedRosyBrown),
                onTap: () => Navigator.pop(ctx, 'accessory'),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;

    bool? added;
    if (choice == 'wardrobe') {
      added = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AddScreen(
            prefilledWishlistItem: item,
          ),
        ),
      );
    } else if (choice == 'accessory') {
      added = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AddAccessoryScreen(
            prefilledWishlistItem: item,
          ),
        ),
      );
    }

    if (added == true && mounted) {
      widget.onWardrobeUpdated?.call();
      final remove = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: FuwaColors.pureWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('已成功收纳', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text('已为您建立档案，是否自动从心愿单移出「${item.name}」？', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('保留在心愿单', style: TextStyle(color: FuwaColors.mutedRosyBrown)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: FuwaColors.balletPink,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('移出心愿单', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (remove == true && item.id != null) {
        await _dbHelper.deleteWishlistItem(item.id!);
        _loadWishlist();
      }
    }
  }

  Future<void> _confirmRemoveWishlist(WishlistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuwaColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认拔草？', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('确认要从少女心愿单中移除「${item.name}」吗？', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: FuwaColors.mutedRosyBrown))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: FuwaColors.balletPink, elevation: 0),
            child: const Text('确认拔草', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && item.id != null) {
      await _dbHelper.deleteWishlistItem(item.id!);
      _loadWishlist();
    }
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
          onPressed: () async {
            final added = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const AddWishlistScreen(),
              ),
            );
            if (added == true) _loadWishlist();
          },
          backgroundColor: FuwaColors.balletPink,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: const Text(
            FuwaColors.ribbonSymbol,
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
