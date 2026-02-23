import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';
import '../services/local_storage.dart';
import 'medicine_cabinet_screen.dart';
import '../medicine_details_screen.dart';
import 'scanner_screen.dart';
import 'medicine_search_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  // --- POPUP DIALOGS FOR INTERACTIVE ALERTS ---

  void _showRecallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.megaphone, color: Colors.red),
            SizedBox(width: 10),
            Text("Recent Recalls"),
          ],
        ),
        content: const Text(
          "CDSCO Alert: Certain batches of Paracetamol Syrup have been flagged for quality issues in Haryana. Please check your batch numbers against official lists.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it", style: TextStyle(color: MedVerifyTheme.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showHealthTipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Daily Health Tip"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("💊 Take your medicines with plain water", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Avoid taking medicines with milk or tea as they can block absorption, especially for Iron or Antibiotic tablets."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Thanks!", style: TextStyle(color: MedVerifyTheme.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedVerifyTheme.bgGray,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Blue Header containing Hello text and Search Bar
            _buildBlueHeader(context),

            // 2. Scan Card remains on gray background with its original offset
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Transform.translate(
                offset: const Offset(0, -32),
                child: _buildScanCard(context),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    context,
                    "My Medicine Cabinet",
                    showViewAll: true,
                  ),
                  const SizedBox(height: 16),
                  _buildMedicineCarousel(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, "Safety Alerts"),
                  const SizedBox(height: 16),
                  _buildSafetyAlerts(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 40),
      decoration: const BoxDecoration(
        color: MedVerifyTheme.primaryBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, Parth",
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            "Stay safe, stay healthy",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _buildSearchBar(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MedicineSearchScreen()),
        ).then((_) => _refresh());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.search, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              "Search medicine to add...",
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          ).then((_) => _refresh());
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: MedVerifyTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.camera, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              const Text(
                "Scan Medicine",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCarousel(BuildContext context) {
    return SizedBox(
      height: 150,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: LocalStorage.getCabinet(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyCarousel();
          }
          final medicines = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final med = medicines[index];
              return _buildMedicineCard(context, med['name'] ?? "Unknown", med['dosage'] ?? "", "Saved", med['code'] ?? "");
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {bool showViewAll = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
        if (showViewAll)
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicineCabinetScreen())).then((_) => _refresh());
            },
            child: const Text("View All", style: TextStyle(color: MedVerifyTheme.primaryBlue, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildMedicineCard(BuildContext context, String name, String dose, String time, String code) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => MedicineDetailsScreen(medicineCode: code, medicineName: name, dosage: dose))).then((_) => _refresh());
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.pill, color: MedVerifyTheme.primaryBlue, size: 24),
              const Spacer(),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(dose, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCarousel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
      child: const Center(child: Text("Cabinet is empty", style: TextStyle(color: Colors.grey))),
    );
  }

  Widget _buildSafetyAlerts() {
    return Column(
      children: [
        _buildAlertItem(
          "Drug Recall Alert", 
          "Urgent", 
          MedVerifyTheme.warningRed, 
          LucideIcons.alertTriangle,
          onTap: () => _showRecallDialog(context),
        ),
        const SizedBox(height: 12),
        _buildAlertItem(
          "Health Tip", 
          "Info", 
          Colors.blue, 
          LucideIcons.info,
          onTap: () => _showHealthTipDialog(context),
        ),
      ],
    );
  }

  Widget _buildAlertItem(String title, String tag, Color color, IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(tag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}