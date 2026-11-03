import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/models/item.dart';
import 'fuwa_animations.dart';

/// 拍立得相纸质感卡片（Polaroid Card）
/// 严格遵循甘系（Sweet Lolita）视觉设计规范：
/// - 纯白卡片底色 + 微粉柔光投影 (r: 22px)
/// - 拍立得相纸相框宽裕留白（已加大底边距防局促）
/// - 右上角悬浮金平糖金微光呼吸徽章（FuwaPulseBadge）
/// - 巧克力深棕标题与价格，杜绝纯黑
class PolaroidCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;

  const PolaroidCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FuwaBounceCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: FuwaColors.pureWhite,
          borderRadius: FuwaColors.roundedCardRadius,
          boxShadow: FuwaColors.softCardShadow,
          border: Border.all(
            color: FuwaColors.subtleBorder,
            width: 1.0,
          ),
        ),
        // 增大底边距至 18px，相纸留白更从容
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拍立得相片主体与悬浮胶囊
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 0.88,
                    child: _buildImageContent(),
                  ),
                ),

                // 右上角工期/等待时长悬浮胶囊（Lolita 专用）
                if (item.isDepositType && item.durationBadgeText != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: item.isPendingBalance
                        ? FuwaPulseBadge(
                            glowColor: FuwaColors.sugarCandyGold,
                            child: _buildDurationBadge(),
                          )
                        : _buildDurationBadge(),
                  ),

                // 地球人季节/类型标签
                if (item.isEarth && item.season != null && item.season!.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: FuwaColors.pureWhite.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.season!,
                        style: const TextStyle(
                          color: FuwaColors.mutedRosyBrown,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // 单品名称（巧克力深棕）
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FuwaColors.chocolateDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 4),

            // 店铺/品牌或子类目
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: FuwaColors.apricotCream,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.subCategory,
                    style: const TextStyle(
                      color: FuwaColors.chocolateDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item.color != null && item.color!.trim().isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: FuwaColors.paleRose,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.color!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FuwaColors.strawberryPink,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (item.shopName != null && item.shopName!.trim().isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.shopName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FuwaColors.mutedRosyBrown,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 6),

            // 价格与支付模式
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '¥',
                        style: TextStyle(
                          color: FuwaColors.chocolateDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: item.totalCost.toStringAsFixed(0),
                        style: const TextStyle(
                          color: FuwaColors.chocolateDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  item.isDepositType
                      ? (item.isPendingBalance ? '待补款' : '已补款')
                      : '现货全款',
                  style: TextStyle(
                    color: item.isPendingBalance
                        ? FuwaColors.sugarCandyGold
                        : FuwaColors.mutedRosyBrown,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      final file = File(item.imagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: FuwaColors.creamWhite,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              FuwaColors.ribbonSymbol,
              style: TextStyle(
                fontSize: 28,
                color: FuwaColors.balletPink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.isLolita ? 'Lolita Dress' : 'Earth Item',
              style: const TextStyle(
                color: FuwaColors.mutedRosyBrown,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationBadge() {
    final isPending = item.isPendingBalance;
    final badgeColor = isPending ? FuwaColors.sugarCandyGold : FuwaColors.balletPink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            FuwaColors.ribbonSymbol,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            item.durationBadgeText ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
