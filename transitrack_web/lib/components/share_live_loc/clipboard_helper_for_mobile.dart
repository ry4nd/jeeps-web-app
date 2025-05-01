import 'clipboard_helper.dart';
import 'package:flutter/services.dart';

class ClipboardHelperImpl extends ClipboardHelperBase {
  @override
  Future<String?> readTextFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text;
    return text;
  }

  @override
  Future<bool> copyTextToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      print('Error copying to clipboard: $e');
      return false;
    }
  }
}
