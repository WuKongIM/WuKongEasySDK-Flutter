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

class LogEntry {
  final String message;
  final DateTime timestamp;
  final LogType type;

  LogEntry(this.message, this.type) : timestamp = DateTime.now();
}

enum LogType { info, success, error, incoming, outgoing }

class _WuKongTestPageState extends State<WuKongTestPage> {
  late WuKongEasySDK easySDK;

  // Controllers for input fields
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _targetUserIdController =
      TextEditingController();
  final TextEditingController _messageJsonController = TextEditingController();

  // State variables
  bool _isConnected = false;
  bool _isConnecting = false;
  final List<LogEntry> _logs = [];

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

    _addLog('Example loaded. Enter connection details and click Connect.',
        LogType.info);
  }

  void _setupEventListeners() {
    connectListener = (ConnectResult result) {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });
        _addLog('Connected to server! (Reason: ${result.reasonCode})',
            LogType.success);
      }
    };

    disconnectListener = (DisconnectInfo info) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isConnecting = false;
        });
        _addLog('Disconnected. Code: ${info.code}, Reason: ${info.reason}',
            LogType.info);
      }
    };

    messageListener = (Message message) {
      if (mounted) {
        _addLog(
            'Received message from ${message.fromUid}: ${jsonEncode(message.payload)}',
            LogType.incoming);
      }
    };

    errorListener = (WuKongError error) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        _addLog('Error: ${error.message}', LogType.error);
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

  void _addLog(String message, LogType type) {
    setState(() {
      _logs.insert(0, LogEntry(message, type));
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

    _addLog('Connecting to ${_serverUrlController.text}...', LogType.info);

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
      _addLog('Connection failed: $e', LogType.error);
    }
  }

  void _disconnect() {
    _addLog('Disconnecting...', LogType.info);
    easySDK.disconnect();
  }

  Future<void> _sendMessage() async {
    if (!_isConnected || _messageJsonController.text.isEmpty) return;

    try {
      // Parse the JSON message
      final messageJson = jsonDecode(_messageJsonController.text);

      _addLog('Sending message to ${_targetUserIdController.text}...',
          LogType.outgoing);

      final result = await easySDK.send(
        channelId: _targetUserIdController.text,
        channelType: WuKongChannelType.person,
        payload: messageJson,
      );

      _addLog('Message sent! ID: ${result.messageId}', LogType.success);
    } catch (e) {
      _addLog('Send message failed: $e', LogType.error);
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('WuKongIM SDK Demo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        actions: [
          _buildConnectionStatusBadge(),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // Horizontal layout for wide screens
            return Row(
              children: [
                // Left side: Settings and Control
                Expanded(
                  flex: 2,
                  child: _buildLeftPanel(),
                ),
                // Right side: Logs
                Expanded(
                  flex: 3,
                  child: _buildRightPanel(),
                ),
              ],
            );
          } else {
            // Vertical layout for narrow screens
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildLeftPanel(),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _buildRightPanel(),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildLeftPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'Connection Settings',
            icon: Icons.settings_ethernet,
            child: Column(
              children: [
                _buildTextField(
                  label: 'Server URL',
                  controller: _serverUrlController,
                  hint: 'ws://host:port',
                  enabled: !_isConnected && !_isConnecting,
                  icon: Icons.link,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'User ID',
                        controller: _userIdController,
                        hint: 'UID',
                        enabled: !_isConnected && !_isConnecting,
                        icon: Icons.person,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Token',
                        controller: _tokenController,
                        hint: 'Token',
                        enabled: !_isConnected && !_isConnecting,
                        icon: Icons.key,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            _isConnected || _isConnecting ? null : _connect,
                        icon: _isConnecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.login),
                        label: const Text('Connect'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isConnected ? _disconnect : null,
                        icon: const Icon(Icons.logout),
                        label: const Text('Disconnect'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                              color: _isConnected ? Colors.red : Colors.grey),
                          foregroundColor:
                              _isConnected ? Colors.red : Colors.grey,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Send Message',
            icon: Icons.send,
            child: Column(
              children: [
                _buildTextField(
                  label: 'Target User ID',
                  controller: _targetUserIdController,
                  hint: 'Friend UID',
                  enabled: _isConnected,
                  icon: Icons.alternate_email,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  label: 'Message (JSON)',
                  controller: _messageJsonController,
                  hint: '{"type":1, "content":"Hello"}',
                  enabled: _isConnected,
                  icon: Icons.code,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isConnected ? _sendMessage : null,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send Message'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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

  Widget _buildRightPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, color: Colors.blue),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Console Logs',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _buildLogTile(_logs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusBadge() {
    Color color;
    String text;
    IconData icon;

    if (_isConnected) {
      color = Colors.green;
      text = 'Connected';
      icon = Icons.check_circle;
    } else if (_isConnecting) {
      color = Colors.orange;
      text = 'Connecting';
      icon = Icons.sync;
    } else {
      color = Colors.red;
      text = 'Disconnected';
      icon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool enabled,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogTile(LogEntry entry) {
    Color color;
    IconData icon;

    switch (entry.type) {
      case LogType.info:
        color = Colors.blueGrey;
        icon = Icons.info_outline;
        break;
      case LogType.success:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case LogType.error:
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      case LogType.incoming:
        color = Colors.indigo;
        icon = Icons.arrow_downward;
        break;
      case LogType.outgoing:
        color = Colors.teal;
        icon = Icons.arrow_upward;
        break;
    }

    final timeStr =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.type.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
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
