import 'package:flutter/material.dart';

class ModeControls extends StatelessWidget {
  final bool randomMode;
  final bool historyMode;
  final bool showCharacter;
  final bool showGuide;

  final VoidCallback onRandomToggle;
  final VoidCallback onHistoryToggle;
  final VoidCallback onCharacterToggle;
  final VoidCallback onGuideToggle;
  final VoidCallback onStrokeOrderPlay;

  const ModeControls({
    super.key,
    required this.randomMode,
    required this.historyMode,
    required this.showCharacter,
    required this.showGuide,
    required this.onRandomToggle,
    required this.onHistoryToggle,
    required this.onCharacterToggle,
    required this.onGuideToggle,
    required this.onStrokeOrderPlay,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 360,
      ),
      child: Row(
        children: [
          _TextModeButton(
            label: randomMode ? '랜덤' : '순차',
            onTap: onRandomToggle,
          ),
          _Separator(),
          _HistoryButton(
            enabled: historyMode,
            onTap: onHistoryToggle,
          ),
          const Spacer(),
          _IconToggle(
            icon: showCharacter
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            enabled: showCharacter,
            tooltip: showCharacter ? '일본어 숨기기' : '일본어 표시',
            onTap: onCharacterToggle,
          ),
          const SizedBox(width: 8),
          _IconToggle(
            icon: showGuide ? Icons.grid_on_rounded : Icons.grid_off_rounded,
            enabled: showGuide,
            tooltip: showGuide ? '획순 가이드 숨기기' : '획순 가이드 표시',
            onTap: onGuideToggle,
          ),
          const SizedBox(width: 8),
          _IconAction(
            icon: Icons.play_arrow_rounded,
            tooltip: '획순 재생',
            onTap: onStrokeOrderPlay,
          ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Text(
        '·',
        style: TextStyle(
          fontSize: 14,
          color: colors.outline,
        ),
      ),
    );
  }
}

class _TextModeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextModeButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 3,
            vertical: 7,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _HistoryButton({
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 3,
            vertical: 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '기록',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? colors.onSurfaceVariant : colors.outline,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled ? colors.primary : Colors.transparent,
                  border: enabled
                      ? null
                      : Border.all(
                          color: colors.outline,
                          width: 1.2,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final String tooltip;
  final VoidCallback onTap;

  const _IconToggle({
    required this.icon,
    required this.enabled,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? const Color(0xFFFFE9A9) : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 18,
              color: enabled ? const Color(0xFF6B5420) : colors.outline,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFFFE9A9),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF6B5420),
            ),
          ),
        ),
      ),
    );
  }
}
