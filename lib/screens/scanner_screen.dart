import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_ml_kit/google_ml_kit.dart' hide Barcode, BarcodeFormat;
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Added Provider
import 'dart:ui';
import '../theme.dart';
import '../medicine_details_screen.dart';
import '../services/medicine_data.dart';
import '../services/language_provider.dart'; // Ensure this matches your file path

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

  // --- 1. BARCODE PARSING ---
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

  // --- 2. REVIEW DIALOG ---
  void _showReviewDialog({
    required String medicineCode,
    required String medicineName,
    required String dosage,
    required LanguageProvider lp, // Added lp
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            const Icon(LucideIcons.checkCircle, color: Colors.green),
            const SizedBox(width: 10),
            Text(lp.translate("Verify Details", "विवरण सत्यापित करें"), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lp.translate("Review identified packaging info.", "पहचानी गई पैकेजिंग जानकारी की समीक्षा करें।"), 
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              _buildReviewField(lp.translate("Medicine Name", "दवा का नाम"), nameController, LucideIcons.pill, enabled: true),
              _buildReviewField(lp.translate("Expiry (DD/MM/YYYY)", "समाप्ति (DD/MM/YYYY)"), expiryController, LucideIcons.calendar),
              _buildReviewField(lp.translate("Batch Number", "बैच संख्या"), batchController, LucideIcons.package),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.start();
            },
            child: Text(lp.translate("Cancel", "रद्द करें"), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MedVerifyTheme.primaryBlue,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
            child: Text(lp.translate("Continue", "जारी रखें"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey.withOpacity(0.1),
        ),
      ),
    );
  }

  // --- 3. OVERHAULED TEXT ANALYSIS (FIXED EXPIRY, NAME, BATCH) ---
  Future<void> _processTextFromImage(LanguageProvider lp) async {
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
      
      String fullRawText = recognizedText.text.toUpperCase();
      List<String> textLines = recognizedText.blocks.expand((b) => b.lines).map((l) => l.text.toUpperCase().trim()).toList();
      textRecognizer.close();

      // --- A. MEDICINE NAME (STRICTER MATCH) ---
      Map<String, dynamic>? bestMatch;
      String? bestCode;
      double highestConfidence = 0;

      MedicineData.allMedicines.forEach((code, data) {
        String dbName = data['name'].toString().toUpperCase();
        
        if (fullRawText.contains(dbName)) {
          bestMatch = data;
          bestCode = code;
          highestConfidence = 1.0;
        }

        if (highestConfidence < 1.0) {
          List<String> dbWords = dbName.split(' ');
          int matchCount = 0;
          for (var word in dbWords) {
            if (word.length > 2 && RegExp('\\b$word\\b').hasMatch(fullRawText)) {
              matchCount++;
            }
          }
          double conf = matchCount / dbWords.length;
          if (conf > highestConfidence) {
            highestConfidence = conf;
            bestMatch = data;
            bestCode = code;
          }
        }
      });

      // --- B. EXPIRY DATE (IGNORES MANUFACTURING) ---
      String detectedExpiry = "";
      RegExp datePattern = RegExp(r'(\d{1,2}[/\-]\d{2,4})|((?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s?\d{2,4})');

      for (String line in textLines) {
        if (line.contains("MFG") || line.contains("MFD") || line.contains("MFR")) continue;

        if (line.contains("EXP") || line.contains("ED") || line.contains("VAL")) {
          Match? match = datePattern.firstMatch(line);
          if (match != null) {
            detectedExpiry = match.group(0)!;
            break; 
          }
        }
      }

      if (detectedExpiry.isEmpty) {
        Iterable<Match> allDates = datePattern.allMatches(fullRawText);
        if (allDates.isNotEmpty) detectedExpiry = allDates.last.group(0)!;
      }

      // --- C. BATCH NUMBER (CLEANER SEARCH) ---
      String detectedBatch = "";
      RegExp batchPattern = RegExp(r'(?:BATCH|B\.?NO|LOT|B/N|BN)[:.\s]*([A-Z0-9\-]{3,})');
      for (String line in textLines) {
        Match? match = batchPattern.firstMatch(line);
        if (match != null) {
          detectedBatch = match.group(1)!;
          break;
        }
      }

      setState(() => _isProcessingText = false);

      if (bestMatch != null && highestConfidence > 0.4) {
        HapticFeedback.mediumImpact();
        _showReviewDialog(
          medicineCode: bestCode!,
          medicineName: bestMatch!['name'],
          dosage: bestMatch!['dosage'],
          lp: lp,
          initialBatch: detectedBatch.isEmpty ? "-" : detectedBatch,
          initialExpiry: detectedExpiry.isEmpty ? "-" : detectedExpiry,
        );
      } else {
        _showNotFoundDialog(context, lp.translate("Could not verify product name. Ensure the brand name is clearly visible and centered.", "उत्पाद के नाम को सत्यापित नहीं किया जा सका। सुनिश्चित करें कि ब्रांड का नाम स्पष्ट रूप से दिखाई दे रहा है और बीच में है।"), lp);
      }
    } catch (e) {
      debugPrint("OCR Error: $e");
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

  void _showNotFoundDialog(BuildContext context, String message, LanguageProvider lp) {
    HapticFeedback.heavyImpact(); 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(lp.translate("Scan Failed", "स्कैन विफल")),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isNavigating = false);
              controller.start();
            },
            child: Text(lp.translate("TRY AGAIN", "पुनः प्रयास करें"), style: const TextStyle(color: MedVerifyTheme.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

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
                    lp: lp,
                    initialBatch: parsed['batch'] ?? "", 
                    initialExpiry: parsed['expiry'] ?? "",
                  );
                }
              }
            },
          ),
          _buildScanningOverlay(context, lp),
          _buildTopBar(context, lp),
          _buildTextScanButton(lp),

          if (_isProcessingText)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: MedVerifyTheme.primaryBlue),
                    const SizedBox(height: 16),
                    Text(lp.translate("Identifying Package...", "पैकेज की पहचान की जा रही है..."), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, LanguageProvider lp) {
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
            Text(
              lp.translate("Verify Packaging", "पैकेजिंग सत्यापित करें"),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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

  Widget _buildScanningOverlay(BuildContext context, LanguageProvider lp) {
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
            height: 250, width: 250,
            decoration: BoxDecoration(
              border: Border.all(color: MedVerifyTheme.primaryBlue, width: 2),
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
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                lp.translate("Align Packaging / QR in box", "बॉक्स में पैकेजिंग / क्यूआर संरेखित करें"),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextScanButton(LanguageProvider lp) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _processTextFromImage(lp),
            icon: const Icon(LucideIcons.camera, color: Colors.white),
            label: Text(
              lp.translate("Read Text from Packaging", "पैकेजिंग से टेक्स्ट पढ़ें"),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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