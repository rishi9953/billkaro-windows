import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String? text;
  final num size;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool isItalic;
  final bool isUnderline;
  final bool isLineThrough;
  final double? height;
  final double letterSpacing;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? padding;
  final TextBaseline? baseLine;
  final String? fontFamily;

  const AppText(
    this.text, {
    this.size = 14,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.isItalic = false,
    this.isUnderline = false,
    this.isLineThrough = false,
    this.height,
    this.letterSpacing = 0.5,
    this.fontWeight = FontWeight.normal,
    this.padding,
    this.baseLine,
    this.fontFamily,
    super.key,
  });

  const AppText.thin(
    this.text, {
    this.size = 14,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.isItalic = false,
    this.isUnderline = false,
    this.isLineThrough = false,
    this.height,
    this.letterSpacing = 0.5,
    this.padding,
    this.baseLine,
    this.fontFamily,
    super.key,
  }) : fontWeight = FontWeight.w100;

  const AppText.extraLight(
    this.text, {
    this.size = 14,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.isItalic = false,
    this.isUnderline = false,
    this.isLineThrough = false,
    this.height,
    this.letterSpacing = 0.5,
    this.padding,
    this.baseLine,
    this.fontFamily,
    super.key,
  }) : fontWeight = FontWeight.w200;

  const AppText.light(
    this.text, {
    this.size = 14,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.isItalic = false,
    this.isUnderline = false,
    this.isLineThrough = false,
    this.height,
    this.letterSpacing = 0.5,
    this.padding,
    this.baseLine,
    this.fontFamily,
    super.key,
  }) : fontWeight = FontWeight.w300;

  const AppText.regular(
    this.text, {
    this.size = 14,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.isItalic = false,
    this.isUnderline = false,
    this.isLineThrough = false,
    this.height,
    this.letterSpacing = 0.5,
    this.padding,
    this.baseLine,
    this.fontFamily,
    super.key,
  }) : fontWeight = FontWeight.w400;

  const AppText.medium(
    this.text, {
    this.size = 14,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.isItalic = false,
    this.isUnderline = false,
    this.isLineThrough = false,
    this.height,
    this.letterSpacing = 0.5,
    this.padding,
    this.baseLine,
    this.fontFamily,
    super.key,
  }) : fontWeight = FontWeight.w500;

  const AppText.semiBold(
    this.text, {
    this.size = 14,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.isItalic = false,
    this.isUnderline = false,
    this.isLineThrough = false,
    this.height,
    this.letterSpacing = 0.5,
    this.padding,
    this.baseLine,
    this.fontFamily,
    super.key,
  }) : fontWeight = FontWeight.w600;

  const AppText.bold(
    this.text, {
    this.size = 14,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.isItalic = false,
    this.isUnderline = false,
    this.isLineThrough = false,
    this.height,
    this.letterSpacing = 0.5,
    this.padding,
    this.baseLine,
    this.fontFamily,
    super.key,
  }) : fontWeight = FontWeight.w700;

  const AppText.extraBold(
    this.text, {
    this.size = 14,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.isItalic = false,
    this.isUnderline = false,
    this.isLineThrough = false,
    this.height,
    this.letterSpacing = 0.5,
    this.padding,
    this.baseLine,
    this.fontFamily,
    super.key,
  }) : fontWeight = FontWeight.w800;

  const AppText.black(
    this.text, {
    this.size = 14,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.isItalic = false,
    this.isUnderline = false,
    this.isLineThrough = false,
    this.height,
    this.letterSpacing = 0.5,
    this.padding,
    this.baseLine,
    this.fontFamily,
    super.key,
  }) : fontWeight = FontWeight.w900;

  @override
  Widget build(BuildContext context) {
    final widget = Text(
      text ?? '',
      textAlign: textAlign ?? TextAlign.start,
      overflow: overflow,
      maxLines: maxLines,
      style: style,
      textHeightBehavior:
          const TextHeightBehavior(applyHeightToLastDescent: false),
    );

    return padding != null ? Padding(padding: padding!, child: widget) : widget;
  }

  TextStyle get style => TextStyle(
        color: color,
        decorationColor: color,
        fontSize: size.toDouble(),
        fontStyle: isItalic ? FontStyle.italic : null,
        decoration: isUnderline
            ? TextDecoration.underline
            : (isLineThrough
                ? TextDecoration.lineThrough
                : TextDecoration.none),
        // fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        textBaseline: baseLine,
        fontFamily: fontFamily,
        fontVariations: [FontVariation.weight(fontWeight.value.toDouble())],
      );
}
