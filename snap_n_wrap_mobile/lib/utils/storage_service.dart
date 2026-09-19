import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _cartKey = 'cart_state';
  static const String _editorKey = 'editor_state';

  static Future<void> saveCartState(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonStr);
  }

  static Future<String?> loadCartState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cartKey);
  }

  static Future<void> saveEditorState(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_editorKey, jsonStr);
  }

  static Future<String?> loadEditorState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_editorKey);
  }
}
