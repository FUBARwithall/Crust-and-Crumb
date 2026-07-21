// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../data/models/order_model.dart';
import '../../../../data/utils/app_snackbar.dart';

class ReceiptCard extends StatelessWidget {
  final OrderModel order;
  final GlobalKey _globalKey = GlobalKey();

  ReceiptCard({super.key, required this.order});

  Uint8List _encodeRgbaToBmp(Uint8List rgbaBytes, int width, int height) {
    const int fileHeaderSize = 14;
    const int infoHeaderSize = 40;
    const int headerSize = fileHeaderSize + infoHeaderSize;
    final int pixelDataSize = width * height * 4;
    final int fileSize = headerSize + pixelDataSize;

    final ByteData header = ByteData(headerSize);

    // File Header ('BM')
    header.setUint8(0, 0x42);
    header.setUint8(1, 0x4D);
    header.setUint32(2, fileSize, Endian.little);
    header.setUint16(6, 0, Endian.little);
    header.setUint16(8, 0, Endian.little);
    header.setUint32(10, headerSize, Endian.little);

    // Info Header (BITMAPINFOHEADER)
    header.setUint32(14, infoHeaderSize, Endian.little);
    header.setInt32(18, width, Endian.little);
    header.setInt32(22, -height, Endian.little); // Top-down
    header.setUint16(26, 1, Endian.little);
    header.setUint16(28, 32, Endian.little); // 32 bpp
    header.setUint32(30, 0, Endian.little);
    header.setUint32(34, pixelDataSize, Endian.little);
    header.setInt32(38, 2835, Endian.little);
    header.setInt32(42, 2835, Endian.little);
    header.setUint32(46, 0, Endian.little);
    header.setUint32(50, 0, Endian.little);

    // Convert RGBA to BGRA (Standard BMP pixel order)
    final Uint8List bgraPixels = Uint8List(pixelDataSize);
    for (int i = 0; i < rgbaBytes.length && i + 3 < pixelDataSize; i += 4) {
      bgraPixels[i] = rgbaBytes[i + 2];     // Blue
      bgraPixels[i + 1] = rgbaBytes[i + 1]; // Green
      bgraPixels[i + 2] = rgbaBytes[i];     // Red
      bgraPixels[i + 3] = rgbaBytes[i + 3]; // Alpha
    }

    final builder = BytesBuilder();
    builder.add(header.buffer.asUint8List());
    builder.add(bgraPixels);
    return builder.toBytes();
  }

  Future<void> _downloadAsBmp() async {
    try {
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData();
      if (byteData == null) return;

      final Uint8List rawRgbaBytes = byteData.buffer.asUint8List();
      final Uint8List bmpBytes = _encodeRgbaToBmp(rawRgbaBytes, image.width, image.height);

      if (kIsWeb) {
        final blob = html.Blob([bmpBytes], 'image/bmp');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..target = '_blank'
          ..download = 'struk_${order.id}.bmp';
        anchor.click();
        html.Url.revokeObjectUrl(url);
      }

      AppSnackbar.success(
        'Struk Berhasil Di-download',
        'File gambar struk_${order.id}.bmp tersimpan.',
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
              onPressed: _downloadAsBmp,
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
