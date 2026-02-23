import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart'; // Add this
import 'screens/home_dashboard.dart';
import 'screens/medicine_cabinet_screen.dart';
import 'screens/scanner_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  // Ensure Flutter is ready before calling native code
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set the device to its maximum refresh rate (90Hz, 120Hz, etc.)
  await setMaxRefreshRate();
  
  runApp(const MedVerifyApp());
}

// Function to unlock high refresh rates on Android devices
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
        // Enabling Material 3 and using seed colors helps with GPU efficiency
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

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      ).then((_) {
        setState(() {
          _homeKey = UniqueKey();
          _cabinetKey = UniqueKey();
        });
      });
    } else {
      if (_selectedIndex != index) {
        setState(() {
          _selectedIndex = index;
          if (index == 2) _cabinetKey = UniqueKey();
          if (index == 0) _homeKey = UniqueKey();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Optimization: IndexedStack works best when the children list 
    // is built once. Use 'const' where possible.
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex, 
        children: [
          HomeDashboard(key: _homeKey),
          const SizedBox.shrink(), // Using shrink() is lighter than SizedBox()
          MedicineCabinetScreen(key: _cabinetKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2260FF),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Cabinet'),
        ],
      ),
    );
  }
}