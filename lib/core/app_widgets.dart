import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: GestureDetector(
        onTap: onTap != null ? () {
          HapticFeedback.lightImpact();
          onTap!();
        } : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.glassBase,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class NeonText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final TextAlign textAlign;

  const NeonText({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing = 4,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        shadows: [
          Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
          Shadow(color: color, blurRadius: 20),
        ],
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool enabled;
  final double height;
  final double? width;

  const GlassButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.enabled = true,
    this.height = 50,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () {
        HapticFeedback.lightImpact();
        onPressed();
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.1) : Colors.white10,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: enabled ? color : Colors.white10, width: 1),
          boxShadow: enabled ? [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10),
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: enabled ? color : Colors.white24,
              letterSpacing: 1.5,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class BackgroundGlows extends StatelessWidget {
  const BackgroundGlows({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: _glowCircle(AppColors.cyan.withValues(alpha: 0.1), 250),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: _glowCircle(AppColors.pink.withValues(alpha: 0.1), 300),
        ),
        Positioned(
          top: 200,
          left: -100,
          child: _glowCircle(AppColors.purple.withValues(alpha: 0.05), 200),
        ),
      ],
    );
  }

  Widget _glowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 100, spreadRadius: size / 2),
        ],
      ),
    );
  }
}

class AnimatedScoreCounter extends StatelessWidget {
  final int value;
  final Color color;
  final TextStyle? style;

  const AnimatedScoreCounter({
    super.key,
    required this.value,
    required this.color,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value',
      style: (style ?? TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
      )).copyWith(
        color: color,
        shadows: value > 0 ? [Shadow(color: color, blurRadius: 10)] : null,
      ),
    ).animate(
      onComplete: (controller) => controller.reset(),
    ).scale(
      begin: const Offset(1.2, 1.2),
      end: const Offset(1, 1),
      duration: 400.ms,
      curve: Curves.elasticOut,
    );
  }
}

class GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color accentColor;

  const GlassInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(Icons.person, color: accentColor, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
      ),
    );
  }
}