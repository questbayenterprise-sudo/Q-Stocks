import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../auth/Session/user_session.dart';
import '../../data/qr_scan_repository.dart';
import 'scan_result_page.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  final QrScanRepository _repo = QrScanRepository();
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    final scannedData = barcode.rawValue!;
    final scannerId = int.tryParse(UserSession().userId ?? '0') ?? 0;

    // Parse QR data — could be booking ref (QS-20260322-001) or full text
    String? bookingRef;
    int? bookingId;

    // Try to extract booking ref pattern
    final refMatch = RegExp(r'QS-\d{8}-\d+').firstMatch(scannedData);
    if (refMatch != null) {
      bookingRef = refMatch.group(0);
    } else {
      // Try to extract booking ID
      final idMatch = RegExp(r'(?:booking_id|id)[:\s]*(\d+)', caseSensitive: false)
          .firstMatch(scannedData);
      if (idMatch != null) {
        bookingId = int.tryParse(idMatch.group(1) ?? '');
      }
    }

    if (bookingRef == null && bookingId == null) {
      // Try parsing the whole string as an ID
      bookingId = int.tryParse(scannedData);
    }

    if (bookingRef == null && bookingId == null) {
      if (mounted) {
        _showError("Invalid QR code format");
        setState(() => _isProcessing = false);
        _controller.start();
      }
      return;
    }

    // Validate with backend
    final result = await _repo.validateScan(
      bookingRef: bookingRef,
      bookingId: bookingId,
      scannerId: scannerId,
    );

    if (!mounted) return;

    if (result == null) {
      _showError("Failed to connect to server");
      setState(() => _isProcessing = false);
      _controller.start();
      return;
    }

    if (result['success'] == true && result['data'] != null) {
      // Navigate to scan result page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultPage(
            bookingData: Map<String, dynamic>.from(result['data']),
          ),
        ),
      );
    } else {
      _showError(result['message'] ?? 'Invalid QR code');
      // If booking found but already completed, show details anyway
      if (result['data'] != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ScanResultPage(
              bookingData: Map<String, dynamic>.from(result['data']),
            ),
          ),
        );
      } else {
        setState(() => _isProcessing = false);
        _controller.start();
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Scan Booking QR",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? Colors.amber : Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay with cutout
          _buildScanOverlay(),

          // Bottom instruction
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_isProcessing)
                  const CircularProgressIndicator(color: Color(0xFF00A36C))
                else
                  const Text(
                    "Point camera at booking QR code",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _isProcessing ? "Validating..." : "Auto-scan enabled",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    const scanAreaSize = 260.0;
    const borderRadius = 20.0;
    const borderWidth = 3.0;
    const cornerLength = 30.0;
    const green = Color(0xFF00A36C);

    return LayoutBuilder(
      builder: (context, constraints) {
        final left = (constraints.maxWidth - scanAreaSize) / 2;
        final top = (constraints.maxHeight - scanAreaSize) / 2 - 40;

        return Stack(
          children: [
            // Dark overlay with transparent cutout
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.red, // Any color, will be cut out
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corner borders
            Positioned(
              left: left,
              top: top,
              child: _corner(green, borderWidth, cornerLength,
                  topLeft: true),
            ),
            Positioned(
              left: left + scanAreaSize - cornerLength,
              top: top,
              child: _corner(green, borderWidth, cornerLength,
                  topRight: true),
            ),
            Positioned(
              left: left,
              top: top + scanAreaSize - cornerLength,
              child: _corner(green, borderWidth, cornerLength,
                  bottomLeft: true),
            ),
            Positioned(
              left: left + scanAreaSize - cornerLength,
              top: top + scanAreaSize - cornerLength,
              child: _corner(green, borderWidth, cornerLength,
                  bottomRight: true),
            ),
          ],
        );
      },
    );
  }

  Widget _corner(Color color, double width, double length,
      {bool topLeft = false,
      bool topRight = false,
      bool bottomLeft = false,
      bool bottomRight = false}) {
    return SizedBox(
      width: length,
      height: length,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          strokeWidth: width,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (topLeft) {
      canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
      canvas.drawLine(
          Offset(size.width, 0), Offset(size.width, size.height), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(
          Offset(0, size.height), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
    }
    if (bottomRight) {
      canvas.drawLine(
          Offset(0, size.height), Offset(size.width, size.height), paint);
      canvas.drawLine(
          Offset(size.width, 0), Offset(size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
