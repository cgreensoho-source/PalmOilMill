import '../datasources/station_remote_datasource.dart';
import '../../core/database/db_helper.dart';
import '../models/station_model.dart';

class StationRepository {
  final StationRemoteDataSource remoteDataSource;
  final DBHelper dbHelper;

  StationRepository(this.remoteDataSource, this.dbHelper);

  Future<List<StationModel>> getAllStations(bool isOnline) async {
    if (isOnline) {
      try {
        final stations = await remoteDataSource.getStations();

        // Simpan ke local DB untuk cadangan offline (Caching)
        for (var s in stations) {
          await dbHelper.insert('stations', s.toMap());
        }
        return stations;
      } catch (e) {
        // Jika gagal API tapi disuruh online, coba lempar ke local
        return _getLocalStations();
      }
    } else {
      return _getLocalStations();
    }
  }

  Future<List<StationModel>> _getLocalStations() async {
    final res = await dbHelper.queryAll('stations');
    return res.map((e) => StationModel.fromJson(e)).toList();
  }

  Future<StationModel?> getStationById(int stationId, bool isOnline) async {
    final stations = await getAllStations(isOnline);
    try {
      return stations.firstWhere((s) => s.stationId == stationId);
    } catch (e) {
      return null;
    }
  }
}
