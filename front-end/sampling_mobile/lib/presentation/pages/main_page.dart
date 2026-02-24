import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/notification/notification_bloc.dart';
import 'dashboard_page.dart';
import 'history_page.dart';
import 'notification_page.dart';
import 'settings_page.dart';
import 'scan_qr_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    HistoryPage(),
    NotificationPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(FetchNotificationsTriggered());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: IndexedStack(index: _selectedIndex, children: _pages),

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
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            size: 34,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFFFFFFF),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                Icons.dashboard_rounded,
                Icons.dashboard_outlined,
                "Dashboard",
                0,
              ),
              _buildNavItem(
                Icons.history_rounded,
                Icons.history_outlined,
                "Riwayat",
                1,
              ),
              const SizedBox(width: 48),
              _buildNavItem(
                Icons.notifications_rounded,
                Icons.notifications_none_rounded,
                "Notifikasi",
                2,
              ),
              _buildNavItem(
                Icons.settings_rounded,
                Icons.settings_outlined,
                "Pengaturan",
                3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData filledIcon,
    IconData outlinedIcon,
    String label,
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Colors.green.shade700 : Colors.grey.shade600;

    // 1. KUNCI ABSOLUT: Kunci wujud ikon asli ke dalam variabel final yang tidak bisa diubah (immutable).
    final Widget baseIcon = Icon(
      isSelected ? filledIcon : outlinedIcon,
      size: 26,
      color: color,
    );

    // 2. Variabel dinamis untuk dirender
    Widget finalIconWidget = baseIcon;

    if (index == 2) {
      finalIconWidget = BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          int unreadCount = 0;
          if (state is NotificationLoaded) {
            unreadCount = state.unreadCount;
          }

          return Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.red.shade600,
            offset: const Offset(4, -4),
            // PANGGIL baseIcon DI SINI, BUKAN finalIconWidget! Mencegah Infinite Loop.
            child: baseIcon,
          );
        },
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        if (index == 2) {
          context.read<NotificationBloc>().add(FetchNotificationsTriggered());
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            finalIconWidget,
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
