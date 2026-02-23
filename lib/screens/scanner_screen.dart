import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';
import '../medicine_details_screen.dart';
import '../services/medicine_data.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.all],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isNavigating = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Map<String, String> _parseMedicineQR(String rawValue) {
    String cleanCode = rawValue;
    String batch = "Not Available";
    String expiry = "Not Available";
    bool isAuthentic = false;

    try {
      if (rawValue.startsWith('01') && rawValue.length >= 16) {
        String gtinPart = rawValue.substring(2, 16); 
        cleanCode = BigInt.parse(gtinPart).toString(); 

        if (rawValue.contains('17')) {
          int idx = rawValue.indexOf('17') + 2;
          if (rawValue.length >= idx + 6) {
            String yy = rawValue.substring(idx, idx + 2);
            String mm = rawValue.substring(idx + 2, idx + 4);
            String dd = rawValue.substring(idx + 4, idx + 6);
            expiry = "$dd/$mm/20$yy";
          }
        }

        if (rawValue.contains('10')) {
          int idx = rawValue.indexOf('10') + 2;
          batch = rawValue.substring(idx).split('17').first.split('21').first;
        }

        if (rawValue.contains('21')) {
          isAuthentic = true;
        }
      } 
      else if (rawValue.length == 14 && rawValue.startsWith('0')) {
        cleanCode = BigInt.parse(rawValue).toString();
      }

      return {
        "code": cleanCode,
        "batch": batch,
        "expiry": expiry,
        "authentic": isAuthentic ? "YES" : "NO",
      };
    } catch (e) {
      return {"code": rawValue, "batch": "Unknown", "expiry": "Unknown", "authentic": "NO"};
    }
  }

  void _showNotFoundDialog(BuildContext context, String code) {
    HapticFeedback.heavyImpact(); 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Product Unrecognized"),
        content: Text("Barcode $code is valid but not found in our medical registry. Please verify manually."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isNavigating = false);
              controller.start();
            },
            child: const Text("Try Again", style: TextStyle(color: MedVerifyTheme.primaryBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isNavigating) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String rawValue = barcodes.first.rawValue ?? "";
                final Map<String, String> parsed = _parseMedicineQR(rawValue);
                final medData = MedicineData.lookup(parsed['code']!);

                setState(() => _isNavigating = true);

                if (medData != null) {
                  HapticFeedback.mediumImpact(); 
                  controller.stop();
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicineDetailsScreen(
                        medicineCode: parsed['code']!,
                        medicineName: medData['name'],
                        dosage: medData['dosage'],
                        scannedBatch: parsed['batch'],
                        scannedExpiry: parsed['expiry'],
                        isAuthentic: parsed['authentic'] == "YES",
                      ),
                    ),
                  ).then((wasAdded) {
                    // --- NAVIGATION FIX ---
                    // If 'wasAdded' is null or false, it means Parth pressed the back button.
                    // We check if the Scanner is still on screen before popping to Home.
                    if (wasAdded == null || wasAdded == false) {
                      if (mounted && Navigator.canPop(context)) {
                        Navigator.pop(context); 
                      }
                    } else {
                      // If medicine was added, the Details screen already called popUntil.
                      // We just reset the lock in case the user comes back to scan again.
                      setState(() => _isNavigating = false);
                    }
                  });
                } else {
                  controller.stop();
                  _showNotFoundDialog(context, parsed['code']!);
                }
              }
            },
          ),
          
          _buildScanningOverlay(context),
          _buildTopBar(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Text(
              "Scan Medicine",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(LucideIcons.zap, color: Colors.white),
                onPressed: () => controller.toggleTorch(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay(BuildContext context) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 250, width: 250,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            height: 260, width: 260,
            decoration: BoxDecoration(
              border: Border.all(color: MedVerifyTheme.primaryBlue, width: 2),
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 120),
            child: Text(
              "Align medicine strip within the frame",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}