import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/services/epub_service.dart';

void main() {
  test('EpubService parses bundled dummy.epub correctly', () async {
    final file = File('assets/dummy.epub');
    expect(file.existsSync(), isTrue);

    final tempDir = Directory.systemTemp.createTempSync('epub_test_');
    try {
      final book = await EpubService.parseEpubFile(file, coversDir: tempDir);

      expect(book.hash, isNotEmpty);
      expect(book.hash.length, 64); // SHA-256 is 64 hex chars
      expect(book.title, isNotEmpty);
      expect(book.author, isNotEmpty);
      expect(book.fileSize, file.lengthSync());
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('EpubService computeHash returns deterministic SHA-256', () {
    final bytes1 = [1, 2, 3, 4, 5];
    final hash1 = EpubService.computeHash(Uint8List.fromList(bytes1));
    final hash2 = EpubService.computeHash(Uint8List.fromList(bytes1));
    expect(hash1, equals(hash2));
    expect(hash1.length, 64);
  });
}
