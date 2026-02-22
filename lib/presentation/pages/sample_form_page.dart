import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import Wajib Internet
import '../../logic/sample/sample_bloc.dart';
import '../../logic/sample/sample_event.dart';
import '../../logic/sample/sample_state.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_state.dart';
import '../../data/models/user_model.dart';

class SampleFormPage extends StatefulWidget {
  const SampleFormPage({super.key});

  @override
  State<SampleFormPage> createState() => _SampleFormPageState();
}

class _SampleFormPageState extends State<SampleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _conditionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late UserModel _currentUser;
  late int _stationId;
  late String _stationName;
  late String _coordinates;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final sampleState = context.read<SampleBloc>().state;
      final authState = context.read<AuthBloc>().state;

      // Ambil data dari BLoC, sediakan fallback aman agar tidak crash LateInitialization
      if (authState is AuthAuthenticated) {
        _currentUser = authState.user;
      } else {
        _currentUser = UserModel(userId: 1, nip: "-", username: "Guest", email: "", phone: "", gender: "");
      }

      if (sampleState.validatedStationId != null) {
        _stationId = sampleState.validatedStationId!;
        _stationName = sampleState.stationName ?? 'Tidak diketahui';
        _coordinates = sampleState.coordinates ?? '-';
        _nameController.text = 'SAMPEL - ${_stationName.toUpperCase()}';
      } else {
        _stationId = 0;
        _stationName = "Station-Error";
        _coordinates = "-";
      }

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null) {
      if (!mounted) return;
      context.read<SampleBloc>().add(PhotoTaken(File(photo.path)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "LAPORAN SAMPLING",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      body: BlocListener<SampleBloc, SampleState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Text(state.successMessage!)),
                  ],
                ),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context); // Kembali ke Dashboard
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Text(state.errorMessage!)),
                  ],
                ),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- KARTU 1: INFO SISTEM ---
                _buildSectionHeader(Icons.info_outline, "Data Perekaman"),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person, "Petugas", _currentUser.username),
                        const Divider(height: 20),
                        _buildInfoRow(Icons.location_on, "Lokasi Stasiun", _stationName),
                        const Divider(height: 20),
                        _buildInfoRow(Icons.gps_fixed, "Koordinat", _coordinates),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- KARTU 2: FORM INPUT ---
                _buildSectionHeader(Icons.edit_document, "Detail Sampel"),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "Nama / Kode Sampel",
                            prefixIcon: Icon(Icons.science, color: primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _conditionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: "Kondisi Fisik / Catatan Lapangan",
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 40),
                              child: Icon(Icons.notes, color: primaryColor),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- KARTU 3: DOKUMENTASI FOTO ---
                _buildSectionHeader(Icons.camera_alt, "Dokumentasi Lapangan"),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ambil foto bukti fisik (Wajib).", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        BlocBuilder<SampleBloc, SampleState>(
                          builder: (context, state) {
                            return SizedBox(
                              height: 110,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: state.capturedImages.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == state.capturedImages.length) {
                                    return GestureDetector(
                                      onTap: _takePhoto,
                                      child: Container(
                                        width: 100,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          border: Border.all(color: Colors.green.shade300, width: 2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo, size: 32, color: primaryColor),
                                            Text("Tambah", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          image: DecorationImage(image: FileImage(state.capturedImages[index]), fit: BoxFit.cover),
                                        ),
                                      ),
                                      Positioned(
                                        right: 12, top: 0,
                                        child: InkWell(
                                          onTap: () => context.read<SampleBloc>().add(PhotoRemoved(index)),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            color: Colors.red,
                                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // --- TOMBOL SUBMIT DENGAN CEK INTERNET (PERBAIKAN VERSI) ---
                BlocBuilder<SampleBloc, SampleState>(
                  builder: (context, state) {
                    final bool isReady = state.capturedImages.isNotEmpty;

                    return SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        icon: state.isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.cloud_upload),
                        label: Text(
                          state.isLoading ? "MEMPROSES..." : "SIMPAN & KIRIM LAPORAN",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: state.isLoading || !isReady
                            ? null
                            : () async {
                          if (_formKey.currentState!.validate()) {
                            // 1. Cek Koneksi Internet (Diperbaiki)
                            final connectivityResult = await Connectivity().checkConnectivity();
                            bool hasInternet = connectivityResult != ConnectivityResult.none;

                            // 2. Tembak Event
                            if (context.mounted) {
                              context.read<SampleBloc>().add(
                                SampleSubmitted(
                                  userId: _currentUser.userId,
                                  stationId: _stationId,
                                  sampleName: _nameController.text,
                                  condition: _conditionController.text,
                                  isOnline: hasInternet, // Mode diputuskan otomatis!
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.green.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}