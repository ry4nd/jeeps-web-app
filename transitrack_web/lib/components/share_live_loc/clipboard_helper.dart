import 'clipboard_helper_stub.dart'
    if (dart.library.io) 'clipboard_helper_for_mobile.dart'
    if (dart.library.html) 'clipboard_helper_for_web.dart';

class ClipboardHelper {
  final ClipboardHelperImpl _helper;

  ClipboardHelper() : _helper = ClipboardHelperImpl();

  Future<String?> readTextFromClipboard() async {
    return _helper.readTextFromClipboard();
  }

  Future<bool> copyTextToClipboard(String text) async {
    return _helper.copyTextToClipboard(text);
  }
}

abstract class ClipboardHelperBase {
  Future<String?> readTextFromClipboard();
  Future<bool> copyTextToClipboard(String text);
}
