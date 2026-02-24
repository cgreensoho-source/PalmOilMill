import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../widgets/initial_avatar.dart';
import 'user_profile_page.dart';
import 'login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Pengaturan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),

          // Menu Profil User
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              String username = "Pekerja";
              if (state is AuthAuthenticated) {
                username = state.user.username;
              }

              return ListTile(
                leading: InitialAvatar(
                  name: username,
                  radius: 22,
                  fontSize: 18,
                  backgroundColor: Colors.green.shade700,
                ),
                title: Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Lihat ID dan detail akun"),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserProfilePage(),
                    ),
                  );
                },
              );
            },
          ),
          const Divider(height: 32),

          // Menu Tentang Aplikasi
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: Icon(
                Icons.info_outline_rounded,
                color: Colors.grey.shade700,
              ),
            ),
            title: const Text("Tentang Aplikasi"),
            subtitle: const Text("Versi 1.0.0"),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade500,
            ),
            onTap: () => _showAboutAppDialog(context),
          ),
          const Divider(height: 32),

          // Menu Logout Tanpa Warna Merah
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: Icon(Icons.logout_rounded, color: Colors.grey.shade700),
            ),
            title: const Text(
              "Keluar Akun",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 24,
          horizontal: 20,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 80,
              width: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.science, size: 80, color: Colors.green),
            ),
            const SizedBox(height: 16),
            const Text(
              "MILL TRACK",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Sistem informasi manajemen terpadu untuk perekaman data sampling lapangan secara real-time.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.3),
            ),
            const SizedBox(height: 24),
            Image.asset(
              'assets/images/cgreen.png',
              height: 70,
              fit: BoxFit.contain,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "TUTUP",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Keluar"),
        content: const Text("Apakah Anda yakin ingin keluar dari sistem?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.grey.shade800, // Menggunakan abu-abu gelap netral
              foregroundColor: Colors.white,
            ),
            child: const Text("Ya, Keluar"),
          ),
        ],
      ),
    );
  }
}
