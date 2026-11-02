import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// The hand's sounds: a soft paper tick as each card passes the selected
/// slot, and a slide-and-land when a card is drawn, each with a light haptic.
abstract class CardSounds {
  void tick();

  void draw();
}

/// Used in tests and anywhere sound isn't wanted.
class SilentCardSounds implements CardSounds {
  const SilentCardSounds();

  @override
  void tick() {}

  @override
  void draw() {}
}

class AudioCardSounds implements CardSounds {
  /// Fast spins pass many cards a second; closer ticks than this blur into noise.
  static const Duration _minTickGap = Duration(milliseconds: 45);

  // Plays alongside the user's music (no audio focus taken) and follows the
  // silent switch on iOS. On Android it plays as a game sound, on the media
  // volume the volume keys control; respectSilence alone would put it on the
  // ringtone volume.
  static final AudioContext _context = () {
    final base = AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: true).build();
    return base.copy(android: base.android.copy(usageType: AndroidUsageType.game, contentType: AndroidContentType.sonification));
  }();

  // A few players per sound, loaded up front and used in turn. AudioPool was
  // late on fast spins: low-latency players never report finishing, so it
  // loaded a fresh player for most ticks.
  Future<List<AudioPlayer>>? _ticks;
  Future<List<AudioPlayer>>? _draws;
  int _nextTick = 0;
  int _nextDraw = 0;
  DateTime _lastTick = DateTime.fromMillisecondsSinceEpoch(0);

  Future<List<AudioPlayer>> _load(String asset, int count, double volume) async {
    final players = <AudioPlayer>[];
    try {
      for (var i = 0; i < count; i++) {
        final player = AudioPlayer();
        await player.setAudioContext(_context);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(volume);
        await player.setSource(AssetSource(asset));
        players.add(player);
      }
    } catch (_) {
      // Fewer players, or none: no sound, the app works the same.
    }
    return players;
  }

  /// Loads the sounds ahead of the first tick.
  void warmUp() {
    _ticks ??= _load('sounds/card_tick.wav', 3, 0.55);
    _draws ??= _load('sounds/card_draw.wav', 2, 0.7);
  }

  @override
  void tick() {
    final now = DateTime.now();
    if (now.difference(_lastTick) < _minTickGap) return;
    _lastTick = now;
    HapticFeedback.selectionClick();
    _play(_ticks ??= _load('sounds/card_tick.wav', 3, 0.55), _nextTick++);
  }

  @override
  void draw() {
    HapticFeedback.lightImpact();
    _play(_draws ??= _load('sounds/card_draw.wav', 2, 0.7), _nextDraw++);
  }

  Future<void> _play(Future<List<AudioPlayer>> loading, int turn) async {
    final players = await loading;
    if (players.isEmpty) return;
    final player = players[turn % players.length];
    try {
      // Low-latency players never report finishing, so each one is still
      // "playing" until stopped. The stop must land before the resume:
      // audioplayers drops a stop that a resume overtakes.
      await player.stop();
      await player.resume();
    } catch (_) {}
  }
}
