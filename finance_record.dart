/// 单笔实际扣款流水记录
/// 严格按照实际扣款发生时间（定金支付日、尾款支付日、现货购买日）归集
class FinanceRecord {
  final String date; // YYYY-MM-DD
  final double amount;
  final String category; // 'earth' | 'lolita' | 'accessory'
  final String title;
  final String paymentType; // '全款' | '定金' | '尾款' | '小物'
  final int? itemId;
  final int? accessoryId;

  const FinanceRecord({
    required this.date,
    required this.amount,
    required this.category,
    required this.title,
    required this.paymentType,
    this.itemId,
    this.accessoryId,
  });

  bool get isDeposit => paymentType == '定金';
  bool get isBalance => paymentType == '尾款';

  String get typeBadge {
    if (isDeposit) return '定金';
    if (isBalance) return '尾款';
    if (paymentType == '小物') return '饰品';
    return '现货';
  }

  String get categoryText {
    switch (category) {
      case 'lolita':
        return '洋装';
      case 'earth':
        return '常服';
      case 'accessory':
        return '搭配小物';
      default:
        return '衣柜单品';
    }
  }

  factory FinanceRecord.fromMap(Map<String, dynamic> map) {
    return FinanceRecord(
      date: map['date'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'earth',
      title: map['title'] as String? ?? '',
      paymentType: map['paymentType'] as String? ?? '全款',
      itemId: map['itemId'] as int?,
      accessoryId: map['accessoryId'] as int?,
    );
  }
}

/// 记账看板宏观财务汇总
class FinanceSummary {
  final double totalWardrobeAsset; // 衣柜总资产总额
  final int pendingBalanceCount; // 当前未完成尾款总数（件数）
  final double pendingBalanceEstimate; // 待补尾款预计总金额
  final double earthTotal; // 地球人累计支出
  final double lolitaTotal; // Lolita 累计支出
  final double accessoryTotal; // 小物累计支出

  const FinanceSummary({
    this.totalWardrobeAsset = 0.0,
    this.pendingBalanceCount = 0,
    this.pendingBalanceEstimate = 0.0,
    this.earthTotal = 0.0,
    this.lolitaTotal = 0.0,
    this.accessoryTotal = 0.0,
  });

  double get pendingBalanceTotal => pendingBalanceEstimate;
  double get earthRatio => totalWardrobeAsset > 0 ? (earthTotal / totalWardrobeAsset) : 0.0;
  double get lolitaRatio => totalWardrobeAsset > 0 ? (lolitaTotal / totalWardrobeAsset) : 0.0;
  double get accessoryRatio => totalWardrobeAsset > 0 ? (accessoryTotal / totalWardrobeAsset) : 0.0;
}
