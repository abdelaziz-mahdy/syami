import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StringConstants {
  static double cornersSettings = 5;
}

class CustomText extends StatelessWidget {
  final String text;
  final bool bold;
  final bool center;
  final Color color;
  final double? defaultFont;
  final int maxLines;

  const CustomText(
    this.text, {
    super.key,
    this.bold = false,
    this.center = true,
    this.color = Colors.white,
    this.defaultFont,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      softWrap: true,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: TextStyle(
        color: color,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: defaultFont ?? 15.sp,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
    );
  }
}

class CustomButton extends StatelessWidget {
  final Widget child;
  final Color? primary;
  final Color? onPrimary;
  final Color? borderColor;
  final double? width;
  final double? height;
  final void Function()? onPressed;

  const CustomButton({
    super.key,
    required this.child,
    this.primary,
    this.onPrimary,
    this.borderColor,
    this.width,
    this.height,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size(width ?? 30.w, height ?? 50.h),
        side: borderColor != null
            ? BorderSide(width: 1.r, color: borderColor!)
            : null,
        backgroundColor: primary ?? Colors.grey[900],
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
