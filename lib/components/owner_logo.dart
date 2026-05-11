import 'package:flutter/material.dart';

class OwnerLogo extends StatelessWidget {
  final double size;
  final double containerSize;
  final bool showShadow;
  final bool showBorder;
  final EdgeInsetsGeometry? padding;

  const OwnerLogo({
    super.key,
    this.size = 40,
    this.containerSize = 80,
    this.showShadow = true,
    this.showBorder = true,
    this.padding,
  });

  const OwnerLogo.small({
    super.key,
    this.size = 24,
    this.containerSize = 48,
    this.showShadow = false,
    this.showBorder = true,
    this.padding,
  });

  const OwnerLogo.medium({
    super.key,
    this.size = 50,
    this.containerSize = 80,
    this.showShadow = true,
    this.showBorder = true,
    this.padding,
  });

  const OwnerLogo.large({
    super.key,
    this.size = 50,
    this.containerSize = 100,
    this.showShadow = true,
    this.showBorder = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: containerSize,
      height: containerSize,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3)
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Image.asset(
          'assets/images/logo.jpeg',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
