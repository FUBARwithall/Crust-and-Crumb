import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/order_service.dart';
import '../../../data/utils/app_snackbar.dart';

class AdminController extends GetxController {
  final OrderService orderService = Get.find<OrderService>();

  RxList<OrderModel> get orders => orderService.orders;

  Future<void> openInGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      AppSnackbar.error('Gagal Membuka Peta', 'Tidak dapat membuka Google Maps pada perangkat ini.');
    }
  }
}
