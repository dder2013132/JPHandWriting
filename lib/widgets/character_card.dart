import 'package:flutter/material.dart';

class CharacterCard extends StatelessWidget {
  final String character;
  final String korean;
  final bool showCharacter;
  final VoidCallback onTap;

  const CharacterCard({
    super.key,
    required this.character,
    required this.korean,
    required this.showCharacter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 360,
        ),
        child: Material(
          color: const Color(0xFFFFF7DE),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: 112,
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE7D6AE),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8C744A).withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showCharacter) ...[
                    Text(
                      character,
                      style: TextStyle(
                        fontFamily: 'KleeOne',
                        fontSize: character.length > 1 ? 52 : 68,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2F2A22),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],

                  Text(
                    korean,
                    style: TextStyle(
                      fontSize: showCharacter ? 27 : 40,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5F513C),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4E2A7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: Color(0xFF6E5520),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}