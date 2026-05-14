import 'dart:convert';
import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

class PdfUtils {
  static Future<String?> generatePdfCoverBase64(Uint8List pdfBytes) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openData(pdfBytes);
      final page = await document.getPage(1);
      try {
        final pageImage = await page.render(
          width: page.width,
          height: page.height,
          format: PdfPageImageFormat.png,
        );
        if (pageImage == null) return null;
        return base64Encode(pageImage.bytes);
      } finally {
        await page.close();
      }
    } catch (_) {
      return null;
    } finally {
      await document?.close();
    }
  }
}
