import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight offline painter used when cloud providers are unavailable.
class BillkaroAiImagePainter extends CustomPainter {
  BillkaroAiImagePainter({
    required this.analysis,
    required this.styleKey,
    required this.seed,
  });

  final PromptAnalysis analysis;
  final String styleKey;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final palette = _paletteFor(styleKey, analysis.hintColor);
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.$1, palette.$2],
        ).createShader(rect),
    );

    for (var i = 0; i < 24; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        10 + rng.nextDouble() * 48,
        Paint()..color = Colors.white.withOpacity(0.03 + rng.nextDouble() * 0.07),
      );
    }

    final center = Offset(size.width / 2, size.height / 2);
    final base = size.shortestSide * 0.22;
    _drawSubject(canvas, center, base, analysis.subject, rng);

    final title = analysis.titleWord.toUpperCase();
    final tp = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.78));
  }

  void _drawSubject(
    Canvas canvas,
    Offset c,
    double r,
    FoodSubject subject,
    math.Random rng,
  ) {
    switch (subject) {
      case FoodSubject.apple:
        canvas.drawCircle(c, r * 0.62, Paint()..color = const Color(0xFFE53935));
      case FoodSubject.coffee:
      case FoodSubject.tea:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: r * 1.2, height: r * 0.9),
            const Radius.circular(12),
          ),
          Paint()..color = const Color(0xFFEFEBE9),
        );
      case FoodSubject.biryani:
      case FoodSubject.generic:
      case FoodSubject.burger:
      case FoodSubject.pizza:
        for (var i = 0; i < 14; i++) {
          final a = i * (math.pi * 2 / 14);
          canvas.drawCircle(
            Offset(c.dx + math.cos(a) * r * 0.4, c.dy + math.sin(a) * r * 0.28),
            8 + rng.nextDouble() * 7,
            Paint()..color = Color.lerp(const Color(0xFFFFB300), const Color(0xFFEF6C00), rng.nextDouble())!,
          );
        }
    }
  }

  (Color, Color) _paletteFor(String style, Color? hint) {
    switch (style) {
      case 'anime':
        return (const Color(0xFF5C6BC0), const Color(0xFF8E99F3));
      case 'cartoon':
        return (const Color(0xFF1E88E5), const Color(0xFF42A5F5));
      case 'realistic':
        return (const Color(0xFF4E342E), const Color(0xFF8D6E63));
      default:
        return (hint ?? const Color(0xFF6A1B9A), const Color(0xFFAB47BC));
    }
  }

  @override
  bool shouldRepaint(covariant BillkaroAiImagePainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.analysis.prompt != analysis.prompt;
  }
}

enum FoodSubject { apple, tea, coffee, pizza, biryani, burger, generic }
enum PromptMood { neutral, warm, dark, bright }
enum ImageScene { food, restaurant, logo, nature, product, abstract }

class PromptAnalysis {
  PromptAnalysis({
    required this.prompt,
    required this.scene,
    required this.subject,
    required this.mood,
    required this.titleWord,
    this.hintColor,
  });

  final String prompt;
  final ImageScene scene;
  final FoodSubject subject;
  final PromptMood mood;
  final String titleWord;
  final Color? hintColor;
}

class PromptAnalyzer {
  static PromptAnalysis analyze(String prompt) {
    final p = prompt.toLowerCase();
    final words = p.split(RegExp(r'[^a-z0-9]+')).where((w) => w.length > 2).toList();

    final subject = p.contains('apple')
        ? FoodSubject.apple
        : (p.contains('coffee') || p.contains('espresso'))
        ? FoodSubject.coffee
        : (p.contains('tea') || p.contains('chai'))
        ? FoodSubject.tea
        : p.contains('pizza')
        ? FoodSubject.pizza
        : p.contains('biryani')
        ? FoodSubject.biryani
        : p.contains('burger')
        ? FoodSubject.burger
        : FoodSubject.generic;

    final mood = p.contains('warm') || p.contains('sunset')
        ? PromptMood.warm
        : p.contains('dark') || p.contains('night')
        ? PromptMood.dark
        : p.contains('bright') || p.contains('sunny')
        ? PromptMood.bright
        : PromptMood.neutral;

    final scene = p.contains('logo')
        ? ImageScene.logo
        : p.contains('restaurant') || p.contains('cafe')
        ? ImageScene.restaurant
        : ImageScene.food;

    return PromptAnalysis(
      prompt: prompt,
      scene: scene,
      subject: subject,
      mood: mood,
      titleWord: words.isEmpty ? 'art' : words.first,
      hintColor: _hintColor(p),
    );
  }

  static Color? _hintColor(String p) {
    if (p.contains('red')) return const Color(0xFFE53935);
    if (p.contains('green')) return const Color(0xFF43A047);
    if (p.contains('blue')) return const Color(0xFF1E88E5);
    if (p.contains('yellow')) return const Color(0xFFFDD835);
    return null;
  }
}
