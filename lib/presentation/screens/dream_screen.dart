import 'package:flutter/material.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';

/// Tab 4: 少女梦境与关于 (`DreamScreen`)
/// 致敬《下妻物语》：“在廉价的生活里做着轻飘飘的少女梦”
class DreamScreen extends StatefulWidget {
  const DreamScreen({super.key});

  @override
  State<DreamScreen> createState() => _DreamScreenState();
}

class _DreamScreenState extends State<DreamScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  int _itemCount = 0;
  int _accCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final items = await _dbHelper.getAllItems();
    final accs = await _dbHelper.getAllAccessories();
    if (mounted) {
      setState(() {
        _itemCount = items.length;
        _accCount = accs.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FuwaColors.creamWhite,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: BoxDecoration(
                color: FuwaColors.pureWhite,
                borderRadius: FuwaColors.roundedCardRadius,
                boxShadow: FuwaColors.softCardShadow,
                border: Border.all(color: FuwaColors.subtleBorder),
              ),
              child: Column(
                children: const [
                  Text(
                    FuwaColors.ribbonSymbol,
                    style: TextStyle(
                      color: FuwaColors.balletPink,
                      fontSize: 40,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'ふわふわ · FuwaFuwa',
                    style: TextStyle(
                      color: FuwaColors.chocolateDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '“在廉价的生活里做着轻飘飘的少女梦”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FuwaColors.mutedRosyBrown,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '—— 电影《下妻物语》',
                    style: TextStyle(
                      color: FuwaColors.balletPink,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    title: '收藏单品',
                    value: '$_itemCount 件',
                    symbol: '୨୧',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStat(
                    title: '搭配小物',
                    value: '$_accCount 件',
                    symbol: '✦',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
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
                  const Text(
                    '纯本地离线运行原则 ୨୧',
                    style: TextStyle(
                      color: FuwaColors.chocolateDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPrincipleRow(
                    icon: Icons.cloud_off_rounded,
                    title: '无云端鉴权 & 零远程调用',
                    desc: '衣物相片与账单数据全部留在手机沙盒，隐私绝对归个人所有。',
                  ),
                  const SizedBox(height: 8),
                  _buildPrincipleRow(
                    icon: Icons.storage_rounded,
                    title: 'SQLite 关系型存储 (fuwafuwa.db)',
                    desc: '外键级联保护，多对多小物自由搭配与解除绑定。',
                  ),
                  const SizedBox(height: 8),
                  _buildPrincipleRow(
                    icon: Icons.photo_size_select_large_rounded,
                    title: '本地相片 1080p 自动优化压缩',
                    desc: '兼顾拍立得高清画质与手机存储空间。',
                  ),
                  const SizedBox(height: 8),
                  _buildPrincipleRow(
                    icon: Icons.favorite_border_rounded,
                    title: '免除穿搭频次记录',
                    desc: '不计算单次穿着成本，让每一件裙子都只为心动而存在。',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'FuwaFuwa Wardrobe v1.0.0 ୨୧ 纯本地版',
                style: TextStyle(
                  color: FuwaColors.mutedRosyBrown,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String title,
    required String value,
    required String symbol,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: FuwaColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: FuwaColors.softCardShadow,
        border: Border.all(color: FuwaColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FuwaColors.mutedRosyBrown,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                symbol,
                style: const TextStyle(
                  color: FuwaColors.balletPink,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: FuwaColors.chocolateDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrincipleRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: FuwaColors.balletPink),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FuwaColors.chocolateDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: FuwaColors.mutedRosyBrown,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
