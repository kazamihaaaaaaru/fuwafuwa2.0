import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/models/item.dart';
import '../widgets/add_accessory_sheet.dart';
import 'add_screen.dart';
import 'earth_screen.dart';
import 'finance_screen.dart';
import 'item_detail_screen.dart';
import 'lolita_screen.dart';
import 'wishlist_screen.dart';

/// 主脚手架与甘系底部导航栏（`MainScaffold`）
/// 严格遵循甘系（Sweet Lolita）视觉设计规范：
/// - 4 个核心 Tab: 【Lolita ୨୧】| 【地球人】| 【心愿单】| 【记账】
/// - 纯白圆角搭配柔粉微阴影底栏
/// - 全局广播刷新协同机制
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  Key _lolitaKey = UniqueKey();
  Key _earthKey = UniqueKey();
  Key _wishlistKey = UniqueKey();
  Key _financeKey = UniqueKey();

  void _notifyGlobalDataChanged() {
    setState(() {
      _lolitaKey = UniqueKey();
      _earthKey = UniqueKey();
      _wishlistKey = UniqueKey();
      _financeKey = UniqueKey();
    });
  }

  void _openItemDetail(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          itemId: item.id!,
          onDataChanged: _notifyGlobalDataChanged,
        ),
      ),
    );
  }

  void _openAddDressScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddScreen(
          initialCategory: AppConstants.categoryLolita,
          onItemAdded: _notifyGlobalDataChanged,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _openAddEarthScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddScreen(
          initialCategory: AppConstants.categoryEarth,
          onItemAdded: _notifyGlobalDataChanged,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _openAddAccessorySheet() {
    AddAccessorySheet.show(
      context,
      onAdded: _notifyGlobalDataChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FuwaColors.creamWhite,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 1: Lolita ＆ 小物（顶部书签两用）
          LolitaScreen(
            key: _lolitaKey,
            onAddDressTap: _openAddDressScreen,
            onAddAccessoryTap: _openAddAccessorySheet,
            onItemTap: _openItemDetail,
          ),
          // Tab 2: 地球人衣柜（双排交集筛选）
          EarthScreen(
            key: _earthKey,
            onAddTap: _openAddEarthScreen,
            onItemTap: _openItemDetail,
          ),
          // Tab 3: 心愿单（种草与一键转入衣柜）
          WishlistScreen(
            key: _wishlistKey,
            onWardrobeUpdated: _notifyGlobalDataChanged,
          ),
          // Tab 4: 记账看板（月度支出与纯正数流水）
          FinanceScreen(
            key: _financeKey,
            onDataChanged: _notifyGlobalDataChanged,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: FuwaColors.pureWhite,
          boxShadow: FuwaColors.softCardShadow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: FuwaColors.subtleBorder, width: 1.0),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.checkroom_rounded,
                  label: 'Lolita',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.dry_cleaning_rounded,
                  label: '地球人',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.favorite_border_rounded,
                  label: '心愿单',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.account_balance_wallet_outlined,
                  label: '记账',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FuwaColors.apricotCream.withOpacity(0.65) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? FuwaColors.balletPink : FuwaColors.mutedRosyBrown,
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: FuwaColors.chocolateDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                FuwaColors.ribbonSymbol,
                style: TextStyle(
                  color: FuwaColors.balletPink,
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
