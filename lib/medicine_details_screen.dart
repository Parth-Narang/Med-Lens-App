import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart'; // Added Provider
import '../theme.dart';
import '../services/local_storage.dart';
import '../services/medicine_data.dart';
import '../services/alert_service.dart'; 
import '../services/language_provider.dart'; // Import Language Provider

class MedicineDetailsScreen extends StatefulWidget {
  final String medicineCode;
  final String medicineName;
  final String dosage;
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

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _hasManuallyChangedTime = false;

  late TextEditingController _batchController;
  late TextEditingController _expiryController;

  @override
  void initState() {
    super.initState();
    
    String initialBatch = (widget.scannedBatch == null || widget.scannedBatch == "Check Packaging" || widget.scannedBatch!.isEmpty) 
        ? "-" 
        : widget.scannedBatch!;
    
    String initialExpiry = (widget.scannedExpiry == null || widget.scannedExpiry == "Check Packaging" || widget.scannedExpiry!.isEmpty) 
        ? "-" 
        : widget.scannedExpiry!;

    _batchController = TextEditingController(text: initialBatch);
    _expiryController = TextEditingController(text: initialExpiry);
    _loadExistingTime();
  }

  @override
  void dispose() {
    _batchController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    DateTime initialDate = DateTime.now();
    try {
      if (_expiryController.text != "-") {
        initialDate = DateFormat("dd/MM/yyyy").parse(_expiryController.text);
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

    if (picked != null) {
      setState(() {
        _expiryController.text = DateFormat("dd/MM/yyyy").format(picked);
      });
    }
  }

  Future<void> _loadExistingTime() async {
    try {
      final cabinet = await LocalStorage.getCabinet();
      for (var med in cabinet) {
        if (med['code'] == widget.medicineCode) {
          if (med.containsKey('reminderHour') && med.containsKey('reminderMinute')) {
            if (mounted && !_hasManuallyChangedTime) {
              setState(() {
                _selectedTime = TimeOfDay(
                  hour: int.parse(med['reminderHour']),
                  minute: int.parse(med['reminderMinute']),
                );
              });
            }
          }
          break;
        }
      }
    } catch (e) {
      debugPrint("Could not load existing time: $e");
    }
  }

  Map<String, dynamic> get _medInfo => 
      MedicineData.lookup(widget.medicineCode) ?? {
        "uses": "-",
        "dosage": "-",
        "sideEffects": "-",
        "warning": "-",
      };

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _hasManuallyChangedTime = true;
      });
    }
  }

  void _showSuccessDialog(BuildContext context, String medName, LanguageProvider lp) {
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
              Text(lp.translate("Success!", "सफलता!"), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  lp.translate(
                    "$medName added. Reminder set for ${_selectedTime.format(context)}.", 
                    "$medName जोड़ दिया गया। रिमाइन्डर ${_selectedTime.format(context)} के लिए सेट है।"
                  ),
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedVerifyTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Text(lp.translate("OK", "ठीक है"), style: const TextStyle(color: Colors.white)),
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
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: MedVerifyTheme.bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(widget.medicineName, style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainInfoCard(widget.medicineName),
            const SizedBox(height: 20),
            _buildTimeSelectionCard(lp),
            const SizedBox(height: 20),
            _buildDetailSection(lp.translate("Uses", "उपयोग"), _medInfo['uses'], LucideIcons.stethoscope, bulletColor: MedVerifyTheme.primaryBlue),
            const SizedBox(height: 12),
            _buildDetailSection(lp.translate("Advised Dosage", "सलाह दी गई खुराक"), _medInfo['dosage'], LucideIcons.clock, bulletColor: MedVerifyTheme.primaryBlue),
            const SizedBox(height: 20),
            _buildSideEffectsCard(_medInfo['sideEffects'], lp), 
            const SizedBox(height: 20),
            _buildSafetyStatus(lp), 
            const SizedBox(height: 20),
            _buildInteractionWarning(_medInfo['warning'], lp), 
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  await AlertService.showInstantTestNotification();

                  Map<String, String> medicineData = {
                    "name": widget.medicineName,
                    "dosage": widget.dosage,
                    "code": widget.medicineCode,
                    "batch": _batchController.text.trim().isEmpty ? "-" : _batchController.text.trim(),
                    "expiry": _expiryController.text.trim().isEmpty ? "-" : _expiryController.text.trim(),
                    "isAuthentic": widget.isAuthentic ? "Yes" : "No",
                    "dateAdded": DateTime.now().toString(),
                    "reminderTime": _selectedTime.format(context),
                    "reminderHour": _selectedTime.hour.toString(),
                    "reminderMinute": _selectedTime.minute.toString(),
                  };
                  await LocalStorage.saveMedicine(medicineData);

                  int medId = widget.medicineCode.hashCode;
                  await AlertService.scheduleDailyReminder(
                    medId, 
                    widget.medicineName, 
                    _selectedTime.hour, 
                    _selectedTime.minute
                  );

                  if (_expiryController.text != "-") {
                    try {
                      DateFormat format = DateFormat("dd/MM/yyyy");
                      DateTime expDate = format.parse(_expiryController.text);
                      await AlertService.scheduleExpiryAlert(medId, widget.medicineName, expDate);
                    } catch (e) {
                      debugPrint("Expiry alert error: $e");
                    }
                  }

                  if (context.mounted) _showSuccessDialog(context, widget.medicineName, lp);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MedVerifyTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(lp.translate("Add to My Cabinet", "मेरे कैबिनेट में जोड़ें"),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyStatus(LanguageProvider lp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(LucideIcons.shieldCheck, lp.translate("Authenticity", "प्रमाणिकता"), 
              widget.isAuthentic ? lp.translate("Verified Genuine", "असली सत्यापित") : lp.translate("Product Identified", "उत्पाद की पहचान"), 
              widget.isAuthentic ? Colors.green : Colors.blueGrey),
          const Divider(height: 32),
          Text(lp.translate("Verification Details", "सत्यापन विवरण"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          _buildEditableRow(
            icon: LucideIcons.calendar, 
            label: lp.translate("Expiry Date", "समाप्ति तिथि"), 
            controller: _expiryController,
            onAction: _pickExpiryDate,
            actionIcon: LucideIcons.calendarDays,
          ),
          const SizedBox(height: 16),
          _buildEditableRow(
            icon: LucideIcons.package, 
            label: lp.translate("Batch Number", "बैच संख्या"), 
            controller: _batchController,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow({
    required IconData icon, 
    required String label, 
    required TextEditingController controller,
    VoidCallback? onAction,
    IconData actionIcon = LucideIcons.edit3,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: InputBorder.none,
              labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ),
        ),
        IconButton(
          onPressed: onAction ?? () {}, 
          icon: Icon(actionIcon, size: 18, color: MedVerifyTheme.primaryBlue),
        ),
      ],
    );
  }

  Widget _buildMainInfoCard(String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: MedVerifyTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(LucideIcons.pill, color: MedVerifyTheme.primaryBlue, size: 32)), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text("ID: ${widget.medicineCode}", style: const TextStyle(fontSize: 10, color: Colors.blueGrey))]))]),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, Color valueColor) {
    return Row(children: [Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 12), Text(label, style: const TextStyle(color: Colors.grey)), const Spacer(), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor))]);
  }

  Widget _buildTimeSelectionCard(LanguageProvider lp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bell, color: MedVerifyTheme.primaryBlue, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lp.translate("Remind Me At", "मुझे याद दिलाएं"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(_selectedTime.format(context), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: _pickTime,
            child: Text(lp.translate("Change Time", "समय बदलें"), style: const TextStyle(color: MedVerifyTheme.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
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
          Row(children: [Icon(icon, color: MedVerifyTheme.primaryBlue, size: 20), const SizedBox(width: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
          const SizedBox(height: 16),
          ...points.where((p) => p.trim().isNotEmpty).map((point) => _bulletPoint(point.trim(), bulletColor)),
        ],
      ),
    );
  }

  Widget _buildSideEffectsCard(String sideEffect, LanguageProvider lp) {
    List<String> effects = sideEffect.split(RegExp(r'[,|\n]'));
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(LucideIcons.thermometer, color: Colors.orange, size: 20), const SizedBox(width: 12), Text(lp.translate("Common Side Effects", "सामान्य दुष्प्रभाव"), style: const TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 16),
          ...effects.where((e) => e.trim().isNotEmpty).map((effect) => _bulletPoint(effect.trim(), Colors.orange)),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(margin: const EdgeInsets.only(top: 6), width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4)))]),
    );
  }

  Widget _buildInteractionWarning(String warningText, LanguageProvider lp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: MedVerifyTheme.warningRed.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: MedVerifyTheme.warningRed.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(LucideIcons.alertTriangle, color: MedVerifyTheme.warningRed), const SizedBox(width: 8), Text(lp.translate("Interaction Warning", "परस्पर क्रिया चेतावनी"), style: const TextStyle(color: MedVerifyTheme.warningRed, fontWeight: FontWeight.bold))]), const SizedBox(height: 12), Text(warningText, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4))]),
    );
  }
}