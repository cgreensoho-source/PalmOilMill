import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../logic/sample/sample_bloc.dart';
import '../../logic/sample/sample_event.dart';
import '../../logic/sample/sample_state.dart';
import 'sample_form_page.dart';

class ScanQRPage extends StatefulWidget {
  const ScanQRPage({super.key});

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> {
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  // Controller untuk mengontrol kamera dan senter (flashlight)
  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
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
    final primaryColor = Colors.green.shade700;

    // --- UI SAAT MENUNGGU PENGECEKAN IZIN ---
    if (_isCheckingPermission) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              const Text("Memeriksa otorisasi perangkat..."),
            ],
          ),
        ),
      );
    }

    // --- UI SAAT IZIN KAMERA DITOLAK ---
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          title: const Text("Otorisasi Kamera", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.videocam_off_rounded, size: 80, color: Colors.red.shade400),
                ),
                const SizedBox(height: 24),
                Text(
                  "Akses Kamera Diperlukan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 12),
                Text(
                  "Sistem membutuhkan akses modul kamera perangkat untuk membaca QR Code Stasiun sesuai standar prosedur operasional.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _checkCameraPermission,
                    child: const Text("Minta Ulang Otorisasi", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => openAppSettings(),
                  child: Text("Buka Pengaturan Sistem", style: TextStyle(color: Colors.grey.shade600)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- UI UTAMA SCANNER ---
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "SCAN STASIUN",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        actions: [
          // Tombol Senter / Flashlight
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
              color: _isFlashOn ? Colors.yellow : Colors.white,
              size: 28,
            ),
            tooltip: 'Senter',
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true, // Agar kamera full screen sampai ke bawah AppBar
      body: BlocListener<SampleBloc, SampleState>(
        listener: (context, state) {
          if (state.validatedStationId != null) {
            // Berikan feedback getaran/suara ringan sebelum pindah (Opsional)
            // Jika QR valid, tutup kamera dan lanjut ke halaman form
            _scannerController.dispose();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SampleFormPage()),
            );
          }
          if (state.errorMessage != null) {
            // Jika QR salah, tampilkan error warna merah
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Text(state.errorMessage!)),
                  ],
                ),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              ),
            );
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Modul Kamera
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    // Kirim data ke BLoC (hindari spam jika sedang loading)
                    final state = context.read<SampleBloc>().state;
                    if (!state.isLoading) {
                      context.read<SampleBloc>().add(
                        ScanQRCodeTriggered(barcode.rawValue!),
                      );
                    }
                  }
                }
              },
            ),

            // 2. Efek Gelap di luar area kotak (Overlay)
            Container(
              decoration: ShapeDecoration(
                shape: _ScannerOverlayShape(
                  borderColor: primaryColor,
                  borderWidth: 6.0,
                  overlayColor: Colors.black.withOpacity(0.6),
                ),
              ),
            ),

            // 3. Teks Instruksi di layar
            Positioned(
              bottom: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.qr_code_2, color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text(
                      "Arahkan kotak ke QR Code Stasiun",
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Indikator Loading saat BLoC sedang validasi QR
            BlocBuilder<SampleBloc, SampleState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const CircularProgressIndicator(color: Colors.green),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- CLASS TAMBAHAN UNTUK MEMBUAT KOTAK SCANNER TRANSPARAN DI TENGAH ---
class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;

  const _ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.overlayColor = const Color(0x88000000),
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }
    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // Ukuran kotak target scanner
    final width = rect.width * 0.7;
    final height = width;
    final borderRadius = 12.0;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxRect = Rect.fromCenter(
      center: rect.center,
      width: width,
      height: height,
    );

    final boxPath = Path()
      ..addRRect(RRect.fromRectAndRadius(boxRect, Radius.circular(borderRadius)));

    // Gambar background gelap yang dipotong tengahnya
    final backgroundPath = Path()
      ..addRect(rect)
      ..addPath(boxPath, Offset.zero)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Gambar bingkai (border)
    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, Radius.circular(borderRadius)), borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return _ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
    );
  }
}