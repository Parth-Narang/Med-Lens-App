import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';
import '../services/local_storage.dart';
import '../services/medicine_data.dart';

class MedicineDetailsScreen extends StatelessWidget {
  final String medicineCode;
  final String medicineName;
  final String dosage;
  
  // Scanned metadata from the GS1 Parser
  final String? scannedBatch;
  final String? scannedExpiry;
  final bool isAuthentic;

  const MedicineDetailsScreen({
    super.key,
    required this.medicineCode,
    this.medicineName = "Aspirin",
    this.dosage = "100mg Tablet",
    this.scannedBatch,
    this.scannedExpiry,
    this.isAuthentic = false,
  });

  Map<String, dynamic> get _medInfo => 
      MedicineData.lookup(medicineCode) ?? {
        "uses": "General pain relief and wellness",
        "dosage": "As directed by a physician",
        "sideEffects": "No common side effects reported",
        "warning": "Consult your doctor if symptoms persist",
      };

  void _showSuccessDialog(BuildContext context, String medName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.checkCircle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text("Success!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("$medName has been added to your cabinet.",
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedVerifyTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // --- NAVIGATION FIX: Return to Dashboard ---
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text("OK", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedVerifyTheme.bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          // --- NAVIGATION FIX: pop with 'false' to avoid black screen ---
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          medicineName,
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainInfoCard(medicineName),
            const SizedBox(height: 20),

            _buildDetailSection(
              "Uses",
              _medInfo['uses'], 
              LucideIcons.stethoscope,
              bulletColor: MedVerifyTheme.primaryBlue,
            ),
            const SizedBox(height: 12),
            
            _buildDetailSection(
              "Advised Dosage",
              _medInfo['dosage'], 
              LucideIcons.clock,
              bulletColor: MedVerifyTheme.primaryBlue,
            ),

            const SizedBox(height: 20),
            _buildSideEffectsCard(_medInfo['sideEffects']), 
            
            const SizedBox(height: 20),
            _buildSafetyStatus(),
            
            const SizedBox(height: 20),
            _buildInteractionWarning(_medInfo['warning']), 
            
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  Map<String, String> medicineData = {
                    "name": medicineName,
                    "dosage": dosage,
                    "code": medicineCode,
                    "batch": scannedBatch ?? "Retail Pack",
                    "expiry": scannedExpiry ?? "Check Packaging",
                    "isAuthentic": isAuthentic ? "Yes" : "No",
                    "dateAdded": DateTime.now().toString(),
                  };
                  await LocalStorage.saveMedicine(medicineData);
                  if (context.mounted) {
                    _showSuccessDialog(context, medicineName);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MedVerifyTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Add to My Cabinet",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon, {required Color bulletColor}) {
    List<String> points = content.split(RegExp(r'[,|\n]'));

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: MedVerifyTheme.primaryBlue, size: 20),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          ...points.where((p) => p.trim().isNotEmpty).map((point) => _bulletPoint(point.trim(), bulletColor)),
        ],
      ),
    );
  }

  Widget _buildSideEffectsCard(String sideEffect) {
    List<String> effects = sideEffect.split(RegExp(r'[,|\n]'));

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.thermometer, color: Colors.orange, size: 20),
              SizedBox(width: 12),
              Text("Common Side Effects", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...effects.where((e) => e.trim().isNotEmpty).map((effect) => _bulletPoint(effect.trim(), Colors.orange)),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8, 
            height: 8, 
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard(String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: MedVerifyTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(LucideIcons.pill, color: MedVerifyTheme.primaryBlue, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("ID: $medicineCode", style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _buildStatusRow(
            LucideIcons.shieldCheck,
            "Authenticity",
            isAuthentic ? "Verified Genuine" : "Product Identified",
            isAuthentic ? Colors.green : Colors.blueGrey,
          ),
          const Divider(height: 32),
          _buildStatusRow(
            LucideIcons.calendar,
            "Expiry Date",
            scannedExpiry ?? "Check Packaging",
            scannedExpiry != null ? Colors.green : Colors.black87,
          ),
          const Divider(height: 32),
          _buildStatusRow(
            LucideIcons.factory,
            "Batch Info",
            scannedBatch ?? "Retail Pack",
            Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildInteractionWarning(String warningText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MedVerifyTheme.warningRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MedVerifyTheme.warningRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: MedVerifyTheme.warningRed),
              SizedBox(width: 8),
              Text("Drug Interaction Warning", style: TextStyle(color: MedVerifyTheme.warningRed, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(warningText, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}