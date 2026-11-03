import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores one receipt image under the signed-in user's folder.
/// The bucket is private; the interface uses a short-lived signed link.
class ReceiptStorageService {
  ReceiptStorageService(this.client);
  final SupabaseClient client;

  static ReceiptStorageService get instance =>
      ReceiptStorageService(Supabase.instance.client);

  Future<String> upload({
    required String entryId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Фото қосу үшін аккаунтқа кіріңіз.');
    final safeExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? extension
        : 'jpg';
    final contentType = switch (safeExtension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final path = '$userId/$entryId.$safeExtension';
    await client.storage
        .from('receipts')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return path;
  }

  Future<String?> signedUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    return client.storage.from('receipts').createSignedUrl(path, 60 * 30);
  }
}
