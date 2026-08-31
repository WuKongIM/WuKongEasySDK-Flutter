# WuKong Easy SDK for Flutter

[![pub package](https://img.shields.io/pub/v/wukong_easy_sdk.svg)](https://pub.dev/packages/wukong_easy_sdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev/)

一个轻量级、易于使用的 Flutter SDK，用于 [WuKongIM](https://github.com/WuKongIM/WuKongIM)，可在几分钟内为您的 Flutter 应用程序启用实时消息功能。

## ✨ 特性

- 🚀 **快速集成**：5分钟内即可开始使用
- 🔄 **自动重连**：内置智能重连机制，支持指数退避
- 📱 **跨平台**：无缝支持 iOS、Android、Web 和桌面端
- 🎯 **类型安全**：完整的 Dart 类型安全和空安全支持
- 🔧 **易于使用**：简单直观的 API 设计
- 📦 **轻量级**：最少依赖（仅2个外部包）
- 🎨 **事件驱动**：响应式编程与事件监听器
- 🔐 **安全**：支持身份验证的 WebSocket
- 📊 **实时**：即时消息传递和状态更新

## 📋 系统要求

- Flutter 3.0.0 或更高版本
- Dart 3.0.0 或更高版本
- 运行中的 [WuKongIM 服务器](https://github.com/WuKongIM/WuKongIM)

## 📦 安装

在您的 `pubspec.yaml` 文件中添加以下依赖：

```yaml
dependencies:
  wukong_easy_sdk: ^1.0.5
```

然后运行：

```bash
flutter pub get
```

## 🚀 快速开始

### 步骤 1：导入 SDK

```dart
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart';
```

### 步骤 2：初始化 SDK

```dart
// 创建配置
final config = WuKongConfig(
  serverUrl: "ws://your-wukongim-server.com:5200",  // 您的 WuKongIM 服务器 URL
  uid: "user123",                                   // 唯一用户标识符
  token: "your_auth_token",                         // 身份验证令牌
  deviceId: "device_001",                           // 可选：设备标识符
  deviceFlag: WuKongDeviceFlag.app,                 // 可选：设备类型（app/web/pc）
  debugLogging: false,                               // 可选：默认关闭
);

// 获取 SDK 实例并初始化
final easySDK = WuKongEasySDK.getInstance();
await easySDK.init(config);
```

SDK 诊断日志默认关闭。开启后只记录协议阶段及请求 ID 是否存在，不记录 ID
本身、认证参数、消息 Payload 或原始 WebSocket 报文。也可以把诊断信息接入应用自己的日志系统：

```dart
final config = WuKongConfig(
  serverUrl: "wss://your-wukongim-server.com/ws",
  uid: "user123",
  token: "your_auth_token",
  debugLogging: true,
  logHandler: (message) => yourLogger.debug(message),
);
```

### 步骤 3：设置事件监听器

```dart
// 监听连接事件
easySDK.addEventListener(WuKongEvent.connect, (ConnectResult result) {
  print("✅ 连接成功！");
  print("服务器版本: ${result.serverVersion}");
  print("时间差: ${result.timeDiff}ms");
});

easySDK.addEventListener(WuKongEvent.disconnect, (DisconnectInfo info) {
  print("❌ 连接断开（代码: ${info.code}）");
  // 不要把 info.reason 写入日志；请映射为可信的用户提示。
});

// 监听接收消息
easySDK.addEventListener(WuKongEvent.message, (Message message) {
  print("📨 收到新消息");
  // 仅在可信 UI 中解析并展示 message.payload，不要将其写入日志。
});

// 监听错误
easySDK.addEventListener(WuKongEvent.error, (WuKongError error) {
  print("🚨 SDK 错误（代码: ${error.code.name}）");
  // 生产日志不要记录 error.message 与 error.data。
});
```

### 步骤 4：连接到服务器

```dart
try {
  await easySDK.connect();
  print("🎉 已连接到 WuKongIM 服务器！");
} catch (e) {
  print("💥 连接失败");
  // 处理错误，但不要把原始异常写入日志。
}
```

### 步骤 5：发送消息

```dart
// 创建消息载荷
final messagePayload = {
  "type": 1,                           // 消息类型（1 = 文本）
  "content": "来自 Flutter 的问候！",    // 消息内容
  "timestamp": DateTime.now().millisecondsSinceEpoch,
};

try {
  final result = await easySDK.send(
    channelId: "friend_user_id",              // 目标用户/频道 ID
    channelType: WuKongChannelType.person,    // 频道类型（个人/群组）
    payload: messagePayload,                  // 消息数据
  );
  
  print("✅ 消息发送成功！");
  print("消息序号: ${result.messageSeq}");
  // 不要把服务端返回的 result.messageId 写入应用日志。
} catch (e) {
  print("❌ 发送消息失败");
  // 只上报固定分类或其他明确安全的元数据。
}
```

### 步骤 6：清理资源（重要！）

```dart
@override
void dispose() {
  // 移除事件监听器
  easySDK.removeEventListener(WuKongEvent.connect, connectListener);
  easySDK.removeEventListener(WuKongEvent.message, messageListener);
  
  // 断开连接并释放资源
  easySDK.disconnect();
  easySDK.dispose();
  
  super.dispose();
}
```

## 📚 使用方法

### 完整示例

以下是在 Flutter 应用中集成 WuKong Easy SDK 的完整示例：

```dart
import 'package:flutter/material.dart';
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late WuKongEasySDK easySDK;
  bool isConnected = false;
  List<String> messages = [];
  
  // 事件监听器引用
  WuKongEventListener<ConnectResult>? connectListener;
  WuKongEventListener<Message>? messageListener;
  WuKongEventListener<DisconnectInfo>? disconnectListener;

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    easySDK = WuKongEasySDK.getInstance();
    
    // 配置 SDK
    final config = WuKongConfig(
      serverUrl: "ws://localhost:5200",
      uid: "flutter_user",
      token: "your_token_here",
    );
    
    await easySDK.init(config);
    _setupEventListeners();
    
    // 连接到服务器
    try {
      await easySDK.connect();
    } catch (e) {
      print("连接失败");
      // 不要把原始异常插入应用日志。
    }
  }

  void _setupEventListeners() {
    connectListener = (ConnectResult result) {
      setState(() {
        isConnected = true;
      });
      _addMessage("已连接到服务器！");
    };

    messageListener = (Message message) {
      _addMessage("收到新消息");
      // 仅在可信聊天 UI 中解析并展示 message.payload。
    };

    disconnectListener = (DisconnectInfo info) {
      setState(() {
        isConnected = false;
      });
      _addMessage("连接断开");
      // 将 info.reason 映射为可信用户提示，不要直接记录。
    };

    easySDK.addEventListener(WuKongEvent.connect, connectListener!);
    easySDK.addEventListener(WuKongEvent.message, messageListener!);
    easySDK.addEventListener(WuKongEvent.disconnect, disconnectListener!);
  }

  void _addMessage(String message) {
    setState(() {
      messages.add(message);
    });
  }

  Future<void> _sendMessage(String content) async {
    if (!isConnected) return;
    
    try {
      await easySDK.send(
        channelId: "test_channel",
        channelType: WuKongChannelType.person,
        payload: {"type": 1, "content": content},
      );
      _addMessage("您: $content");
    } catch (e) {
      _addMessage("发送失败");
      // 不要在日志或面向用户的诊断信息中记录原始异常。
    }
  }

  @override
  void dispose() {
    // 清理事件监听器
    if (connectListener != null) {
      easySDK.removeEventListener(WuKongEvent.connect, connectListener!);
    }
    if (messageListener != null) {
      easySDK.removeEventListener(WuKongEvent.message, messageListener!);
    }
    if (disconnectListener != null) {
      easySDK.removeEventListener(WuKongEvent.disconnect, disconnectListener!);
    }
    
    easySDK.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WuKong 聊天'),
        backgroundColor: isConnected ? Colors.green : Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## 📖 API 参考

### WuKongEasySDK

实现单例模式的主要 SDK 类。

#### 静态方法

| 方法 | 描述 | 返回值 |
|------|------|--------|
| `getInstance()` | 获取单例 SDK 实例 | `WuKongEasySDK` |

#### 实例方法

| 方法 | 参数 | 描述 | 返回值 |
|------|------|------|--------|
| `init(config)` | `WuKongConfig config` | 使用配置初始化 SDK | `Future<void>` |
| `connect()` | 无 | 连接到 WuKongIM 服务器 | `Future<void>` |
| `disconnect()` | 无 | 断开服务器连接 | `void` |
| `send()` | 见 [发送参数](#发送参数) | 发送消息 | `Future<SendResult>` |
| `addEventListener()` | `WuKongEvent event, Function listener` | 添加事件监听器 | `void` |
| `removeEventListener()` | `WuKongEvent event, Function listener` | 移除事件监听器 | `void` |
| `dispose()` | 无 | 清理所有资源 | `void` |

#### 属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `isConnected` | `bool` | 是否已连接到服务器 |
| `isConnecting` | `bool` | 是否正在连接中 |
| `isInitialized` | `bool` | SDK 是否已初始化 |

#### 发送参数

```dart
Future<SendResult> send({
  required String channelId,           // 目标频道/用户 ID
  required WuKongChannelType channelType, // 频道类型
  required dynamic payload,            // 消息载荷
  String? clientMsgNo,                // 可选：客户端消息编号
  Map<String, dynamic>? header,       // 可选：消息头
  String? topic,                      // 可选：消息主题
  dynamic setting,                    // 可选：消息设置
})
```

### 事件

| 事件 | 触发时机 | 数据类型 |
|------|----------|----------|
| `WuKongEvent.connect` | 连接建立 | `ConnectResult` |
| `WuKongEvent.disconnect` | 连接丢失 | `DisconnectInfo` |
| `WuKongEvent.message` | 接收到消息 | `Message` |
| `WuKongEvent.error` | 发生错误 | `WuKongError` |
| `WuKongEvent.sendAck` | 收到消息发送确认 | `SendResult` |
| `WuKongEvent.reconnecting` | SDK 正在尝试重连 | `ReconnectingInfo` |
| `WuKongEvent.customEvent` | 收到服务器自定义事件 | `EventNotification` |

### 频道类型

| 类型 | 值 | 描述 |
|------|----|----- |
| `WuKongChannelType.person` | 1 | 一对一私聊 |
| `WuKongChannelType.group` | 2 | 群聊 |
| `WuKongChannelType(value)` | 自定义 | 自定义频道类型 |

### 数据模型

#### ConnectResult
```dart
class ConnectResult {
  final String? serverKey;      // 服务器加密密钥（可选）
  final String? salt;           // 加密盐值（可选）
  final int timeDiff;           // 与服务器的时间差（毫秒）
  final int reasonCode;         // 连接原因代码
  final int? serverVersion;     // 服务器版本（可选）
  final int? nodeId;            // 服务器节点 ID（可选）
}
```

#### Message
```dart
class Message {
  final String messageId;       // 唯一消息 ID
  final int messageSeq;         // 消息序列号
  final String fromUid;         // 发送者用户 ID
  final String channelId;       // 频道/会话 ID
  final int channelType;        // 频道类型
  final dynamic payload;        // 消息内容
  final int timestamp;          // 消息时间戳
  final MessageHeader header;   // 消息头
}
```

#### SendResult
```dart
class SendResult {
  final String messageId;       // 生成的消息 ID
  final int messageSeq;         // 消息序列号
  final int reasonCode;         // 原因码（参考 WuKongReasonCode）
}
```

#### EventNotification
```dart
class EventNotification {
  final String id;              // 事件唯一 ID
  final String type;            // 事件类型
  final int timestamp;          // 事件时间戳
  final dynamic data;           // 事件数据
  final MessageHeader? header;  // 可选消息头
}
```

#### ReconnectingInfo
```dart
class ReconnectingInfo {
  final int attempt;            // 当前重连尝试次数
  final int delay;              // 下一次尝试前的延迟（毫秒）
}
```

## 🚨 错误处理

SDK 为不同的错误场景提供了特定的异常类型：

```dart
try {
  await easySDK.send(
    channelId: "user123",
    channelType: WuKongChannelType.person,
    payload: {"type": 1, "content": "你好！"},
  );
} catch (e) {
  if (e is WuKongNotConnectedException) {
    print("❌ 未连接到服务器");
    // 向用户显示连接错误
  } else if (e is WuKongConfigurationException) {
    print("⚙️ 配置错误");
    // 修复配置问题
  } else if (e is WuKongProtocolException) {
    print("🔌 协议错误");
    // 处理协议级错误
  } else if (e is WuKongNetworkException) {
    print("🌐 网络错误");
    // 处理网络连接问题
  } else if (e is WuKongAuthenticationException) {
    print("🔐 身份验证失败");
    // 处理身份验证错误
  } else if (e is WuKongConnectionTimeoutException) {
    print("⏰ 连接超时");
    // 处理超时场景
  } else {
    print("💥 意外错误");
    // 处理其他错误
  }
}
```

异常消息、断开原因及消息 Payload 可能包含服务端或用户可控数据。生产日志不要
直接记录这些内容；应先映射为固定分类和明确安全的元数据。

## 💡 最佳实践

### 1. 事件监听器管理

始终存储事件监听器的引用以便正确清理：

```dart
class _ChatPageState extends State<ChatPage> {
  late WuKongEasySDK easySDK;
  WuKongEventListener<Message>? messageListener;
  WuKongEventListener<ConnectResult>? connectListener;

  @override
  void initState() {
    super.initState();
    easySDK = WuKongEasySDK.getInstance();
    _setupListeners();
  }

  void _setupListeners() {
    messageListener = (Message message) {
      if (mounted) {
        setState(() {
          // 安全地处理消息
        });
      }
    };

    connectListener = (ConnectResult result) {
      if (mounted) {
        // 处理连接
      }
    };

    easySDK.addEventListener(WuKongEvent.message, messageListener!);
    easySDK.addEventListener(WuKongEvent.connect, connectListener!);
  }

  @override
  void dispose() {
    // 始终清理监听器
    if (messageListener != null) {
      easySDK.removeEventListener(WuKongEvent.message, messageListener!);
    }
    if (connectListener != null) {
      easySDK.removeEventListener(WuKongEvent.connect, connectListener!);
    }
    super.dispose();
  }
}
```

### 2. 连接状态管理

```dart
class ConnectionManager {
  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  static Future<void> ensureConnection() async {
    final sdk = WuKongEasySDK.getInstance();

    if (!sdk.isConnected) {
      try {
        await sdk.connect();
        _isConnected = true;
      } catch (e) {
        _isConnected = false;
        throw e;
      }
    }
  }

  static Future<void> sendMessage(String channelId, dynamic payload) async {
    await ensureConnection();

    final sdk = WuKongEasySDK.getInstance();
    await sdk.send(
      channelId: channelId,
      channelType: WuKongChannelType.person,
      payload: payload,
    );
  }
}
```

### 3. 消息载荷结构

```dart
// 推荐的消息载荷结构
final messagePayload = {
  "type": 1,                                    // 消息类型（1=文本，2=图片等）
  "content": "你好，世界！",                      // 消息内容
  "timestamp": DateTime.now().millisecondsSinceEpoch,
  "extra": {                                    // 可选的额外数据
    "mentions": ["user123"],                    // 提及的用户
    "reply_to": "message_id_123",              // 回复的消息
  }
};
```

## 📱 示例应用程序

此 SDK 包含一个完整的示例应用程序，演示所有功能：

```bash
cd example
flutter run
```

示例应用包括：
- ✅ 带有可视状态的连接管理
- ✅ 实时消息界面
- ✅ 事件日志和调试
- ✅ 错误处理演示
- ✅ 现代 Material Design 3 UI

## 🔧 开发

### 运行测试

```bash
flutter test
```

### 代码分析

```bash
flutter analyze
```

### 构建文档

```bash
dart doc
```

## 🌍 平台支持

| 平台 | 状态 | 说明 |
|------|------|------|
| Android | ✅ 支持 | Android 5.0+ (API 21+) |
| iOS | ✅ 支持 | iOS 11.0+ |
| Web | ✅ 支持 | 支持 WebSocket 的现代浏览器 |
| macOS | ✅ 支持 | macOS 10.14+ |
| Windows | ✅ 支持 | Windows 10+ |
| Linux | ✅ 支持 | 现代 Linux 发行版 |

## 📄 许可证

本项目采用 MIT 许可证 - 详情请参阅 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎贡献！请随时提交 Pull Request。对于重大更改，请先开启 issue 讨论您想要更改的内容。

1. Fork 仓库
2. 创建您的功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📞 支持

- 📖 **文档**: [API 参考](https://pub.dev/documentation/wukong_easy_sdk/latest/)
- 🐛 **问题**: [GitHub Issues](https://github.com/WuKongIM/wukong_easy_sdk/issues)
- 💬 **讨论**: [GitHub Discussions](https://github.com/WuKongIM/wukong_easy_sdk/discussions)
- 🌐 **WuKongIM**: [官方网站](https://github.com/WuKongIM/WuKongIM)

## 📊 更新日志

详细的更改和版本历史请参阅 [CHANGELOG.md](CHANGELOG.md)。

---

由 WuKongIM 团队用 ❤️ 制作
