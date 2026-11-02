/// 心愿单（Wishlist）模型
/// 记录种草清单、预算、预计贩售月份与心动等级
class WishlistItem {
  final int? id;
  final String name;
  final String? imagePath;
  final String? shopName;
  final double budgetPrice;
  final String? releaseDate; // YYYY-MM
  final String desireLevel; // '非入不可 ♡' | '很心动 ୨୧' | '还在观望 ~'
  final String category; // 'lolita' | 'earth' | 'accessory'
  final String? subCategory;
  final String? note;
  final String? createdDate;

  const WishlistItem({
    this.id,
    required this.name,
    this.imagePath,
    this.shopName,
    this.budgetPrice = 0.0,
    this.releaseDate,
    required this.desireLevel,
    this.category = 'lolita',
    this.subCategory,
    this.note,
    this.createdDate,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'imagePath': imagePath,
      'shopName': shopName,
      'budgetPrice': budgetPrice,
      'releaseDate': releaseDate,
      'desireLevel': desireLevel,
      'category': category,
      'subCategory': subCategory,
      'note': note,
      'createdDate': createdDate,
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
      shopName: map['shopName'] as String?,
      budgetPrice: (map['budgetPrice'] as num?)?.toDouble() ?? 0.0,
      releaseDate: map['releaseDate'] as String?,
      desireLevel: map['desireLevel'] as String? ?? '很心动 ୨୧',
      category: map['category'] as String? ?? 'lolita',
      subCategory: map['subCategory'] as String?,
      note: map['note'] as String?,
      createdDate: map['createdDate'] as String?,
    );
  }

  WishlistItem copyWith({
    int? id,
    String? name,
    String? imagePath,
    String? shopName,
    double? budgetPrice,
    String? releaseDate,
    String? desireLevel,
    String? category,
    String? subCategory,
    String? note,
    String? createdDate,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      shopName: shopName ?? this.shopName,
      budgetPrice: budgetPrice ?? this.budgetPrice,
      releaseDate: releaseDate ?? this.releaseDate,
      desireLevel: desireLevel ?? this.desireLevel,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      note: note ?? this.note,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WishlistItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
