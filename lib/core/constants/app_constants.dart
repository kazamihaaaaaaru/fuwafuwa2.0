/// 衣柜领域枚举常量与类目定义
class AppConstants {
  AppConstants._();

  // 主大类
  static const String categoryEarth = 'earth';
  static const String categoryLolita = 'lolita';
  static const String categoryAccessory = 'accessory';

  // 地球人服饰子类目（已扩展鞋、袜、帽子、包、伞）
  static const List<String> earthSubCategories = [
    '上衣',
    '下装',
    '外套',
    '连衣裙',
    '鞋',
    '袜',
    '帽子',
    '包',
    '伞',
    '其他',
  ];

  // Lolita 洋装子类目
  static const List<String> lolitaSubCategories = [
    'JSK',
    'OP',
    'SK',
    '衬衫',
    '斗篷',
    '裙撑/内搭',
  ];

  // 地球人季节标签
  static const List<String> seasons = [
    '春',
    '夏',
    '秋',
    '冬',
    '四季通用',
  ];

  // 小物类型（已加入发带）
  static const List<String> accessoryTypes = [
    'KC',
    'BNT',
    '发带',
    '边夹',
    '手袖',
    '袜',
    '鞋',
    '包',
    '项链胸针',
    '其他',
  ];

  // 心愿单心动等级（专属少女感设计）
  static const List<String> desireLevels = [
    '非入不可 ♡',
    '很心动 ୨୧',
    '还在观望 ~',
  ];
}
