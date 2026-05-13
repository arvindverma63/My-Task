import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _compactModeKey = 'compact_mode';
  static const String _showDescriptionsKey = 'show_descriptions';
  static const String _showTimestampsKey = 'show_timestamps';
  static const String _groupCompletedAtBottomKey = 'group_completed_at_bottom';
  static const String _hasSeenTipsKey = 'has_seen_tips';
  static const String _allowTextFieldsKey = 'allow_text_fields';
  static const String _allowImageFieldsKey = 'allow_image_fields';
  static const String _allowVideoFieldsKey = 'allow_video_fields';
  static const String _allowNumberFieldsKey = 'allow_number_fields';
  static const String _importantRemindersKey = 'important_reminders';

  ThemeMode _themeMode = ThemeMode.light;
  bool _compactMode = false;
  bool _showDescriptions = true;
  bool _showTimestamps = true;
  bool _groupCompletedAtBottom = true;
  bool _hasSeenTips = false;
  bool _isLoaded = false;
  bool _allowTextFields = true;
  bool _allowImageFields = true;
  bool _allowVideoFields = false;
  bool _allowNumberFields = true;
  bool _importantReminders = false;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;
  bool get compactMode => _compactMode;
  bool get showDescriptions => _showDescriptions;
  bool get showTimestamps => _showTimestamps;
  bool get groupCompletedAtBottom => _groupCompletedAtBottom;
  bool get hasSeenTips => _hasSeenTips;
  bool get isLoaded => _isLoaded;
  bool get allowTextFields => _allowTextFields;
  bool get allowImageFields => _allowImageFields;
  bool get allowVideoFields => _allowVideoFields;
  bool get allowNumberFields => _allowNumberFields;
  bool get importantReminders => _importantReminders;

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _themeModeFromString(prefs.getString(_themeModeKey));
    _compactMode = prefs.getBool(_compactModeKey) ?? false;
    _showDescriptions = prefs.getBool(_showDescriptionsKey) ?? true;
    _showTimestamps = prefs.getBool(_showTimestampsKey) ?? true;
    _groupCompletedAtBottom = prefs.getBool(_groupCompletedAtBottomKey) ?? true;
    _hasSeenTips = prefs.getBool(_hasSeenTipsKey) ?? false;
    _allowTextFields = prefs.getBool(_allowTextFieldsKey) ?? true;
    _allowImageFields = prefs.getBool(_allowImageFieldsKey) ?? true;
    _allowVideoFields = prefs.getBool(_allowVideoFieldsKey) ?? false;
    _allowNumberFields = prefs.getBool(_allowNumberFieldsKey) ?? true;
    _importantReminders = prefs.getBool(_importantRemindersKey) ?? false;
    await TodoNotificationService.instance.setImportantRemindersEnabled(_importantReminders);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setCompactMode(bool value) async {
    _compactMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactModeKey, value);
  }

  Future<void> setShowDescriptions(bool value) async {
    _showDescriptions = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showDescriptionsKey, value);
  }

  Future<void> setShowTimestamps(bool value) async {
    _showTimestamps = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTimestampsKey, value);
  }

  Future<void> setGroupCompletedAtBottom(bool value) async {
    _groupCompletedAtBottom = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_groupCompletedAtBottomKey, value);
  }

  Future<void> markTipsSeen() async {
    _hasSeenTips = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenTipsKey, true);
  }

  Future<void> resetTips() async {
    _hasSeenTips = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenTipsKey, false);
  }

  Future<void> setAllowTextFields(bool value) async {
    _allowTextFields = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_allowTextFieldsKey, value);
  }

  Future<void> setAllowImageFields(bool value) async {
    _allowImageFields = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_allowImageFieldsKey, value);
  }

  Future<void> setAllowVideoFields(bool value) async {
    _allowVideoFields = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_allowVideoFieldsKey, value);
  }

  Future<void> setAllowNumberFields(bool value) async {
    _allowNumberFields = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_allowNumberFieldsKey, value);
  }

  Future<void> setImportantReminders(bool value) async {
    _importantReminders = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_importantRemindersKey, value);
    await TodoNotificationService.instance.setImportantRemindersEnabled(value);
  }

  ThemeMode _themeModeFromString(String? storedMode) {
    if (storedMode == null) {
      return ThemeMode.light;
    }

    return ThemeMode.values.firstWhere(
      (mode) => mode.name == storedMode,
      orElse: () => ThemeMode.light,
    );
  }
}
