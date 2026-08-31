# WuKong Easy SDK for Flutter

[![pub package](https://img.shields.io/pub/v/wukong_easy_sdk.svg)](https://pub.dev/packages/wukong_easy_sdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev/)

A lightweight, easy-to-use Flutter SDK for [WuKongIM](https://github.com/WuKongIM/WuKongIM) that enables real-time messaging functionality in your Flutter applications within minutes.

## ✨ Features

- 🚀 **Quick Integration**: Get started in under 5 minutes
- 🔄 **Auto Reconnection**: Built-in intelligent reconnection with exponential backoff
- 📱 **Cross Platform**: Works seamlessly on iOS, Android, Web, and Desktop
- 🎯 **Type Safe**: Full Dart type safety with null safety support
- 🔧 **Easy to Use**: Simple and intuitive API design
- 📦 **Lightweight**: Minimal dependencies (only 2 external packages)
- 🎨 **Event-Driven**: Reactive programming with event listeners
- 🔐 **Secure**: WebSocket with authentication support
- 📊 **Real-time**: Instant message delivery and status updates

## 📋 Requirements

- Flutter 3.0.0 or higher
- Dart 3.0.0 or higher
- A running [WuKongIM server](https://github.com/WuKongIM/WuKongIM)

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  wukong_easy_sdk: ^1.0.4
```

Then run:

```bash
flutter pub get
```

> **Next release:** `debugLogging` and `logHandler` are available on the
> current `main` branch and will ship in the next package release. They are not
> part of the published `1.0.4` package.

## 🚀 Quick Start

### Step 1: Import the SDK

```dart
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart';
```

### Step 2: Initialize the SDK

```dart
// Create configuration
final config = WuKongConfig(
  serverUrl: "ws://your-wukongim-server.com:5200",  // Your WuKongIM server URL
  uid: "user123",                                   // Unique user identifier
  token: "your_auth_token",                         // Authentication token
  deviceId: "device_001",                           // Optional: Device identifier
  deviceFlag: WuKongDeviceFlag.app,                 // Optional: Device type (app/web/pc)
  debugLogging: false,                               // Optional: disabled by default
);

// Get SDK instance and initialize
final easySDK = WuKongEasySDK.getInstance();
await easySDK.init(config);
```

Diagnostic logging is opt-in. When enabled, the SDK logs protocol stages and
whether a request ID is present, but never the ID itself, authentication
parameters, message payloads, or raw WebSocket frames. You can route those
diagnostics into your own logging system:

```dart
final config = WuKongConfig(
  serverUrl: "wss://your-wukongim-server.com/ws",
  uid: "user123",
  token: "your_auth_token",
  debugLogging: true,
  logHandler: (message) => yourLogger.debug(message),
);
```

### Step 3: Set up Event Listeners

```dart
// Listen for connection events
easySDK.addEventListener(WuKongEvent.connect, (ConnectResult result) {
  print("✅ Connected successfully!");
  print("Server version: ${result.serverVersion}");
  print("Time difference: ${result.timeDiff}ms");
});

easySDK.addEventListener(WuKongEvent.disconnect, (DisconnectInfo info) {
  print("❌ Disconnected (Code: ${info.code})");
  // Do not write info.reason to logs; map it to trusted user-facing copy.
});

// Listen for incoming messages
easySDK.addEventListener(WuKongEvent.message, (Message message) {
  print("📨 New message received");
  // Decode and render message.payload only in a trusted UI; do not log it.
});

// Listen for errors
easySDK.addEventListener(WuKongEvent.error, (WuKongError error) {
  print("🚨 SDK error (Code: ${error.code.name})");
  // Keep error.message and error.data out of production logs.
});
```

### Step 4: Connect to Server

```dart
try {
  await easySDK.connect();
  print("🎉 Connected to WuKongIM server!");
} catch (e) {
  print("💥 Connection failed");
  // Handle the error without logging the raw exception.
}
```

### Step 5: Send Messages

```dart
// Create message payload
final messagePayload = {
  "type": 1,                           // Message type (1 = text)
  "content": "Hello from Flutter!",    // Message content
  "timestamp": DateTime.now().millisecondsSinceEpoch,
};

try {
  final result = await easySDK.send(
    channelId: "friend_user_id",              // Target user/channel ID
    channelType: WuKongChannelType.person,    // Channel type (person/group)
    payload: messagePayload,                  // Message data
  );

  print("✅ Message sent successfully!");
  print("Message Sequence: ${result.messageSeq}");
  // Keep the server-provided result.messageId out of application logs.
} catch (e) {
  print("❌ Failed to send message");
  // Report only a fixed category or other explicitly safe metadata.
}
```

### Step 6: Clean Up (Important!)

```dart
@override
void dispose() {
  // Remove event listeners
  easySDK.removeEventListener(WuKongEvent.connect, connectListener);
  easySDK.removeEventListener(WuKongEvent.message, messageListener);

  // Disconnect and dispose
  easySDK.disconnect();
  easySDK.dispose();

  super.dispose();
}
```

## 📚 Usage

### Complete Example

Here's a complete example of integrating WuKong Easy SDK in a Flutter app:

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

  // Event listener references
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

    // Configure SDK
    final config = WuKongConfig(
      serverUrl: "ws://localhost:5200",
      uid: "flutter_user",
      token: "your_token_here",
    );

    await easySDK.init(config);
    _setupEventListeners();

    // Connect to server
    try {
      await easySDK.connect();
    } catch (e) {
      print("Connection failed");
      // Do not interpolate the raw exception into application logs.
    }
  }

  void _setupEventListeners() {
    connectListener = (ConnectResult result) {
      setState(() {
        isConnected = true;
      });
      _addMessage("Connected to server!");
    };

    messageListener = (Message message) {
      _addMessage("New message received");
      // Decode message.payload and render it only in the trusted chat UI.
    };

    disconnectListener = (DisconnectInfo info) {
      setState(() {
        isConnected = false;
      });
      _addMessage("Disconnected");
      // Map info.reason to trusted user-facing copy instead of logging it.
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
      _addMessage("You: $content");
    } catch (e) {
      _addMessage("Failed to send");
      // Keep the raw exception out of logs and user-visible diagnostics.
    }
  }

  @override
  void dispose() {
    // Clean up event listeners
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
        title: Text('WuKong Chat'),
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
                      hintText: 'Type a message...',
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

## 📖 API Reference

### WuKongEasySDK

The main SDK class implementing the singleton pattern.

#### Static Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `getInstance()` | Get the singleton SDK instance | `WuKongEasySDK` |

#### Instance Methods

| Method | Parameters | Description | Returns |
|--------|------------|-------------|---------|
| `init(config)` | `WuKongConfig config` | Initialize SDK with configuration | `Future<void>` |
| `connect()` | None | Connect to WuKongIM server | `Future<void>` |
| `disconnect()` | None | Disconnect from server | `void` |
| `send()` | See [Send Parameters](#send-parameters) | Send a message | `Future<SendResult>` |
| `addEventListener()` | `WuKongEvent event, Function listener` | Add event listener | `void` |
| `removeEventListener()` | `WuKongEvent event, Function listener` | Remove event listener | `void` |
| `dispose()` | None | Clean up all resources | `void` |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isConnected` | `bool` | Whether connected to server |
| `isConnecting` | `bool` | Whether currently connecting |
| `isInitialized` | `bool` | Whether SDK is initialized |

#### Send Parameters

```dart
Future<SendResult> send({
  required String channelId,           // Target channel/user ID
  required WuKongChannelType channelType, // Channel type
  required dynamic payload,            // Message payload
  String? clientMsgNo,                // Optional: Client message number
  Map<String, dynamic>? header,       // Optional: Message headers
  String? topic,                      // Optional: Message topic
  dynamic setting,                    // Optional: Message settings
})
```

### Events

| Event | Trigger | Data Type |
|-------|---------|-----------|
| `WuKongEvent.connect` | Connection established | `ConnectResult` |
| `WuKongEvent.disconnect` | Connection lost | `DisconnectInfo` |
| `WuKongEvent.message` | Message received | `Message` |
| `WuKongEvent.error` | Error occurred | `WuKongError` |
| `WuKongEvent.sendAck` | Received message send acknowledgment | `SendResult` |
| `WuKongEvent.reconnecting` | SDK is attempting to reconnect | `ReconnectingInfo` |
| `WuKongEvent.customEvent` | Received custom event from server | `EventNotification` |

### Channel Types

| Type | Value | Description |
|------|-------|-------------|
| `WuKongChannelType.person` | 1 | 1-on-1 private chat |
| `WuKongChannelType.group` | 2 | Group chat |
| `WuKongChannelType(value)` | Custom | Custom channel type |

### Data Models

#### ConnectResult
```dart
class ConnectResult {
  final String? serverKey;      // Server encryption key (optional)
  final String? salt;           // Encryption salt (optional)
  final int timeDiff;           // Time difference with server (ms)
  final int reasonCode;         // Connection reason code
  final int? serverVersion;     // Server version (optional)
  final int? nodeId;            // Server node ID (optional)
}
```

#### Message
```dart
class Message {
  final String messageId;       // Unique message ID
  final int messageSeq;         // Message sequence number
  final String fromUid;         // Sender user ID
  final String channelId;       // Channel/conversation ID
  final int channelType;        // Channel type
  final dynamic payload;        // Message content
  final int timestamp;          // Message timestamp
  final MessageHeader header;   // Message headers
}
```

#### SendResult
```dart
class SendResult {
  final String messageId;       // Generated message ID
  final int messageSeq;         // Message sequence number
  final int reasonCode;         // Reason code (see WuKongReasonCode)
}
```

#### EventNotification
```dart
class EventNotification {
  final String id;              // Unique event ID
  final String type;            // Event type
  final int timestamp;          // Event timestamp
  final dynamic data;           // Event data
  final MessageHeader? header;  // Optional message header
}
```

#### ReconnectingInfo
```dart
class ReconnectingInfo {
  final int attempt;            // Current reconnection attempt count
  final int delay;              // Delay before next attempt (ms)
}
```

## 🚨 Error Handling

The SDK provides specific exception types for different error scenarios:

```dart
try {
  await easySDK.send(
    channelId: "user123",
    channelType: WuKongChannelType.person,
    payload: {"type": 1, "content": "Hello!"},
  );
} catch (e) {
  if (e is WuKongNotConnectedException) {
    print("❌ Not connected to server");
    // Show connection error to user
  } else if (e is WuKongConfigurationException) {
    print("⚙️ Configuration error");
    // Fix configuration issues
  } else if (e is WuKongProtocolException) {
    print("🔌 Protocol error");
    // Handle protocol-level errors
  } else if (e is WuKongNetworkException) {
    print("🌐 Network error");
    // Handle network connectivity issues
  } else if (e is WuKongAuthenticationException) {
    print("🔐 Authentication failed");
    // Handle authentication errors
  } else if (e is WuKongConnectionTimeoutException) {
    print("⏰ Connection timeout");
    // Handle timeout scenarios
  } else {
    print("💥 Unexpected error");
    // Handle other errors
  }
}
```

Exception messages, disconnect reasons, and message payloads may contain
server- or user-controlled data. Do not write them directly to production logs;
map them to fixed categories and explicitly safe metadata first.

## 💡 Best Practices

### 1. Event Listener Management

Always store references to your event listeners for proper cleanup:

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
          // Handle message safely
        });
      }
    };

    connectListener = (ConnectResult result) {
      if (mounted) {
        // Handle connection
      }
    };

    easySDK.addEventListener(WuKongEvent.message, messageListener!);
    easySDK.addEventListener(WuKongEvent.connect, connectListener!);
  }

  @override
  void dispose() {
    // Always clean up listeners
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

### 2. Connection State Management

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

### 3. Message Payload Structure

```dart
// Recommended message payload structure
final messagePayload = {
  "type": 1,                                    // Message type (1=text, 2=image, etc.)
  "content": "Hello, World!",                   // Message content
  "timestamp": DateTime.now().millisecondsSinceEpoch,
  "extra": {                                    // Optional extra data
    "mentions": ["user123"],                    // Mentioned users
    "reply_to": "message_id_123",              // Reply to message
  }
};
```

## 📱 Example Application

This SDK includes a complete example application demonstrating all features:

```bash
cd example
flutter run
```

The example app includes:
- ✅ Connection management with visual status
- ✅ Real-time messaging interface
- ✅ Event logging and debugging
- ✅ Error handling demonstrations
- ✅ Modern Material Design 3 UI

## 🔧 Development

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Building Documentation

```bash
dart doc
```

## 🌍 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android | ✅ Supported | Android 5.0+ (API 21+) |
| iOS | ✅ Supported | iOS 11.0+ |
| Web | ✅ Supported | Modern browsers with WebSocket support |
| macOS | ✅ Supported | macOS 10.14+ |
| Windows | ✅ Supported | Windows 10+ |
| Linux | ✅ Supported | Modern Linux distributions |

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

- 📖 **Documentation**: [API Reference](https://pub.dev/documentation/wukong_easy_sdk/latest/)
- 🐛 **Issues**: [GitHub Issues](https://github.com/WuKongIM/wukong_easy_sdk/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/WuKongIM/wukong_easy_sdk/discussions)
- 🌐 **WuKongIM**: [Official Website](https://github.com/WuKongIM/WuKongIM)

## 📊 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes and version history.

---

Made with ❤️ by the WuKongIM team
