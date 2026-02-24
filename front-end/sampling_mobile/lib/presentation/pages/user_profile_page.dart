import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../widgets/initial_avatar.dart';
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
          String role = "OPERATOR";

          if (state is AuthAuthenticated) {
            username = state.user.username;
            nip = state.user.nip;
            role = state.user.role;
          }

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Avatar Inisial dengan warna hijau tetap
              Center(
                child: InitialAvatar(
                  name: username,
                  radius: 60,
                  fontSize: 48,
                  backgroundColor: primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // Kartu Informasi Profil
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

              // Tombol Logout dengan tema netral (Abu-abu)
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
      title: Text(
        title,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: color, // Teks Nama, NIP, dan Role menjadi Hijau
        ),
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
          backgroundColor: Colors.white,
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
