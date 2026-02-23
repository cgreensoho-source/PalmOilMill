import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

      if (authState is AuthAuthenticated) {
        _currentUser = authState.user;
      } else {
        _currentUser = UserModel(
          userId: 0,
          nip: "-",
          username: "Guest",
          role: "OPERATOR",
          token: "",
          email: "",
          phone: "",
          gender: "",
        );
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocListener<SampleBloc, SampleState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
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
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.person,
                          "Petugas",
                          _currentUser.username,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          Icons.location_on,
                          "Lokasi",
                          _stationName,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nama Sampel",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _conditionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Kondisi",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Foto Dokumentasi",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                BlocBuilder<SampleBloc, SampleState>(
                  builder: (context, state) {
                    return SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.capturedImages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == state.capturedImages.length) {
                            return GestureDetector(
                              onTap: _takePhoto,
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          }
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(state.capturedImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                BlocBuilder<SampleBloc, SampleState>(
                  builder: (context, state) {
                    return SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        onPressed:
                            state.isLoading || state.capturedImages.isEmpty
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  // PERBAIKAN: Mengakses hasil koneksi tanpa .any() karena tipenya enum, bukan list
                                  final result = await Connectivity()
                                      .checkConnectivity();
                                  bool hasInternet =
                                      result != ConnectivityResult.none;

                                  if (context.mounted) {
                                    context.read<SampleBloc>().add(
                                      SampleSubmitted(
                                        userId: _currentUser.userId,
                                        stationId: _stationId,
                                        sampleName: _nameController.text,
                                        condition: _conditionController.text,
                                        isOnline: hasInternet,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Text(
                          state.isLoading ? "MEMPROSES..." : "KIRIM LAPORAN",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.green),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
