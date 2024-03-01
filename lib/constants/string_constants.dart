import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syami/controller/classes.dart';

class StringConstants {
  static String appName = 'Anime Here';
  static String errorsEmail = "zcreations00@gmail.com";
  static String loadingLink1 = "Reading the site";
  static String loadingLink2 = "converting the response";
  static String loadingLinkError = "Connection Failed";

  static double paddingSettings = 5;
  static double cornersSettings = 5;
  static double cornersSettings2 = 10;
  static double iconSize = 20;
  static Color iconColorSettings = Colors.blueAccent;
  static Color dialogColor = Colors.grey.shade800;
  static Color messagesColor = Colors.grey.shade900;
  static Color videoPlayerButtonsColor = Colors.black45;

////////////////////////////////////////////////////////////
  static const SECRET_KEY = "2020_PRIVATES_KEYS_ENCRYPTS_2020";
//////////////////////////////////////////////////////////////////
}

class CustomAutoSizeText extends StatelessWidget {
  final String text;
  final bool bold;
  final bool center;
  final double? maxFont;
  final double? minFont;
  final int maxLines;
  final Color color;
  final double? defaultFont;

  const CustomAutoSizeText(
    this.text, {
    super.key,
    this.bold = false,
    this.center = true,
    this.maxFont,
    this.minFont,
    this.maxLines = 1,
    this.color = Colors.white,
    this.defaultFont,
  });

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      maxLines: maxLines,
      maxFontSize: maxFont ?? double.parse((16.sp).toStringAsFixed(0)),
      minFontSize: minFont ?? double.parse((12.sp).toStringAsFixed(0)),
      softWrap: true,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: TextStyle(
        color: color,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: defaultFont ?? double.parse((17.sp).toStringAsFixed(0)),
      ),
      overflow: TextOverflow.ellipsis,
      stepGranularity: 0.1,
    );
  }
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
    this.center = false,
    this.color = Colors.white,
    this.defaultFont,
    this.maxLines = 1,
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
        fontSize: defaultFont ?? 18.sp,
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
        minimumSize: Size(width ?? 30.w, height ?? 30.h),
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

class LoadingStateWidget extends StatelessWidget {
  final LoadingStatus state;
  final Widget child;

  const LoadingStateWidget({
    super.key,
    required this.state,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case LoadingStatus.loading:
        return SizedBox(
            width: 50.w,
            height: 50.h,
            child: const Center(child: CircularProgressIndicator()));
      case LoadingStatus.error:
        return SizedBox(
            width: 50.w,
            height: 50.h,
            child: const Center(child: Icon(Icons.error, color: Colors.red)));
      default:
        return child;
    }
  }
}
