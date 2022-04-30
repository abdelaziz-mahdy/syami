import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:syami/controller/classes.dart';
import 'package:url_launcher/url_launcher.dart';

part 'String constants.g.dart';

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

Widget customAutoSizeText(String text,
    {bool bold = false,
    bool center = true,
    double? maxFont,
    double? minFont,
    int maxLines = 1,
    Color color = Colors.white,
    double? defaultFont}) {
  //print(maxFont??double.parse((18.sp).toStringAsFixed(1)));
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

Widget customText(String text,
    {bool bold = false,
    bool center = false,
    Color color = Colors.white,
    double? defaultFont,
    int maxLines = 1}) {
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

Widget customButton(
    {required Widget child,
    Color? primary,
    Color? onPrimary,
    Color? borderColor,
    double? width,
    double? height,
    void Function()? onPressed}) {
  return TextButton(
    style: TextButton.styleFrom(
        //elevation: 2,
        //shadowColor: Colors.black,
        //onSurface: Colors.purple,
        minimumSize: Size(width ?? 30.w, height ?? 30.h),
        side: borderColor != null
            ? BorderSide(width: 1.r, color: borderColor)
            : null,
        // primary: , // background
        backgroundColor: primary ?? Colors.grey[900]
        //onPrimary: onPrimary??Colors.blue,
        ),
    onPressed: onPressed,
    child: child,
  );
}

Path buildHeartPath(double scale) {
  return Path()
    ..moveTo(55 * scale, 15 * scale)
    ..cubicTo(
        55 * scale, 12 * scale, 50 * scale, 0 * scale, 30 * scale, 0 * scale)
    ..cubicTo(
        0 * scale, 0 * scale, 0 * scale, 37.5 * scale, 0 * scale, 37.5 * scale)
    ..cubicTo(
        0 * scale, 55 * scale, 20 * scale, 77 * scale, 55 * scale, 95 * scale)
    ..cubicTo(90 * scale, 77 * scale, 110 * scale, 55 * scale, 110 * scale,
        37.5 * scale)
    ..cubicTo(110 * scale, 37.5 * scale, 110 * scale, 0 * scale, 80 * scale,
        0 * scale)
    ..cubicTo(
        65 * scale, 0 * scale, 55 * scale, 12 * scale, 55 * scale, 15 * scale)
    ..close();
}

Widget loadingStateWidget(LoadingStatus state, Widget child) {
  print("state == " + state.toString());
  if (state == LoadingStatus.loading) {
    print("loading");
    return Container(
        key: UniqueKey(),
        width: 50.w,
        height: 50.h,
        child: Center(child: CircularProgressIndicator()));
  }
  if (state == LoadingStatus.error) {
    print("error");
    return Container(
        key: UniqueKey(),
        width: 50.w,
        height: 50.h,
        child: Center(
            child: Icon(
          Icons.error,
          color: Colors.red,
        )));
  }
  print("loaded");

  return child;
}

void launchURL(String url) async {
  if (!await launch(url)) throw 'Could not launch $url';
}
