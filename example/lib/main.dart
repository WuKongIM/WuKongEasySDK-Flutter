import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WuKongIM Test Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const WuKongTestPage(),
    );
  }
}

class WuKongTestPage extends StatefulWidget {
  const WuKongTestPage({super.key});

  @override
  State<WuKongTestPage> createState() => _WuKongTestPageState();
}

class _WuKongTestPageState extends State<WuKongTestPage> {
  late WuKongEasySDK easySDK;

  // Controllers for input fields
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _targetUserIdController = TextEditingController();
  final TextEditingController _messageJsonController = TextEditingController();

  // State variables
  bool _isConnected = false;
  bool _isConnecting = false;
  List<String> _logs = [];

  // Event listeners
  WuKongEventListener<ConnectResult>? connectListener;
  WuKongEventListener<DisconnectInfo>? disconnectListener;
  WuKongEventListener<Message>? messageListener;
  WuKongEventListener<WuKongError>? errorListener;

  @override
  void initState() {
    super.initState();
    easySDK = WuKongEasySDK.getInstance();
    _setupEventListeners();

    // Set default values matching the image
    _serverUrlController.text = 'ws://localhost:5200';
    _userIdController.text = 'testUser';
    _tokenController.text = 'testToken';
    _targetUserIdController.text = 'friendUser';
    _messageJsonController.text = '{"type":1, "content":"Hello!"}';

    _addLog('Example loaded. Enter connection details and click Connect.');
  }

  void _setupEventListeners() {
    connectListener = (ConnectResult result) {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });
        _addLog('Event: Connected! {');
        _addLog('  "serverVersion": ${result.serverVersion ?? 'null'},');
        _addLog('  "timeDiff": ${result.timeDiff},');
        _addLog('  "reasonCode": ${result.reasonCode},');
        _addLog('  "nodeId": ${result.nodeId ?? 'null'}');
        _addLog('}');
      }
    };

    disconnectListener = (DisconnectInfo info) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isConnecting = false;
        });
        _addLog('Event: Disconnected. Code: ${info.code}, Reason: ${info.reason}');
      }
    };

    messageListener = (Message message) {
      if (mounted) {
        _addLog('Event: Message Received {');
        _addLog('  "messageId": "${message.messageId}",');
        _addLog('  "fromUid": "${message.fromUid}",');
        _addLog('  "channelId": "${message.channelId}",');
        _addLog('  "payload": ${jsonEncode(message.payload)}');
        _addLog('}');
      }
    };

    errorListener = (WuKongError error) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        _addLog('Event: Error Occurred - ${error.message}');
      }
    };

    // Add event listeners
    easySDK.addEventListener(WuKongEvent.connect, connectListener!);
    easySDK.addEventListener(WuKongEvent.disconnect, disconnectListener!);
    easySDK.addEventListener(WuKongEvent.message, messageListener!);
    easySDK.addEventListener(WuKongEvent.error, errorListener!);
  }

  void _removeEventListeners() {
    if (connectListener != null) {
      easySDK.removeEventListener(WuKongEvent.connect, connectListener!);
    }
    if (disconnectListener != null) {
      easySDK.removeEventListener(WuKongEvent.disconnect, disconnectListener!);
    }
    if (messageListener != null) {
      easySDK.removeEventListener(WuKongEvent.message, messageListener!);
    }
    if (errorListener != null) {
      easySDK.removeEventListener(WuKongEvent.error, errorListener!);
    }
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now();
      final timeStr = '[${timestamp.hour.toString().padLeft(2, '0')}:'
          '${timestamp.minute.toString().padLeft(2, '0')}:'
          '${timestamp.second.toString().padLeft(2, '0')}]';
      _logs.add('$timeStr $message');
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _connect() async {
    if (_isConnecting || _isConnected) return;

    setState(() {
      _isConnecting = true;
    });

    _addLog('Initializing WKIM with URL: ${_serverUrlController.text}, UID: ${_userIdController.text}');
    _addLog('Attempting to connect...');

    try {
      final config = WuKongConfig(
        serverUrl: _serverUrlController.text,
        uid: _userIdController.text,
        token: _tokenController.text,
        deviceFlag: WuKongDeviceFlag.app,
      );

      await easySDK.init(config);
      await easySDK.connect();
    } catch (e) {
      setState(() {
        _isConnecting = false;
      });
      _addLog('Connection failed: $e');
    }
  }

  void _disconnect() {
    _addLog('Disconnecting...');
    easySDK.disconnect();
  }

  Future<void> _sendMessage() async {
    if (!_isConnected || _messageJsonController.text.isEmpty) return;

    try {
      // Parse the JSON message
      final messageJson = jsonDecode(_messageJsonController.text);

      _addLog('Sending message to ${_targetUserIdController.text}...');

      final result = await easySDK.send(
        channelId: _targetUserIdController.text,
        channelType: WuKongChannelType.person,
        payload: messageJson,
      );

      _addLog('Message sent successfully! MessageID: ${result.messageId}, MessageSeq: ${result.messageSeq}');
    } catch (e) {
      _addLog('Send message failed: $e');
    }
  }

  @override
  void dispose() {
    _removeEventListeners();
    _serverUrlController.dispose();
    _userIdController.dispose();
    _tokenController.dispose();
    _targetUserIdController.dispose();
    _messageJsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'WuKongIM Test Example',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Connection Settings Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputField('Server URL:', _serverUrlController, !_isConnected && !_isConnecting),
                  const SizedBox(height: 16),
                  _buildInputField('User ID:', _userIdController, !_isConnected && !_isConnecting),
                  const SizedBox(height: 16),
                  _buildInputField('Token:', _tokenController, !_isConnected && !_isConnecting),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildButton(
                        'Connect',
                        _isConnected || _isConnecting ? null : _connect,
                        Colors.grey[600]!,
                        _isConnecting,
                      ),
                      const SizedBox(width: 12),
                      _buildButton(
                        'Disconnect',
                        _isConnected ? _disconnect : null,
                        Colors.blue,
                        false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Message Sending Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputField('Target User ID:', _targetUserIdController, _isConnected),
                  const SizedBox(height: 16),
                  const Text(
                    'Message (JSON):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: _messageJsonController,
                      enabled: _isConnected,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                        hintText: '{"type":1, "content":"Hello!"}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildButton(
                    'Send Message',
                    _isConnected ? _sendMessage : null,
                    Colors.blue,
                    false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logs Section
            Row(
              children: [
                const Text(
                  'Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                _buildButton(
                  'Clear Log',
                  _clearLogs,
                  Colors.blue,
                  false,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Logs Container
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
            color: enabled ? Colors.white : Colors.grey[100],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback? onPressed, Color color, bool isLoading) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey[400],
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
      ),
    );
  }
}
