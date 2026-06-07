import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kDeveloperModeKey = 'developer_mode_enabled';
const _storage = FlutterSecureStorage();

class DeveloperModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _init();
    return false;
  }

  Future<void> _init() async {
    final value = await _storage.read(key: _kDeveloperModeKey);
    state = value == 'true';
  }

  Future<void> toggle() async {
    final newValue = !state;
    await _storage.write(key: _kDeveloperModeKey, value: newValue.toString());
    state = newValue;
  }
}

final developerModeProvider = NotifierProvider<DeveloperModeNotifier, bool>(() {
  return DeveloperModeNotifier();
});
