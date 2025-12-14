// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:convert';

void downloadTextFile({required String filename, required String content, required String mimeType}) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}


