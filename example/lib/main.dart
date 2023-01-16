import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon_example/controller/requirement_state_controller.dart';
import 'package:flutter_beacon_example/view/home_page.dart';
import 'package:get/get.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Get.put(RequirementStateController());

    final themeData = Theme.of(context);
    final primary = Colors.blue;

    return GetMaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: primary,
        appBarTheme: themeData.appBarTheme.copyWith(
          elevation: 0.5,
          color: Colors.white,
          actionsIconTheme: themeData.primaryIconTheme.copyWith(
            color: primary,
          ),
          iconTheme: themeData.primaryIconTheme.copyWith(
            color: primary,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          toolbarTextStyle: themeData.primaryTextTheme
              .copyWith(
                headline6: themeData.textTheme.headline6?.copyWith(
                  color: primary,
                ),
              )
              .bodyText2,
          titleTextStyle: themeData.primaryTextTheme
              .copyWith(
                headline6: themeData.textTheme.headline6?.copyWith(
                  color: primary,
                ),
              )
              .headline6,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: primary,
      ),
      home: HomePage(),
    );
  }
}
