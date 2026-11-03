import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/fuwa_colors.dart';

/// 1. 拍立得相纸弹性按压动效包装器（`FuwaBounceCard`）
/// 模拟指尖触摸实体相纸时的微妙弹性微缩（Scale: 0.97）与阴影收放
class FuwaBounceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const FuwaBounceCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<FuwaBounceCard> createState() => _FuwaBounceCardState();
}

class _FuwaBounceCardState extends State<FuwaBounceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.965).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// 2. 蝴蝶结小缎带轻飘飘呼吸动效（`FuwaBreathingRibbon`）
/// 呈现《下妻物语》名句中“轻飘飘”的少女梦境律动（细微旋转 ±3° 与轻度浮动）
class FuwaBreathingRibbon extends StatefulWidget {
  final Widget child;
  final bool animate;

  const FuwaBreathingRibbon({
    super.key,
    required this.child,
    this.animate = true,
  });

  @override
  State<FuwaBreathingRibbon> createState() => _FuwaBreathingRibbonState();
}

class _FuwaBreathingRibbonState extends State<FuwaBreathingRibbon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.05).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.05, end: -0.05).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.05, end: 0.0).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 1,
      ),
    ]).animate(_controller);

    _translateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -3.0).chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -3.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 1,
      ),
    ]).animate(_controller);

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateAnimation.value),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 3. 金平糖金/柔粉状态胶囊心跳光晕（`FuwaPulseBadge`）
/// 用于“待补尾款”等重点关注状态的微弱呼吸光晕提示
class FuwaPulseBadge extends StatefulWidget {
  final Widget child;
  final Color glowColor;

  const FuwaPulseBadge({
    super.key,
    required this.child,
    this.glowColor = FuwaColors.sugarCandyGold,
  });

  @override
  State<FuwaPulseBadge> createState() => _FuwaPulseBadgeState();
}

class _FuwaPulseBadgeState extends State<FuwaPulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(_glowAnimation.value),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
