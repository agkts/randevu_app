import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Responsive {
  // Mobil için maksimum genişlik
  static const double mobileMaxWidth = 650;

  // Tablet için maksimum genişlik
  static const double tabletMaxWidth = 1100;

  // Ekran boyutuna göre cihaz tipini belirleme
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMaxWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < tabletMaxWidth &&
      MediaQuery.of(context).size.width >= mobileMaxWidth;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMaxWidth;

  // GetX kullanarak ekran boyutunu alma (context olmadan da kullanılabilir)
  static double get width => Get.width;
  static double get height => Get.height;

  // Ekran genişliğine göre ölçekleme
  static double wp(double percentage) => Get.width * (percentage / 100);

  // Ekran yüksekliğine göre ölçekleme
  static double hp(double percentage) => Get.height * (percentage / 100);

  // Cihaz tipine göre değer döndürme
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // Yatay padding değeri (cihaz tipine göre)
  static EdgeInsets get horizontalPadding =>
      EdgeInsets.symmetric(horizontal: wp(isMobile(Get.context!) ? 4.0 : 8.0));

  // Dikey padding değeri
  static EdgeInsets get verticalPadding =>
      EdgeInsets.symmetric(vertical: hp(2.0));

  // Standart sayfa padding'i
  static EdgeInsets get pagePadding => EdgeInsets.symmetric(
    horizontal: wp(isMobile(Get.context!) ? 4.0 : 8.0),
    vertical: hp(2.0),
  );

  // Ekran moduna göre boyut alma (SafeArea için)
  static EdgeInsets safeAreaPadding() => EdgeInsets.only(
    top: Get.mediaQuery.padding.top,
    bottom: Get.mediaQuery.padding.bottom,
  );

  // Cihaz tipine uygun kolon sayısı
  static int get gridCrossAxisCount {
    if (isMobile(Get.context!)) return 1;
    if (isTablet(Get.context!)) return 2;
    return 3; // Desktop
  }

  // Responsive genişlikleri
  static double get formWidth {
    if (isMobile(Get.context!)) return wp(90);
    if (isTablet(Get.context!)) return wp(70);
    return wp(50); // Desktop
  }

  // Responsive yükseklikler
  static double get buttonHeight => hp(6);
  static double get inputHeight => hp(6);
  static double get cardHeight => hp(15);
}
