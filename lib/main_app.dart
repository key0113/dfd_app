import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:newdfd/controller/loading_controller.dart';
import 'package:newdfd/pages/main_page.dart';
import 'package:newdfd/utils/app_colors.dart';
import 'package:newdfd/widgets/loading_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
  }

  _getApp(BuildContext context) {
    return GetMaterialApp(
      color: AppColors.white,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      fallbackLocale: const Locale('ko'),
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            //? LOADING INDICATOR
            GetBuilder<LoadingController>(
              builder: (controller) {
                return Visibility(
                    visible: controller.isLoading,
                    child: const LoadingIndicatorWidget());
              },
            ),
          ],
        );
        // final MediaQueryData data = MediaQuery.of(context);
        // return MediaQuery(
        //   //! 안드로이드 폰트 사이즈 설정
        //   data: data.copyWith(textScaleFactor: 1.0),
        //   child: Stack(
        //     children: [
        //       if (child != null) child,

        //       //? LOADING INDICATOR
        //       GetBuilder<LoadingController>(
        //         builder: (controller) {
        //           return Visibility(
        //               visible: controller.isLoading,
        //               child: const LoadingIndicatorWidget());
        //         },
        //       ),
        //     ],
        //   ),
        // );
      },
      getPages: [
        GetPage(
            name: '/',
            transition: Transition.noTransition,
            page: () {
              return const MainPage();
            }),
      ],
      // theme: ThemeData(
      //     appBarTheme: AppBarTheme(
      //   systemOverlayStyle: SystemUiOverlayStyle.light,
      // )

      // scaffoldBackgroundColor: AppColors.white,
      // appBarTheme: const AppBarTheme(
      //   backgroundColor: AppColors.white,
      //   foregroundColor: AppColors.foregroundColor,
      //   systemOverlayStyle: SystemUiOverlayStyle.light, // 2
      // ),
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return _getApp(context);
        });
  }
}
