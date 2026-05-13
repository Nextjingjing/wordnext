import 'dart:io' show Platform;
import 'package:flutter_tts/flutter_tts.dart';

Future<void> configureTtsForPlatform(FlutterTts tts) async {
  if (Platform.isIOS) {
    await tts.setSharedInstance(true);
    await tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
      IosTextToSpeechAudioMode.defaultMode,
    );
  }
}
