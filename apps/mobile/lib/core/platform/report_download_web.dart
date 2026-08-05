// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> saveReport(List<int> bytes, String filename, String mime) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
