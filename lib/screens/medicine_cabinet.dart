import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';
import '../services/local_storage.dart';

class MedicineCabinet extends StatefulWidget {
  const MedicineCabinet({super.key});

  @override
  State<MedicineCabinet> createState() => _MedicineCabinetState();
}

class _MedicineCabinetState extends State<MedicineCabinet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedVerifyTheme.bgGray,
      appBar: AppBar(
        title: const Text(
          "My Cabinet",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: LocalStorage.getCabinet(), // Grabs the "notebook" data
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final meds = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meds.length,
            itemBuilder: (context, index) {
              final med = meds[index];
              return _buildMedicineCard(med, index);
            },
          );
        },
      ),
    );
  }

  // UI for when the cabinet is empty
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.archive, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Your cabinet is empty",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text(
            "Scan a medicine to add it here",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // The individual medicine card with Swipe-to-Delete
  Widget _buildMedicineCard(Map<String, dynamic> med, int index) {
    return Dismissible(
      key: Key(med['dateAdded'] ?? index.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (direction) async {
        // Logic to delete will go here in the next sub-step!
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${med['name']} removed")));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MedVerifyTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.pill,
                color: MedVerifyTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med['name'] ?? "Unknown",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    med['dosage'] ?? "",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
