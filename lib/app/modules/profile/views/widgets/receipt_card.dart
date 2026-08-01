import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../data/models/order_model.dart';
import '../../../../data/utils/app_snackbar.dart';
import '../../../../data/utils/download_helper.dart';

class ReceiptCard extends StatelessWidget {
  final OrderModel order;
  final GlobalKey _globalKey = GlobalKey();

  ReceiptCard({super.key, required this.order});

  Future<void> _downloadAsPng() async {
    try {
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      downloadBmpFile(pngBytes, 'struk_${order.id}.png');

      AppSnackbar.success(
        'Struk Tersimpan di Folder Download',
        'File struk_${order.id}.png berhasil tersimpan di folder Download / Pictures HP Anda.',
      );
    } catch (e) {
      debugPrint('[ReceiptCard] Error downloading receipt: $e');
      AppSnackbar.info(
        'Struk Di-capture',
        'Struk transaksi ${order.id} siap dicetak.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${order.orderTime.day.toString().padLeft(2, '0')}/${order.orderTime.month.toString().padLeft(2, '0')}/${order.orderTime.year} ${order.orderTime.hour.toString().padLeft(2, '0')}:${order.orderTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          // Repaint Boundary Wrap for Image Conversion
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF9), // Thermal paper background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2D8CC), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Receipt Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B4513),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bakery_dining,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'CRUST & CRUMB BAKERY',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const Text(
                          'STRUK BUKTI PEMBAYARAN RESMI',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            letterSpacing: 1.0,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDashedLine(),
                  const SizedBox(height: 14),

                  // Metadata Section
                  _buildRowDetail('No. Struk', order.id),
                  _buildRowDetail('Waktu Transaksi', formattedDate),
                  _buildRowDetail('Pelanggan', order.customerName),
                  _buildRowDetail('No. Telepon', order.customerPhone.isNotEmpty ? order.customerPhone : '-'),
                  if (order.addressNotes.isNotEmpty)
                    _buildRowDetail('Patokan Alamat', order.addressNotes),
                  _buildRowDetail('Opsi Pengiriman', order.shippingMethod.isNotEmpty ? order.shippingMethod : 'Kurir Express'),
                  _buildRowDetail('Metode Pembayaran', order.paymentMethod.isNotEmpty ? order.paymentMethod : 'COD'),
                  _buildRowDetail('Koordinat GPS', '${order.latitude.toStringAsFixed(4)}, ${order.longitude.toStringAsFixed(4)}'),

                  const SizedBox(height: 14),
                  _buildDashedLine(),
                  const SizedBox(height: 14),

                  // Items Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('ITEM', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                      Text('SUBTOTAL', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Item Rows
                  ...order.items.map((cartItem) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${cartItem.item.name} (${cartItem.quantity}x)',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Color(0xFF2B1B17),
                              ),
                            ),
                          ),
                          Text(
                            'Rp ${cartItem.subtotal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B1B17),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 14),
                  _buildDashedLine(),
                  const SizedBox(height: 14),

                  // Total & Status Stamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL PEMBAYARAN',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rp ${order.totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B4513),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
                        ),
                        child: const Text(
                          'LUNAS / PAID',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildDashedLine(),
                  const SizedBox(height: 16),

                  // Receipt Footer Barcode Simulation
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          '||| | ||||| ||| |||| || ||||| ||| |||',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Terima Kasih Atas Kunjungan Anda!',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action Buttons: Download Struk Image
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B4513),
                side: const BorderSide(color: Color(0xFF8B4513), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.download_for_offline_outlined, size: 20),
              label: const Text(
                'Download Struk (Gambar BMP)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: _downloadAsPng,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B1B17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFBCAAA4)),
              ),
            );
          }),
        );
      },
    );
  }
}
