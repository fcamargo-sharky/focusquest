// Native implementation — uses Windows Beep() via dart:ffi on Windows,
// no-op on all other non-web platforms (macOS, Linux, Android, iOS).
import 'dart:ffi';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

typedef _BeepFn = Int32 Function(Uint32 dwFreq, Uint32 dwDuration);

// Runs inside a background isolate so the UI thread is never blocked.
void _beepSequence(List<List<int>> notes) {
  final lib = DynamicLibrary.open('kernel32.dll');
  final beep = lib.lookupFunction<_BeepFn, int Function(int, int)>('Beep');
  for (final note in notes) {
    beep(note[0], note[1]);
  }
}

class SoundService {
  SoundService._();

  static Future<void> _play(List<List<int>> notes) async {
    if (defaultTargetPlatform != TargetPlatform.windows) return;
    try {
      // Capture notes in a sendable closure and run in separate isolate.
      await Isolate.run(() => _beepSequence(notes));
    } catch (_) {}
  }

  /// C5 → G5  — task completed
  static void playTaskComplete() =>
      _play([[523, 80], [784, 130]]);

  /// C5 → E5 → G5  — Pomodoro work session done
  static void playPomodoroComplete() =>
      _play([[523, 120], [659, 120], [784, 200]]);

  /// A4  — break finished
  static void playBreakComplete() =>
      _play([[440, 200]]);

  /// A5  — routine marked complete
  static void playRoutineComplete() =>
      _play([[880, 100]]);
}
