/// 小物（Accessory）模型
/// 独立管理，支持多对多绑定，支持现货全款与定金尾款制，支持记录品牌/店铺
class Accessory {
  final int? id;
  final String name;
  final String? imagePath;
  final String accessoryType;
  final String? shopName; // 店铺/品牌名称
  final String? color; // 饰品颜色
  final bool isDepositType; // false: 全款现货, true: 定金尾款制
  final double fullPrice; // 全款金额
  final double depositPrice; // 定金金额
  final String? depositDate; // 定金支付/购买日期 (YYYY-MM-DD)
  final double balancePrice; // 实付尾款 (未补款为 0)
  final String? balanceDate; // 尾款支付日期 (YYYY-MM-DD)
  final String? expectedDate; // 预计补款/出货日期 (YYYY-MM-DD)

  const Accessory({
    this.id,
    required this.name,
    this.imagePath,
    required this.accessoryType,
    this.shopName,
    this.color,
    this.isDepositType = false,
    this.fullPrice = 0.0,
    this.depositPrice = 0.0,
    this.depositDate,
    this.balancePrice = 0.0,
    this.balanceDate,
    this.expectedDate,
  });

  double get price => totalCost;
  String? get purchaseDate => depositDate;

  /// 总支出计算
  double get totalCost {
    if (isDepositType) {
      return depositPrice + balancePrice;
    }
    return fullPrice;
  }

  /// 是否处于待补尾款状态
  bool get isPendingBalance {
    return isDepositType && (balanceDate == null || balanceDate!.trim().isEmpty);
  }

  /// 是否处于已补齐尾款状态
  bool get isCompletedBalance {
    return isDepositType && (balanceDate != null && balanceDate!.trim().isNotEmpty);
  }

  /// 工期与等待时长计算
  int? get waitingDays {
    if (!isDepositType || depositDate == null || depositDate!.trim().isEmpty) {
      return null;
    }

    try {
      final depositDt = DateTime.parse(depositDate!.trim());
      if (isPendingBalance) {
        final now = DateTime.now();
        final diff = now.difference(depositDt).inDays;
        return diff >= 0 ? diff : 0;
      } else if (isCompletedBalance) {
        final balanceDt = DateTime.parse(balanceDate!.trim());
        final diff = balanceDt.difference(depositDt).inDays;
        return diff >= 0 ? diff : 0;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// 状态胶囊徽章文本
  String? get durationBadgeText {
    final days = waitingDays;
    if (days == null) return null;
    if (isPendingBalance) {
      return '已等 $days 天';
    } else if (isCompletedBalance) {
      return '工期 $days 天';
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'imagePath': imagePath,
      'accessoryType': accessoryType,
      'shopName': shopName,
      'color': color,
      'isDepositType': isDepositType ? 1 : 0,
      'fullPrice': fullPrice,
      'depositPrice': depositPrice,
      'depositDate': depositDate,
      'balancePrice': balancePrice,
      'balanceDate': balanceDate,
      'expectedDate': expectedDate,
      'price': totalCost,
      'purchaseDate': depositDate,
    };
  }

  factory Accessory.fromMap(Map<String, dynamic> map) {
    final legacyPrice = (map['price'] as num?)?.toDouble() ?? 0.0;
    final fullPriceVal = (map['fullPrice'] as num?)?.toDouble() ?? legacyPrice;
    final isDeposit = (map['isDepositType'] as int? ?? 0) == 1;

    return Accessory(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
      accessoryType: map['accessoryType'] as String? ?? '其他',
      shopName: map['shopName'] as String?,
      color: map['color'] as String?,
      isDepositType: isDeposit,
      fullPrice: fullPriceVal,
      depositPrice: (map['depositPrice'] as num?)?.toDouble() ?? 0.0,
      depositDate: (map['depositDate'] as String?) ?? (map['purchaseDate'] as String?),
      balancePrice: (map['balancePrice'] as num?)?.toDouble() ?? 0.0,
      balanceDate: map['balanceDate'] as String?,
      expectedDate: map['expectedDate'] as String?,
    );
  }

  Accessory copyWith({
    int? id,
    String? name,
    String? imagePath,
    String? accessoryType,
    String? shopName,
    String? color,
    bool? isDepositType,
    double? fullPrice,
    double? depositPrice,
    String? depositDate,
    double? balancePrice,
    String? balanceDate,
    String? expectedDate,
  }) {
    return Accessory(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      accessoryType: accessoryType ?? this.accessoryType,
      shopName: shopName ?? this.shopName,
      color: color ?? this.color,
      isDepositType: isDepositType ?? this.isDepositType,
      fullPrice: fullPrice ?? this.fullPrice,
      depositPrice: depositPrice ?? this.depositPrice,
      depositDate: depositDate ?? this.depositDate,
      balancePrice: balancePrice ?? this.balancePrice,
      balanceDate: balanceDate ?? this.balanceDate,
      expectedDate: expectedDate ?? this.expectedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Accessory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
