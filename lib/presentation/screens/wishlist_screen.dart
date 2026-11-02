import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/wishlist_item.dart';
import '../widgets/fuwa_animations.dart';
import 'add_screen.dart';
import 'add_wishlist_screen.dart';

/// Tab 3: 全新【心愿单】(`WishlistScreen`)
/// 严格遵循甘系（Sweet Lolita）视觉设计规范：
/// - 胶囊栏与前面页面严格统一尺寸（高 36px，无多余空隙留白）
/// - 记录种草单品、预算、店家、预计贩售月份与心动等级
/// - 支持【转入衣柜 ୨୧】预填无缝流转与自动归档
/// - 支持【拔草】一键清爽删除
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
            // 1. 顶部标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '少女心愿单 ୨୧',
                    style: TextStyle(
                      color: FuwaColors.chocolateDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
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

            // 2. 心动等级胶囊筛选栏（高度统一为 36px，无多余白边空隙，和前序页面视觉严格统一）
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

            const SizedBox(height: 6),

            // 3. 心愿卡片网格照片流
            Expanded(
              child: RefreshIndicator(
                color: FuwaColors.balletPink,
                backgroundColor: FuwaColors.pureWhite,
                onRefresh: _loadWishlist,
                child: _buildWishlistGrid(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildWishlistGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: FuwaColors.balletPink));
    }

    if (_wishlist.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 36)),
            SizedBox(height: 8),
            Text('心愿单还是空的呢 ୨୧', style: TextStyle(color: FuwaColors.chocolateDark, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('点击右下角小缎带种草第一件心动小裙子', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: _wishlist.length,
      itemBuilder: (context, index) {
        final item = _wishlist[index];
        return _buildWishlistCard(item);
      },
    );
  }

  Widget _buildWishlistCard(WishlistItem item) {
    Color levelColor;
    switch (item.desireLevel) {
      case '非入不可 ♡':
        levelColor = FuwaColors.balletPink;
        break;
      case '很心动 ୨୧':
        levelColor = FuwaColors.sugarCandyGold;
        break;
      default:
        levelColor = const Color(0xFFC798A6);
        break;
    }

    return FuwaBounceCard(
      onTap: () => _showWishlistDetailModal(item),
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
                      child: item.imagePath != null && File(item.imagePath!).existsSync()
                          ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                          : const Center(
                              child: Text(
                                FuwaColors.ribbonSymbol,
                                style: TextStyle(color: FuwaColors.balletPink, fontSize: 30),
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
                        color: levelColor.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.desireLevel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FuwaColors.chocolateDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                if (item.shopName != null && item.shopName!.isNotEmpty) ...[
                  Expanded(
                    child: Text(
                      item.shopName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11),
                    ),
                  ),
                ],
                if (item.releaseDate != null && item.releaseDate!.isNotEmpty)
                  Text(
                    '${item.releaseDate} 出',
                    style: const TextStyle(color: FuwaColors.sugarCandyGold, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.budgetPrice > 0 ? '预算 ¥${item.budgetPrice.toStringAsFixed(0)}' : '未定预算',
              style: const TextStyle(
                color: FuwaColors.chocolateDark,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
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
                        color: FuwaColors.apricotCream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.desireLevel,
                        style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.name,
                      style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: FuwaColors.mutedRosyBrown),
                  onPressed: () => Navigator.pop(ctx),
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
                        Text('预算金额：¥${item.budgetPrice.toStringAsFixed(0)}', style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w700)),
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(FuwaColors.ribbonSymbol, style: TextStyle(color: Colors.white, fontSize: 12)),
                        SizedBox(width: 6),
                        Text('转入衣柜 ୨୧', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
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

  Future<void> _transferToWardrobe(WishlistItem item) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddScreen(
          prefilledWishlistItem: item,
        ),
      ),
    );

    if (added == true && mounted) {
      widget.onWardrobeUpdated?.call();
      final remove = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: FuwaColors.pureWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('已成功收纳进衣柜 ୨୧', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text('已为您在衣柜中建立档案，是否自动从心愿单移出「${item.name}」？', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13)),
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

      if (remove == true) {
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
        title: const Text('确认拔草此单品？', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('确定要将「${item.name}」从心愿单拔草移除吗？', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('再想想', style: TextStyle(color: FuwaColors.mutedRosyBrown))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: FuwaColors.balletPink, elevation: 0),
            child: const Text('确定拔草', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteWishlistItem(item.id!);
      _loadWishlist();
    }
  }

  Widget _buildFab() {
    return FuwaBreathingRibbon(
      child: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => AddWishlistScreen(onAdded: _loadWishlist),
            ),
          );
        },
        backgroundColor: FuwaColors.balletPink,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Text(FuwaColors.ribbonSymbol, style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
