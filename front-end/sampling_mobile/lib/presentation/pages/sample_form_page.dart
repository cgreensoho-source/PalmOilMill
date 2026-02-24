import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/location_service.dart';
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
  late String _coordinates; // Format expected: "latitude, longitude"
  bool _isInitialized = false;

  // State Manajemen GPS Aktual & Jarak
  Position? _userPosition;
  bool _isLoadingInitialLocation = false;
  String _locationStatus = "";
  double _distanceInMeters = 0.0;
  bool _isInRange = false;
  bool _hasValidTarget = false;

  bool _isFetchingLocation = false; // Kunci submit UI

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
          userId: 1,
          nip: "-",
          username: "Guest",
          role: "GUEST",
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
      _fetchInitialLocation(); // Langsung cari satelit saat halaman dibuka
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  // --- LOGIKA PERHITUNGAN RADIUS 50 METER ---
  Future<void> _fetchInitialLocation() async {
    setState(() {
      _isLoadingInitialLocation = true;
      _locationStatus = "Mencari satelit GPS...";
    });

    try {
      final posisi = await LocationService.getCurrentLocation();

      double targetLat = 0.0;
      double targetLng = 0.0;
      bool hasValidTarget = false;

      try {
        final parts = _coordinates.split(',');
        if (parts.length >= 2) {
          targetLat = double.parse(parts[0].trim());
          targetLng = double.parse(parts[1].trim());
          hasValidTarget = true;
        }
      } catch (e) {
        // Format titik target dari database salah atau kosong
      }

      double distance = 0.0;
      bool inRange = false;

      if (hasValidTarget) {
        // Kalkulasi jarak menggunakan formula Haversine bawaan Geolocator
        distance = Geolocator.distanceBetween(
          targetLat,
          targetLng,
          posisi.latitude,
          posisi.longitude,
        );
        inRange = distance <= 50.0; // Validasi radius maksimal 50 meter
      }

      if (mounted) {
        setState(() {
          _userPosition = posisi;
          _distanceInMeters = distance;
          _isInRange = inRange;
          _hasValidTarget = hasValidTarget;
          _isLoadingInitialLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInitialLocation = false;
          _locationStatus = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
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

  Future<void> _submitWithLocation(
    BuildContext context,
    SampleState state,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi Lapis Dua Keamanan
    if (_userPosition == null || !_isInRange) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Tindakan Ditolak: Lokasi belum valid atau di luar radius.",
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    setState(() => _isFetchingLocation = true);

    try {
      // Gunakan posisi yang sudah berhasil divalidasi dan dihitung jaraknya
      final double latitude = _userPosition!.latitude;
      final double longitude = _userPosition!.longitude;

      final connectivityResult = await Connectivity().checkConnectivity();
      bool hasInternet = connectivityResult != ConnectivityResult.none;

      if (mounted) {
        context.read<SampleBloc>().add(
          SampleSubmitted(
            userId: _currentUser.userId,
            stationId: _stationId,
            sampleName: _nameController.text,
            condition: _conditionController.text,
            isOnline: hasInternet,
            // Jika backend Anda butuh parameter lokasi, uncomment ini:
            // lat: latitude,
            // lng: longitude,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
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
                content: Text(state.successMessage!),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
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
                // --- KARTU 1: INFO SISTEM & VALIDASI RADIUS ---
                _buildSectionHeader(Icons.info_outline, "Data Perekaman"),
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
                        const Divider(height: 20),
                        _buildInfoRow(
                          Icons.location_on,
                          "Lokasi Stasiun",
                          _stationName,
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          Icons.gps_fixed,
                          "Koordinat Target",
                          _coordinates,
                        ),
                        const Divider(height: 20),
                        // UI Dinamis Validasi Radius
                        _buildUserLocationStatus(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- KARTU 2: FORM INPUT ---
                _buildSectionHeader(Icons.edit_document, "Detail Sampel"),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "Nama / Kode Sampel",
                            prefixIcon: Icon(
                              Icons.science,
                              color: primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Wajib diisi' : null,
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Wajib diisi' : null,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ambil foto bukti fisik (Wajib).",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
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
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          border: Border.all(
                                            color: Colors.green.shade300,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_a_photo,
                                              size: 32,
                                              color: primaryColor,
                                            ),
                                            Text(
                                              "Tambah",
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          image: DecorationImage(
                                            image: FileImage(
                                              state.capturedImages[index],
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 12,
                                        top: 0,
                                        child: InkWell(
                                          onTap: () => context
                                              .read<SampleBloc>()
                                              .add(PhotoRemoved(index)),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            color: Colors.red,
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
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

                // --- TOMBOL SUBMIT ---
                BlocBuilder<SampleBloc, SampleState>(
                  builder: (context, state) {
                    final bool isReady = state.capturedImages.isNotEmpty;
                    final bool isProcessing =
                        state.isLoading || _isFetchingLocation;

                    // Kunci strategi operasional: Submit ditolak jika di luar jangkauan
                    final bool isSubmitAllowed =
                        isReady && !_isLoadingInitialLocation && _isInRange;

                    return SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        icon: isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: Text(
                          isProcessing ? "MEMPROSES..." : "SIMPAN LAPORAN",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmitAllowed && !isProcessing
                            ? () => _submitWithLocation(context, state)
                            : null, // Blokir jika di luar radius
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

  // --- WIDGET LOKASI AKTUAL & NOTIFIKASI RADIUS ---
  Widget _buildUserLocationStatus() {
    if (_isLoadingInitialLocation) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            "Membaca koordinat aktual...",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      );
    }

    if (_userPosition == null) {
      return Row(
        children: [
          Icon(Icons.location_off, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _locationStatus,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _fetchInitialLocation, // Tombol retry lokasi manual
          ),
        ],
      );
    }

    final userCoordString =
        "${_userPosition!.latitude}, ${_userPosition!.longitude}";
    final statusColor = _isInRange
        ? Colors.green.shade700
        : Colors.red.shade700;
    final statusIcon = _isInRange ? Icons.check_circle : Icons.cancel;

    String statusText;
    if (!_hasValidTarget) {
      statusText = "Gagal memvalidasi radius (Format Target Invalid)";
    } else if (_isInRange) {
      statusText =
          "Sedang dalam lokasi stasiun (${_distanceInMeters.toStringAsFixed(1)} meter)";
    } else {
      statusText =
          "Sedang tidak dalam lokasi (${_distanceInMeters.toStringAsFixed(1)} meter)";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          Icons.person_pin_circle,
          "Koordinat Aktual",
          userCoordString,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              InkWell(
                onTap:
                    _fetchInitialLocation, // Tombol refresh jika pengguna bergeser
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.refresh,
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
