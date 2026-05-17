import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_game/app/settings/game_feedback_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('feedback settings are clamped and persisted', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = GameFeedbackSettingsController();
    controller
      ..setSoundVolume(1.4)
      ..setVibrationIntensity(-0.2);
    await controller.saveSettings();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('game_feedback.sound_volume'), 1);
    expect(prefs.getDouble('game_feedback.vibration_intensity'), 0);

    final restored = GameFeedbackSettingsController();
    await restored.loadSavedSettings();

    expect(restored.soundVolume, 1);
    expect(restored.vibrationIntensity, 0);
  });
}
