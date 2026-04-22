import 'package:flutter/material.dart';

class AppQuickAction {
  const AppQuickAction({
    required this.id,
    required this.label,
    required this.color,
  });

  final String id;
  final String label;
  final Color color;
}

class AppSpeedDial extends StatelessWidget {
  const AppSpeedDial({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.actions,
    required this.onActionSelected,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final List<AppQuickAction> actions;
  final ValueChanged<AppQuickAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        IgnorePointer(
          ignoring: !expanded,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: expanded ? 1 : 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              offset: expanded ? Offset.zero : const Offset(0, 0.08),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: actions
                      .map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _AppSpeedDialAction(
                            action: action,
                            onTap: () => onActionSelected(action),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
        FloatingActionButton(
          onPressed: onToggle,
          backgroundColor: const Color(0xFF1DB954),
          foregroundColor: Colors.white,
          elevation: 14,
          child: Icon(
            expanded ? Icons.close_rounded : Icons.add_rounded,
            size: 34,
          ),
        ),
      ],
    );
  }
}

class _AppSpeedDialAction extends StatelessWidget {
  const _AppSpeedDialAction({required this.action, required this.onTap});

  final AppQuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: action.color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: action.color.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            action.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
