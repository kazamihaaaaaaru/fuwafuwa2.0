import 'package:flutter/material.dart';

/// 甘系（Sweet Lolita）视觉设计系统规范
/// 灵感源自《下妻物语》：“在廉价的生活里做着轻飘飘的少女梦”
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

  // 点缀色：奶霜杏（未选中标签/辅助背景）
  static const Color apricotCream = Color(0xFFFCEEE3);

  // 点缀色：金平糖金（待补款/预警状态徽章）
  static const Color sugarCandyGold = Color(0xFFE6B875);

  // 标题与价格：巧克力深棕（严禁纯黑）
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
