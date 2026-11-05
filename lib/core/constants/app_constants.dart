/// 衣柜领域枚举常量与类目定义
class AppConstants {
  AppConstants._();

  // 主大类
  static const String categoryEarth = 'earth';
  static const String categoryLolita = 'lolita';
  static const String categoryAccessory = 'accessory';

  // 服装尺码规范（Lolita 与地球人均通用）
  static const List<String> clothingSizes = [
    'XS',
    'S',
    'M',
    'L',
    '均码',
    '其他',
  ];

  // 地球人服饰子类目（含鞋、袜、帽子、包、伞）
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

  // Lolita 洋装子类目（裙撑与内搭已拆分，包含 JK）
  static const List<String> lolitaSubCategories = [
    'JSK',
    'OP',
    'SK',
    '衬衫',
    '斗篷',
    '外套',
    '开衫',
    '围裙',
    '裙撑',
    '内搭',
    'JK',
    '其他',
  ];

  // 地球人季节标签
  static const List<String> seasons = [
    '春',
    '夏',
    '秋',
    '冬',
    '四季通用',
  ];

  // 小物类型（已加入“帽子”）
  static const List<String> accessoryTypes = [
    'KC',
    'BNT',
    '发带',
    '帽子',
    '边夹',
    '手袖',
    '袜',
    '鞋',
    '包',
    '项链胸针',
    '其他',
  ];

  // 心愿单心动等级
  static const List<String> desireLevels = [
    '非入不可 ♡',
    '很心动 ୨୧',
    '还在观望 ~',
  ];

  /// 价格金额展示格式化（整数显示整数，小数保留两位，杜绝抹零）
  static String formatPrice(double val) {
    if (val <= 0) return '0';
    if (val % 1 == 0) {
      return val.toInt().toString();
    } else {
      return val.toStringAsFixed(2);
    }
  }

  /// 价格输入框预填格式化
  static String formatPriceInput(double val) {
    if (val <= 0) return '';
    if (val % 1 == 0) {
      return val.toInt().toString();
    } else {
      return val.toStringAsFixed(2);
    }
  }
}
