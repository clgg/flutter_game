import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameFeedbackSettingsController extends ChangeNotifier {
  GameFeedbackSettingsController() {
    unawaited(_restore());
  }

  static const _soundVolumeKey = 'game_feedback.sound_volume';
  static const _vibrationIntensityKey = 'game_feedback.vibration_intensity';

  double _soundVolume = 1;
  double _vibrationIntensity = 1;

  double get soundVolume => _soundVolume;
  double get vibrationIntensity => _vibrationIntensity;

  Future<void> loadSavedSettings() => _restore();

  Future<void> saveSettings() => _save();

  void setSoundVolume(double value) {
    final nextValue = value.clamp(0, 1).toDouble();
    if (_soundVolume == nextValue) {
      return;
    }
    _soundVolume = nextValue;
    notifyListeners();
    unawaited(_save());
  }

  void setVibrationIntensity(double value) {
    final nextValue = value.clamp(0, 1).toDouble();
    if (_vibrationIntensity == nextValue) {
      return;
    }
    _vibrationIntensity = nextValue;
    notifyListeners();
    unawaited(_save());
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final soundVolume = prefs.getDouble(_soundVolumeKey);
    final vibrationIntensity = prefs.getDouble(_vibrationIntensityKey);
    var changed = false;
    if (soundVolume != null) {
      _soundVolume = soundVolume.clamp(0, 1).toDouble();
      changed = true;
    }
    if (vibrationIntensity != null) {
      _vibrationIntensity = vibrationIntensity.clamp(0, 1).toDouble();
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_soundVolumeKey, _soundVolume);
    await prefs.setDouble(_vibrationIntensityKey, _vibrationIntensity);
  }
}
