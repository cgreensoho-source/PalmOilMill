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
        title: const Text("Profil Pekerja", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String username = "Memuat...";
          String nip = "-";

          if (state is AuthAuthenticated) {
            username = state.user.username;
            nip = state.user.nip;
          }

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Foto Profil Besar
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, size: 80, color: primaryColor),
                ),
              ),
              const SizedBox(height: 24),

              // Kartu Informasi Detail
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.badge_outlined, color: primaryColor),
                        title: const Text("Nama Pekerja"),
                        subtitle: Text(username.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.pin_outlined, color: primaryColor),
                        title: const Text("NIP"),
                        subtitle: Text(nip, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.work_outline, color: primaryColor),
                        title: const Text("Departemen"),
                        subtitle: const Text("Quality Control (QC)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Tombol Keluar (Logout)
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text("KELUAR DARI SISTEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  // Dialog Konfirmasi Logout
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            child: const Text("Ya, Keluar"),
          ),
        ],
      ),
    );
  }
}