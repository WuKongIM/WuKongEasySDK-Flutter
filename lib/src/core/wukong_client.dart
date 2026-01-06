import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../enums/wukong_event.dart';
import '../enums/wukong_channel_type.dart';
import '../exceptions/wukong_exceptions.dart';
import '../models/connect_result.dart';
import '../models/disconnect_info.dart';
import '../models/message.dart';
import '../models/send_result.dart';
import '../models/wukong_error.dart';
import '../utils/json_rpc.dart';
import '../utils/uuid_generator.dart';
import '../utils/wukong_constants.dart';
import 'event_manager.dart';
import 'wukong_config.dart';

/// WebSocket client for WuKong communication
///
/// Handles WebSocket connection, JSON-RPC protocol, ping/pong heartbeat, and reconnection logic.
class WuKongClient {
  /// WebSocket channel
  WebSocketChannel? _channel;

  /// Configuration
  final WuKongConfig _config;

  /// Event manager
  final EventManager _eventManager;

  /// Whether the client is connected
  bool _isConnected = false;

  /// Whether the client is connecting
  bool _isConnecting = false;

  /// Whether manual disconnect was initiated
  bool _manualDisconnect = false;

  /// Whether reconnection is in progress
  bool _isReconnecting = false;

  /// Current reconnection attempt count
  int _reconnectAttempts = 0;

  /// Pending requests waiting for responses
  final Map<String, PendingRequest> _pendingRequests = {};

  /// Ping timer
  Timer? _pingTimer;

  /// Connection completer
  Completer<void>? _connectionCompleter;

  /// Stream subscription for WebSocket messages
  StreamSubscription? _messageSubscription;

  /// Creates a new WuKong client
  WuKongClient(this._config, this._eventManager);

  /// Whether the client is connected
  bool get isConnected => _isConnected;

  /// Whether the client is connecting
  bool get isConnecting => _isConnecting;

  /// Connects to the WebSocket server
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      developer.log('Already connected or connecting');
      if (_connectionCompleter != null) {
        return _connectionCompleter!.future;
      }
      return;
    }

    _manualDisconnect = false;
    _isConnecting = true;
    _connectionCompleter = Completer<void>();
    final future = _connectionCompleter!.future;

    try {
      developer.log('Connecting to ${_config.serverUrl}...');

      // Create WebSocket connection
      _channel = WebSocketChannel.connect(Uri.parse(_config.serverUrl));

      // Listen for messages
      _messageSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // Send authentication request
      await _sendConnectRequest();

      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete();
      }
    } catch (error) {
      developer.log('Failed to connect: $error');
      _isConnecting = false;
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError(error);
      }
      _cleanup();
      rethrow;
    } finally {
      _connectionCompleter = null;
    }

    return future;
  }

  /// Disconnects from the WebSocket server
  void disconnect() {
    developer.log('Manual disconnect initiated');
    _manualDisconnect = true;
    _isReconnecting = false;
    _handleDisconnect();
  }

  /// Sends a message
  Future<SendResult> send({
    required String channelId,
    required WuKongChannelType channelType,
    required dynamic payload,
    String? clientMsgNo,
    Map<String, dynamic>? header,
    String? topic,
    dynamic setting,
  }) async {
    if (!_isConnected) {
      throw const WuKongNotConnectedException();
    }

    if (payload == null) {
      throw const WuKongConfigurationException('Payload cannot be null');
    }

    // Set default header values
    final messageHeader = <String, dynamic>{
      'redDot': true,
      ...?header,
    };

    final params = {
      'clientMsgNo': clientMsgNo ?? UuidGenerator.generate(),
      'channelId': channelId,
      'channelType': channelType.value,
      'payload': payload,
      'header': messageHeader,
      if (topic != null) 'topic': topic,
      if (setting != null) 'setting': setting,
    };

    final response = await _sendRequest('send', params);
    return SendResult.fromJson(response);
  }

  /// Sends a JSON-RPC request and waits for response
  Future<dynamic> _sendRequest(String method, dynamic params,
      [int? timeoutMs]) async {
    if (_channel == null) {
      throw const WuKongNotConnectedException();
    }

    final requestId = UuidGenerator.generate();
    final request = JsonRpcRequest(
      method: method,
      params: params,
      id: requestId,
    );

    final completer = Completer<dynamic>();
    final timeout = timeoutMs ?? WuKongConstants.defaultRequestTimeoutMs;

    // Set up timeout
    final timer = Timer(Duration(milliseconds: timeout), () {
      _pendingRequests.remove(requestId);
      if (!completer.isCompleted) {
        completer.completeError(
          WuKongConnectionTimeoutException(
              'Request timeout for method $method'),
        );
      }
    });

    _pendingRequests[requestId] = PendingRequest(
      resolve: (result) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      },
      reject: (error) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      timeoutTimer: timer,
    );

    try {
      final message = jsonEncode(request.toJson());
      developer.log('--> Sending request: $message');
      _channel!.sink.add(message);
    } catch (error) {
      timer.cancel();
      _pendingRequests.remove(requestId);
      rethrow;
    }

    return completer.future;
  }

  /// Sends a JSON-RPC notification (no response expected)
  void _sendNotification(String method, dynamic params) {
    if (_channel == null) {
      developer.log('Cannot send notification, not connected');
      return;
    }

    final notification = JsonRpcNotification(
      method: method,
      params: params,
    );

    try {
      final message = jsonEncode(notification.toJson());
      developer.log('--> Sending notification: $message');
      _channel!.sink.add(message);
    } catch (error) {
      developer.log('Error sending notification: $error');
    }
  }

  /// Sends the connect/authentication request
  Future<void> _sendConnectRequest() async {
    try {
      final params = _config.toAuthParams();
      final result = await _sendRequest(
          'connect', params, WuKongConstants.connectTimeoutMs);

      final connectResult = ConnectResult.fromJson(result);
      developer.log('Authentication successful: $connectResult');

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _isReconnecting = false;

      _startPing();
      _eventManager.emit(WuKongEvent.connect, connectResult);
    } catch (error) {
      developer.log('Authentication failed: $error');
      _isConnecting = false;

      final wukongError = error is WuKongException
          ? WuKongError.authError(error.message)
          : WuKongError.authError('Authentication failed: $error');

      _eventManager.emit(WuKongEvent.error, wukongError);
      _cleanup();
      rethrow;
    }
  }

  /// Handles incoming WebSocket messages
  void _handleMessage(dynamic data) {
    try {
      developer.log('<-- Received: $data');
      final json = jsonDecode(data.toString()) as Map<String, dynamic>;

      if (json.containsKey('id')) {
        // It's a response
        _handleResponse(JsonRpcResponse.fromJson(json));
      } else if (json.containsKey('method')) {
        // It's a notification
        _handleNotification(JsonRpcNotification.fromJson(json));
      } else {
        developer.log('Unknown message format: $json');
      }
    } catch (error) {
      developer.log('Error parsing message: $error');
      _eventManager.emit(
          WuKongEvent.error,
          WuKongError.fromException(
            Exception('Failed to parse message: $error'),
          ));
    }
  }

  /// Handles JSON-RPC responses
  void _handleResponse(JsonRpcResponse response) {
    developer.log('<-- Handling response: ${response.id}');

    final pending = _pendingRequests.remove(response.id);
    if (pending != null) {
      if (response.isError) {
        final error =
            WuKongProtocolException('Server error: ${response.error!.message}');
        pending.reject(error);
      } else {
        pending.resolve(response.result);
      }
    } else {
      developer.log('Received response for unknown request: ${response.id}');
    }
  }

  /// Handles JSON-RPC notifications
  void _handleNotification(JsonRpcNotification notification) {
    developer.log('<-- Handling notification: ${notification.method}');

    switch (notification.method) {
      case 'recv':
        _handleRecvNotification(notification.params);
        break;
      case 'pong':
        _handlePongNotification();
        break;
      case 'disconnect':
        _handleServerDisconnect(notification.params);
        break;
      default:
        developer.log('Unknown notification method: ${notification.method}');
    }
  }

  /// Handles incoming message notifications
  void _handleRecvNotification(dynamic params) {
    try {
      final message = Message.fromJson(params as Map<String, dynamic>);
      _eventManager.emit(WuKongEvent.message, message);

      // Send acknowledgment
      _sendRecvAck(
          message.header.toJson(), message.messageId, message.messageSeq);
    } catch (error) {
      developer.log('Error handling recv notification: $error');
    }
  }

  /// Handles pong notifications
  void _handlePongNotification() {
    developer.log('Pong received');
  }

  /// Handles server-initiated disconnect
  void _handleServerDisconnect(dynamic params) {
    developer.log('Server initiated disconnect: $params');
    final disconnectInfo =
        DisconnectInfo.fromJson(params as Map<String, dynamic>? ?? {});
    _eventManager.emit(WuKongEvent.disconnect, disconnectInfo);
    _handleDisconnect();
  }

  /// Sends message acknowledgment
  void _sendRecvAck(
      Map<String, dynamic> header, String messageId, int messageSeq) {
    final params = {
      'header': header,
      'messageId': messageId,
      'messageSeq': messageSeq,
    };
    _sendNotification('recvack', params);
  }

  /// Starts the ping timer
  void _startPing() {
    _stopPing();

    _pingTimer = Timer.periodic(
      Duration(milliseconds: WuKongConstants.pingIntervalMs),
      (timer) {
        if (_isConnected && _channel != null) {
          _sendPing();
        } else {
          _stopPing();
        }
      },
    );

    developer.log(
        'Ping timer started (${WuKongConstants.pingIntervalMs}ms interval)');
  }

  /// Stops the ping timer
  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
    developer.log('Ping timer stopped');
  }

  /// Sends a ping request
  void _sendPing() {
    try {
      _sendRequest('ping', {}, WuKongConstants.pongTimeoutMs)
          .catchError((error) {
        developer.log('Ping failed: $error');
        _eventManager.emit(
            WuKongEvent.error, WuKongError.timeoutError('Ping timeout'));
        _tryReconnect();
      });
    } catch (error) {
      developer.log('Error sending ping: $error');
    }
  }

  /// Handles WebSocket errors
  void _handleError(dynamic error) {
    developer.log('WebSocket error: $error');

    final wukongError = WuKongError.networkError('WebSocket error: $error');
    _eventManager.emit(WuKongEvent.error, wukongError);
  }

  /// Handles WebSocket disconnection
  void _handleDisconnect() {
    final wasConnected = _isConnected;
    developer.log('WebSocket disconnected. Was connected: $wasConnected');

    final disconnectInfo = DisconnectInfo(
      code: _manualDisconnect ? 1000 : 1006,
      reason: _manualDisconnect ? 'Manual disconnect' : 'Connection lost',
    );

    _cleanup();
    _eventManager.emit(WuKongEvent.disconnect, disconnectInfo);

    // Try to reconnect if it wasn't a manual disconnect and we were previously connected
    if (!_manualDisconnect && wasConnected) {
      _tryReconnect();
    }
  }

  /// Attempts to reconnect with exponential backoff
  void _tryReconnect() {
    if (_isReconnecting || _manualDisconnect) {
      return;
    }

    _isReconnecting = true;
    _scheduleReconnect();
  }

  /// Schedules the next reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= WuKongConstants.maxReconnectAttempts) {
      developer.log('Max reconnect attempts reached. Giving up.');
      _isReconnecting = false;
      _reconnectAttempts = 0;
      _eventManager.emit(
          WuKongEvent.error, WuKongError.networkError('Reconnection failed'));
      return;
    }

    final delay =
        WuKongConstants.initialReconnectDelayMs * pow(2, _reconnectAttempts);
    _reconnectAttempts++;

    developer
        .log('Scheduling reconnect attempt $_reconnectAttempts in ${delay}ms');

    Timer(Duration(milliseconds: delay.toInt()), () {
      if (!_isReconnecting) {
        developer.log('Reconnection cancelled');
        return;
      }

      connect().catchError((error) {
        developer.log('Reconnection attempt failed: $error');
        if (_isReconnecting) {
          _scheduleReconnect();
        }
      });
    });
  }

  /// Cleans up resources
  void _cleanup() {
    _isConnected = false;
    _isConnecting = false;
    _stopPing();

    // Cancel all pending requests
    for (final pending in _pendingRequests.values) {
      if (pending.timeoutTimer is Timer) {
        (pending.timeoutTimer as Timer).cancel();
      }
      pending.reject(const WuKongNetworkException('Connection closed'));
    }
    _pendingRequests.clear();

    // Close WebSocket
    _messageSubscription?.cancel();
    _messageSubscription = null;

    try {
      _channel?.sink.close();
    } catch (error) {
      developer.log('Error closing WebSocket: $error');
    }
    _channel = null;

    // Complete connection completer with error if still pending
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!
          .completeError(const WuKongNetworkException('Connection closed'));
      _connectionCompleter = null;
    }
  }

  /// Disposes the client and cleans up all resources
  void dispose() {
    developer.log('Disposing WuKong client');
    _manualDisconnect = true;
    _isReconnecting = false;
    _cleanup();
  }
}
