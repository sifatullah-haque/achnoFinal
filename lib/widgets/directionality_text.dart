import 'package:flutter/material.dart';
import 'package:achno/main.dart';

// A text widget that respects the text directionality but not layout directionality
class DirectionalityText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const DirectionalityText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    // Get text direction from parent DirectionalityOverride
    final override = DirectionalityOverride.of(context);
    final textDirection = override?.textDirection ?? TextDirection.ltr;

    // Calculate text alignment based on directionality if not explicitly provided
    TextAlign? effectiveTextAlign;
    if (textAlign == null) {
      effectiveTextAlign =
          textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left;
    } else {
      effectiveTextAlign = textAlign;
    }

    return Text(
      text,
      style: style,
      textAlign: effectiveTextAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textDirection: textDirection, // Apply text directionality explicitly
    );
  }
}

// Extension to easily replace Text widgets with DirectionalityText
extension TextDirectionality on Text {
  DirectionalityText withDirectionality() {
    return DirectionalityText(
      data ?? '',
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
