import 'package:flutter/material.dart';

class TKText extends StatelessWidget {
  final String text;
  final TKFont tkFont;
  final TextStyle style;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;

  TKText(this.text,
      {this.tkFont = TKFont.REGULAR,
        this.textAlign = TextAlign.left,
        this.maxLines,
        this.overflow,
        TextStyle style = const TextStyle()})
      : style = style;

  getFont(TKFont _hmFont) {
    switch (_hmFont) {
      case TKFont.REGULAR:
        return "Sarabun";
      case TKFont.MEDIUM:
        return "Sarabun-Medium";
      case TKFont.BOLD:
        return "Sarabun-SemiBold";
      case TKFont.SFProDisplayBold:
        return "SFProDisplay-Bold";
      case TKFont.SFProDisplayRegular:
        return "SFProDisplay-Regular";
      case TKFont.SFProDisplayMedium:
        return "SFProDisplay-Medium";
      case TKFont.SFProDisplaySemiBold:
        return "SFProDisplay-Semibold";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: style.copyWith(fontFamily: getFont(tkFont)));
  }
}

enum TKFont {
  REGULAR,
  MEDIUM,
  BOLD,
  SFProDisplayBold,
  SFProDisplayRegular,
  SFProDisplayMedium,
  SFProDisplaySemiBold
}
