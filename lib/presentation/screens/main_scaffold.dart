import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/models/item.dart';
import 'add_accessory_screen.dart';
import 'add_screen.dart';
import 'earth_screen.dart';
import 'finance_screen.dart';
import 'item_detail_screen.dart';
import 'lolita_screen.dart';
import 'wishlist_screen.dart';

/// 主脚手架与甘系底部导航栏（`MainScaffold`）
/// 严格遵循甘系（Sweet Lolita）视觉设计规范：
/// - Lolita 采用专属优雅蝴蝶结图标（与主视觉小缎带区分）
/// - 地球人采用典雅衣架图标（Icons.checkroom_rounded）
/// - 4 个核心 Tab: 【Lolita】| 【地球人】| 【心愿单】| 【记账】
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

  void _openAddAccessoryScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddAccessoryScreen(
          onAdded: _notifyGlobalDataChanged,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FuwaColors.creamWhite,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LolitaScreen(
            key: _lolitaKey,
            onAddDressTap: _openAddDressScreen,
            onAddAccessoryTap: _openAddAccessoryScreen,
            onItemTap: _openItemDetail,
          ),
          EarthScreen(
            key: _earthKey,
            onAddTap: _openAddEarthScreen,
            onItemTap: _openItemDetail,
          ),
          WishlistScreen(
            key: _wishlistKey,
            onWardrobeUpdated: _notifyGlobalDataChanged,
          ),
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
                // 1. Lolita 专属蝴蝶结图标
                _buildNavItem(
                  index: 0,
                  customIcon: (color) => BowIcon(size: 20, color: color),
                  label: 'Lolita',
                ),
                // 2. 地球人衣柜衣架图标
                _buildNavItem(
                  index: 1,
                  systemIcon: Icons.checkroom_rounded,
                  label: '地球人',
                ),
                // 3. 心愿单爱心图标
                _buildNavItem(
                  index: 2,
                  systemIcon: Icons.favorite_border_rounded,
                  label: '心愿单',
                ),
                // 4. 记账看板钱包图标
                _buildNavItem(
                  index: 3,
                  systemIcon: Icons.account_balance_wallet_outlined,
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
    IconData? systemIcon,
    Widget Function(Color color)? customIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? FuwaColors.balletPink : FuwaColors.mutedRosyBrown;

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
            if (customIcon != null)
              customIcon(color)
            else if (systemIcon != null)
              Icon(systemIcon, size: 21, color: color),
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

/// Lolita 专属蝴蝶结图标组件（独立绘制，区分主视觉小缎带）
class BowIcon extends StatelessWidget {
  final double size;
  final Color color;

  const BowIcon({super.key, this.size = 20, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BowPainter(color),
    );
  }
}

class _BowPainter extends CustomPainter {
  final Color color;
  _BowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.44;

    // 左侧蝴蝶结环
    final leftPath = Path()
      ..moveTo(cx - 1.5, cy)
      ..cubicTo(cx - w * 0.48, cy - h * 0.38, cx - w * 0.48, cy + h * 0.38, cx - 1.5, cy)
      ..close();
    canvas.drawPath(leftPath, paint);

    // 右侧蝴蝶结环
    final rightPath = Path()
      ..moveTo(cx + 1.5, cy)
      ..cubicTo(cx + w * 0.48, cy - h * 0.38, cx + w * 0.48, cy + h * 0.38, cx + 1.5, cy)
      ..close();
    canvas.drawPath(rightPath, paint);

    // 中间蝴蝶结绳结
    canvas.drawCircle(Offset(cx, cy), w * 0.12, paint);

    // 左侧飘带
    final leftTail = Path()
      ..moveTo(cx - 1.5, cy + 2)
      ..lineTo(cx - w * 0.28, h * 0.94)
      ..lineTo(cx - w * 0.12, h * 0.94)
      ..close();
    canvas.drawPath(leftTail, paint);

    // 右侧飘带
    final rightTail = Path()
      ..moveTo(cx + 1.5, cy + 2)
      ..lineTo(cx + w * 0.28, h * 0.94)
      ..lineTo(cx + w * 0.12, h * 0.94)
      ..close();
    canvas.drawPath(rightTail, paint);
  }

  @override
  bool shouldRepaint(covariant _BowPainter oldDelegate) => oldDelegate.color != color;
}
