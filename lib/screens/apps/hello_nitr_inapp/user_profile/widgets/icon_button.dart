import 'package:flutter/material.dart';

class IconButtonWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final double iconSize;
  final double fontSize;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool enableFeedback;

  const IconButtonWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.fontSize,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.width,
    this.padding,
    this.enableFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultIconColor = iconColor ?? theme.primaryColor;
    final defaultTextColor = textColor ?? theme.primaryColor;

    return Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        splashColor: defaultIconColor.withOpacity(0.2),
        highlightColor: defaultIconColor.withOpacity(0.1),
        enableFeedback: enableFeedback,
        child: Container(
          width: width ?? MediaQuery.of(context).size.width * 0.25,
          padding: padding ?? const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 8.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with animated hover effect
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.0),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(
                      icon,
                      color: defaultIconColor,
                      size: iconSize,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8.0),
              // Text with proper styling
              Text(
                label,
                style: TextStyle(
                  color: defaultTextColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}