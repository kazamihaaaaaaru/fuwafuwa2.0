import '../../core/constants/app_constants.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/accessory.dart';
import '../../data/models/item.dart';
import '../widgets/fuwa_animations.dart';
import '../widgets/polaroid_card.dart';
import 'item_detail_screen.dart';

/// 各专区独立全屏衣橱多维统计页面 (`WardrobeStatisticsScreen`)
/// 严格遵循甘系（Sweet Lolita）视觉设计规范：
/// - 草莓奶霜底色（#FDF8F9），去一切突兀黑边
/// - 原生 CustomPainter 绘制甘系梦幻甜甜圈饼状图，直观展现多维分布
/// - 微光胶囊比例条与数值清单
/// - 选定标签即刻联动下方拍立得照片墙（可点击查看单品详情）
class WardrobeStatisticsScreen extends StatefulWidget {
  final String category; // 'lolita' | 'accessory' | 'earth'

  const WardrobeStatisticsScreen({
    super.key,
    required this.category,
  });

  @override
  State<WardrobeStatisticsScreen> createState() => _WardrobeStatisticsScreenState();
}

class _WardrobeStatisticsScreenState extends State<WardrobeStatisticsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isLoading = true;
  List<Item> _items = [];
  List<Accessory> _accessories = [];

  // 维度选项定义
  late final List<String> _dimensionOptions;
  String _selectedDimension = '类型';
  String? _selectedFilterValue; // 当前选中的饼图扇区/过滤标签（为空则显示全部）

  // 甜系马卡龙配色板，用于饼状图各个扇区
  static const List<Color> _pieColors = [
    Color(0xFFF299AC), // 芭蕾舞鞋粉
    Color(0xFF89C4F4), // 冰蓝
    Color(0xFFFFDAC1), // 奶杏
    Color(0xFFB5EAD7), // 薄荷马卡龙
    Color(0xFFE2D4F0), // 丁香紫
    Color(0xFFFCF6BD), // 香草奶黄
    Color(0xFFFF9AA2), // 草莓柔光
    Color(0xFFC7CEEA), // 浅灰蓝
    Color(0xFFD4A373), // 优雅焦糖
    Color(0xFFB7B7A4), // 浅雾灰
  ];

  @override
  void initState() {
    super.initState();
    _initDimensions();
    _loadData();
  }

  void _initDimensions() {
    if (widget.category == 'earth') {
      // 常服：类型、年份、颜色、季节、状态
      _dimensionOptions = ['类型', '年份', '颜色', '季节', '状态'];
    } else if (widget.category == 'lolita') {
      // 洋装：类型、年份、颜色、状态、店铺/品牌
      _dimensionOptions = ['类型', '年份', '颜色', '状态', '店铺/品牌'];
    } else {
      // 小物：类型、年份、状态、店铺/品牌（无颜色）
      _dimensionOptions = ['类型', '年份', '颜色', '状态', '店铺/品牌'];
    }
    _selectedDimension = _dimensionOptions.first;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    if (widget.category == 'accessory') {
      final list = await _dbHelper.getAllAccessories();
      if (mounted) {
        setState(() {
          _accessories = list;
          _isLoading = false;
        });
      }
    } else {
      final list = await _dbHelper.getAllItems(category: widget.category);
      if (mounted) {
        setState(() {
          _items = list;
          _isLoading = false;
        });
      }
    }
  }

  String get _pageTitle {
    switch (widget.category) {
      case 'lolita':
        return '洋装衣橱统计';
      case 'accessory':
        return '小物收藏统计';
      case 'earth':
      default:
        return '常服衣橱统计';
    }
  }

  /// 提取单品的指定维度取值
  String _getItemDimensionValue(Item item, String dimension) {
    switch (dimension) {
      case '类型':
        return item.subCategory;
      case '年份':
        final d = item.depositDate ?? item.balanceDate;
        if (d != null && d.length >= 4) return '${d.substring(0, 4)}年';
        return '未记录年份';
      case '颜色':
        return (item.color != null && item.color!.trim().isNotEmpty) ? item.color!.trim() : '未标颜色';
      case '季节':
        return (item.season != null && item.season!.trim().isNotEmpty) ? item.season!.trim() : '四季通用';
      case '状态':
        return item.isDepositType
            ? (item.isPendingBalance ? '待补尾款' : '已补款出货')
            : '现货全款';
      case '店铺/品牌':
        return (item.shopName != null && item.shopName!.trim().isNotEmpty) ? item.shopName!.trim() : '未填店铺';
      default:
        return '其他';
    }
  }

  /// 提取饰品的指定维度取值
  String _getAccessoryDimensionValue(Accessory acc, String dimension) {
    switch (dimension) {
      case '类型':
        return acc.accessoryType;
      case '年份':
        final d = acc.depositDate ?? acc.balanceDate;
        if (d != null && d.length >= 4) return '${d.substring(0, 4)}年';
        return '未记录年份';
      case '颜色':
        return (acc.color != null && acc.color!.trim().isNotEmpty) ? acc.color!.trim() : '未标颜色';
      case '状态':
        return acc.isDepositType
            ? (acc.isPendingBalance ? '待补尾款' : '已补款出货')
            : '现货全款';
      case '店铺/品牌':
        return (acc.shopName != null && acc.shopName!.trim().isNotEmpty) ? acc.shopName!.trim() : '未填店铺';
      default:
        return '其他';
    }
  }

  /// 统计聚合计算
  Map<String, int> _computeDistribution() {
    final Map<String, int> result = {};

    if (widget.category == 'accessory') {
      for (final a in _accessories) {
        final val = _getAccessoryDimensionValue(a, _selectedDimension);
        result[val] = (result[val] ?? 0) + 1;
      }
    } else {
      for (final it in _items) {
        final val = _getItemDimensionValue(it, _selectedDimension);
        result[val] = (result[val] ?? 0) + 1;
      }
    }

    // 按数量降序排序
    final sortedEntries = result.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  /// 获取当前筛选下的单品列表
  List<Item> get _filteredItems {
    if (_selectedFilterValue == null) return _items;
    return _items.where((it) => _getItemDimensionValue(it, _selectedDimension) == _selectedFilterValue).toList();
  }

  /// 获取当前筛选下的小物列表
  List<Accessory> get _filteredAccessories {
    if (_selectedFilterValue == null) return _accessories;
    return _accessories.where((a) => _getAccessoryDimensionValue(a, _selectedDimension) == _selectedFilterValue).toList();
  }

  int get _totalCount {
    return widget.category == 'accessory' ? _accessories.length : _items.length;
  }

  @override
  Widget build(BuildContext context) {
    final distribution = _computeDistribution();

    return Scaffold(
      backgroundColor: FuwaColors.creamWhite,
      appBar: AppBar(
        backgroundColor: FuwaColors.creamWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: FuwaColors.pureWhite,
              shape: BoxShape.circle,
              boxShadow: FuwaColors.softCardShadow,
              border: Border.all(color: FuwaColors.subtleBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: FuwaColors.chocolateDark, size: 16),
          ),
        ),
        title: Text(
          _pageTitle,
          style: const TextStyle(
            color: FuwaColors.chocolateDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FuwaColors.balletPink))
          : CustomScrollView(
              slivers: [
                // 1. 维度切换胶囊横条
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _buildDimensionBar(),
                  ),
                ),

                // 2. 统计图表核心卡片（甘系甜甜圈饼状图 + 微光胶囊列表）
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildChartAndCapsuleCard(distribution),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 3. 联动照片墙标题栏
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildWallHeader(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // 4. 联动照片墙拍立得网格
                _buildPhotoWall(),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  /// 维度切换横条
  Widget _buildDimensionBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _dimensionOptions.map((dim) {
          final isSel = _selectedDimension == dim;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDimension = dim;
                _selectedFilterValue = null; // 切换维度时重置过滤
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? FuwaColors.balletPink : FuwaColors.pureWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSel
                    ? [BoxShadow(color: FuwaColors.balletPink.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2))]
                    : FuwaColors.softCardShadow,
                border: Border.all(
                  color: isSel ? FuwaColors.balletPink : FuwaColors.subtleBorder,
                ),
              ),
              child: Text(
                dim,
                style: TextStyle(
                  color: isSel ? Colors.white : FuwaColors.chocolateDark,
                  fontSize: 13,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 饼状图 + 微光胶囊卡片
  Widget _buildChartAndCapsuleCard(Map<String, int> distribution) {
    if (_totalCount == 0) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: FuwaColors.pureWhite,
          borderRadius: FuwaColors.roundedCardRadius,
          boxShadow: FuwaColors.softCardShadow,
          border: Border.all(color: FuwaColors.subtleBorder),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 32)),
              SizedBox(height: 8),
              Text('衣橱里暂无该分类的单品', style: TextStyle(color: FuwaColors.chocolateDark, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }

    final entries = distribution.entries.toList();

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
              Row(
                children: [
                  const Icon(Icons.pie_chart_rounded, size: 16, color: FuwaColors.balletPink),
                  const SizedBox(width: 6),
                  Text(
                    '$_selectedDimension分布大盘',
                    style: const TextStyle(
                      color: FuwaColors.chocolateDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                '共 $_totalCount 件单品',
                style: const TextStyle(
                  color: FuwaColors.mutedRosyBrown,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 核心：自绘甘系甜甜圈饼状图
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: CustomPaint(
                painter: _FuwaDonutChartPainter(
                  distribution: distribution,
                  total: _totalCount,
                  colors: _pieColors,
                  selectedKey: _selectedFilterValue,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedFilterValue != null
                            ? '${distribution[_selectedFilterValue] ?? 0}'
                            : '$_totalCount',
                        style: const TextStyle(
                          color: FuwaColors.chocolateDark,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _selectedFilterValue ?? '总收纳数',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FuwaColors.mutedRosyBrown,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: FuwaColors.creamWhite, height: 1),
          const SizedBox(height: 14),

          // 微光胶囊与水平条状图列表
          Column(
            children: List.generate(entries.length, (idx) {
              final e = entries[idx];
              final color = _pieColors[idx % _pieColors.length];
              final isSel = _selectedFilterValue == e.key;
              final pct = (_totalCount > 0) ? (e.value / _totalCount) : 0.0;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedFilterValue == e.key) {
                      _selectedFilterValue = null; // 再次点击取消选中
                    } else {
                      _selectedFilterValue = e.key;
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? FuwaColors.apricotCream.withOpacity(0.55) : FuwaColors.creamWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSel ? FuwaColors.balletPink : FuwaColors.subtleBorder,
                      width: isSel ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                e.key,
                                style: TextStyle(
                                  color: FuwaColors.chocolateDark,
                                  fontSize: 13,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${e.value} 件 (${(pct * 100).toStringAsFixed(1)}%)',
                            style: TextStyle(
                              color: isSel ? FuwaColors.strawberryPink : FuwaColors.mutedRosyBrown,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: FuwaColors.pureWhite,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 照片墙标题与筛选重置
  Widget _buildWallHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              FuwaColors.ribbonSymbol,
              style: TextStyle(color: FuwaColors.balletPink, fontSize: 13),
            ),
            const SizedBox(width: 6),
            Text(
              _selectedFilterValue != null
                  ? '【$_selectedFilterValue】归档收纳'
                  : '全部归档单品',
              style: const TextStyle(
                color: FuwaColors.chocolateDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (_selectedFilterValue != null)
          GestureDetector(
            onTap: () => setState(() => _selectedFilterValue = null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: FuwaColors.pureWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FuwaColors.subtleBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 12, color: FuwaColors.balletPink),
                  SizedBox(width: 4),
                  Text('查看全部', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 照片墙网格
  Widget _buildPhotoWall() {
    if (widget.category == 'accessory') {
      final list = _filteredAccessories;
      if (list.isEmpty) {
        return const SliverFillRemaining(
          child: Center(
            child: Text('当前分类下暂无饰品', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13)),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final acc = list[index];
              return _buildAccessoryMiniCard(acc);
            },
            childCount: list.length,
          ),
        ),
      );
    } else {
      final list = _filteredItems;
      if (list.isEmpty) {
        return const SliverFillRemaining(
          child: Center(
            child: Text('当前分类下暂无衣物', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13)),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.64,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final it = list[index];
              return PolaroidCard(
                item: it,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(
                        itemId: it.id!,
                        onDataChanged: _loadData,
                      ),
                    ),
                  );
                },
              );
            },
            childCount: list.length,
          ),
        ),
      );
    }
  }

  Widget _buildAccessoryMiniCard(Accessory acc) {
    return Container(
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
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: FuwaColors.creamWhite,
                width: double.infinity,
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
              Text(
                '¥${AppConstants.formatPrice(acc.totalCost)}',
                style: const TextStyle(
                  color: FuwaColors.chocolateDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: FuwaColors.apricotCream,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  acc.accessoryType,
                  style: const TextStyle(
                    color: FuwaColors.chocolateDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 自绘甘系甜甜圈饼状图 CustomPainter
class _FuwaDonutChartPainter extends CustomPainter {
  final Map<String, int> distribution;
  final int total;
  final List<Color> colors;
  final String? selectedKey;

  _FuwaDonutChartPainter({
    required this.distribution,
    required this.total,
    required this.colors,
    this.selectedKey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.62; // 甜甜圈内径
    final strokeWidth = outerRadius - innerRadius;

    final rect = Rect.fromCircle(center: center, radius: (outerRadius + innerRadius) / 2);

    double startAngle = -math.pi / 2; // 从正上方 12 点钟开始绘制
    int idx = 0;

    for (final entry in distribution.entries) {
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final isSelected = selectedKey == entry.key;

      final paint = Paint()
        ..color = colors[idx % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth + 4 : strokeWidth
        ..isAntiAlias = true;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      // 分隔线微光缝隙
      final dividerPaint = Paint()
        ..color = FuwaColors.pureWhite
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..isAntiAlias = true;

      canvas.drawArc(rect, startAngle, 0.03, false, dividerPaint);

      startAngle += sweepAngle;
      idx++;
    }
  }

  @override
  bool shouldRepaint(covariant _FuwaDonutChartPainter oldDelegate) {
    return oldDelegate.distribution != distribution ||
        oldDelegate.total != total ||
        oldDelegate.selectedKey != selectedKey;
  }
}
