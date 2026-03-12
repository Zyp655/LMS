import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';

class EncryptionService {
  static const int _chunkSize = 2 * 1024 * 1024;

  String generateKey() {
    final key = encrypt.Key.fromSecureRandom(32);
    return base64Encode(key.bytes);
  }

  String deriveDeviceBoundKey(String baseKey, String deviceId) {
    final combined = utf8.encode('$baseKey:$deviceId');
    final hash = List<int>.generate(
      32,
      (i) => combined[i % combined.length] ^ (i * 37),
    );
    return base64Encode(hash);
  }

  Future<String> encryptFile(String inputPath, String keyBase64) async {
    final file = File(inputPath);
    if (!await file.exists()) {
      throw FileSystemException('Input file not found', inputPath);
    }

    final appDir = await getApplicationSupportDirectory();
    final encDir = Directory('${appDir.path}/encrypted');
    if (!await encDir.exists()) {
      await encDir.create(recursive: true);
    }

    final outputPath =
        '${encDir.path}/${DateTime.now().millisecondsSinceEpoch}.enc';
    final outputFile = File(outputPath);

    final keyBytes = base64Decode(keyBase64);
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    final iv = encrypt.IV.fromSecureRandom(16);

    final sink = outputFile.openWrite();
    sink.add(iv.bytes);
    final inputStream = file.openRead();
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    final buffer = <int>[];
    await for (final chunk in inputStream) {
      buffer.addAll(chunk);

      while (buffer.length >= _chunkSize) {
        final chunkData = Uint8List.fromList(buffer.sublist(0, _chunkSize));
        buffer.removeRange(0, _chunkSize);

        final encrypted = encrypter.encryptBytes(chunkData, iv: iv);
        final sizeBytes = ByteData(4)..setInt32(0, encrypted.bytes.length);
        sink.add(sizeBytes.buffer.asUint8List());
        sink.add(encrypted.bytes);
      }
    }
    if (buffer.isNotEmpty) {
      final encrypted = encrypter.encryptBytes(
        Uint8List.fromList(buffer),
        iv: iv,
      );
      final sizeBytes = ByteData(4)..setInt32(0, encrypted.bytes.length);
      sink.add(sizeBytes.buffer.asUint8List());
      sink.add(encrypted.bytes);
    }

    await sink.flush();
    await sink.close();

    return outputPath;
  }

  Future<String> decryptToTemp(String encryptedPath, String keyBase64) async {
    final encFile = File(encryptedPath);
    if (!await encFile.exists()) {
      throw FileSystemException('Encrypted file not found', encryptedPath);
    }

    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/dec_${DateTime.now().millisecondsSinceEpoch}';
    final outputFile = File(outputPath);

    final keyBytes = base64Decode(keyBase64);
    final key = encrypt.Key(Uint8List.fromList(keyBytes));

    final bytes = await encFile.readAsBytes();
    final iv = encrypt.IV(Uint8List.fromList(bytes.sublist(0, 16)));
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    final sink = outputFile.openWrite();
    int offset = 16;

    while (offset < bytes.length) {
      final sizeData = ByteData.sublistView(
        Uint8List.fromList(bytes.sublist(offset, offset + 4)),
      );
      final chunkSize = sizeData.getInt32(0);
      offset += 4;
      final encChunk = bytes.sublist(offset, offset + chunkSize);
      offset += chunkSize;

      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(Uint8List.fromList(encChunk)),
        iv: iv,
      );
      sink.add(decrypted);
    }

    await sink.flush();
    await sink.close();

    return outputPath;
  }

  Future<void> cleanupTempFiles() async {
    final tempDir = await getTemporaryDirectory();
    final files = tempDir.listSync().whereType<File>();
    for (final file in files) {
      if (file.path.contains('dec_')) {
        await file.delete();
      }
    }
  }
}
