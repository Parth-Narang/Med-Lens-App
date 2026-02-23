import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/medicine_data.dart';
import '../medicine_details_screen.dart';
import '../theme.dart';

class MedicineSearchScreen extends StatefulWidget {
  const MedicineSearchScreen({super.key});

  @override
  State<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen> {
  String _searchQuery = "";
  
  // This filters the 30+ medicines in your database based on the name
  List<MapEntry<String, Map<String, dynamic>>> get _filteredMedicines {
    return MedicineData.database.entries.where((entry) {
      final name = entry.value['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedVerifyTheme.bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search medicine name...",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _filteredMedicines.isEmpty
          ? _buildNoResults()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredMedicines.length,
              itemBuilder: (context, index) {
                final entry = _filteredMedicines[index];
                final code = entry.key;
                final data = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: const Icon(LucideIcons.pill, color: MedVerifyTheme.primaryBlue),
                    title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    trailing: const Icon(LucideIcons.chevronRight, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MedicineDetailsScreen(
                            medicineCode: code,
                            medicineName: data['name'],
                            dosage: data['dosage'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("No medicines found", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}