import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class FileSaver {
  FileSaver._();

  /// يفتح نافذة اختيار مكان الحفظ.
  /// يرجع true عند الحفظ، و false إذا ألغى المستخدم.
  static Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    String? dialogTitle,
  }) async {
    final Object? result = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: bytes,
    );

    if (result == null) return false;

    // على الهاتف تكتب الحزمة الملف بنفسها. على سطح المكتب
    // نكتبه يدوياً لأن بعض الأنظمة ترجع المسار فقط.
    if (!Platform.isAndroid && !Platform.isIOS) {
      final path = result is Uri ? result.toFilePath() : result.toString();

      await File(path).writeAsBytes(bytes);
    }

    return true;
  }

  static Future<bool> saveText({
    required String fileName,
    required String content,
    String? dialogTitle,
  }) {
    return save(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(content)),
      dialogTitle: dialogTitle,
    );
  }

  /// يختار ملف JSON ويرجع نصه، أو null عند الإلغاء.
  static Future<String?> pickJsonText() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (file == null) return null;

    return utf8.decode(await file.readAsBytes());
  }

  /// 2026-11-27
  static String dateStamp([DateTime? date]) {
    final d = date ?? DateTime.now();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');

    return '${d.year}-$month-$day';
  }
}
