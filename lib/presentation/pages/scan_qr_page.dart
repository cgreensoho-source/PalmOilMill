import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../logic/sample/sample_bloc.dart';
import '../../logic/sample/sample_event.dart';
import '../../logic/sample/sample_state.dart';
import 'sample_form_page.dart'; // Halaman form setelah scan sukses

class ScanQRPage extends StatefulWidget {
  const ScanQRPage({super.key});

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> {
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
      _isCheckingPermission = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text("Scan QR Stasiun")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Izin Kamera Diperlukan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Untuk scan QR code, aplikasi memerlukan akses kamera.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkCameraPermission,
                child: const Text("Berikan Izin"),
              ),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text("Buka Pengaturan"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Stasiun")),
      body: BlocListener<SampleBloc, SampleState>(
        listener: (context, state) {
          if (state.validatedStationId != null) {
            // Jika QR valid, lanjut ke halaman form sampling
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SampleFormPage()),
            );
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
        child: MobileScanner(
          controller: MobileScannerController(
            facing: CameraFacing.back,
            torchEnabled: false,
          ),
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                // Kirim data QR ke BLoC untuk divalidasi
                context.read<SampleBloc>().add(
                  ScanQRCodeTriggered(barcode.rawValue!),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
