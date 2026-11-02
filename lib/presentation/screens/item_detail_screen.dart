import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/accessory.dart';
import '../../data/models/item.dart';

/// 子页面: 单品详情页 (`ItemDetailScreen`)
/// 严格遵循甘系（Sweet Lolita）视觉设计规范：
/// - 拍立得大图与完整档案
/// - 价格与工期全维度看板（定金、尾款、等待天数）
/// - 若待补款，提供高亮按钮：【记录补款】一键出货
/// - 底部横向滚动展示搭配小物，支持一键增删解绑
class ItemDetailScreen extends StatefulWidget {
  final int itemId;
  final VoidCallback? onDataChanged;

  const ItemDetailScreen({
    super.key,
    required this.itemId,
    this.onDataChanged,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Item? _item;
  List<Accessory> _associatedAccessories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItemDetail();
  }

  /// 加载单品最新详情及关联小物
  Future<void> _loadItemDetail() async {
    setState(() => _isLoading = true);
    final item = await _dbHelper.getItemById(widget.itemId);
    if (item != null) {
      final accessories = await _dbHelper.getAccessoriesForItem(widget.itemId);
      if (mounted) {
        setState(() {
          _item = item;
          _associatedAccessories = accessories;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: FuwaColors.creamWhite,
        body: Center(
          child: CircularProgressIndicator(color: FuwaColors.balletPink),
        ),
      );
    }

    if (_item == null) {
      return Scaffold(
        backgroundColor: FuwaColors.creamWhite,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _buildBackButton(),
        ),
        body: const Center(
          child: Text(
            '未找到该单品记录',
            style: TextStyle(color: FuwaColors.mutedRosyBrown),
          ),
        ),
      );
    }

    final item = _item!;

    return Scaffold(
      backgroundColor: FuwaColors.creamWhite,
      body: CustomScrollView(
        slivers: [
          // 1. 顶部大图 SliverAppBar
          _buildSliverHeader(item),

          // 2. 核心信息面板
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题、店铺与分类标签
                  _buildTitleCard(item),

                  const SizedBox(height: 14),

                  // 工期与补款状态看板（仅针对定金尾款制 Lolita）
                  if (item.isDepositType) ...[
                    _buildDurationCard(item),
                    const SizedBox(height: 14),
                  ],

                  // 财务全维度看板（总支出、定金/尾款明细）
                  _buildFinanceBreakdownCard(item),

                  const SizedBox(height: 14),

                  // 基础规格与属性看板
                  _buildSpecsCard(item),

                  const SizedBox(height: 20),

                  // 搭配小物箱与绑定操作
                  _buildAccessoriesSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部大图折叠栏
  Widget _buildSliverHeader(Item item) {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      backgroundColor: FuwaColors.creamWhite,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildBackButton(),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: FuwaColors.pureWhite.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: FuwaColors.softCardShadow,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: FuwaColors.balletPink,
                size: 20,
              ),
            ),
            onPressed: () => _confirmDeleteItem(item),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 大图展示
            _buildLargeImage(item),
            // 底部柔和淡化渐变
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      FuwaColors.creamWhite.withOpacity(0.0),
                      FuwaColors.creamWhite,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 优雅的返回按钮
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        decoration: BoxDecoration(
          color: FuwaColors.pureWhite.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: FuwaColors.softCardShadow,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: FuwaColors.chocolateDark,
          size: 18,
        ),
      ),
    );
  }

  /// 详情大图
  Widget _buildLargeImage(Item item) {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      final file = File(item.imagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
        );
      }
    }
    // 少女梦境占位大图
    return Container(
      color: FuwaColors.apricotCream,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              FuwaColors.ribbonSymbol,
              style: TextStyle(
                color: FuwaColors.balletPink,
                fontSize: 64,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'FuwaFuwa Wardrobe ୨୧',
              style: TextStyle(
                color: FuwaColors.chocolateDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 标题与基本分类卡片
  Widget _buildTitleCard(Item item) {
    return Container(
      width: double.infinity,
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isLolita ? FuwaColors.balletPink : FuwaColors.apricotCream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.isLolita ? 'Lolita ୨୧' : '地球人',
                  style: TextStyle(
                    color: item.isLolita ? Colors.white : FuwaColors.chocolateDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FuwaColors.creamWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FuwaColors.subtleBorder),
                ),
                child: Text(
                  item.subCategory,
                  style: const TextStyle(
                    color: FuwaColors.chocolateDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // 总支出展示
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '总计 ¥',
                      style: TextStyle(
                        color: FuwaColors.mutedRosyBrown,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: item.totalCost.toStringAsFixed(0),
                      style: const TextStyle(
                        color: FuwaColors.chocolateDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            style: const TextStyle(
              color: FuwaColors.chocolateDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          if (item.shopName != null && item.shopName!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 15,
                  color: FuwaColors.mutedRosyBrown,
                ),
                const SizedBox(width: 5),
                Text(
                  item.shopName!,
                  style: const TextStyle(
                    color: FuwaColors.mutedRosyBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 工期与等待时长看板（含一键补款高亮按钮）
  Widget _buildDurationCard(Item item) {
    final isPending = item.isPendingBalance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isPending
            ? FuwaColors.sugarCandyGold.withOpacity(0.08)
            : FuwaColors.balletPink.withOpacity(0.06),
        borderRadius: FuwaColors.roundedCardRadius,
        border: Border.all(
          color: isPending
              ? FuwaColors.sugarCandyGold.withOpacity(0.35)
              : FuwaColors.balletPink.withOpacity(0.3),
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isPending
                          ? FuwaColors.sugarCandyGold
                          : FuwaColors.balletPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      FuwaColors.ribbonSymbol,
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPending ? '制作等待中' : '工期圆满完成 ୨୧',
                    style: TextStyle(
                      color: isPending
                          ? FuwaColors.sugarCandyGold
                          : FuwaColors.chocolateDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              // 工期/等待天数徽章
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? FuwaColors.sugarCandyGold : FuwaColors.balletPink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  item.durationBadgeText ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 预计补款时间（若在待补款状态）
          if (isPending && item.expectedDate != null && item.expectedDate!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.alarm_on_rounded,
                  size: 15,
                  color: FuwaColors.mutedRosyBrown,
                ),
                const SizedBox(width: 6),
                Text(
                  '预计出货/补款：${item.expectedDate}',
                  style: const TextStyle(
                    color: FuwaColors.mutedRosyBrown,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // 若仍待补尾款，提供高亮按钮：【记录补款】
          if (isPending)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _showRecordBalanceDialog(item),
                icon: const Text(
                  FuwaColors.ribbonSymbol,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                label: const Text(
                  '【记录补款】一键转已出货',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FuwaColors.balletPink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  shadowColor: FuwaColors.balletPink.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 价格全维度看板（定金、尾款、支付流水）
  Widget _buildFinanceBreakdownCard(Item item) {
    return Container(
      width: double.infinity,
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
            children: const [
              Icon(Icons.account_balance_wallet_outlined, size: 16, color: FuwaColors.balletPink),
              SizedBox(width: 6),
              Text(
                '支出流水看板',
                style: TextStyle(
                  color: FuwaColors.chocolateDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (item.isDepositType) ...[
            // 定金支付记录
            _buildFinanceRow(
              title: '定金支出',
              amount: item.depositPrice,
              date: item.depositDate ?? '未记录',
              isPaid: true,
            ),
            const Divider(color: FuwaColors.creamWhite, height: 20),
            // 尾款支付记录
            _buildFinanceRow(
              title: '尾款支出',
              amount: item.balancePrice,
              date: item.balanceDate ?? (item.expectedDate != null ? '预计 ${item.expectedDate}' : '待补款'),
              isPaid: item.isCompletedBalance,
            ),
          ] else ...[
            // 现货全款
            _buildFinanceRow(
              title: '全款现货',
              amount: item.fullPrice,
              date: item.depositDate ?? '购买日未填',
              isPaid: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinanceRow({
    required String title,
    required double amount,
    required String date,
    required bool isPaid,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
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
              date,
              style: const TextStyle(
                color: FuwaColors.mutedRosyBrown,
                fontSize: 11,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPaid ? FuwaColors.apricotCream : FuwaColors.creamWhite,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPaid ? '已扣款' : '待补款',
                style: TextStyle(
                  color: isPaid ? FuwaColors.chocolateDark : FuwaColors.sugarCandyGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isPaid ? '¥${amount.toStringAsFixed(0)}' : (amount > 0 ? '¥${amount.toStringAsFixed(0)}' : '--'),
              style: const TextStyle(
                color: FuwaColors.chocolateDark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 规格与基础属性
  Widget _buildSpecsCard(Item item) {
    return Container(
      width: double.infinity,
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
            '单品档案',
            style: TextStyle(
              color: FuwaColors.chocolateDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpecItem('体系', item.isLolita ? 'Lolita 洋装' : '地球人常服'),
          _buildSpecItem('品类', item.subCategory),
          if (item.isEarth && item.season != null && item.season!.isNotEmpty)
            _buildSpecItem('适用季节', item.season!),
          if (item.isLolita && item.shopName != null && item.shopName!.isNotEmpty)
            _buildSpecItem('店铺品牌', item.shopName!),
          _buildSpecItem('购买方式', item.isDepositType ? '定金尾款预定制' : '现货全款'),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FuwaColors.mutedRosyBrown,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: FuwaColors.chocolateDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 搭配小物箱区域（横向滚动展示，支持增删绑定）
  Widget _buildAccessoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '搭配小物箱 ୨୧',
                  style: TextStyle(
                    color: FuwaColors.chocolateDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: FuwaColors.apricotCream,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_associatedAccessories.length} 件',
                    style: const TextStyle(
                      color: FuwaColors.chocolateDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            // 添加搭配按钮
            TextButton.icon(
              onPressed: _showBindAccessorySheet,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: FuwaColors.balletPink),
              label: const Text(
                '搭配管理',
                style: TextStyle(
                  color: FuwaColors.balletPink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_associatedAccessories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: FuwaColors.pureWhite,
              borderRadius: FuwaColors.roundedCardRadius,
              border: Border.all(color: FuwaColors.subtleBorder),
            ),
            child: Column(
              children: [
                const Text(
                  FuwaColors.ribbonSymbol,
                  style: TextStyle(color: FuwaColors.balletPink, fontSize: 24),
                ),
                const SizedBox(height: 6),
                const Text(
                  '尚未绑定任何搭配小物（KC、手袖、鞋袜等）',
                  style: TextStyle(
                    color: FuwaColors.mutedRosyBrown,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showBindAccessorySheet,
                  child: const Text(
                    '点击添加专属搭配 ୨୧',
                    style: TextStyle(
                      color: FuwaColors.balletPink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _associatedAccessories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final acc = _associatedAccessories[index];
                return _buildAccessoryCard(acc);
              },
            ),
          ),
      ],
    );
  }

  /// 单个搭配小物卡片
  Widget _buildAccessoryCard(Accessory acc) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: FuwaColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: FuwaColors.softCardShadow,
        border: Border.all(color: FuwaColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 缩略图与快速解绑
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 62,
                  width: double.infinity,
                  color: FuwaColors.creamWhite,
                  child: acc.imagePath != null && File(acc.imagePath!).existsSync()
                      ? Image.file(File(acc.imagePath!), fit: BoxFit.cover)
                      : const Center(
                          child: Text(
                            FuwaColors.ribbonSymbol,
                            style: TextStyle(color: FuwaColors.balletPink, fontSize: 16),
                          ),
                        ),
                ),
              ),
              // 解绑按钮
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _unbindAccessory(acc),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 小物类型
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: FuwaColors.apricotCream,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              acc.accessoryType,
              style: const TextStyle(
                color: FuwaColors.chocolateDark,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 3),
          // 小物名称
          Text(
            acc.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FuwaColors.chocolateDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          // 价格
          Text(
            '¥${acc.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: FuwaColors.mutedRosyBrown,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 弹窗与交互逻辑
  // ==========================================

  /// 【记录补款】弹窗：输入实付尾款金额和日期，一键转为已出货
  Future<void> _showRecordBalanceDialog(Item item) async {
    final balanceController = TextEditingController(
      text: item.balancePrice > 0 ? item.balancePrice.toStringAsFixed(0) : '',
    );
    String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: FuwaColors.pureWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '记录补款 · 一键转已出货 ୨୧',
                        style: TextStyle(
                          color: FuwaColors.chocolateDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: FuwaColors.mutedRosyBrown),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '实付尾款金额 (元)',
                    style: TextStyle(
                      color: FuwaColors.chocolateDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: FuwaColors.creamWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: FuwaColors.subtleBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      cursorColor: FuwaColors.balletPink,
                      style: const TextStyle(
                        color: FuwaColors.chocolateDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '如 450',
                        hintStyle: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '尾款支付日期',
                    style: TextStyle(
                      color: FuwaColors.chocolateDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: FuwaColors.balletPink,
                                onPrimary: Colors.white,
                                surface: FuwaColors.pureWhite,
                                onSurface: FuwaColors.chocolateDark,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: FuwaColors.creamWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: FuwaColors.subtleBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate,
                            style: const TextStyle(
                              color: FuwaColors.chocolateDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: FuwaColors.balletPink,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final val = double.tryParse(balanceController.text.trim()) ?? 0.0;
                        await _dbHelper.recordBalancePayment(
                          item.id!,
                          val,
                          selectedDate,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadItemDetail();
                          widget.onDataChanged?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: FuwaColors.balletPink,
                              content: Text('尾款已记录，工期已圆满结算 ୨୧'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FuwaColors.balletPink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        '确认补款并出货 ୨୧',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 搭配小物管理半屏底抽屉（展示可选小物，支持勾选一键绑定与解绑）
  Future<void> _showBindAccessorySheet() async {
    final allAccessories = await _dbHelper.getAllAccessories();
    final boundIds = _associatedAccessories.map((a) => a.id!).toSet();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
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
                      const Text(
                        '选择搭配小物 ୨୧',
                        style: TextStyle(
                          color: FuwaColors.chocolateDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: FuwaColors.mutedRosyBrown),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '勾选要为该单品绑定的 KC、手袖、鞋袜或包包',
                    style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  if (allAccessories.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          '小物箱目前为空，请先在小物箱 Tab 中录入小物 ୨୧',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: FuwaColors.mutedRosyBrown),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: allAccessories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final acc = allAccessories[index];
                          final isBound = boundIds.contains(acc.id);

                          return InkWell(
                            onTap: () async {
                              if (isBound) {
                                await _dbHelper.unbindAccessory(widget.itemId, acc.id!);
                                boundIds.remove(acc.id);
                              } else {
                                await _dbHelper.bindAccessory(widget.itemId, acc.id!);
                                boundIds.add(acc.id!);
                              }
                              setSheetState(() {});
                              _loadItemDetail();
                              widget.onDataChanged?.call();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isBound ? FuwaColors.apricotCream.withOpacity(0.5) : FuwaColors.creamWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isBound ? FuwaColors.balletPink : FuwaColors.subtleBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // 小物缩略图
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      color: FuwaColors.pureWhite,
                                      child: acc.imagePath != null && File(acc.imagePath!).existsSync()
                                          ? Image.file(File(acc.imagePath!), fit: BoxFit.cover)
                                          : const Center(
                                              child: Text(
                                                FuwaColors.ribbonSymbol,
                                                style: TextStyle(color: FuwaColors.balletPink, fontSize: 14),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          acc.name,
                                          style: const TextStyle(
                                            color: FuwaColors.chocolateDark,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${acc.accessoryType} · ¥${acc.price.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: FuwaColors.mutedRosyBrown,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 勾选标识
                                  Icon(
                                    isBound ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: isBound ? FuwaColors.balletPink : FuwaColors.mutedRosyBrown,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 单个小物快捷解绑
  Future<void> _unbindAccessory(Accessory acc) async {
    await _dbHelper.unbindAccessory(widget.itemId, acc.id!);
    _loadItemDetail();
    widget.onDataChanged?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: FuwaColors.balletPink,
          content: Text('已解除与 ${acc.name} 的搭配绑定 ୨୧'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// 删除单品确认
  Future<void> _confirmDeleteItem(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuwaColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '移除这件轻飘飘的单品？',
          style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '确定要从衣柜中删除「${item.name}」吗？已搭配的小物不会被删除。',
          style: const TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('保留', style: TextStyle(color: FuwaColors.mutedRosyBrown)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FuwaColors.balletPink,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('确认删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _dbHelper.deleteItem(item.id!);
      widget.onDataChanged?.call();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
