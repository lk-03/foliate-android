import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/services/epub_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Epub duplicate detection by SHA-256 hash', () async {
    final sampleFile = File('assets/dummy.epub');
    expect(sampleFile.existsSync(), isTrue);

    final tempDir = Directory.systemTemp.createTempSync('folder_sync_test_');
    final coversDir = Directory('${tempDir.path}/covers');

    try {
      final bytes = sampleFile.readAsBytesSync();
      final hash1 = EpubService.computeHash(bytes);

      final book1 = await EpubService.parseEpubBytes(
        bytes: bytes,
        sourceFilePath: sampleFile.path,
        coversDir: coversDir,
      );

      expect(book1.hash, equals(hash1));

      // Create a copy with a completely different file name in another folder
      final renamedCopy = File('${tempDir.path}/renamed_book.epub');
      renamedCopy.writeAsBytesSync(bytes);

      final hash2 = EpubService.computeHash(renamedCopy.readAsBytesSync());
      // Renamed file MUST have identical hash
      expect(hash2, equals(hash1));

      final book2 = await EpubService.parseEpubFile(renamedCopy, coversDir: coversDir);
      expect(book2.hash, equals(book1.hash));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
