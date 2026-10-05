import 'package:flutter/material.dart';

import 'practice_screen.dart';

class PracticeMenuScreen extends StatelessWidget {
  const PracticeMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final heightScale = (screenHeight / 900).clamp(0.78, 1.0).toDouble();

    final cardHeight = 125.0 * heightScale;
    final characterSize = 44.0 * heightScale;
    final sectionGap = 18.0 * heightScale;
    final titleGap = 9.0 * heightScale;
    final cardInnerGap = 9.0 * heightScale;

    return Scaffold(
      appBar: AppBar(
        title: const Text('문자 연습'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    '연습할 문자를 골라봐요',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF766A57),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _SectionTitle(
                    title: '기본 문자',
                  ),
                  SizedBox(height: titleGap),
                  Row(
                    children: [
                      Expanded(
                        child: _PracticeCard(
                          character: 'あ',
                          title: '히라가나',
                          subtitle: '46자',
                          height: cardHeight,
                          characterSize: characterSize,
                          innerGap: cardInnerGap,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PracticeScreen(
                                  initialHiragana: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _PracticeCard(
                          character: 'ア',
                          title: '가타카나',
                          subtitle: '46자',
                          height: cardHeight,
                          characterSize: characterSize,
                          innerGap: cardInnerGap,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PracticeScreen(
                                  initialHiragana: false,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sectionGap),
                  const _SectionTitle(
                    title: '탁음',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PracticeCard(
                          character: 'が',
                          title: '히라가나',
                          subtitle: '20자',
                          height: cardHeight,
                          characterSize: characterSize,
                          innerGap: cardInnerGap,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PracticeScreen(
                                  initialHiragana: true,
                                  category: PracticeCategory.dakuten,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _PracticeCard(
                          character: 'ガ',
                          title: '가타카나',
                          subtitle: '20자',
                          height: cardHeight,
                          characterSize: characterSize,
                          innerGap: cardInnerGap,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PracticeScreen(
                                  initialHiragana: false,
                                  category: PracticeCategory.dakuten,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sectionGap),
                  const _SectionTitle(
                    title: '반탁음',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PracticeCard(
                          character: 'ぱ',
                          title: '히라가나',
                          subtitle: '5자',
                          height: cardHeight,
                          characterSize: characterSize,
                          innerGap: cardInnerGap,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PracticeScreen(
                                  initialHiragana: true,
                                  category: PracticeCategory.handakuten,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _PracticeCard(
                          character: 'パ',
                          title: '가타카나',
                          subtitle: '5자',
                          height: cardHeight,
                          characterSize: characterSize,
                          innerGap: cardInnerGap,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PracticeScreen(
                                  initialHiragana: false,
                                  category: PracticeCategory.handakuten,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sectionGap),
                  const _SectionTitle(
                    title: '요음',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PracticeCard(
                          character: 'きゃ',
                          title: '히라가나',
                          subtitle: '33자',
                          height: cardHeight,
                          characterSize: characterSize,
                          innerGap: cardInnerGap,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PracticeScreen(
                                  initialHiragana: true,
                                  category: PracticeCategory.youon,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _PracticeCard(
                          character: 'キャ',
                          title: '가타카나',
                          subtitle: '33자',
                          height: cardHeight,
                          characterSize: characterSize,
                          innerGap: cardInnerGap,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PracticeScreen(
                                  initialHiragana: false,
                                  category: PracticeCategory.youon,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF3C3426),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final String character;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  final double height;
  final double characterSize;
  final double innerGap;

  const _PracticeCard({
    required this.character,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    required this.height,
    required this.characterSize,
    required this.innerGap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? const Color(0xFFFFF7DE) : const Color(0xFFF7F3E8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: height < 115 ? 8 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  enabled ? const Color(0xFFE7D6AE) : const Color(0xFFE4DED0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C744A).withOpacity(
                  enabled ? 0.07 : 0.025,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                character,
                style: TextStyle(
                  fontFamily: 'KleeOne',
                  fontSize: characterSize,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? const Color(0xFF2F2A22)
                      : const Color(0xFFAAA394),
                ),
              ),
              SizedBox(height: innerGap),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? const Color(0xFF3C3426)
                      : const Color(0xFF918B80),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: enabled
                      ? const Color(0xFF82755F)
                      : const Color(0xFFAAA397),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
