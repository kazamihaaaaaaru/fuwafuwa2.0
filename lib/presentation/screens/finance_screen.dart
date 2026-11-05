import '../../core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/finance_record.dart';
import '../widgets/backup_dialog.dart';

/// Tab 4: 记账看板 (`FinanceScreen`)
/// 严格遵循甘系（Sweet）视觉设计规范：
/// - 顶部年份大 Tab 切换（支持【全部年份】与具体某一年，如 2026、2025）
/// - 全部年份模式：总资产大盘、分类占比、历年支出总结对比条形图与全局流水
/// - 选定具体年份模式：该年年度大盘（年总支出、月均支出、笔数、分类占比）、月度水平条状图（点击联动过滤当月明细）
/// - 纯正数优雅展示（绝无负号减号）
class FinanceScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const FinanceScreen({super.key, this.onDataChanged});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  FinanceSummary _summary = const FinanceSummary();
  List<FinanceRecord> _allRecords = [];
  bool _isLoading = true;

  // 年份与月份过滤状态
  String _selectedYear = '全部年份';
  List<String> _availableYears = ['全部年份'];

  String _selectedMonth = '全部月份'; // 在选定具体年份时，进一步按月过滤
  List<String> _availableMonthsInYear = ['全部月份'];

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    setState(() => _isLoading = true);

    try {
      final summary = await _dbHelper.getFinanceSummary();
      final records = await _dbHelper.getFinanceTimeline();

      // 提取可用年份
      final yearsSet = <String>{};
      for (final r in records) {
        if (r.date.length >= 4) {
          yearsSet.add(r.date.substring(0, 4));
        }
      }
      final sortedYears = yearsSet.toList()..sort((a, b) => b.compareTo(a));

      if (mounted) {
        setState(() {
          _summary = summary;
          _allRecords = records;
          _availableYears = ['全部年份', ...sortedYears];
          _isLoading = false;
        });
        _updateAvailableMonths();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 根据选定年份更新该年份下的可用月份
  void _updateAvailableMonths() {
    if (_selectedYear == '全部年份') {
      setState(() {
        _selectedMonth = '全部月份';
        _availableMonthsInYear = ['全部月份'];
      });
      return;
    }

    final monthsSet = <String>{};
    for (final r in _allRecords) {
      if (r.date.startsWith(_selectedYear) && r.date.length >= 7) {
        monthsSet.add(r.date.substring(5, 7)); // e.g. "11", "10"
      }
    }
    final sortedMonths = monthsSet.toList()..sort((a, b) => b.compareTo(a));

    setState(() {
      _availableMonthsInYear = ['全部月份', ...sortedMonths.map((m) => '$m月')];
      _selectedMonth = '全部月份';
    });
  }

  /// 当前生效的流水列表
  List<FinanceRecord> get _displayedTimeline {
    return _allRecords.where((r) {
      // 1. 年份过滤
      if (_selectedYear != '全部年份') {
        if (!r.date.startsWith(_selectedYear)) return false;

        // 2. 月份过滤
        if (_selectedMonth != '全部月份') {
          final mStr = _selectedMonth.replaceAll('月', '');
          final targetPrefix = '$_selectedYear-$mStr';
          if (!r.date.startsWith(targetPrefix)) return false;
        }
      }
      return true;
    }).toList();
  }

  /// 计算历年汇总数据（用于全部年份下的历年条形对比）
  Map<String, double> get _yearlyTotals {
    final Map<String, double> map = {};
    for (final r in _allRecords) {
      if (r.date.length >= 4) {
        final yr = r.date.substring(0, 4);
        map[yr] = (map[yr] ?? 0.0) + r.amount;
      }
    }
    final sortedEntries = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sortedEntries);
  }

  /// 计算选定年份下各个月份的汇总（用于具体某年的月度水平条状图）
  Map<String, double> get _monthlyTotalsInSelectedYear {
    if (_selectedYear == '全部年份') return {};
    final Map<String, double> map = {};
    for (final r in _allRecords) {
      if (r.date.startsWith(_selectedYear) && r.date.length >= 7) {
        final m = '${r.date.substring(5, 7)}月';
        map[m] = (map[m] ?? 0.0) + r.amount;
      }
    }
    final sortedEntries = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sortedEntries);
  }

  /// 选定年份的各项统计总和
  double get _selectedYearTotal {
    if (_selectedYear == '全部年份') return _summary.totalWardrobeAsset;
    double t = 0.0;
    for (final r in _allRecords) {
      if (r.date.startsWith(_selectedYear)) {
        t += r.amount;
      }
    }
    return t;
  }

  int get _selectedYearCount {
    if (_selectedYear == '全部年份') return _allRecords.length;
    return _allRecords.where((r) => r.date.startsWith(_selectedYear)).length;
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
                    // 1. 顶部艺术标题与数据迁移按钮
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: _buildHeader(),
                      ),
                    ),

                    // 2. 顶部年份大 Tab 切换栏（可切换全部年份与具体某一年）
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: _buildYearTabBar(),
                      ),
                    ),

                    // 3. 根据是否选择全部年份，展现对应看板
                    if (_selectedYear == '全部年份') ...[
                      // 全部年份：总资产大盘 + 待补款预警
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildTopAssetCards(),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),

                      // 支出分类进度占比卡片
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildCategoryBreakdownCard(),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),

                      // 历年支出对比水平条形图
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildYearlyComparisonCard(),
                        ),
                      ),
                    ] else ...[
                      // 具体某一年：年度大盘总结卡片
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildYearSummaryCard(),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),

                      // 月度条状图与月份细分卡片
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildMonthlyBarChartCard(),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 18)),

                    // 4. 流水时间线标题
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
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
                                  _selectedYear == '全部年份'
                                      ? '历年支出流水明细'
                                      : '$_selectedYear年${_selectedMonth != '全部月份' ? _selectedMonth : ''}支出流水',
                                  style: const TextStyle(
                                    color: FuwaColors.chocolateDark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '共 ${_displayedTimeline.length} 笔',
                              style: const TextStyle(
                                color: FuwaColors.mutedRosyBrown,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 10)),

                    // 5. 扣款流水列表
                    _buildTimelineSliverList(),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
        ),
      ),
    );
  }

  /// 顶部艺术标题区
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '记账看板 ୨୧',
              style: TextStyle(
                color: FuwaColors.chocolateDark,
                fontSize: 24,
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
        GestureDetector(
          onTap: () => BackupDialog.show(
            context,
            onRestored: () {
              _loadFinanceData();
              widget.onDataChanged?.call();
            },
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: FuwaColors.pureWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: FuwaColors.subtleBorder),
              boxShadow: FuwaColors.softCardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.swap_horiz_rounded, size: 16, color: FuwaColors.balletPink),
                SizedBox(width: 4),
                Text(
                  '备份与迁移',
                  style: TextStyle(
                    color: FuwaColors.chocolateDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 顶部年份切换大 Tab 栏
  Widget _buildYearTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _availableYears.map((yr) {
          final isSel = _selectedYear == yr;
          final title = yr == '全部年份' ? yr : '$yr年';

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedYear = yr;
              });
              _updateAvailableMonths();
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
                border: Border.all(color: isSel ? FuwaColors.balletPink : FuwaColors.subtleBorder),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: isSel ? Colors.white : FuwaColors.chocolateDark,
                  fontSize: 13,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 双资产统计卡（衣柜总资产 + 待补尾款预警）
  Widget _buildTopAssetCards() {
    return Row(
      children: [
        Expanded(
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
                    Icon(Icons.checkroom_rounded, size: 14, color: FuwaColors.balletPink),
                    SizedBox(width: 4),
                    Text('衣柜总资产', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(text: '¥', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
                      TextSpan(
                        text: AppConstants.formatPrice(_summary.totalWardrobeAsset),
                        style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FuwaColors.pureWhite,
              borderRadius: FuwaColors.roundedCardRadius,
              boxShadow: FuwaColors.softCardShadow,
              border: Border.all(
                color: _summary.pendingBalanceTotal > 0 ? FuwaColors.sugarCandyGold.withOpacity(0.5) : FuwaColors.subtleBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: _summary.pendingBalanceTotal > 0 ? FuwaColors.sugarCandyGold : FuwaColors.mutedRosyBrown),
                    const SizedBox(width: 4),
                    const Text('待补尾款预警', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '¥',
                        style: TextStyle(
                          color: _summary.pendingBalanceTotal > 0 ? FuwaColors.sugarCandyGold : FuwaColors.chocolateDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: AppConstants.formatPrice(_summary.pendingBalanceTotal),
                        style: TextStyle(
                          color: _summary.pendingBalanceTotal > 0 ? FuwaColors.sugarCandyGold : FuwaColors.chocolateDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 支出分类进度占比卡片
  Widget _buildCategoryBreakdownCard() {
    final lolitaPct = _summary.totalWardrobeAsset > 0 ? _summary.lolitaTotal / _summary.totalWardrobeAsset : 0.0;
    final earthPct = _summary.totalWardrobeAsset > 0 ? _summary.earthTotal / _summary.totalWardrobeAsset : 0.0;
    final accPct = _summary.totalWardrobeAsset > 0 ? _summary.accessoryTotal / _summary.totalWardrobeAsset : 0.0;

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
              Text('支出分类大盘', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('洋装 · 常服 · 小物', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          _buildProgressRow(title: '洋装专区', amount: _summary.lolitaTotal, pct: lolitaPct, color: FuwaColors.balletPink),
          const SizedBox(height: 10),
          _buildProgressRow(title: '地球人专区', amount: _summary.earthTotal, pct: earthPct, color: FuwaColors.iceBlue),
          const SizedBox(height: 10),
          _buildProgressRow(title: '搭配小物', amount: _summary.accessoryTotal, pct: accPct, color: FuwaColors.apricotCream),
        ],
      ),
    );
  }

  Widget _buildProgressRow({required String title, required double amount, required double pct, required Color color}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w600)),
            Text('¥${AppConstants.formatPrice(amount)} (${(pct * 100).toStringAsFixed(1)}%)', style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: FuwaColors.creamWhite,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  /// 历年支出总结对比条形图卡片（全部年份模式下）
  Widget _buildYearlyComparisonCard() {
    final yearly = _yearlyTotals;
    final maxAmount = yearly.values.fold<double>(1.0, (prev, val) => val > prev ? val : prev);

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
              Text('历年支出总结对比', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w800)),
              Text('点击切换具体年份', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          if (yearly.isEmpty)
            const Text('暂无历年支出记录', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12))
          else
            Column(
              children: yearly.entries.map((entry) {
                final yr = entry.key;
                final amt = entry.value;
                final pct = (maxAmount > 0) ? (amt / maxAmount) : 0.0;
                final count = _allRecords.where((r) => r.date.startsWith(yr)).length;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedYear = yr;
                    });
                    _updateAvailableMonths();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: FuwaColors.creamWhite,
                      borderRadius: BorderRadius.circular(14),
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
                                Text('$yr 年', style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w800)),
                                const SizedBox(width: 6),
                                Text('$count 笔', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11)),
                              ],
                            ),
                            Text('¥${AppConstants.formatPrice(amt)}', style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: FuwaColors.pureWhite,
                            valueColor: const AlwaysStoppedAnimation<Color>(FuwaColors.balletPink),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// 具体年份的年度总结大卡片
  Widget _buildYearSummaryCard() {
    final yearTotal = _selectedYearTotal;
    final yearCount = _selectedYearCount;
    final monthlyAvg = yearTotal / 12.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FuwaColors.pureWhite,
        borderRadius: FuwaColors.roundedCardRadius,
        boxShadow: FuwaColors.softCardShadow,
        border: Border.all(color: FuwaColors.balletPink.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_selectedYear 年度总结看板',
                style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FuwaColors.balletPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$yearCount 笔支出', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('年度总支出', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('¥${AppConstants.formatPrice(yearTotal)}', style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: FuwaColors.subtleBorder),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('月均支出', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('¥${AppConstants.formatPrice(monthlyAvg)}', style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 月度水平条状图细分卡片（带水平条与点按联动）
  Widget _buildMonthlyBarChartCard() {
    final monthly = _monthlyTotalsInSelectedYear;
    final maxMonth = monthly.values.fold<double>(1.0, (prev, val) => val > prev ? val : prev);

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
              Text('$_selectedYear年各月支出条形图', style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 14, fontWeight: FontWeight.w800)),
              Text(_selectedMonth == '全部月份' ? '点击月份联动筛选' : '已筛选 $_selectedMonth', style: const TextStyle(color: FuwaColors.strawberryPink, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),

          // 月份横向胶囊切换栏
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _availableMonthsInYear.map((m) {
                final isSel = _selectedMonth == m;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMonth = m;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSel ? FuwaColors.balletPink : FuwaColors.creamWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSel ? FuwaColors.balletPink : FuwaColors.subtleBorder),
                    ),
                    child: Text(
                      m,
                      style: TextStyle(
                        color: isSel ? Colors.white : FuwaColors.chocolateDark,
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // 月度水平进度条
          if (monthly.isEmpty)
            const Text('该年暂无月度支出数据', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12))
          else
            Column(
              children: monthly.entries.map((entry) {
                final m = entry.key;
                final amt = entry.value;
                final pct = (maxMonth > 0) ? (amt / maxMonth) : 0.0;
                final isSel = _selectedMonth == m;
                final mNum = m.replaceAll('月', '');
                final count = _allRecords.where((r) => r.date.startsWith('$_selectedYear-$mNum')).length;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedMonth == m) {
                        _selectedMonth = '全部月份'; // 再次点击取消筛选
                      } else {
                        _selectedMonth = m;
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? FuwaColors.apricotCream.withOpacity(0.55) : FuwaColors.creamWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? FuwaColors.balletPink : FuwaColors.subtleBorder,
                        width: isSel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(m, style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 12, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600)),
                                const SizedBox(width: 6),
                                Text('$count 笔', style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 10)),
                              ],
                            ),
                            Text('¥${AppConstants.formatPrice(amt)}', style: TextStyle(color: isSel ? FuwaColors.strawberryPink : FuwaColors.chocolateDark, fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: FuwaColors.pureWhite,
                            valueColor: AlwaysStoppedAnimation<Color>(isSel ? FuwaColors.strawberryPink : FuwaColors.balletPink),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// 支出流水时间线 SliverList
  Widget _buildTimelineSliverList() {
    final records = _displayedTimeline;

    if (records.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text('当前筛选下暂无支出记录', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final r = records[index];
            final isDeposit = r.paymentType == '定金';
            final isBalance = r.paymentType == '尾款';
            String typeBadge;
            if (isDeposit) {
              typeBadge = '定金';
            } else if (isBalance) {
              typeBadge = '尾款';
            } else if (r.paymentType == '小物') {
              typeBadge = '饰品';
            } else {
              typeBadge = '现货';
            }

            String catText;
            switch (r.category) {
              case 'lolita':
                catText = '洋装';
                break;
              case 'earth':
                catText = '常服';
                break;
              case 'accessory':
                catText = '搭配小物';
                break;
              default:
                catText = '衣柜单品';
                break;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                    decoration: BoxDecoration(
                      color: isDeposit
                          ? FuwaColors.apricotCream
                          : (isBalance ? FuwaColors.balletPink.withOpacity(0.15) : FuwaColors.creamWhite),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      typeBadge,
                      style: TextStyle(
                        color: isDeposit
                            ? FuwaColors.chocolateDark
                            : (isBalance ? FuwaColors.balletPink : FuwaColors.chocolateDark),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FuwaColors.chocolateDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${r.date} · $catText',
                          style: const TextStyle(
                            color: FuwaColors.mutedRosyBrown,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          text: AppConstants.formatPrice(r.amount),
                          style: const TextStyle(
                            color: FuwaColors.chocolateDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: records.length,
        ),
      ),
    );
  }
}
