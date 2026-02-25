import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/medicine_data.dart';
import '../services/local_storage.dart';
import '../services/alert_service.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  List<Map<String, dynamic>> _foundMedicines = [];
  bool _isProcessing = false;

  Future<void> _scanPrescription() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _isProcessing = true;
      _foundMedicines = [];
    });

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String rawText = recognizedText.text.toUpperCase();

      List<Map<String, dynamic>> matches = [];
      
      MedicineData.allMedicines.forEach((code, data) {
        String dbName = data['name'].toString().toUpperCase();
        if (rawText.contains(dbName)) {
          matches.add({
            "code": code,
            "name": data['name'],
            "dosage": data['dosage'],
            "expiry": "-", 
            "batch": "-",
          });
        }
      });

      setState(() {
        _foundMedicines = matches;
        _isProcessing = false;
      });
      textRecognizer.close();
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  void _updateExpiry(int index, String date) {
    setState(() => _foundMedicines[index]['expiry'] = date);
  }

  Future<void> _saveAll() async {
    for (var med in _foundMedicines) {
      Map<String, String> data = {
        "name": med['name'],
        "code": med["code"],
        "dosage": med["dosage"],
        "expiry": med["expiry"],
        "batch": "-",
        "dateAdded": DateTime.now().toString(),
        "isAuthentic": "No",
        "reminderHour": "9", 
        "reminderMinute": "0",
      };
      await LocalStorage.saveMedicine(data);
      
      await AlertService.scheduleDailyReminder(
        med["code"].hashCode, 
        med['name'], 
        9, 0
      );
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${_foundMedicines.length} medicines added to Cabinet"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: MedVerifyTheme.primaryBlue,
        )
      );
      // Using a slight delay to let the user see the result before popping
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isProcessing 
              ? const Center(child: CircularProgressIndicator(color: MedVerifyTheme.primaryBlue))
              : _foundMedicines.isEmpty 
                ? _buildEmptyState() 
                : _buildMedicineList(),
          ),
        ],
      ),
      floatingActionButton: _foundMedicines.isNotEmpty 
        ? FloatingActionButton.extended(
            onPressed: _saveAll,
            elevation: 4,
            label: Text(
              "Add All to Cabinet",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5
              ),
            ),
            icon: const Icon(LucideIcons.plus, color: Colors.white),
            backgroundColor: MedVerifyTheme.primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          )
        : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 40),
      decoration: const BoxDecoration(
        color: MedVerifyTheme.primaryBlue,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Prescription Scan",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Bulk-identify medications from documents",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
              ),
              child: Icon(LucideIcons.fileSearch, size: 64, color: Colors.grey[300]),
            ),
            const SizedBox(height: 24),
            Text(
              "No items detected yet",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1C1E)
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Scan a medical prescription to add\nmultiple items automatically.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _scanPrescription, 
                icon: const Icon(LucideIcons.camera, color: Colors.white, size: 20),
                label: Text(
                  "Capture Prescription", 
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MedVerifyTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: _foundMedicines.length,
      itemBuilder: (context, index) {
        final med = _foundMedicines[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.pill, color: MedVerifyTheme.primaryBlue, size: 24),
            ),
            title: Text(
              med['name'], 
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "Expiry: ${med['expiry']}",
                style: TextStyle(color: med['expiry'] == "-" ? Colors.grey : MedVerifyTheme.primaryBlue, fontWeight: med['expiry'] == "-" ? FontWeight.normal : FontWeight.bold),
              ),
            ),
            trailing: Container(
              decoration: BoxDecoration(
                color: MedVerifyTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.calendar, color: MedVerifyTheme.primaryBlue, size: 20),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(primary: MedVerifyTheme.primaryBlue),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) _updateExpiry(index, DateFormat("dd/MM/yyyy").format(picked));
                },
              ),
            ),
          ),
        );
      },
    );
  }
}