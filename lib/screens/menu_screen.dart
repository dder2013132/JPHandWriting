import 'package:flutter/material.dart';

import 'practice_menu_screen.dart';
import 'quiz_setup_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // 앱 타이틀
              // 나중에 이미지로 교체 예정
              const Text(
                '일본어 필기 연습 ✍️',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3C3426),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '한 글자씩 천천히 연습해봐요',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.75),
                ),
              ),

              const SizedBox(height: 48),

              // 문자 연습
              _MenuCard(
                character: 'あ',
                title: '문자 연습',
                description: '히라가나 · 가타카나를 직접 써보세요',
                enabled: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PracticeMenuScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // 필기 퀴즈
              _MenuCard(
                character: '問',
                title: '필기 퀴즈',
                description: '발음을 보고 가나를 떠올려 써보세요',
                enabled: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QuizSetupScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String character;
  final String title;
  final String description;
  final bool enabled;
  final VoidCallback onTap;

  const _MenuCard({
    required this.character,
    required this.title,
    required this.description,
    required this.enabled,
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
          color: enabled ? const Color(0xFFFFF7DE) : const Color(0xFFF7F3E8),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: 150,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: enabled
                      ? const Color(0xFFE7D6AE)
                      : const Color(0xFFE4DED0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8C744A).withOpacity(
                      enabled ? 0.08 : 0.03,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Center(
                      child: Text(
                        character,
                        style: TextStyle(
                          fontFamily: 'KleeOne',
                          fontSize: 64,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? const Color(0xFF2F2A22)
                              : const Color(0xFFAAA394),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: enabled
                                ? const Color(0xFF3C3426)
                                : const Color(0xFF918B80),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: enabled
                                ? const Color(0xFF766A57)
                                : const Color(0xFFAAA397),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (enabled)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Color(0xFF8D7746),
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
