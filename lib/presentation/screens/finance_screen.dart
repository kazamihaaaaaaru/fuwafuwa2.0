import 'package:flutter/material.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/finance_record.dart';

/// Tab 4: 记账看板 (`FinanceScreen`)
/// 严格遵循甘系（Sweet Lolita）视觉设计规范：
/// - 顶部资产总额与待补尾款金平糖金预警看板
/// - 支出分类进度占比（Lolita vs 地球人 vs 小物）
/// - 支持按月份胶囊过滤，选定月份顶部显眼展示当月支出总额、笔数与占比
/// - 支出金额一律采用优雅柔和的 ¥278（绝无负号减号）
class FinanceScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const FinanceScreen({super.key, this.onDataChanged});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  FinanceSummary _summary = const FinanceSummary();
  List<FinanceRecord> _timeline = [];
  String _selectedMonthFilter = '全部';
  List<String> _availableMonths = ['全部'];
  double _selectedMonthTotal = 0.0;
  int _selectedMonthCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    setState(() => _isLoading = true);

    try {
      final summary = await _dbHelper.getFinanceSummary();
      final allRecords = await _dbHelper.getFinanceTimeline();

      final monthsSet = <String>{};
      for (final r in allRecords) {
        if (r.date.length >= 7) {
          monthsSet.add(r.date.substring(0, 7));
        }
      }
      final sortedMonths = monthsSet.toList()..sort((a, b) => b.compareTo(a));

      final filteredRecords = (_selectedMonthFilter == '全部')
          ? allRecords
          : allRecords.where((r) => r.date.startsWith(_selectedMonthFilter)).toList();

      double mTotal = 0.0;
      for (final r in filteredRecords) {
        mTotal += r.amount;
      }

      if (mounted) {
        setState(() {
          _summary = summary;
          _timeline = filteredRecords;
          _availableMonths = ['全部', ...sortedMonths];
          _selectedMonthTotal = mTotal;
          _selectedMonthCount = filteredRecords.length;
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
        child: RefreshIndicator(
          color: FuwaColors.balletPink,
          backgroundColor: FuwaColors.pureWhite,
          onRefresh: _loadFinanceData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: FuwaColors.balletPink))
              : CustomScrollView(
                  slivers: [
                    // 1. 顶部艺术标题区
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '记账看板 ୨୧',
                              style: TextStyle(
                                color: FuwaColors.chocolateDark,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '每一次心动与少女梦的真切记录',
                              style: TextStyle(
                                color: FuwaColors.mutedRosyBrown,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. 顶部双资产统计卡（衣柜总资产 + 待补尾款预警）
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildTopAssetCards(),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    // 3. 支出分类进度占比卡片
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildCategoryBreakdownCard(),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 18)),

                    // 4. 扣款流水月份筛选胶囊
                    SliverToBoxAdapter(
                      child: _buildMonthFilterBar(),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 10)),

                    // 5. 选定月份专属统计高亮卡片（方式 A）
                    if (_selectedMonthFilter != '全部')
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _buildMonthHighlightCard(),
                        ),
                      ),

                    // 6. 扣款流水时间线列表（纯正数优雅展示）
                    _buildTimelineSliverList(),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
        ),
      ),
    );
  }

  /// 方式 A：当月总支出高亮卡片
  Widget _buildMonthHighlightCard() {
    final yearMonthParts = _selectedMonthFilter.split('-');
    final label = yearMonthParts.length == 2
        ? '${yearMonthParts[0]}年${yearMonthParts[1]}月'
        : _selectedMonthFilter;

    final pct = _summary.totalWardrobeAsset > 0
        ? ((_selectedMonthTotal / _summary.totalWardrobeAsset) * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FuwaColors.apricotCream.withOpacity(0.55),
        borderRadius: FuwaColors.roundedCardRadius,
        border: Border.all(color: FuwaColors.balletPink.withOpacity(0.35)),
        boxShadow: FuwaColors.softCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    FuwaColors.ribbonSymbol,
                    style: TextStyle(color: FuwaColors.balletPink, fontSize: 11),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$label具体支出总额',
                    style: const TextStyle(
                      color: FuwaColors.chocolateDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '共记 $_selectedMonthCount 笔实际扣款 · 占累计总额 $pct%',
                style: const TextStyle(
                  color: FuwaColors.mutedRosyBrown,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          // 纯正数展示，绝无负号
          Text(
            '¥${_selectedMonthTotal.toStringAsFixed(0)}',
            style: const TextStyle(
              color: FuwaColors.chocolateDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAssetCards() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(16),
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
                  children: const [
                    Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 12)),
                    SizedBox(width: 4),
                    Text('衣柜总资产', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '¥',
                        style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: _summary.totalWardrobeAsset.toStringAsFixed(0),
                        style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text('已累计投入金额', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FuwaColors.sugarCandyGold.withOpacity(0.08),
              borderRadius: FuwaColors.roundedCardRadius,
              border: Border.all(color: FuwaColors.sugarCandyGold.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: FuwaColors.sugarCandyGold, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('待补尾款', style: TextStyle(color: FuwaColors.sugarCandyGold, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_summary.pendingBalanceCount} 件',
                  style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  _summary.pendingBalanceEstimate > 0 ? '约 ¥${_summary.pendingBalanceEstimate.toStringAsFixed(0)}' : '工期等待中',
                  style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdownCard() {
    final lolitaRatio = _summary.lolitaRatio;
    final earthRatio = _summary.earthRatio;
    final accRatio = _summary.accessoryRatio;

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
            children: const [
              Text('支出分类分布', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('三大体系占比 ୨୧', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (lolitaRatio > 0)
                    Expanded(flex: (lolitaRatio * 1000).toInt(), child: Container(color: FuwaColors.balletPink)),
                  if (earthRatio > 0)
                    Expanded(flex: (earthRatio * 1000).toInt(), child: Container(color: FuwaColors.sugarCandyGold)),
                  if (accRatio > 0)
                    Expanded(flex: (accRatio * 1000).toInt(), child: Container(color: const Color(0xFFC798A6))),
                  if (_summary.totalWardrobeAsset == 0)
                    Expanded(child: Container(color: FuwaColors.creamWhite)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(title: 'Lolita 洋装', color: FuwaColors.balletPink, amount: _summary.lolitaTotal, percentage: (lolitaRatio * 100).toStringAsFixed(1)),
              _buildLegendItem(title: '地球人常服', color: FuwaColors.sugarCandyGold, amount: _summary.earthTotal, percentage: (earthRatio * 100).toStringAsFixed(1)),
              _buildLegendItem(title: '搭配饰品', color: const Color(0xFFC798A6), amount: _summary.accessoryTotal, percentage: (accRatio * 100).toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required String title, required Color color, required double amount, required String percentage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text('¥${amount.toStringAsFixed(0)}', style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
        Text('$percentage%', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 10)),
      ],
    );
  }

  Widget _buildMonthFilterBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _availableMonths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final m = _availableMonths[index];
          final isSelected = _selectedMonthFilter == m;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedMonthFilter = m);
              _loadFinanceData();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? FuwaColors.balletPink : FuwaColors.pureWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isSelected ? FuwaColors.balletPink : FuwaColors.subtleBorder),
                boxShadow: isSelected
                    ? [BoxShadow(color: FuwaColors.balletPink.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2))]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                m == '全部' ? '全部明细' : m,
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

  Widget _buildTimelineSliverList() {
    if (_timeline.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              children: [
                Text(FuwaColors.ribbonSymbol, style: TextStyle(color: FuwaColors.balletPink, fontSize: 32)),
                SizedBox(height: 8),
                Text('当前筛选区间暂无扣款流水 ୨୧', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final record = _timeline[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildTransactionTile(record),
            );
          },
          childCount: _timeline.length,
        ),
      ),
    );
  }

  Widget _buildTransactionTile(FinanceRecord record) {
    Color typeBgColor;
    Color typeTextColor;

    switch (record.paymentType) {
      case '定金':
        typeBgColor = FuwaColors.balletPink.withOpacity(0.12);
        typeTextColor = FuwaColors.balletPink;
        break;
      case '尾款':
        typeBgColor = FuwaColors.sugarCandyGold.withOpacity(0.15);
        typeTextColor = FuwaColors.sugarCandyGold;
        break;
      case '小物':
        typeBgColor = FuwaColors.apricotCream;
        typeTextColor = FuwaColors.chocolateDark;
        break;
      case '全款':
      default:
        typeBgColor = FuwaColors.creamWhite;
        typeTextColor = FuwaColors.chocolateDark;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: FuwaColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: FuwaColors.softCardShadow,
        border: Border.all(color: FuwaColors.subtleBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: typeBgColor, borderRadius: BorderRadius.circular(8)),
            child: Text(record.paymentType, style: TextStyle(color: typeTextColor, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text('实际支付日：${record.date}', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11)),
              ],
            ),
          ),
          // 纯正数显示，绝无负号
          Text(
            '¥${record.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: FuwaColors.chocolateDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
