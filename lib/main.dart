import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:lucide_icons/lucide_icons.dart'; // Added for modern icons
import 'screens/home_dashboard.dart';
import 'screens/medicine_cabinet_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/prescription_screen.dart'; // Import the new screen

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  await _createNotificationChannels();
  await requestNotificationPermissions();
  
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  
  await setMaxRefreshRate();
  
  runApp(const MedVerifyApp());
}

Future<void> _createNotificationChannels() async {
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
    'dosage_channel', 
    'Dosage Alerts',
    description: 'Reminders to take your medicine',
    importance: Importance.max,
    playSound: true,
  ));

  await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
    'expiry_channel', 
    'Expiry Alerts',
    description: 'Alerts for medicine expiration',
    importance: Importance.max,
    playSound: true,
  ));
}

Future<void> requestNotificationPermissions() async {
  final androidImplementation = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  
  if (androidImplementation != null) {
    await androidImplementation.requestNotificationsPermission();
    await androidImplementation.requestExactAlarmsPermission();
  }
}

Future<void> setMaxRefreshRate() async {
  try {
    final List<DisplayMode> modes = await FlutterDisplayMode.supported;
    final DisplayMode highest = modes.reduce((a, b) => a.refreshRate > b.refreshRate ? a : b);
    await FlutterDisplayMode.setPreferredMode(highest);
  } catch (e) {
    debugPrint("High refresh rate not supported on this device: $e");
  }
}

class MedVerifyApp extends StatelessWidget {
  const MedVerifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedVerify',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver], 
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2260FF),
          primary: const Color(0xFF2260FF),
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const ScreenSwitcher(),
    );
  }
}

class ScreenSwitcher extends StatefulWidget {
  const ScreenSwitcher({super.key});

  @override
  State<ScreenSwitcher> createState() => _ScreenSwitcherState();
}

class _ScreenSwitcherState extends State<ScreenSwitcher> {
  int _selectedIndex = 0;
  Key _cabinetKey = UniqueKey();
  Key _homeKey = UniqueKey();
  Key _prescriptionKey = UniqueKey();

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      ).then((_) {
        setState(() {
          _homeKey = UniqueKey();
          _cabinetKey = UniqueKey();
          _prescriptionKey = UniqueKey();
        });
      });
    } else {
      if (_selectedIndex != index) {
        setState(() {
          _selectedIndex = index;
          if (index == 0) _homeKey = UniqueKey();
          if (index == 2) _prescriptionKey = UniqueKey();
          if (index == 3) _cabinetKey = UniqueKey();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex, 
        children: [
          HomeDashboard(key: _homeKey),
          const SizedBox.shrink(), 
          PrescriptionScreen(key: _prescriptionKey), 
          MedicineCabinetScreen(key: _cabinetKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2260FF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        // REMOVED 'const' from items to allow LucideIcons
        items: [
          const BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.scanLine), label: 'Scan'),
          const BottomNavigationBarItem(icon: Icon(LucideIcons.fileText), label: 'Prescription'),
          // Changed 'inventory' to 'package' which exists in Lucide
          const BottomNavigationBarItem(icon: Icon(LucideIcons.package), label: 'Cabinet'),
        ],
      ),
    );
  }
}