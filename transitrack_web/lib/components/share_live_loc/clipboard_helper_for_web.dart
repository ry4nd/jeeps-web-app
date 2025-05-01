import 'package:js/js.dart';
import 'clipboard_helper.dart';
import 'package:js/js_util.dart';
import 'dart:async';

@JS('pasteFromClipboard')
external dynamic pasteFromClipboard();

@JS('copyToClipboard')
external dynamic copyToClipboard(String text);

class ClipboardHelperImpl extends ClipboardHelperBase {
  @override
  Future<String?> readTextFromClipboard() async {
    try {
      // Check if we're in a secure context where clipboard API is available
      final String? text = await promiseToFuture(
        pasteFromClipboard(),
      );
      return text;
    } catch (e) {
      print('Error reading from clipboard: $e');
      return null;
    }
  }

  @override
  Future<bool> copyTextToClipboard(String text) async {
    try {
      await promiseToFuture(
        copyToClipboard(text),
      );
      return true;
    } catch (e) {
      print('Error copying to clipboard: $e');
      return false;
    }
  }
}
