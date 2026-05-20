import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AnimatedInteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool enableScale;
  final Color? selectedBorderColor;
  final Color? selectedBackgroundColor;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const AnimatedInteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.enableScale = true,
    this.selectedBorderColor,
    this.selectedBackgroundColor,
    this.borderRadius = 24.0,
    this.padding,
    this.margin,
  });

  @override
  State<AnimatedInteractiveCard> createState() => _AnimatedInteractiveCardState();
}

class _AnimatedInteractiveCardState extends State<AnimatedInteractiveCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableScale) _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableScale) _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.enableScale) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: widget.padding ?? EdgeInsets.zero,
          margin: widget.margin ?? EdgeInsets.zero,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (widget.selectedBackgroundColor ?? AppColors.primaryLight)
                : Colors.white,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.isSelected
                  ? (widget.selectedBorderColor ?? AppColors.primary)
                  : AppColors.border,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: (widget.selectedBorderColor ?? AppColors.primary).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
