import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'stream_controller.dart';
import 'stream_http.dart';
import 'stream_acceptance.dart';

class StreamDemoView extends StatefulWidget {
  const StreamDemoView({super.key});
  @override
  State<StreamDemoView> createState() => _StreamDemoViewState();
}

class _StreamDemoViewState extends State<StreamDemoView> {
  final controller = StreamController();
  late final api = TextEditingController(
    text: defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5001'
        : 'http://127.0.0.1:5001',
  );
  final question = TextEditingController(text: '介绍一下流消息'),
      reply = TextEditingController(text: StreamController.defaultReply);
  final modelUrl = TextEditingController(text: 'http://127.0.0.1:11434/v1'),
      modelName = TextEditingController(text: 'qwen3:8b'),
      modelKey = TextEditingController();
  bool useModel = false;
  double chunk = 2, interval = 80;
  @override
  void initState() {
    super.initState();
    const acceptanceApi = String.fromEnvironment('STREAM_ACCEPTANCE_API');
    const acceptanceModel = String.fromEnvironment('STREAM_ACCEPTANCE_MODEL');
    if (kDebugMode && acceptanceApi.isNotEmpty && acceptanceModel.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          runStreamAcceptance(controller, acceptanceApi, acceptanceModel),
        );
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    for (final field in [api, question, reply, modelUrl, modelName, modelKey]) {
      field.dispose();
    }
    super.dispose();
  }

  ModelConfig? get model => useModel
      ? ModelConfig(
          url: modelUrl.text.trim(),
          model: modelName.text.trim(),
          key: modelKey.text,
        )
      : null;
  void send() {
    unawaited(
      controller.send(
        question.text,
        reply: reply.text,
        chunk: chunk.toInt(),
        interval: interval.toInt(),
        model: model,
      ),
    );
  }

  Future<void> settings() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('回复设置', style: Theme.of(context).textTheme.titleLarge),
              SwitchListTile(
                title: const Text('兼容模型 SSE'),
                value: useModel,
                onChanged: (value) => update(() {
                  useModel = value;
                }),
              ),
              if (useModel) ...[
                TextField(
                  controller: modelUrl,
                  decoration: const InputDecoration(
                    labelText: '模型 API Base URL',
                  ),
                ),
                TextField(
                  controller: modelName,
                  decoration: const InputDecoration(labelText: '模型名称'),
                ),
                TextField(
                  controller: modelKey,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'API Key（仅保留在当前页面内存）',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('原生设备直接访问模型。生产环境请由业务后端持有模型密钥并写入流事件。'),
                ),
              ] else ...[
                TextField(
                  controller: reply,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 16384,
                  decoration: const InputDecoration(labelText: '模拟回复'),
                ),
                Text('每段 ${chunk.toInt()} 个字符'),
                Slider(
                  value: chunk,
                  min: 1,
                  max: 32,
                  divisions: 31,
                  onChanged: (value) => update(() {
                    chunk = value;
                  }),
                ),
                Text('间隔 ${interval.toInt()} ms'),
                Slider(
                  value: interval,
                  min: 40,
                  max: 500,
                  divisions: 46,
                  onChanged: (value) => update(() {
                    interval = value;
                  }),
                ),
              ],
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('完成'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final rows = controller.timeline?.rows.reversed.toList() ?? <StreamRow>[];
      return Scaffold(
        appBar: AppBar(
          title: const Text('流消息'),
          actions: [
            IconButton(
              onPressed: controller.generating ? null : settings,
              tooltip: '回复设置',
              icon: const Icon(Icons.tune),
            ),
            IconButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('协议日志'),
                  content: SizedBox(
                    width: 500,
                    child: SingleChildScrollView(
                      child: Text(controller.logs.join('\n')),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              ),
              tooltip: '协议日志',
              icon: const Icon(Icons.receipt_long),
            ),
            IconButton(
              onPressed: controller.busy || controller.generating
                  ? null
                  : controller.reset,
              tooltip: '新会话',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: api,
                        enabled:
                            !controller.readerOnline &&
                            !controller.busy &&
                            !controller.generating,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'WuKongIM HTTP API',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: controller.busy || controller.generating
                          ? null
                          : () => controller.connect(api.text),
                      child: const Text('连接'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: controller.readerOnline
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(controller.status)),
                    Text('生成端：${controller.generator}'),
                  ],
                ),
              ),
              if (controller.error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    controller.error,
                    maxLines: 3,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Expanded(
                child: rows.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: Text(
                            '连接后发送问题，观察文字逐段到达。\n\n需要可写的开发集群 API；真机请使用可达的局域网地址。',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          return Align(
                            alignment: row.user
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 620),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: row.user
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row.user ? '你' : '助手 · ${row.status}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  SelectableText(
                                    row.text.isEmpty ? '等待回复…' : row.text,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: controller.busy || !controller.writerOnline
                          ? null
                          : controller.toggleReceiver,
                      child: Text(controller.readerOnline ? '断开接收端' : '重连接收端'),
                    ),
                    if (controller.generating) ...[
                      TextButton(
                        onPressed: controller.stop,
                        child: const Text('取消生成'),
                      ),
                      TextButton(
                        onPressed: () => controller.stop(failed: true),
                        child: const Text('模拟失败'),
                      ),
                    ] else
                      OutlinedButton(
                        onPressed: !controller.writerOnline || controller.busy
                            ? null
                            : () => controller.generate(
                                reply: reply.text,
                                chunk: chunk.toInt(),
                                interval: interval.toInt(),
                                model: model,
                              ),
                        child: const Text('生成回复'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: question,
                        minLines: 1,
                        maxLines: 3,
                        maxLength: 4000,
                        decoration: const InputDecoration(
                          hintText: '输入问题',
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) {
                          if (controller.canSend) send();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: controller.canSend ? send : null,
                      tooltip: '发送',
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
