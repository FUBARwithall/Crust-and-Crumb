import 'package:get/get.dart';

import '../../catalog/controllers/catalog_controller.dart';
import '../../checkout/controllers/checkout_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<CatalogController>(() => CatalogController());
    Get.lazyPut<CheckoutController>(() => CheckoutController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
