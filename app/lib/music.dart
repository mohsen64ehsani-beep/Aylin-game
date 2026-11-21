import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Original, locally synthesized bakery theme. No network or bundled copyrighted music.
class BakeryMusic {
  BakeryMusic._();
  static final BakeryMusic instance = BakeryMusic._();
  final AudioPlayer _player = AudioPlayer();
  bool enabled = true;

  Future<void> start() async {
    if (!enabled) return;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.24);
      await _player.play(BytesSource(_makeTheme()));
    } catch (_) {
      // Gameplay remains available if an audio device/plugin is unavailable.
    }
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    if (value) {
      await start();
    } else {
      await _player.pause();
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  Uint8List _makeTheme() {
    const rate = 22050;
    const seconds = 8;
    final samples = rate * seconds;
    final pcm = BytesBuilder();
    final notes = <int>[523, 659, 784, 659, 587, 698, 880, 698,
      523, 659, 784, 988, 880, 784, 659, 587];
    for (var i = 0; i < samples; i++) {
      final t = i / rate;
      final beat = (t * 2).floor() % notes.length;
      final local = (t * 2) % 1;
      final freq = notes[beat];
      final envelope = math.min(1.0, local * 12) *
          math.min(1.0, (1 - local) * 5) * 0.19;
      final fundamental = math.sin(2 * math.pi * freq * t);
      final harmonic = math.sin(4 * math.pi * freq * t) * 0.22;
      final bass = math.sin(2 * math.pi * (freq / 2) * t) * 0.16;
      final value = ((fundamental + harmonic + bass) * envelope * 15000)
          .round().clamp(-32768, 32767);
      final b = ByteData(2)..setInt16(0, value, Endian.little);
      pcm.add(b.buffer.asUint8List());
    }
    final data = pcm.toBytes();
    final header = ByteData(44);
    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        header.setUint8(offset + i, value.codeUnitAt(i));
      }
    }
    ascii(0, 'RIFF');
    header.setUint32(4, 36 + data.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, rate, Endian.little);
    header.setUint32(28, rate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    header.setUint32(40, data.length, Endian.little);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...data]);
  }
}
