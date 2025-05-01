import 'clipboard_helper.dart';

class ClipboardHelperImpl extends ClipboardHelperBase {
  @override
  Future<String?> readTextFromClipboard() async {
    throw Exception("Stub implementation");
  }

  @override
  Future<bool> copyTextToClipboard(String text) async {
    throw Exception("Stub implementation");
  }
}
