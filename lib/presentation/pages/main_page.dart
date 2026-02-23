import 'package:flutter/material.dart';

// Import halaman-halaman yang akan masuk ke dalam tab
import 'dashboard_page.dart'; // Tab 1
import 'history_page.dart';   // Tab 2
import 'notification_page.dart'; // Tab 3
import 'settings_page.dart';  // Tab 4
import 'scan_qr_page.dart';   // Untuk tombol tengah

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // Daftar halaman untuk tiap tab
  final List<Widget> _pages = const [
    DashboardPage(),
    HistoryPage(),
    NotificationPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // IndexedStack agar state halaman tidak ter-reset saat pindah tab
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // TOMBOL SCAN QR DI TENGAH
      floatingActionButton: SizedBox(
        height: 68,
        width: 68,
        child: FloatingActionButton(
          backgroundColor: Colors.green.shade600,
          shape: const CircleBorder(),
          elevation: 4,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanQRPage()),
            );
          },
          child: const Icon(Icons.qr_code_scanner_rounded, size: 34, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BOTTOM NAVIGATION BAR GELAP
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFFFFFFF),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.grid_view_rounded, 0),
              _buildNavItem(Icons.history_rounded, 1),

              const SizedBox(width: 48), // Ruang kosong untuk tombol tengah

              _buildNavItem(Icons.notifications_none_rounded, 2),
              _buildNavItem(Icons.settings_outlined, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        size: 28,
        color: isSelected ? Colors.green : Colors.grey.shade600,
      ),
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}