import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

// Import screens
import 'screens/home_dashboard.dart';
import 'screens/medicine_cabinet_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/prescription_screen.dart';

// Import services
import 'services/language_provider.dart';

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
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: const MedVerifyApp(),
    ),
  );
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

  // Screens are kept in a list to preserve their state without using UniqueKeys
  final List<Widget> _screens = [
    const HomeDashboard(),
    const SizedBox.shrink(), // Placeholder for Scan button
    const PrescriptionScreen(), 
    const MedicineCabinetScreen(),
  ];

  void _onItemTapped(int index) {
    // If "Scan" is clicked, open Scanner Screen as a Full-Screen Modal
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex, 
        children: _screens,
      ),
      bottomNavigationBar: Consumer<LanguageProvider>(
        builder: (context, lp, child) {
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: const Color(0xFF2260FF),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(LucideIcons.home), 
                label: lp.translate('Home', 'होम')
              ),
              BottomNavigationBarItem(
                icon: const Icon(LucideIcons.scanLine), 
                label: lp.translate('Scan', 'स्कैन')
              ),
              BottomNavigationBarItem(
                icon: const Icon(LucideIcons.fileText), 
                label: lp.translate('Prescription', 'पर्चा')
              ),
              BottomNavigationBarItem(
                icon: const Icon(LucideIcons.package), 
                label: lp.translate('Cabinet', 'कैबिनेट')
              ),
            ],
          );
        },
      ),
    );
  }
}