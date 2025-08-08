import 'dart:developer' as developer;

import '../enums/wukong_event.dart';
import '../enums/wukong_channel_type.dart';
import '../exceptions/wukong_exceptions.dart';
import '../models/send_result.dart';
import '../utils/event_listener.dart';
import 'event_manager.dart';
import 'wukong_client.dart';
import 'wukong_config.dart';

/// WuKong Easy SDK
///
/// A lightweight Flutter SDK for WuKongIM that enables real-time chat functionality.
/// This is the main entry point for the SDK.
class WuKongEasySDK {
  /// Singleton instance
  static WuKongEasySDK? _instance;

  /// Event manager
  late final EventManager _eventManager;

  /// WebSocket client
  WuKongClient? _client;

  /// Configuration
  WuKongConfig? _config;

  /// Whether the SDK has been initialized
  bool _isInitialized = false;

  /// Private constructor for singleton pattern
  WuKongEasySDK._() {
    _eventManager = EventManager();
  }

  /// Gets the singleton instance of the SDK
  static WuKongEasySDK getInstance() {
    _instance ??= WuKongEasySDK._();
    return _instance!;
  }

  /// Initializes the SDK with the provided configuration
  ///
  /// [config] The configuration for the SDK
  ///
  /// Throws [WuKongConfigurationException] if the configuration is invalid
  Future<void> init(WuKongConfig config) async {
    try {
      developer.log('Initializing WuKong SDK...');

      // Validate configuration
      config.validate();

      // Store configuration
      _config = config;

      // Dispose existing client if any
      _client?.dispose();

      // Create new client
      _client = WuKongClient(config, _eventManager);

      _isInitialized = true;
      developer.log('WuKong SDK initialized successfully');
    } catch (error) {
      developer.log('Failed to initialize SDK: $error');
      if (error is ArgumentError) {
        throw WuKongConfigurationException(error.message);
      }
      rethrow;
    }
  }

  /// Connects to the WuKong server
  ///
  /// Returns a Future that completes when the connection is established and authenticated
  ///
  /// Throws [WuKongConfigurationException] if the SDK is not initialized
  /// Throws [WuKongConnectionTimeoutException] if the connection times out
  /// Throws [WuKongAuthenticationException] if authentication fails
  Future<void> connect() async {
    if (!_isInitialized || _client == null) {
      throw const WuKongConfigurationException(
          'SDK not initialized. Call init() first.');
    }

    try {
      developer.log('Connecting to WuKong server...');
      await _client!.connect();
      developer.log('Connected to WuKong server successfully');
    } catch (error) {
      developer.log('Failed to connect: $error');
      rethrow;
    }
  }

  /// Disconnects from the WuKong server
  void disconnect() {
    if (_client != null) {
      developer.log('Disconnecting from WuKong server...');
      _client!.disconnect();
      developer.log('Disconnected from WuKong server');
    }
  }

  /// Sends a message to the specified channel
  ///
  /// [channelId] The ID of the target channel
  /// [channelType] The type of the target channel
  /// [payload] The message payload (must be JSON-serializable)
  /// [clientMsgNo] Optional client message number (auto-generated if not provided)
  /// [header] Optional message header
  /// [topic] Optional topic for the message
  /// [setting] Optional message settings
  ///
  /// Returns a Future that completes with the send result
  ///
  /// Throws [WuKongNotConnectedException] if not connected
  /// Throws [WuKongInvalidChannelException] if the channel is invalid
  /// Throws [WuKongMessageTooLargeException] if the message is too large
  Future<SendResult> send({
    required String channelId,
    required WuKongChannelType channelType,
    required dynamic payload,
    String? clientMsgNo,
    Map<String, dynamic>? header,
    String? topic,
    dynamic setting,
  }) async {
    if (!_isInitialized || _client == null) {
      throw const WuKongConfigurationException(
          'SDK not initialized. Call init() first.');
    }

    if (!_client!.isConnected) {
      throw const WuKongNotConnectedException();
    }

    try {
      developer.log('Sending message to channel $channelId...');

      final result = await _client!.send(
        channelId: channelId,
        channelType: channelType,
        payload: payload,
        clientMsgNo: clientMsgNo,
        header: header,
        topic: topic,
        setting: setting,
      );

      developer.log('Message sent successfully: ${result.messageId}');
      return result;
    } catch (error) {
      developer.log('Failed to send message: $error');
      rethrow;
    }
  }

  /// Adds an event listener for the specified event type
  ///
  /// [event] The event type to listen for
  /// [listener] The listener function to call when the event occurs
  ///
  /// Example:
  /// ```dart
  /// easySDK.addEventListener(WuKongEvent.connect, (ConnectResult result) {
  ///   print("Connected: $result");
  /// });
  /// ```
  void addEventListener<T>(WuKongEvent event, WuKongEventListener<T> listener) {
    _eventManager.addEventListener(event, listener);
    developer.log('Added event listener for $event');
  }

  /// Removes a specific event listener for the specified event type
  ///
  /// [event] The event type to stop listening for
  /// [listener] The specific listener function to remove
  ///
  /// Returns true if the listener was found and removed, false otherwise
  ///
  /// Example:
  /// ```dart
  /// bool removed = easySDK.removeEventListener(WuKongEvent.connect, connectListener);
  /// ```
  bool removeEventListener<T>(
      WuKongEvent event, WuKongEventListener<T> listener) {
    final removed = _eventManager.removeEventListener(event, listener);
    if (removed) {
      developer.log('Removed event listener for $event');
    } else {
      developer.log('Event listener not found for $event');
    }
    return removed;
  }

  /// Removes all event listeners for the specified event type
  ///
  /// [event] The event type to clear all listeners for
  ///
  /// Returns the number of listeners that were removed
  int removeAllEventListeners(WuKongEvent event) {
    final count = _eventManager.removeAllEventListeners(event);
    developer.log('Removed $count event listeners for $event');
    return count;
  }

  /// Removes all event listeners for all event types
  ///
  /// Returns the total number of listeners that were removed
  int clearAllEventListeners() {
    final count = _eventManager.clearAllEventListeners();
    developer.log('Cleared all event listeners. Total removed: $count');
    return count;
  }

  /// Gets the current connection status
  ///
  /// Returns true if connected to the server, false otherwise
  bool get isConnected => _client?.isConnected ?? false;

  /// Gets the current connecting status
  ///
  /// Returns true if currently connecting to the server, false otherwise
  bool get isConnecting => _client?.isConnecting ?? false;

  /// Gets whether the SDK has been initialized
  ///
  /// Returns true if the SDK has been initialized, false otherwise
  bool get isInitialized => _isInitialized;

  /// Gets the current configuration
  ///
  /// Returns the current configuration or null if not initialized
  WuKongConfig? get config => _config;

  /// Gets the number of listeners for a specific event type
  ///
  /// [event] The event type to count listeners for
  ///
  /// Returns the number of listeners registered for the event
  int getListenerCount(WuKongEvent event) {
    return _eventManager.getListenerCount(event);
  }

  /// Gets the total number of listeners across all event types
  ///
  /// Returns the total number of listeners registered
  int getTotalListenerCount() {
    return _eventManager.getTotalListenerCount();
  }

  /// Disposes the SDK and cleans up all resources
  ///
  /// This should be called when the SDK is no longer needed to prevent memory leaks
  void dispose() {
    developer.log('Disposing WuKong SDK...');

    _client?.dispose();
    _client = null;

    _eventManager.clearAllEventListeners();

    _config = null;
    _isInitialized = false;

    developer.log('WuKong SDK disposed');
  }
}
