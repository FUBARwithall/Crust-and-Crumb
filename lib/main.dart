import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/data/services/auth_service.dart';
import 'app/data/services/order_service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  final authService = Get.put(AuthService());
  Get.put(OrderService());

  final String initialRoute = authService.isLoggedIn ? Routes.CATALOG : Routes.LOGIN;

  runApp(
    GetMaterialApp(
      title: "Crust & Crumb",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B4513)),
        useMaterial3: true,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF8B4513),
          contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    ),
  );
}
