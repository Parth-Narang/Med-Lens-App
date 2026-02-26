import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/local_storage.dart';
import '../services/language_provider.dart';
import 'medicine_cabinet_screen.dart';
import '../medicine_details_screen.dart';
import 'scanner_screen.dart';
import 'medicine_search_screen.dart';
import 'prescription_screen.dart'; 

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

  // --- POPUP DIALOGS ---

  void _showRecallDialog(BuildContext context, LanguageProvider lp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            const Icon(LucideIcons.megaphone, color: Colors.red),
            const SizedBox(width: 10),
            Text(lp.translate("Recent Recalls", "हालिया रिकॉल")),
          ],
        ),
        content: Text(
          lp.translate(
            "CDSCO Alert: Certain batches of Paracetamol Syrup have been flagged for quality issues in Haryana. Please check your batch numbers against official lists.",
            "CDSCO अलर्ट: हरियाणा में पैरासिटामोल सिरप के कुछ बैचों में गुणवत्ता संबंधी समस्याओं के लिए ध्वजांकित किया गया है। कृपया आधिकारिक सूचियों के विरुद्ध अपने बैच नंबरों की जांच करें।"
          ),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lp.translate("Got it", "समझ गया"), 
              style: const TextStyle(color: MedVerifyTheme.primaryBlue, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthTipDialog(BuildContext context, LanguageProvider lp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(lp.translate("Daily Health Tip", "दैनिक स्वास्थ्य टिप")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lp.translate("💊 Take your medicines with plain water", "💊 अपनी दवाएं सादे पानी के साथ लें"), 
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Text(
              lp.translate(
                "Avoid taking medicines with milk or tea as they can block absorption, especially for Iron or Antibiotic tablets.",
                "दूध या चाय के साथ दवाएं लेने से बचें क्योंकि वे अवशोषण को रोक सकते हैं, विशेष रूप से आयरन या एंटीबायोटिक टैबलेट के लिए।"
              )
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lp.translate("Thanks!", "धन्यवाद!"), 
              style: const TextStyle(color: MedVerifyTheme.primaryBlue, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  // --- PREMIUM STATS LOGIC ---
  Future<Map<String, int>> _getStats() async {
    final cabinet = await LocalStorage.getCabinet();
    int expiringSoon = 0;
    for (var med in cabinet) {
      String? exp = med['expiry'];
      if (exp != null && exp != "-") {
        try {
          List<String> parts = exp.split('/');
          DateTime expiry = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          if (expiry.difference(DateTime.now()).inDays <= 30) expiringSoon++;
        } catch (_) {}
      }
    }
    return {"total": cabinet.length, "expiring": expiringSoon};
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), 
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBlueHeader(context, lp),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Column(
                  children: [
                    _buildStatsRow(lp), 
                    const SizedBox(height: 20),
                    _buildScanCard(context, lp),
                    const SizedBox(height: 16),
                    _buildPrescriptionQuickAction(context, lp), 
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    context,
                    lp.translate("Recently Added", "हाल ही में जोड़ा गया"),
                    showViewAll: true,
                    lp: lp,
                  ),
                  const SizedBox(height: 16),
                  _buildMedicineCarousel(context, lp),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, lp.translate("Safety & Wellness", "सुरक्षा और कल्याण"), lp: lp),
                  const SizedBox(height: 16),
                  _buildSafetyAlerts(lp),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueHeader(BuildContext context, LanguageProvider lp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 60),
      decoration: const BoxDecoration(
        color: MedVerifyTheme.primaryBlue,
        borderRadius: BorderRadius.zero, 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lp.translate("Health Dashboard", "स्वास्थ्य डैशबोर्ड"),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    lp.translate("Your medication safety, verified.", "आपकी दवा सुरक्षा, सत्यापित।"),
                    style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5),
                  ),
                ],
              ),
              _buildLanguageToggle(lp),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchBar(context, lp),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle(LanguageProvider lp) {
    return GestureDetector(
      onTap: () => lp.toggleLanguage(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.languages, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              lp.isHindi ? "English" : "हिन्दी",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, LanguageProvider lp) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicineSearchScreen())).then((_) => _refresh());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.search, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              lp.translate("Search medicines...", "दवाएं खोजें..."), 
              style: const TextStyle(color: Colors.white70, fontSize: 15)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(LanguageProvider lp) {
    return FutureBuilder<Map<String, int>>(
      future: _getStats(),
      builder: (context, snapshot) {
        final total = snapshot.data?['total'] ?? 0;
        final expiring = snapshot.data?['expiring'] ?? 0;

        return Row(
          children: [
            _buildStatItem(
              lp.translate("Active Meds", "सक्रिय दवाएं"), 
              total.toString(), 
              LucideIcons.pill, 
              Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicineCabinetScreen())).then((_) => _refresh()),
            ),
            const SizedBox(width: 12),
            _buildStatItem(
              lp.translate("Expiring", "समाप्त हो रही"), 
              expiring.toString(), 
              LucideIcons.alertCircle, 
              expiring > 0 ? Colors.orange : Colors.green,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicineCabinetScreen())).then((_) => _refresh()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

Widget _buildScanCard(BuildContext context, LanguageProvider lp) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen())).then((_) => _refresh()),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MedVerifyTheme.primaryBlue.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(14)
                  ),
                  child: const Icon(LucideIcons.scanLine, color: MedVerifyTheme.primaryBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lp.translate("Verify Medicine", "दवा सत्यापित करें"), 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))
                    ),
                    Text(
                      lp.translate("Scan barcode or product text", "बारकोड या उत्पाद टेक्स्ट स्कैन करें"),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionQuickAction(BuildContext context, LanguageProvider lp) {
    return Container(
      decoration: BoxDecoration(
        color: MedVerifyTheme.primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: MedVerifyTheme.primaryBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrescriptionScreen())).then((_) => _refresh()),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(LucideIcons.fileText, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lp.translate("Scan Prescription", "पर्चा स्कैन करें"), 
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    Text(
                      lp.translate("Bulk add medicines at once", "एक साथ कई दवाएं जोड़ें"), 
                      style: const TextStyle(color: Colors.white70, fontSize: 12)
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(LucideIcons.arrowRight, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCarousel(BuildContext context, LanguageProvider lp) {
    return SizedBox(
      height: 160,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: LocalStorage.getCabinet(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyCarousel(lp);
          }
          final medicines = snapshot.data!.reversed.toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: medicines.length > 5 ? 5 : medicines.length,
            itemBuilder: (context, index) {
              final med = medicines[index];
              return _buildMedicineCard(context, med['name'] ?? "Unknown", med['dosage'] ?? "", med['code'] ?? "", lp);
            },
          );
        },
      ),
    );
  }

  Widget _buildMedicineCard(BuildContext context, String name, String dose, String code, LanguageProvider lp) {
    return Container(
      width: 160, 
      margin: const EdgeInsets.only(right: 16, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MedicineDetailsScreen(medicineCode: code, medicineName: name, dosage: dose))).then((_) => _refresh()),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MedVerifyTheme.primaryBlue.withOpacity(0.08), 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: const Icon(LucideIcons.pill, color: MedVerifyTheme.primaryBlue, size: 22),
                  ),
                  const Icon(LucideIcons.shieldCheck, color: Colors.green, size: 16),
                ],
              ),
              const Spacer(),
              Text(
                name, 
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, 
                  fontSize: 15, 
                  color: const Color(0xFF1A1C1E)
                ), 
                maxLines: 2, 
                overflow: TextOverflow.ellipsis
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lp.translate("VERIFIED", "सत्यापित"),
                  style: const TextStyle(
                    color: MedVerifyTheme.primaryBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCarousel(LanguageProvider lp) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Center(
        child: Text(
          lp.translate("Add your first medicine", "अपनी पहली दवा जोड़ें"), 
          style: const TextStyle(color: Colors.grey)
        )
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {bool showViewAll = false, required LanguageProvider lp}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E))),
        if (showViewAll)
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicineCabinetScreen())).then((_) => _refresh()),
            child: Text(
              lp.translate("View All", "सभी देखें"), 
              style: const TextStyle(color: MedVerifyTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)
            ),
          ),
      ],
    );
  }

  Widget _buildSafetyAlerts(LanguageProvider lp) {
    return Column(
      children: [
        _buildAlertItem(lp.translate("Drug Recall Alert", "दवा रिकॉल अलर्ट"), lp.translate("Urgent", "अति आवश्यक"), const Color(0xFFFFEFEF), Colors.red, LucideIcons.alertTriangle, () => _showRecallDialog(context, lp)),
        const SizedBox(height: 12),
        _buildAlertItem(lp.translate("Health Tip", "स्वास्थ्य टिप"), lp.translate("New", "नया"), const Color(0xFFF0F6FF), MedVerifyTheme.primaryBlue, LucideIcons.info, () => _showHealthTipDialog(context, lp)),
      ],
    );
  }

  Widget _buildAlertItem(String title, String tag, Color bg, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.03))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Text(tag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}