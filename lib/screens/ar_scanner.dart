import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';

class ARScanner extends StatefulWidget {
  const ARScanner({super.key});

  @override
  State<ARScanner> createState() => _ARScannerState();
}

class _ARScannerState extends State<ARScanner> {
  String _statusText = "Align medicine label within the box";
  bool _isScanning = true;

  // ============================================================
  // THIS IS THE "BRAIN" CODE YOU GAVE ME - INTEGRATED BELOW
  // ============================================================
  Future<void> _processImage(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      final String? foundName = barcode.rawValue;

      if (foundName != null) {
        setState(() {
          _statusText = "Detected: $foundName";
          _isScanning = false; // Stop scanning to show results
        });

        // Match detected text with medicine info and show sheet
        _handleMedicineMatch(foundName);
      }
    }
  }

  void _handleMedicineMatch(String name) {
    // Simulated Medicine Data (Your Mock Database)
    Map<String, String> medData = {
      "Dolo-650": "Used for fever and pain. Safe dose: 1 tab every 6 hours.",
      "Aspirin": "Blood thinner. WARNING: Do not take with Ibuprofen!",
      "Ibuprofen": "Anti-inflammatory. Take after meals to avoid acidity.",
    };

    String info =
        medData[name] ??
        "Medicine recognized, but details not in local database.";

    // Show the "Deep Dive" Bottom Sheet (Matching your Figma design)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDetailSheet(name, info),
    ).then((_) {
      // When the sheet is closed, start scanning again
      setState(() {
        _isScanning = true;
        _statusText = "Align medicine label within the box";
      });
    });
  }

  Widget _buildDetailSheet(String name, String info) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.verified, color: Color(0xFF2260FF), size: 30),
              const SizedBox(width: 10),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "Safety Information",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(info, style: GoogleFonts.inter(fontSize: 16, height: 1.5)),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2260FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$name added to Cabinet!")),
                );
              },
              child: Text(
                "Add to My Cabinet",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Live Camera Feed
          MobileScanner(onDetect: _processImage),

          // 2. The Custom Scanning Overlay (The fix for your previous error)
          Container(
            decoration: const ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Color(0xFF2260FF),
                borderRadius: 20,
                borderLength: 30,
                borderWidth: 10,
                cutOutWidth: 280,
                cutOutHeight: 180,
              ),
            ),
          ),

          // 3. Status Text at bottom
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CUSTOM PAINTER FOR THE SCANNING BOX (NO ERRORS NOW)
// ============================================================
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 10,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 20,
    this.borderLength = 30,
    this.cutOutWidth = 280,
    this.cutOutHeight = 180,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: cutOutWidth,
      height: cutOutHeight,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(
          RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        ),
      ),
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final borderPath = Path();
    // Top Left corner
    borderPath.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    borderPath.lineTo(cutOutRect.left, cutOutRect.top);
    borderPath.lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    // Top Right corner
    borderPath.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    borderPath.lineTo(cutOutRect.right, cutOutRect.top);
    borderPath.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom Left corner
    borderPath.moveTo(cutOutRect.left, cutOutRect.bottom - borderLength);
    borderPath.lineTo(cutOutRect.left, cutOutRect.bottom);
    borderPath.lineTo(cutOutRect.left + borderLength, cutOutRect.bottom);

    // Bottom Right corner
    borderPath.moveTo(cutOutRect.right - borderLength, cutOutRect.bottom);
    borderPath.lineTo(cutOutRect.right, cutOutRect.bottom);
    borderPath.lineTo(cutOutRect.right, cutOutRect.bottom - borderLength);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
