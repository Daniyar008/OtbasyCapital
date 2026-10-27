import 'package:shared_preferences/shared_preferences.dart';

abstract interface class StorageService {
  Future<String?> read();
  Future<void> write(String value);
}

/// Persists demonstration records locally. No credentials are stored.
class LocalStorageService implements StorageService {
  static const key = 'otbasy_lesson3_v1';
  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(key);
  @override
  Future<void> write(String value) async {
    final success = await (await SharedPreferences.getInstance()).setString(
      key,
      value,
    );
    if (!success) throw StateError('Local storage rejected the write');
  }
}

class MemoryStorageService implements StorageService {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}
