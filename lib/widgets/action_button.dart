import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;
  final bool isSecondary;

  const ActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
        final buttonSize = isSecondary 
            ? (isDesktop ? 40.0 : 36.0)
            : (isDesktop ? 48.0 : 40.0);
        final iconSize = isSecondary
            ? (isDesktop ? 24.0 : 20.0)
            : (isDesktop ? 28.0 : 24.0);
        final padding = isSecondary
            ? (isDesktop ? 8.0 : 6.0)
            : (isDesktop ? 12.0 : 8.0);

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: onPressed,
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  color: (color ?? Theme.of(context).primaryColor)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: color ?? Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 