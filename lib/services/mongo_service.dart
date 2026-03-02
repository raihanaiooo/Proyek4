import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoService {
  Db? _db;

  Db get db {
    if (_db == null) {
      throw Exception("Database belum terhubung. Panggil connect() dulu.");
    }
    return _db!;
  }

  /// 🔌 Connect ke MongoDB Atlas
  Future<void> connect() async {
    final uri = dotenv.env['MONGODB_URI'];

    if (uri == null || uri.isEmpty) {
      throw Exception("MONGODB_URI tidak ditemukan di .env");
    }

    _db = await Db.create(uri); // ⭐ PENTING
    await _db!.open();
  }

  /// 🔒 Close connection
  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
    }
  }

  /// 📂 Helper ambil collection (optional tapi berguna)
  DbCollection collection(String name) {
    return db.collection(name);
  }
}
