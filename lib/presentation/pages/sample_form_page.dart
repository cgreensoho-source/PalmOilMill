import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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

      if (authState is AuthAuthenticated) {
        _currentUser = authState.user;
      }

      if (sampleState.validatedStationId != null) {
        _stationId = sampleState.validatedStationId!;
        _stationName = sampleState.stationName ?? 'Tidak diketahui';
        _coordinates = sampleState.coordinates ?? 'Tidak diketahui';

        // Pre-fill nama sampel dengan nama stasiun
        _nameController.text = _stationName;
      }
      _isInitialized = true;
    }
  }

  // FUNGSI KUNCI: HANYA CAMERA, TIDAK ADA PILIHAN GALERI
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70, // Kompres dikit biar upload enteng
    );

    if (photo != null) {
      if (!mounted) return;
      context.read<SampleBloc>().add(PhotoTaken(File(photo.path)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Form Sampling")),
      body: BlocListener<SampleBloc, SampleState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // Balik ke Dashboard
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info User - Read Only Fields
              const Text(
                "Informasi Petugas",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: TextEditingController(text: _currentUser.username),
                decoration: const InputDecoration(
                  labelText: "Nama Petugas",
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: TextEditingController(text: _currentUser.nip),
                decoration: const InputDecoration(
                  labelText: "NIP Petugas",
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 20),

              // Info Stasiun - Read Only Fields
              const Text(
                "Informasi Stasiun",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: TextEditingController(text: _stationId.toString()),
                decoration: const InputDecoration(
                  labelText: "ID Stasiun",
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: TextEditingController(text: _stationName),
                decoration: const InputDecoration(
                  labelText: "Nama Stasiun",
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: TextEditingController(text: _coordinates),
                decoration: const InputDecoration(
                  labelText: "Koordinat",
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nama Sampel",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _conditionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Kondisi/Catatan",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                "Foto Petugas (Wajib Camera):",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // LIST FOTO YANG SUDAH DIAMBIL
              BlocBuilder<SampleBloc, SampleState>(
                builder: (context, state) {
                  return SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.capturedImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == state.capturedImages.length) {
                          // Tombol Tambah Foto
                          return GestureDetector(
                            onTap: _takePhoto,
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.add_a_photo, size: 40),
                            ),
                          );
                        }
                        // Preview Foto
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: FileImage(state.capturedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 5,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                onPressed: () => context.read<SampleBloc>().add(
                                  PhotoRemoved(index),
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

              const SizedBox(height: 40),

              // TOMBOL SUBMIT
              BlocBuilder<SampleBloc, SampleState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              final authState = context.read<AuthBloc>().state;
                              if (authState is AuthAuthenticated) {
                                context.read<SampleBloc>().add(
                                  SampleSubmitted(
                                    userId: authState.user.userId,
                                    stationId:
                                        state.validatedStationId ??
                                        0, // ID dari QR tadi
                                    sampleName: _nameController.text,
                                    condition: _conditionController.text,
                                    isOnline:
                                        true, // Nanti tambahkan logic cek koneksi asli
                                  ),
                                );
                              }
                            },
                      child: state.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SIMPAN & KIRIM SAMPEL"),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
