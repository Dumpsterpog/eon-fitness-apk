import 'package:flutter/material.dart';

import '../theme/eon_theme.dart';

/// Screen title row: optional back arrow, glowing icon, title, trailing action.
class EonHeader extends StatelessWidget {
  const EonHeader({
    super.key,
    required this.title,
    this.icon,
    this.onBack,
    this.trailing,
    this.titleSize = 21,
  });

  final String title;
  final IconData? icon;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              tooltip: 'Back',
              icon: Icon(Icons.arrow_back_rounded, color: p.text),
            )
          else
            const SizedBox(width: 14),
          if (icon != null) ...[
            Icon(icon, size: 26, color: p.highlight, shadows: p.textGlow()),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: eonText(titleSize, weight: FontWeight.w600),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Small section label with a fading rule.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: p.highlight, shadows: p.textGlow()),
          const SizedBox(width: 10),
        ],
        Text(text, style: eonText(15, weight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.highlight.withValues(alpha: 0.4),
                  p.highlight.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
