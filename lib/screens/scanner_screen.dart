import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_ml_kit/google_ml_kit.dart' hide Barcode, BarcodeFormat;
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
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
  bool _isProcessingText = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // --- 1. BARCODE PARSING (Retained) ---
  Map<String, String> _parseMedicineQR(String rawValue) {
    String cleanCode = rawValue;
    String batch = "";
    String expiry = "";
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
        if (rawValue.contains('21')) isAuthentic = true;
      } else if (rawValue.length == 14 && rawValue.startsWith('0')) {
        cleanCode = BigInt.parse(rawValue).toString();
      }
      return {
        "code": cleanCode,
        "batch": batch,
        "expiry": expiry,
        "authentic": isAuthentic ? "YES" : "NO",
      };
    } catch (e) {
      return {"code": rawValue, "batch": "", "expiry": "", "authentic": "NO"};
    }
  }

  // --- 2. REVIEW DIALOG (Retained) ---
  void _showReviewDialog({
    required String medicineCode,
    required String medicineName,
    required String dosage,
    String initialBatch = "",
    String initialExpiry = "",
  }) {
    final nameController = TextEditingController(text: medicineName);
    final expiryController = TextEditingController(text: initialExpiry);
    final batchController = TextEditingController(text: initialBatch);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(LucideIcons.checkCircle, color: Colors.green),
            SizedBox(width: 10),
            Text("Verify Details"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Confirm medicine and add manual details.", 
                style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              _buildReviewField("Medicine Name", nameController, LucideIcons.pill, enabled: false),
              _buildReviewField("Expiry (DD/MM/YYYY)", expiryController, LucideIcons.calendar),
              _buildReviewField("Batch Number", batchController, LucideIcons.package),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.start();
            },
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MedVerifyTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _navigateToDetails(
                code: medicineCode,
                name: nameController.text,
                dosage: dosage,
                batch: batchController.text,
                expiry: expiryController.text,
                isAuthentic: false,
              );
            },
            child: const Text("Continue", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: MedVerifyTheme.primaryBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey.withOpacity(0.1),
        ),
      ),
    );
  }

  // --- 3. TEXT ANALYSIS (Retained) ---
  Future<void> _processTextFromImage() async {
    final ImagePicker picker = ImagePicker();
    controller.stop(); 
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 100);
    if (image == null) {
      controller.start();
      return; 
    }
    setState(() => _isProcessingText = true);
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String rawText = recognizedText.text.toUpperCase().replaceAll('-', ' ');
      textRecognizer.close();
      Map<String, dynamic>? matchedMed;
      String? matchedCode;
      MedicineData.allMedicines.forEach((code, data) {
        String dbName = data['name'].toString().toUpperCase();
        if (rawText.contains(dbName)) {
          matchedMed = data;
          matchedCode = code;
        }
      });
      setState(() => _isProcessingText = false);
      if (matchedMed != null) {
        HapticFeedback.mediumImpact();
        _showReviewDialog(
          medicineCode: matchedCode!,
          medicineName: matchedMed!['name'],
          dosage: matchedMed!['dosage'],
        );
      } else {
        _showNotFoundDialog(context, "Could not identify medicine name. Please ensure the brand name is clearly visible.");
      }
    } catch (e) {
      setState(() => _isProcessingText = false);
      controller.start();
    }
  }

  void _navigateToDetails({required String code, required String name, required String dosage, String? batch, String? expiry, required bool isAuthentic}) {
    setState(() => _isNavigating = true);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineDetailsScreen(
          medicineCode: code,
          medicineName: name,
          dosage: dosage,
          scannedBatch: batch,
          scannedExpiry: expiry,
          isAuthentic: isAuthentic,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isNavigating = false);
        controller.start();
      }
    });
  }

  void _showNotFoundDialog(BuildContext context, String message) {
    HapticFeedback.heavyImpact(); 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Product Unrecognized"),
        content: Text(message),
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
              if (_isNavigating || _isProcessingText) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String rawValue = barcodes.first.rawValue ?? "";
                final Map<String, String> parsed = _parseMedicineQR(rawValue);
                final medData = MedicineData.lookup(parsed['code']!);
                if (medData != null) {
                  HapticFeedback.mediumImpact(); 
                  controller.stop();
                  _showReviewDialog(
                    medicineCode: parsed['code']!,
                    medicineName: medData['name'],
                    dosage: medData['dosage'],
                    initialBatch: parsed['batch'] ?? "", 
                    initialExpiry: parsed['expiry'] ?? "",
                  );
                } else {
                  controller.stop();
                  _showNotFoundDialog(context, "Barcode ${parsed['code']} not found in our registry.");
                }
              }
            },
          ),
          _buildScanningOverlay(context),
          _buildTopBar(context),
          _buildTextScanButton(),

          if (_isProcessingText)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: MedVerifyTheme.primaryBlue),
                    SizedBox(height: 16),
                    Text("Verifying Medicine...", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
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
                  // SCANNING BOX RADIUS 24
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),
        ),
        // Visual border for the scanning box
        Center(
          child: Container(
            height: 250, width: 250,
            decoration: BoxDecoration(
              border: Border.all(color: MedVerifyTheme.primaryBlue, width: 2),
              // SCANNING BOX RADIUS 24
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 160),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // TEXT BOX RADIUS 24
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                "Align Barcode/QR inside frame",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextScanButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _processTextFromImage,
            icon: const Icon(LucideIcons.camera, color: Colors.white),
            label: const Text(
              "Read Text from Packaging",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedVerifyTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }
}