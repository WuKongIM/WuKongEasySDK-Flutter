import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart';
import 'stream_http.dart';
import 'stream_timeline.dart';
export 'stream_timeline.dart';

class _Session {
  final String id = const Uuid().v4().substring(0, 8),
      token = const Uuid().v4();
  late final reader = 'flutter-reader-$id',
      writer = 'flutter-writer-$id',
      channel = 'flutter-stream-$id';
}

class _Run {
  final key = const Uuid().v4();
  String text = '', stop = '';
  int index = 0;
  StreamModel? model;
}

/// Screen-scoped owner of two independent peers, recovery and one producer.
class StreamController extends ChangeNotifier {
  StreamTimeline? timeline;
  bool connecting = false,
      restoring = false,
      sending = false,
      generating = false;
  bool readerOnline = false,
      writerOnline = false,
      _recoveryFailed = false,
      _disposed = false;
  String error = '', generator = '就绪';
  final logs = <String>[];
  _Session? _session;
  StreamAPI? _api;
  WuKongEasySDK? _reader, _writer;
  _Run? _run;
  int _epoch = 0, _lifecycle = 0;
  final _buffered = <EventNotification>[];
  bool get busy => connecting || restoring || sending;
  bool get canSend =>
      readerOnline && writerOnline && !busy && !generating && !_recoveryFailed;
  String get status => connecting
      ? '连接中'
      : restoring
      ? '恢复历史中'
      : _recoveryFailed
      ? '历史恢复失败，请重连'
      : readerOnline && writerOnline
      ? '在线'
      : writerOnline
      ? '接收端离线'
      : _session == null
      ? '未连接'
      : '离线';
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _log(String text) {
    if (logs.length == 100) logs.removeAt(0);
    logs.add(text);
    _emit();
  }

  bool _current(int stamp) => !_disposed && stamp == _lifecycle;
  Future<void> connect(String base) async {
    if (busy || generating || _disposed) return;
    final stamp = _lifecycle;
    connecting = true;
    error = '';
    _emit();
    try {
      if (_session == null) {
        _api?.close();
        final api = StreamAPI(base);
        _api = api;
        final session = _Session();
        for (final uid in [session.reader, session.writer]) {
          await api.post('/user/token', {
            'uid': uid,
            'token': session.token,
            'device_flag': 0,
            'device_level': 0,
          });
          if (!_current(stamp)) return;
        }
        await api.post('/channel', {
          'channel_id': session.channel,
          'channel_type': 2,
          'subscribers': [session.reader, session.writer],
        });
        if (!_current(stamp)) return;
        _session = session;
        timeline = StreamTimeline(session.channel);
        _log('HTTP 演示账号及群频道已创建');
      }
      await _connectPeers(stamp);
    } catch (_) {
      if (_current(stamp)) {
        _closePeers();
        error = '连接失败，请检查 API、设备可达的 WebSocket 地址和演示写入权限。';
      }
    } finally {
      if (_current(stamp)) {
        connecting = false;
        _emit();
      }
    }
  }

  Future<void> _connectPeers(int stamp) async {
    final session = _session!, api = _api!;
    if (_reader?.isConnected != true) {
      _reader?.dispose();
      final address = await api.route(session.reader);
      if (!_current(stamp)) return;
      final peer = await _makePeer(
        address,
        session.reader,
        session.token,
        true,
      );
      _reader = peer;
      await peer.connect();
    }
    if (!_current(stamp)) return;
    if (_writer?.isConnected != true) {
      _writer?.dispose();
      final address = await api.route(session.writer);
      if (!_current(stamp)) return;
      final peer = await _makePeer(
        address,
        session.writer,
        session.token,
        false,
      );
      _writer = peer;
      await peer.connect();
    }
  }

  Future<WuKongEasySDK> _makePeer(
    String address,
    String uid,
    String token,
    bool receiving,
  ) async {
    final peer = WuKongEasySDK.createInstance();
    await peer.init(
      WuKongConfig(
        serverUrl: address,
        uid: uid,
        token: token,
        debugLogging: false,
      ),
    );
    bool current() =>
        !_disposed && identical(receiving ? _reader : _writer, peer);
    peer.addEventListener<ConnectResult>(WuKongEvent.connect, (_) {
      if (!current()) return;
      if (receiving) {
        readerOnline = true;
        unawaited(_recover());
      } else {
        writerOnline = true;
      }
      _log(receiving ? 'SDK 接收端已连接' : 'SDK 生成端已连接');
    });
    peer.addEventListener<DisconnectInfo>(WuKongEvent.disconnect, (_) {
      if (!current()) return;
      if (receiving) {
        readerOnline = false;
        _cancelRecovery();
      } else {
        writerOnline = false;
      }
      _log('SDK 连接已断开');
    });
    peer.addEventListener<WuKongError>(WuKongEvent.error, (_) {
      if (current()) {
        error = 'SDK 连接或协议异常，请检查网络后重试。';
        _log('SDK 错误');
      }
    });
    if (receiving) {
      peer.addEventListener<Message>(WuKongEvent.message, (message) {
        if (current()) {
          timeline?.receive(message);
          _emit();
        }
      });
      peer.addEventListener<EventNotification>(WuKongEvent.customEvent, (
        event,
      ) {
        if (!current()) return;
        if (restoring) {
          if (_buffered.length < 2048) {
            _buffered.add(event);
          } else {
            _recoveryFailed = true;
            error = '恢复期间事件过多，请重连接收端。';
          }
        } else {
          timeline?.apply(event);
        }
        _log('SDK ← 流事件');
      });
    }
    return peer;
  }

  /// One bounded full-history read per authenticated reader connection.
  Future<void> _recover() async {
    _cancelRecovery();
    final stamp = _epoch;
    restoring = true;
    _recoveryFailed = false;
    _emit();
    try {
      final session = _session!;
      final history = await _api!.post('/channel/messagesync', {
        'login_uid': session.reader,
        'channel_id': session.channel,
        'channel_type': 2,
        'limit': 40,
        'event_summary_mode': 'full',
      });
      if (stamp != _epoch || _disposed) return;
      timeline?.restore(history);
      for (final event in _buffered) {
        timeline?.apply(event);
      }
      _buffered.clear();
      _log('HTTP 历史快照已恢复');
    } catch (_) {
      if (stamp == _epoch && !_disposed) {
        _recoveryFailed = true;
        error = '历史恢复失败，请重连接收端。';
      }
    } finally {
      if (stamp == _epoch && !_disposed) {
        restoring = false;
        _emit();
      }
    }
  }

  void _cancelRecovery() {
    _epoch++;
    restoring = false;
    _buffered.clear();
  }

  Future<void> toggleReceiver() async {
    if (busy || _session == null || _disposed) return;
    if (readerOnline) {
      _reader?.disconnect();
      readerOnline = false;
      _cancelRecovery();
      _emit();
    } else {
      final stamp = _lifecycle;
      connecting = true;
      error = '';
      _emit();
      try {
        await _connectPeers(stamp);
      } catch (_) {
        if (_current(stamp)) {
          _reader?.disconnect();
          readerOnline = false;
          error = '重连失败，请检查网络后重试。';
        }
      } finally {
        if (_current(stamp)) {
          connecting = false;
          _emit();
        }
      }
    }
  }

  Future<void> send(
    String question, {
    String reply = '',
    int chunk = 2,
    int interval = 80,
    ModelConfig? model,
  }) async {
    if (!canSend || question.trim().isEmpty) return;
    final stamp = _lifecycle, session = _session!;
    sending = true;
    error = '';
    _emit();
    try {
      final key = const Uuid().v4(),
          payload = {'type': 1, 'content': boundedText(question, 4000)};
      final ack = await _reader!.send(
        channelId: session.channel,
        channelType: WuKongChannelType.group,
        payload: payload,
        options: SendOptions(clientMsgNo: key),
      );
      if (!_current(stamp)) return;
      if (ack.reasonCode.value != 1) throw const StreamFailure();
      timeline?.receive(
        Message(
          header: const MessageHeader(),
          messageId: ack.messageId,
          messageSeq: ack.messageSeq,
          timestamp: 0,
          channelId: session.channel,
          channelType: WuKongChannelType.group,
          fromUid: session.reader,
          payload: payload,
          clientMsgNo: key,
        ),
      );
      _log('SDK 问题已发送');
      generate(reply: reply, chunk: chunk, interval: interval, model: model);
    } catch (_) {
      if (_current(stamp)) error = '发送结果未确认；请重连查看历史后再决定是否重发。';
    } finally {
      if (_current(stamp)) {
        sending = false;
        _emit();
      }
    }
  }

  void generate({
    String reply = '',
    int chunk = 2,
    int interval = 80,
    ModelConfig? model,
  }) {
    if (!writerOnline || generating || _disposed) return;
    final run = _Run();
    _run = run;
    generating = true;
    generator = '生成中';
    error = '';
    _emit();
    unawaited(
      _produce(run, reply, chunk.clamp(1, 64), interval.clamp(40, 2000), model),
    );
  }

  Future<void> _produce(
    _Run run,
    String reply,
    int chunk,
    int interval,
    ModelConfig? model,
  ) async {
    try {
      final session = _session!;
      final parent = await _writer!.send(
        channelId: session.channel,
        channelType: WuKongChannelType.group,
        payload: {'type': 1, 'content': ''},
        options: SendOptions(
          clientMsgNo: run.key,
          setting: const MessageSetting(stream: true),
        ),
      );
      if (parent.reasonCode.value != 1) throw const _EventWrite();
      await _append(run, 'stream.open', {'kind': 'text'});
      if (model != null) {
        final source = StreamModel();
        run.model = source;
        try {
          if (run.stop.isEmpty) {
            await source.consume(model, timeline?.context() ?? [], (
              delta,
            ) async {
              if (run.stop.isEmpty) {
                await _append(run, 'stream.delta', {
                  'kind': 'text',
                  'delta': delta,
                });
                run.text += delta;
              }
            });
          }
        } on _EventWrite {
          rethrow;
        } catch (_) {
          if (_disposed) return;
          if (run.stop.isEmpty) {
            run.stop = 'error';
            error = '模型请求失败或流意外中断，已保存确认的部分内容。';
          }
        }
      } else {
        final chars = boundedText(
          reply.isEmpty ? defaultReply : reply,
          16384,
        ).runes.toList();
        for (
          var offset = 0;
          offset < chars.length && run.stop.isEmpty;
          offset += chunk
        ) {
          final delta = String.fromCharCodes(
            chars.sublist(offset, (offset + chunk).clamp(0, chars.length)),
          );
          await _append(run, 'stream.delta', {'kind': 'text', 'delta': delta});
          run.text += delta;
          await Future<void>.delayed(Duration(milliseconds: interval));
        }
      }
      final snapshot = {'kind': 'text', 'text': run.text};
      if (run.stop.isNotEmpty) {
        await _append(run, 'stream.${run.stop}', {'snapshot': snapshot});
      }
      await _append(run, 'stream.finish', {'snapshot': snapshot});
      if (!_disposed) {
        generator = run.stop == 'cancel'
            ? '已取消'
            : run.stop == 'error'
            ? '失败'
            : '完成';
      }
    } catch (_) {
      if (!_disposed) {
        generator = '写入结果未确认';
        error = '流写入结果未确认；已停止追加，请重连恢复历史。';
      }
    } finally {
      run.model?.cancel();
      if (!_disposed) {
        _run = null;
        generating = false;
        _emit();
      }
    }
  }

  Future<void> _append(
    _Run run,
    String type,
    Map<String, dynamic> payload,
  ) async {
    if (_disposed) throw const _EventWrite();
    run.index++;
    try {
      final session = _session!;
      await _api!.post('/message/event', {
        'channel_id': session.channel,
        'channel_type': 2,
        'from_uid': session.writer,
        'client_msg_no': run.key,
        'event_id': '${run.key}:${run.index}',
        'event_type': type,
        'event_key': 'main',
        'visibility': 'public',
        'payload': payload,
      });
    } catch (_) {
      throw const _EventWrite();
    }
    if (_disposed) throw const _EventWrite();
    _log('HTTP → $type 已确认');
  }

  void stop({bool failed = false}) {
    final run = _run;
    if (run == null) return;
    if (run.stop.isEmpty) run.stop = failed ? 'error' : 'cancel';
    run.model?.cancel();
  }

  void _closePeers() {
    _cancelRecovery();
    _reader?.dispose();
    _writer?.dispose();
    _reader = null;
    _writer = null;
    readerOnline = false;
    writerOnline = false;
  }

  void reset() {
    if (busy || generating) return;
    _lifecycle++;
    _closePeers();
    _api?.close();
    _api = null;
    _session = null;
    timeline = null;
    error = '';
    generator = '就绪';
    logs.clear();
    _emit();
  }

  @override
  void dispose() {
    _disposed = true;
    _lifecycle++;
    _run?.stop = 'cancel';
    _run?.model?.cancel();
    _closePeers();
    _api?.close();
    super.dispose();
  }

  static const defaultReply =
      'WuKongIM 会先创建一条流消息，再把回复逐段送达。\n\n这些文字由 Flutter EasySDK 实时接收，中文和 emoji 🙂 按 UTF-8 字节偏移合并。\n\n试试取消生成，或断开接收端后重连，观察历史快照恢复。';
}

class _EventWrite implements Exception {
  const _EventWrite();
}
