import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// معالِج صوت «إذاعة القرآن» لـ audio_service: يجسر مشغّلَ البثّ إلى جلسة
/// الوسائط (إشعار + شاشة القفل) فيستمرّ التشغيل في الخلفية ويظهر بإشعارٍ فيه:
/// تشغيل/إيقاف، التنقّل بين السور (سابق/تالٍ)، شريط تمرير للتقديم/الإرجاع،
/// وزرّ «العودة لبداية البثّ» (الفاتحة).
///
/// مقتصر على الإذاعة وحدها؛ بقية مشغّلات التطبيق (السور/الختمة/المؤثّرات/
/// التسجيلات) تبقى مشغّلات just_audio عادية لا تتأثّر بهذا المعالِج.
class RadioAudioHandler extends BaseAudioHandler with SeekHandler {
  AudioPlayer? _player;

  /// اسم الإجراء المخصّص لإعادة البثّ من سورة الفاتحة.
  static const String restartBroadcastAction = 'radio.restartBroadcast';

  /// يربط مشغّل البثّ مرّةً واحدة، ثم يبثّ حالته باستمرار إلى جلسة الوسائط.
  void attachPlayer(AudioPlayer player) {
    if (_player != null) return;
    _player = player;
    player.playbackEventStream.listen(
      (_) => _broadcastState(),
      onError: (_) => _broadcastState(),
    );
    player.currentIndexStream.listen((_) => _broadcastState());
  }

  /// يضبط العنصر الجاري عرضه في الإشعار (السورة + القارئ).
  void setNowPlaying({
    required String id,
    required String title,
    required String artist,
    Duration? duration,
  }) {
    mediaItem.add(
      MediaItem(id: id, title: title, artist: artist, duration: duration),
    );
  }

  /// يحدّث مدّة العنصر الحالي عند توفّرها (لإظهار شريط التمرير).
  void updateDuration(Duration? duration) {
    final current = mediaItem.value;
    if (current != null && duration != null && current.duration != duration) {
      mediaItem.add(current.copyWith(duration: duration));
    }
  }

  /// يمسح الإشعار وحالة الجلسة عند إيقاف الإذاعة كلّياً.
  void clearNotification() {
    mediaItem.add(null);
    playbackState.add(PlaybackState());
  }

  void _broadcastState() {
    final player = _player;
    if (player == null) return;
    final playing = player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.custom(
            androidIcon: 'drawable/ic_radio_restart',
            label: 'Restart',
            name: restartBroadcastAction,
          ),
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        // الأزرار المختصرة (في الإشعار المطويّ): سابق، تشغيل/إيقاف، تالٍ.
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessingState(player.processingState),
        playing: playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
        queueIndex: player.currentIndex,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() async => _player?.play();

  @override
  Future<void> pause() async => _player?.pause();

  @override
  Future<void> seek(Duration position) async => _player?.seek(position);

  @override
  Future<void> stop() async {
    await _player?.stop();
    clearNotification();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async => _player?.seekToNext();

  /// «العودة للبداية»: إن مضى أكثر من 3 ثوانٍ يُعيد السورة الحالية لأوّلها،
  /// وإلا ينتقل للسورة السابقة (السلوك المعتاد لزرّ «السابق»).
  @override
  Future<void> skipToPrevious() async {
    final player = _player;
    if (player == null) return;
    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
    } else {
      await player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async =>
      _player?.seek(Duration.zero, index: index);

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == restartBroadcastAction) {
      await _player?.seek(Duration.zero, index: 0);
    }
  }
}
