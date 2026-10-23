import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'stream_controller.dart';
import 'stream_http.dart';

/// Opt-in native driver, compiled only into explicitly configured debug runs.
Future<void> runStreamAcceptance(
  StreamController controller,
  String api,
  String model,
) async {
  final checks = <String>[];
  String failed = '';
  Future<void> wait(String stage, bool Function() condition) async {
    for (var i = 0; i < 300; i++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError(stage);
  }

  void verify(bool condition, String stage) {
    if (!condition) throw StateError(stage);
  }

  Future<void> phase(String name) async {
    await http.post(
      Uri.parse('$model/acceptance'),
      body: jsonEncode({'phase': name}),
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  StreamRow? last() {
    final rows =
        controller.timeline?.rows.where((row) => !row.user).toList() ?? [];
    return rows.isEmpty ? null : rows.last;
  }

  bool completed() => !controller.generating && last()?.finished == true;
  try {
    await controller.connect(api);
    await wait('initial connection', () => controller.canSend);
    const reply = 'Flutter 原生回复：你好🙂，按 UTF-8 偏移逐段抵达。';
    await controller.send('介绍一下流消息', reply: reply, chunk: 1, interval: 80);
    await wait(
      'progressive text',
      () => last()?.text.isNotEmpty == true && last()?.text != reply,
    );
    await phase('partial');
    await wait('normal finish', completed);
    verify(last()?.text == reply, 'normal text mismatch');
    await phase('completed');
    checks.add('actual SDK SEND, EVENT and progressive UTF-8 reply');
    var previous = last()?.key;
    controller.generate(
      reply: List.filled(40, '取消保留🙂').join(),
      chunk: 1,
      interval: 50,
    );
    await wait(
      'cancel partial',
      () =>
          last()?.key != previous &&
          last()?.text.isNotEmpty == true &&
          controller.generating,
    );
    controller.stop();
    await wait('cancel finish', completed);
    verify(
      last()?.status == '已取消' && last()?.text.isNotEmpty == true,
      'cancel snapshot',
    );
    checks.add('cancel preserves confirmed partial snapshot');
    previous = last()?.key;
    controller.generate(
      reply: List.filled(40, '失败保留🙂').join(),
      chunk: 1,
      interval: 50,
    );
    await wait(
      'error partial',
      () =>
          last()?.key != previous &&
          last()?.text.isNotEmpty == true &&
          controller.generating,
    );
    controller.stop(failed: true);
    await wait('error finish', completed);
    verify(last()?.status == '失败', 'failure status');
    checks.add('failure preserves confirmed partial snapshot');
    await controller.toggleReceiver();
    const offline = '离线时生成的完整快照🙂';
    controller.generate(reply: offline, chunk: 2, interval: 40);
    await wait(
      'offline producer finish',
      () => !controller.generating && controller.generator == '完成',
    );
    await controller.toggleReceiver();
    await wait(
      'offline recovery',
      () => controller.canSend && last()?.text == offline,
    );
    await phase('recovered');
    checks.add('offline generation and messagesync recovery');
    final overlap = List.filled(10, '重连合并🙂').join();
    previous = last()?.key;
    controller.generate(reply: overlap, chunk: 1, interval: 50);
    await wait(
      'overlap partial',
      () =>
          last()?.key != previous &&
          controller.generating &&
          utf8.encode(last()?.text ?? '').length > 20,
    );
    await controller.toggleReceiver();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await controller.toggleReceiver();
    await wait(
      'overlap finish',
      () => controller.canSend && completed() && last()?.text == overlap,
    );
    checks.add('snapshot and buffered live deltas merge without repetition');
    const secret = 'FLUTTER_MODEL_KEY_CANARY_9B1E';
    ModelConfig config(String name) =>
        ModelConfig(url: model, model: name, key: secret);
    previous = last()?.key;
    await controller.send('继续上一轮问题', model: config('fixture-chat'));
    await wait('model finish', () => last()?.key != previous && completed());
    verify(
      last()?.text == '模型回复🙂，分段到达。' && last()?.status == '完成',
      'model response',
    );
    checks.add('local compatible SSE model through actual IM events');
    for (final name in ['fixture-error', 'fixture-truncated']) {
      previous = last()?.key;
      controller.generate(model: config(name));
      await wait(name, () => last()?.key != previous && completed());
      verify(
        last()?.status == '失败' && last()?.text.isNotEmpty == true,
        '$name partial snapshot',
      );
    }
    checks.add('SSE error and unexpected EOF preserve partial snapshots');
    previous = last()?.key;
    controller.generate(model: config('fixture-slow'));
    await wait(
      'model partial',
      () =>
          last()?.key != previous &&
          controller.generating &&
          last()?.text.isNotEmpty == true,
    );
    controller.stop();
    await wait('model cancelled', completed);
    verify(last()?.status == '已取消', 'model cancellation status');
    checks.add('upstream model cancellation');
    final visible =
        (controller.timeline?.rows.map((r) => r.text).join() ?? '') +
        controller.logs.join();
    verify(!visible.contains(secret), 'model key visible');
    checks.add('model key excluded from transcript and logs');
    await phase('model');
  } on StateError catch (error) {
    failed = error.message;
  } catch (_) {
    failed = 'native acceptance operation';
  }
  await http.post(
    Uri.parse('$model/acceptance'),
    body: jsonEncode({
      'report': {
        'passed': failed.isEmpty,
        'checks': checks,
        'failed_stage': failed,
        if (failed.isNotEmpty)
          'diagnostics': {
            'status': controller.status,
            'generator': controller.generator,
            'error': controller.error,
            'rows': controller.timeline?.rows
                .map(
                  (r) => {
                    'user': r.user,
                    'status': r.status,
                    'bytes': utf8.encode(r.text).length,
                  },
                )
                .toList(),
            'logs': controller.logs,
          },
        'environment': {'framework': 'Flutter'},
      },
    }),
  );
}
