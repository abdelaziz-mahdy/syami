import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:syami/constants/String%20constants.dart';
import 'package:syami/controller/Engine.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

Future<void> updateDialog(Version version) async {
  final SearchEngine cont = Get.find();
  Get.dialog(
    SimpleDialog(
        backgroundColor: StringConstants.dialogColor,
        title: CustomText(
          'Update YAY',
        ),
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                'Do you want to download it?',
              ),
              Container(
                  width: 0.5.sw,
                  height: 0.3.sh,
                  child: ListView.separated(
                      scrollDirection: Axis.vertical,
                      itemCount: cont.releaseNotes.length,
                      separatorBuilder: (context, index) {
                        return Divider(
                          height: 5,
                        );
                      },
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.all(1),
                          color: Colors.grey[900],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                  text: TextSpan(
                                      text: "Version" + ": ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      children: <TextSpan>[
                                    TextSpan(
                                        text: cont.releaseNotes[index].version),
                                  ])),
                              Divider(),
                              RichText(
                                  text: TextSpan(
                                      text: "Description" + ": ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      children: <TextSpan>[
                                    TextSpan(
                                        text: cont
                                            .releaseNotes[index].description),
                                  ])),
                            ],
                          ),
                        );
                      })),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomButton(
                      primary: Colors.grey[800]!, // background
                      onPrimary: Colors.white, // foreground

                      child: CustomText(
                        'No',
                      ),
                      onPressed: () {
                        Get.back();
                      }),
                  CustomButton(
                      primary: Colors.blue[800]!, // background
                      onPrimary: Colors.white, // foreground

                      child: CustomText(
                        'Yes',
                      ),
                      onPressed: () {
                        Get.back();
                        cont.launchDownloadLink();
                        //cont.downloaderController.downloadUpdateAndInstall();
                      }),
                ],
              ),
            ],
          ),
        ]),
  );
}
