import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Added Provider
import '../services/medicine_data.dart';
import '../medicine_details_screen.dart';
import '../services/language_provider.dart'; // Ensure this matches your file path
import '../theme.dart';

class MedicineSearchScreen extends StatefulWidget {
  const MedicineSearchScreen({super.key});

  @override
  State<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen> {
  String _searchQuery = "";
  
  List<MapEntry<String, Map<String, dynamic>>> get _filteredMedicines {
    return MedicineData.database.entries.where((entry) {
      final name = entry.value['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          _buildPremiumHeader(context, lp),
          Expanded(
            child: _filteredMedicines.isEmpty
                ? _buildNoResults(lp)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    itemCount: _filteredMedicines.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredMedicines[index];
                      final code = entry.key;
                      final data = entry.value;

                      return _buildSearchItem(context, data['name'], data['dosage'], code, lp);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, LanguageProvider lp) {
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
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                lp.translate("Medicine Registry", "दवा रजिस्ट्री"),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchField(lp),
        ],
      ),
    );
  }

  Widget _buildSearchField(LanguageProvider lp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: lp.translate("Search verified medicines...", "सत्यापित दवाएं खोजें..."),
          hintStyle: const TextStyle(color: Colors.white60, fontSize: 15),
          border: InputBorder.none,
          icon: const Icon(LucideIcons.search, color: Colors.white70, size: 20),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildSearchItem(BuildContext context, String name, String dose, String code, LanguageProvider lp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 12, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MedicineDetailsScreen(
                  medicineCode: code,
                  medicineName: name,
                  dosage: dose,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.pill, color: MedVerifyTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lp.translate("Verified Formulation", "सत्यापित फॉर्मूलेशन"),
                        style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults(LanguageProvider lp) {
    return Center(
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
            child: Icon(LucideIcons.searchX, size: 48, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            lp.translate("No results found", "कोई परिणाम नहीं मिला"),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1C1E)
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lp.translate(
              "Try checking the spelling or use the\nQuick Scanner for better accuracy.",
              "वर्तनी की जाँच करें या बेहतर सटीकता\nके लिए त्वरित स्कैनर का उपयोग करें।"
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}