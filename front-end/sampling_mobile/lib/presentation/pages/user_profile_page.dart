import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import 'login_page.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Profil Pekerja",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String username = "Memuat...";
          String nip = "-";
          String role = "OPERATOR"; // Default role

          if (state is AuthAuthenticated) {
            username = state.user.username;
            nip = state.user.nip;
            role = state.user.role; // Mengambil role dinamis
          }

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, size: 80, color: primaryColor),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildProfileItem(
                        Icons.badge_outlined,
                        "Nama Pekerja",
                        username.toUpperCase(),
                        primaryColor,
                      ),
                      const Divider(),
                      _buildProfileItem(
                        Icons.pin_outlined,
                        "NIP",
                        nip,
                        primaryColor,
                      ),
                      const Divider(),
                      // Tampilan Role Dinamis menggantikan teks statis
                      _buildProfileItem(
                        Icons.work_outline,
                        "Jabatan / Role",
                        role.toUpperCase(),
                        primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildLogoutButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          "KELUAR AKUN",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.grey.shade800,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
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
            child: const Text("Batal"),
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
              backgroundColor: Colors.grey.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text("Ya, Keluar"),
          ),
        ],
      ),
    );
  }
}
