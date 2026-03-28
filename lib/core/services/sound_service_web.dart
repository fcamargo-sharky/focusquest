import 'dart:js_interop';

import 'package:flutter/foundation.dart';

// ── Web Audio API bindings (dart:js_interop) ────────────────────────────────

@JS('AudioContext')
extension type _AudioCtx._(JSObject _) implements JSObject {
  external factory _AudioCtx();
  external double get currentTime;
  external JSObject get destination;
  external _OscillatorNode createOscillator();
  external _GainNode createGain();
}

extension type _AudioParam._(JSObject _) implements JSObject {
  external void setValueAtTime(double value, double startTime);
  external void exponentialRampToValueAtTime(double value, double endTime);
}

extension type _OscillatorNode._(JSObject _) implements JSObject {
  external set type(String type);
  external _AudioParam get frequency;
  external void connect(JSObject destination);
  external void start(double when);
  external void stop(double when);
}

extension type _GainNode._(JSObject _) implements JSObject {
  external _AudioParam get gain;
  external void connect(JSObject destination);
}

// ── SoundService ─────────────────────────────────────────────────────────────

class SoundService {
  SoundService._();

  static _AudioCtx? _context;
  static _AudioCtx get _ctx => _context ??= _AudioCtx();

  /// Synthesise a single sine tone.
  static void _tone({
    required double frequency,
    required double delay,   // seconds from now
    required double duration,
    required double gain,
  }) {
    if (!kIsWeb) return;
    try {
      final ctx = _ctx;
      final osc = ctx.createOscillator();
      final g = ctx.createGain();
      final t = ctx.currentTime + delay;

      osc.type = 'sine';
      osc.frequency.setValueAtTime(frequency, t);

      g.gain.setValueAtTime(gain, t);
      g.gain.exponentialRampToValueAtTime(0.001, t + duration);

      osc.connect(g as JSObject);
      g.connect(ctx.destination);

      osc.start(t);
      osc.stop(t + duration + 0.05);
    } catch (_) {}
  }

  // ── Public sounds ───────────────────────────────────────────────────────

  /// Quick ascending two-note chime — task completed.
  /// C5 → G5
  static void playTaskComplete() {
    if (!kIsWeb) return;
    _tone(frequency: 523.25, delay: 0.00, duration: 0.18, gain: 0.22); // C5
    _tone(frequency: 783.99, delay: 0.14, duration: 0.28, gain: 0.18); // G5
  }

  /// Three ascending bell tones — Pomodoro work session done.
  /// C5 → E5 → G5
  static void playPomodoroComplete() {
    if (!kIsWeb) return;
    _tone(frequency: 523.25, delay: 0.00, duration: 0.45, gain: 0.20); // C5
    _tone(frequency: 659.25, delay: 0.24, duration: 0.45, gain: 0.18); // E5
    _tone(frequency: 783.99, delay: 0.48, duration: 0.55, gain: 0.16); // G5
  }

  /// Single soft tone — break finished, back to work.
  /// A4
  static void playBreakComplete() {
    if (!kIsWeb) return;
    _tone(frequency: 440.0, delay: 0.00, duration: 0.35, gain: 0.15); // A4
  }

  /// Soft single high chime — routine marked done.
  /// A5
  static void playRoutineComplete() {
    if (!kIsWeb) return;
    _tone(frequency: 880.0, delay: 0.00, duration: 0.20, gain: 0.13); // A5
  }
}
