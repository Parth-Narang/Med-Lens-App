import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart'; // Added for state management
import '../theme.dart';
import '../services/local_storage.dart';
import '../services/language_provider.dart'; // Ensure this matches your file path
import '../medicine_details_screen.dart';
import '../main.dart'; 

class MedicineCabinetScreen extends StatefulWidget {
  const MedicineCabinetScreen({super.key});

  @override
  State<MedicineCabinetScreen> createState() => _MedicineCabinetScreenState();
}

class _MedicineCabinetScreenState extends State<MedicineCabinetScreen> with RouteAware {
  late Future<List<Map<String, dynamic>>> _cabinetData;
  final Map<int, bool> _completedDosages = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadData(); 
  }

  void _loadData() {
    if (mounted) {
      setState(() {
        _cabinetData = LocalStorage.getCabinet();
      });
    }
  }

  Color _getExpiryColor(String? expiryStr) {
    if (expiryStr == null || expiryStr == "-" || expiryStr.isEmpty) return Colors.blueGrey;
    try {
      List<String> parts = expiryStr.split('/');
      DateTime expiry = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      int daysRemaining = expiry.difference(DateTime.now()).inDays;

      if (daysRemaining < 0) return Colors.red; 
      if (daysRemaining <= 30) return Colors.orange; 
      return Colors.green; 
    } catch (e) {
      return Colors.blueGrey;
    }
  }

  Future<bool> _showDeleteDialog(BuildContext context, String medName, LanguageProvider lp) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          lp.translate("Remove Medicine?", "दवा हटाएँ?"), 
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)
        ),
        content: Text(
          lp.translate("Are you sure you want to remove $medName?", "क्या आप वाकई $medName को हटाना चाहते हैं?")
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lp.translate("Cancel", "रद्द करें"), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              lp.translate("Remove", "हटाएं"), 
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          _buildHeader(lp),
          
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _cabinetData, 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: MedVerifyTheme.primaryBlue));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(lp);
                }

                final medicines = snapshot.data!.reversed.toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final Map<String, String> med = medicines[index].map(
                      (key, value) => MapEntry(key, value.toString()),
                    );
                    final int originalIndex = (snapshot.data!.length - 1) - index;
                    return _buildCabinetItem(context, med, originalIndex, lp);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageProvider lp) {
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
            lp.translate("My Medicine Cabinet", "मेरी दवा कैबिनेट"),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lp.translate("Manage your active prescriptions", "अपने सक्रिय नुस्खों का प्रबंधन करें"),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCabinetItem(BuildContext context, Map<String, String> med, int storageIndex, LanguageProvider lp) {
    bool isDone = _completedDosages[storageIndex] ?? false;
    String expiryDisplay = (med['expiry'] == null || med['expiry']!.isEmpty) ? "-" : med['expiry']!;
    Color statusColor = _getExpiryColor(expiryDisplay);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MedicineDetailsScreen(
                  medicineCode: med['code'] ?? "",
                  medicineName: med['name'] ?? "",
                  dosage: med['dosage'] ?? "",
                  scannedBatch: med['batch'],
                  scannedExpiry: expiryDisplay,
                  isAuthentic: med['isAuthentic'] == "Yes",
                ),
              ),
            ).then((_) => _loadData());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _completedDosages[storageIndex] = !isDone;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDone ? Colors.green : const Color(0xFFF1F4FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? LucideIcons.check : LucideIcons.pill, 
                      color: isDone ? Colors.white : MedVerifyTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med['name'] ?? 'Unknown', 
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.grey : const Color(0xFF1A1C1E),
                        )
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.calendar, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            "${lp.translate("Expires", "समाप्ति")}: $expiryDisplay",
                            style: TextStyle(
                              fontSize: 12, 
                              color: statusColor, 
                              fontWeight: expiryDisplay != "-" ? FontWeight.bold : FontWeight.normal
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: Color.fromARGB(255, 255, 1, 1), size: 20),
                  onPressed: () async {
                    bool confirm = await _showDeleteDialog(context, med['name'] ?? "this medicine", lp);
                    if (confirm) {
                      if (med.containsKey('code')) {
                        int medId = med['code']!.hashCode;
                        await flutterLocalNotificationsPlugin.cancel(medId);
                        await flutterLocalNotificationsPlugin.cancel(medId + 1000);
                      }
                      await LocalStorage.deleteMedicine(storageIndex);
                      _loadData(); 
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lp) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.packageSearch, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            lp.translate("No medicines found", "कोई दवा नहीं मिली"), 
            style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)
          ),
          Text(
            lp.translate("Your cabinet is currently empty", "आपकी कैबिनेट वर्तमान में खाली है"), 
            style: const TextStyle(color: Colors.grey, fontSize: 13)
          ),
        ],
      ),
    );
  }
}