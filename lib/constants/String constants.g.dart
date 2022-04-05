// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'String constants.dart';

// **************************************************************************
// FunctionalWidgetGenerator
// **************************************************************************

class CustomAutoSizeText extends StatelessWidget {
  const CustomAutoSizeText(this.text,
      {Key? key,
      this.bold = false,
      this.center = true,
      this.maxFont,
      this.minFont,
      this.maxLines = 1,
      this.color = Colors.white,
      this.defaultFont})
      : super(key: key);

  final String text;

  final bool bold;

  final bool center;

  final double? maxFont;

  final double? minFont;

  final int maxLines;

  final Color color;

  final double? defaultFont;

  @override
  Widget build(BuildContext _context) => customAutoSizeText(text,
      bold: bold,
      center: center,
      maxFont: maxFont,
      minFont: minFont,
      maxLines: maxLines,
      color: color,
      defaultFont: defaultFont);
}

class CustomText extends StatelessWidget {
  const CustomText(this.text,
      {Key? key,
      this.bold = false,
      this.center = false,
      this.color = Colors.white,
      this.defaultFont,
      this.maxLines = 1})
      : super(key: key);

  final String text;

  final bool bold;

  final bool center;

  final Color color;

  final double? defaultFont;

  final int maxLines;

  @override
  Widget build(BuildContext _context) => customText(text,
      bold: bold,
      center: center,
      color: color,
      defaultFont: defaultFont,
      maxLines: maxLines);
}

class CustomButton extends StatelessWidget {
  const CustomButton(
      {Key? key,
      required this.child,
      this.primary,
      this.onPrimary,
      this.borderColor,
      this.width,
      this.height,
      this.onPressed})
      : super(key: key);

  final Widget child;

  final Color? primary;

  final Color? onPrimary;

  final Color? borderColor;

  final double? width;

  final double? height;

  final void Function()? onPressed;

  @override
  Widget build(BuildContext _context) => customButton(
      child: child,
      primary: primary,
      onPrimary: onPrimary,
      borderColor: borderColor,
      width: width,
      height: height,
      onPressed: onPressed);
}

class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget(this.state, this.child, {Key? key})
      : super(key: key);

  final LoadingStatus state;

  final Widget child;

  @override
  Widget build(BuildContext _context) => loadingStateWidget(state, child);
}
