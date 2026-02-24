import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Validasi Hardware
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS mati. Nyalakan GPS perangkat Anda.');
    }

    // 2. Validasi Izin
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Akses lokasi ditolak. Tidak bisa melakukan absensi.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Buka pengaturan HP.');
    }

    // 3. Eksekusi Pengambilan Titik
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    // 4. ANTI-SPOOFING (DETEKSI FAKE GPS)
    if (position.isMocked) {
      throw Exception(
        'SISTEM MENOLAK: Aplikasi Fake GPS terdeteksi aktif di perangkat Anda.',
      );
    }

    return position;
  }
}
