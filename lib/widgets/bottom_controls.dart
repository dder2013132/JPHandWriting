import 'package:flutter/material.dart';

class BottomControls extends StatelessWidget {
  final int currentIndex;
  final int totalCount;

  final VoidCallback onPrevious;
  final VoidCallback onClear;
  final VoidCallback onNext;

  const BottomControls({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.onPrevious,
    required this.onClear,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          '${currentIndex + 1} / $totalCount',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant.withOpacity(0.75),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                ),
                label: const Text('이전'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                ),
              ),
            ),

            const SizedBox(width: 10),

            SizedBox(
              width: 52,
              height: 50,
              child: OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Icon(
                  Icons.cleaning_services_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: onNext,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                ),
                label: const Text('다음'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}