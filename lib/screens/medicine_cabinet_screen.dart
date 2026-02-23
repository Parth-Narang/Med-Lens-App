import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';
import '../services/local_storage.dart';
import '../medicine_details_screen.dart';
import '../main.dart'; 

class MedicineCabinetScreen extends StatefulWidget {
  const MedicineCabinetScreen({super.key});

  @override
  State<MedicineCabinetScreen> createState() => _MedicineCabinetScreenState();
}

class _MedicineCabinetScreenState extends State<MedicineCabinetScreen> with RouteAware {
  late Future<List<Map<String, dynamic>>> _cabinetData;

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
        // We fetch the data as usual
        _cabinetData = LocalStorage.getCabinet();
      });
    }
  }

  Future<bool> _showDeleteDialog(BuildContext context, String medName) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove Medicine?"),
        content: Text("Are you sure you want to remove $medName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedVerifyTheme.bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("My Cabinet", 
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cabinetData, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          // --- SORTING LOGIC ---
          // LocalStorage saves items by appending to the end. 
          // Reversing the list puts the newest items (the ones at the end) at the top.
          final medicines = snapshot.data!.reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final Map<String, String> med = medicines[index].map(
                (key, value) => MapEntry(key, value.toString()),
              );

              // Calculate the original index for deletion
              // Original Index = (Total Length - 1) - Current Index
              final int originalIndex = (snapshot.data!.length - 1) - index;

              return _buildCabinetItem(context, med, originalIndex);
            },
          );
        },
      ),
    );
  }

  Widget _buildCabinetItem(BuildContext context, Map<String, String> med, int storageIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MedVerifyTheme.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.pill, color: MedVerifyTheme.primaryBlue),
        ),
        title: Text(med['name'] ?? 'Unknown', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              const Icon(LucideIcons.calendar, size: 14, color: Colors.blueGrey),
              const SizedBox(width: 6),
              Text(
                "Expires: ${med['expiry'] ?? 'N/A'}", 
                style: const TextStyle(
                  fontSize: 13, 
                  color: Colors.blueGrey, 
                  fontWeight: FontWeight.w500
                )
              ),
            ],
          ),
        ),
        
        trailing: IconButton(
          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
          onPressed: () async {
            bool confirm = await _showDeleteDialog(context, med['name'] ?? "this medicine");
            if (confirm) {
              // We use the storageIndex calculated in the ListView
              await LocalStorage.deleteMedicine(storageIndex);
              _loadData(); 
            }
          },
        ),
        
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicineDetailsScreen(
                medicineCode: med['code'] ?? "",
                medicineName: med['name'] ?? "",
                dosage: med['dosage'] ?? "",
                scannedBatch: med['batch'],
                scannedExpiry: med['expiry'],
                isAuthentic: med['isAuthentic'] == "Yes",
              ),
            ),
          ).then((_) {
            _loadData();
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.packageOpen, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Your cabinet is empty", 
            style: TextStyle(color: Colors.grey, fontSize: 18)),
        ],
      ),
    );
  }
}