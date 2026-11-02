import 'accessory.dart';

/// 衣物单品（Item）模型
/// 涵盖地球人（Earth）日常服饰与甘系（Lolita）定制洋装
class Item {
  final int? id;
  final String category; // 'earth' | 'lolita'
  final String subCategory;
  final String name;
  final String? imagePath;
  final String? size; // 服装尺码：XS/S/M/L/均码/手写定制
  final String? season; // 地球人专用：春/夏/秋/冬/四季通用
  final String? shopName; // 店铺/品牌名称（地球人与 Lolita 均支持）
  final bool isDepositType; // false: 全款现货, true: 定金尾款制
  final double fullPrice; // 全款金额
  final double depositPrice; // 定金金额
  final String? depositDate; // 定金/购买发生日期 (YYYY-MM-DD)
  final double balancePrice; // 尾款实付金额 (未补款为 0)
  final String? balanceDate; // 尾款支付日期 (YYYY-MM-DD，为空表示待补款)
  final String? expectedDate; // 预计补款时间 (YYYY-MM-DD)

  // 关联小物列表
  final List<Accessory> associatedAccessories;

  const Item({
    this.id,
    required this.category,
    required this.subCategory,
    required this.name,
    this.imagePath,
    this.size,
    this.season,
    this.shopName,
    this.isDepositType = false,
    this.fullPrice = 0.0,
    this.depositPrice = 0.0,
    this.depositDate,
    this.balancePrice = 0.0,
    this.balanceDate,
    this.expectedDate,
    this.associatedAccessories = const [],
  });

  bool get isLolita => category == 'lolita';
  bool get isEarth => category == 'earth';

  /// 总支出计算
  double get totalCost {
    if (isDepositType) {
      return depositPrice + balancePrice;
    }
    return fullPrice;
  }

  /// 是否处于“待补尾款”状态
  bool get isPendingBalance {
    return isDepositType && (balanceDate == null || balanceDate!.trim().isEmpty);
  }

  /// 是否处于“已补尾款”状态
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
      'category': category,
      'subCategory': subCategory,
      'name': name,
      'imagePath': imagePath,
      'size': size,
      'season': season,
      'shopName': shopName,
      'isDepositType': isDepositType ? 1 : 0,
      'fullPrice': fullPrice,
      'depositPrice': depositPrice,
      'depositDate': depositDate,
      'balancePrice': balancePrice,
      'balanceDate': balanceDate,
      'expectedDate': expectedDate,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map, {List<Accessory> accessories = const []}) {
    return Item(
      id: map['id'] as int?,
      category: map['category'] as String? ?? 'earth',
      subCategory: map['subCategory'] as String? ?? '其他',
      name: map['name'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
      size: map['size'] as String?,
      season: map['season'] as String?,
      shopName: map['shopName'] as String?,
      isDepositType: (map['isDepositType'] as int? ?? 0) == 1,
      fullPrice: (map['fullPrice'] as num?)?.toDouble() ?? 0.0,
      depositPrice: (map['depositPrice'] as num?)?.toDouble() ?? 0.0,
      depositDate: map['depositDate'] as String?,
      balancePrice: (map['balancePrice'] as num?)?.toDouble() ?? 0.0,
      balanceDate: map['balanceDate'] as String?,
      expectedDate: map['expectedDate'] as String?,
      associatedAccessories: accessories,
    );
  }

  Item copyWith({
    int? id,
    String? category,
    String? subCategory,
    String? name,
    String? imagePath,
    String? size,
    String? season,
    String? shopName,
    bool? isDepositType,
    double? fullPrice,
    double? depositPrice,
    String? depositDate,
    double? balancePrice,
    String? balanceDate,
    String? expectedDate,
    List<Accessory>? associatedAccessories,
  }) {
    return Item(
      id: id ?? this.id,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      size: size ?? this.size,
      season: season ?? this.season,
      shopName: shopName ?? this.shopName,
      isDepositType: isDepositType ?? this.isDepositType,
      fullPrice: fullPrice ?? this.fullPrice,
      depositPrice: depositPrice ?? this.depositPrice,
      depositDate: depositDate ?? this.depositDate,
      balancePrice: balancePrice ?? this.balancePrice,
      balanceDate: balanceDate ?? this.balanceDate,
      expectedDate: expectedDate ?? this.expectedDate,
      associatedAccessories: associatedAccessories ?? this.associatedAccessories,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
