import 'package:flutter/material.dart';

import '../theme/eon_theme.dart';

/// Bottom sheet with a few "+N unit" buttons for quick logging.
Future<void> showQuickAddSheet(
  BuildContext context, {
  required String title,
  required String unit,
  required List<int> amounts,
  required ValueChanged<int> onAdd,
  IconData icon = Icons.add_circle_outline_rounded,
  String? subtitle,
}) {
  return showEonSheet<void>(
    context,
    builder:
        (sheetContext) => EonSheet(
          title: title,
          icon: icon,
          subtitle: subtitle,
          child: Row(
            children: [
              for (var i = 0; i < amounts.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
                    child: _AmountChip(
                      label: '+${fmtThousands(amounts[i])} $unit',
                      onTap: () {
                        // Close the sheet first so a Level Up shows on top.
                        Navigator.of(sheetContext).pop();
                        onAdd(amounts[i]);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
  );
}

/// [showModalBottomSheet] preconfigured for Eon sheets: transparent so
/// [EonSheet] draws its own frame, and keyboard-aware.
Future<T?> showEonSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder:
        (sheetContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: builder(sheetContext),
        ),
  );
}

/// Shared frame for Eon bottom sheets.
class EonSheet extends StatelessWidget {
  const EonSheet({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.surfaceTop, p.background],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: p.border),
        boxShadow: p.boxGlow(strength: 1.2),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.textFaint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: p.highlight, shadows: p.textGlow()),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: eonText(18, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: eonText(13, color: p.textMuted)),
              ],
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: p.borderStrong),
    );
    return Material(
      color: p.accent.withValues(alpha: p.isDark ? 0.18 : 0.1),
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: eonText(15, weight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }
}
