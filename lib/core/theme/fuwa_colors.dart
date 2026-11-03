import 'package:flutter/material.dart';

/// 甘系（Sweet Lolita）视觉设计系统规范
class FuwaColors {
  FuwaColors._();

  // 背景底色：草莓奶霜白
  static const Color creamWhite = Color(0xFFFDF8F9);

  // 卡片底色：纯白
  static const Color pureWhite = Color(0xFFFFFFFF);

  // 卡片微粉柔光投影
  static const Color softGlowPink = Color(0xFFF3D8E2);

  // 主交互/高亮色：芭蕾舞鞋粉
  static const Color balletPink = Color(0xFFF299AC);

  // 鲜活草莓粉色（颜色标签文字与高亮数字）
  static const Color strawberryPink = Color(0xFFF28299);

  // 柔和浅玫瑰微粉色（颜色胶囊与浅色背景）
  static const Color paleRose = Color(0xFFFDEEF2);

  // 清爽冰蓝（地球人专区与夏天冰蓝色）
  static const Color iceBlue = Color(0xFF8EC5FC);

  // 点缀色：奶霜杏（未选中标签/辅助背景）
  static const Color apricotCream = Color(0xFFFCEEE3);

  // 点缀色：金平糖金（待补款/预警状态徽章）
  static const Color sugarCandyGold = Color(0xFFE6B875);

  // 四季专属灵动高亮色（樱粉、冰蓝、奶杏、雪灰蓝）
  static const Color seasonSpring = Color(0xFFF7A8B8); // 春：樱粉色
  static const Color seasonSummer = Color(0xFF8EC5FC); // 夏：冰蓝色
  static const Color seasonAutumn = Color(0xFFE8C39E); // 秋：奶杏色
  static const Color seasonWinter = Color(0xFFB8C9D9); // 冬：雪白浅灰蓝

  // 标题与价格：巧克力深棕（杜绝纯黑）
  static const Color chocolateDark = Color(0xFF5C3D42);

  // 副文本与次要信息：灰粉棕
  static const Color mutedRosyBrown = Color(0xFF9E7B82);

  // 边框柔粉色
  static const Color subtleBorder = Color(0xFFF8E5EB);

  // 统一圆角规范 (20px ~ 24px)
  static const double cardRadius = 22.0;
  static const BorderRadius roundedCardRadius = BorderRadius.all(Radius.circular(cardRadius));

  // 柔光微粉阴影
  static List<BoxShadow> get softCardShadow => [
    const BoxShadow(
      color: softGlowPink,
      offset: Offset(0, 8),
      blurRadius: 18,
      spreadRadius: 0,
    ),
  ];

  // 缎带符号装饰
  static const String ribbonSymbol = '୨୧';
}
